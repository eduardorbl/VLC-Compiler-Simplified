#!/usr/bin/env python3
"""
VLC Build Doctor - Auditoria de ambiente minimalista

Este utilitário verifica se as dependências essenciais para compilar o VLC no
Windows 10 e 11 estão disponíveis. Ele foi projetado para ser simples, sem
instalação automática de pacotes e sem dependências externas, entregando
relatórios fáceis de compartilhar com outros membros da equipe.
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import re
import shutil
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Callable, Dict, Iterable, List, Optional, Sequence


DEFAULT_VERSION_PATTERN = r"(\d+(?:\.\d+)+)"


@dataclass
class CheckOutcome:
    """Representa o resultado de uma verificação."""

    name: str
    status: str
    version: Optional[str]
    location: Optional[str]
    message: str
    optional: bool = False


@dataclass
class Dependency:
    """Configuração de uma verificação."""

    key: str
    label: str
    checker: Callable[[], CheckOutcome]
    optional: bool = False


def deduplicate_paths(paths: Iterable[Path]) -> List[Path]:
    """Remove caminhos duplicados preservando a ordem."""
    seen: set[str] = set()
    result: List[Path] = []

    for path in paths:
        raw = str(path).strip().strip('"')
        if not raw:
            continue
        normalized = os.path.normcase(os.path.normpath(raw))
        if normalized in seen:
            continue
        seen.add(normalized)
        result.append(Path(raw))

    return result


def discover_msys2_roots() -> List[Path]:
    """
    Retorna candidatos para a raiz do MSYS2 com base em variáveis de ambiente,
    caminhos padrão e entradas do PATH.
    """
    candidates: List[Path] = []
    env_root = os.environ.get("MSYS2_ROOT")
    if env_root:
        candidates.append(Path(env_root))

    candidates.extend(
        [
            Path(r"C:\msys64"),
            Path(r"C:\msys32"),
        ]
    )

    path_env = os.environ.get("PATH", "")
    for raw in path_env.split(os.pathsep):
        cleaned = raw.strip().strip('"')
        if not cleaned:
            continue
        entry = Path(cleaned)
        if entry.is_file():
            entry = entry.parent
        parts = entry.parts
        lower_parts = [part.lower() for part in parts]
        for idx, part in enumerate(lower_parts):
            if part.startswith("msys"):
                root = Path(*parts[: idx + 1])
                candidates.append(root)
                break

    return deduplicate_paths(candidates)


def extract_version(text: str, pattern: str = DEFAULT_VERSION_PATTERN) -> Optional[str]:
    """Extrai a primeira versão identificável do texto."""
    match = re.search(pattern, text)
    if match:
        return match.group(1)
    return None


def normalize_version(raw: str) -> List[int]:
    """Converte string de versão em lista de inteiros para comparação."""
    parts: List[int] = []
    for chunk in re.split(r"[^\d]+", raw):
        if chunk:
            try:
                parts.append(int(chunk))
            except ValueError:
                break
    return parts


def version_is_at_least(found: str, minimum: str) -> bool:
    """Compara duas versões numéricas simples."""
    return normalize_version(found) >= normalize_version(minimum)


def run_subprocess(command: Sequence[str]) -> subprocess.CompletedProcess:
    """Executa comando capturando saída de forma segura."""
    return subprocess.run(
        list(command),
        capture_output=True,
        text=True,
        check=False,
    )


def check_command(
    label: str,
    command_names: Sequence[str],
    version_args: Sequence[str],
    *,
    min_version: Optional[str] = None,
    hint: str,
    version_pattern: str = DEFAULT_VERSION_PATTERN,
) -> CheckOutcome:
    """
    Verifica se um comando está disponível e qual versão responde.

    command_names aceita múltiplos nomes para tentar (ex.: python, python3).
    """
    for command in command_names:
        path = shutil.which(command)
        if not path:
            continue

        try:
            completed = run_subprocess([path, *version_args])
        except OSError as exc:
            return CheckOutcome(
                name=label,
                status="fail",
                version=None,
                location=path,
                message=f"Falha ao executar {command}: {exc}",
            )

        combined = "\n".join(
            part.strip() for part in [completed.stdout, completed.stderr] if part
        )
        version = extract_version(combined, version_pattern)

        if completed.returncode != 0 and not combined:
            return CheckOutcome(
                name=label,
                status="warn",
                version=version,
                location=path,
                message=f"Comando retornou código {completed.returncode}. {hint}",
            )

        if min_version and version and not version_is_at_least(version, min_version):
            return CheckOutcome(
                name=label,
                status="warn",
                version=version,
                location=path,
                message=f"Versão detectada {version}. Recomendado >= {min_version}. {hint}",
            )

        if min_version and version is None:
            return CheckOutcome(
                name=label,
                status="warn",
                version=None,
                location=path,
                message=f"Não foi possível determinar a versão. {hint}",
            )

        return CheckOutcome(
            name=label,
            status="ok",
            version=version,
            location=path,
            message=(combined or f"{command} disponível."),
        )

    return CheckOutcome(
        name=label,
        status="fail",
        version=None,
        location=None,
        message=f"Não encontrado no PATH. {hint}",
    )


def check_python() -> CheckOutcome:
    return check_command(
        "Python",
        ("python", "python3"),
        ("--version",),
        min_version="3.8",
        hint="Instale o Python 3.8+ pelo Microsoft Store ou python.org e habilite 'Add to PATH'.",
    )


def check_git() -> CheckOutcome:
    return check_command(
        "Git",
        ("git",),
        ("--version",),
        min_version="2.20",
        hint="Instale o Git para Windows: https://git-scm.com/download/win.",
    )


def check_cmake() -> CheckOutcome:
    return check_command(
        "CMake",
        ("cmake",),
        ("--version",),
        min_version="3.16",
        hint="Baixe o instalador do CMake para Windows: https://cmake.org/download/.",
    )


def check_ninja() -> CheckOutcome:
    return check_command(
        "Ninja",
        ("ninja",),
        ("--version",),
        min_version="1.8",
        hint="Adicione Ninja ao PATH (via MSYS2, Chocolatey ou download manual).",
    )


def check_meson() -> CheckOutcome:
    return check_command(
        "Meson",
        ("meson",),
        ("--version",),
        min_version="0.54",
        hint="Instale com 'pip install meson' dentro do Python utilizado para compilar.",
    )


def check_pkg_config() -> CheckOutcome:
    return check_command(
        "pkg-config",
        ("pkg-config",),
        ("--version",),
        hint="Instale via MSYS2 (pacote mingw-w64-x86_64-pkg-config) e mantenha o binário no PATH.",
    )


def check_nasm() -> CheckOutcome:
    return check_command(
        "NASM",
        ("nasm",),
        ("--version",),
        min_version="2.13",
        hint="Instale o NASM via https://www.nasm.us/ ou gerenciadores (winget/choco).",
    )


def check_perl() -> CheckOutcome:
    # Strawberry Perl escreve versão em stderr (v5.32.1, por exemplo)
    return check_command(
        "Perl",
        ("perl",),
        ("-v",),
        min_version="5.10",
        hint="Instale Strawberry Perl: https://strawberryperl.com/.",
    )


def check_msys2() -> CheckOutcome:
    label = "MSYS2"
    candidates = discover_msys2_roots()

    for root in candidates:
        if not root.exists():
            continue
        bash_locations = [
            root / "usr" / "bin" / "bash.exe",
            root / "bin" / "bash.exe",
        ]
        for bash_path in bash_locations:
            if bash_path.exists():
                return CheckOutcome(
                    name=label,
                    status="ok",
                    version=None,
                    location=str(bash_path),
                    message=f"Instalação detectada em {root}",
                )

    return CheckOutcome(
        name=label,
        status="fail",
        version=None,
        location=None,
        message="MSYS2 não localizado. Instale a partir de https://www.msys2.org/, defina MSYS2_ROOT ou mantenha o diretório \\usr\\bin no PATH.",
    )


def check_mingw() -> CheckOutcome:
    label = "GCC (MinGW-w64)"
    candidates: List[Path] = []
    roots = discover_msys2_roots()
    gcc_layouts = (
        ("mingw64", "bin", "gcc.exe"),
        ("ucrt64", "bin", "gcc.exe"),
        ("clang64", "bin", "gcc.exe"),
        ("mingw32", "bin", "gcc.exe"),
    )

    for root in roots:
        if not root.exists():
            continue
        for layout in gcc_layouts:
            candidates.append(root.joinpath(*layout))

    for env_var in ("MINGW_ROOT", "MINGW_HOME", "MINGW64_DIR"):
        env_value = os.environ.get(env_var)
        if env_value:
            candidates.append(Path(env_value) / "bin" / "gcc.exe")

    candidates.append(Path(r"C:\mingw64\bin\gcc.exe"))

    for exe in candidates:
        if exe.exists():
            try:
                completed = run_subprocess([str(exe), "--version"])
            except OSError as exc:  # pragma: no cover - caminho inválido
                return CheckOutcome(
                    name=label,
                    status="warn",
                    version=None,
                    location=str(exe),
                    message=f"Falha ao executar GCC: {exc}",
                )

            combined = "\n".join(
                part.strip()
                for part in [completed.stdout, completed.stderr]
                if part
            )
            version = extract_version(combined)
            status = "ok" if completed.returncode == 0 else "warn"
            message = (
                combined
                if combined
                else "gcc.exe encontrado, mas sem saída de versão."
            )
            return CheckOutcome(
                name=label,
                status=status,
                version=version,
                location=str(exe),
                message=message,
            )

    fallback = check_command(
        label,
        ("gcc",),
        ("--version",),
        hint="Certifique-se de que o ambiente MinGW-w64 do MSYS2 esteja instalado e no PATH.",
    )
    if fallback.status == "ok":
        return fallback

    return CheckOutcome(
        name=label,
        status="fail",
        version=None,
        location=None,
        message="gcc.exe não encontrado. Instale o MSYS2 e o toolchain MinGW-w64 (pacote mingw-w64-x86_64-toolchain).",
    )


def check_vcpkg() -> CheckOutcome:
    label = "vcpkg"
    env_root = os.environ.get("VCPKG_ROOT")
    candidates: List[Path] = []

    if env_root:
        candidates.append(Path(env_root))
    candidates.append(Path(r"C:\vcpkg"))

    for root in candidates:
        exe = root / "vcpkg.exe"
        if exe.exists():
            try:
                completed = run_subprocess([str(exe), "version"])
            except OSError as exc:
                return CheckOutcome(
                    name=label,
                    status="warn",
                    version=None,
                    location=str(exe),
                    message=f"Não foi possível executar vcpkg: {exc}",
                )

            combined = "\n".join(
                part.strip()
                for part in [completed.stdout, completed.stderr]
                if part
            )
            version = extract_version(combined)
            return CheckOutcome(
                name=label,
                status="ok" if completed.returncode == 0 else "warn",
                version=version,
                location=str(exe),
                message=combined or "vcpkg encontrado.",
            )

    return CheckOutcome(
        name=label,
        status="warn",
        version=None,
        location=None,
        message="vcpkg não localizado. Necessário apenas para dependências extras; instale em https://github.com/microsoft/vcpkg.",
    )


def check_visual_studio() -> CheckOutcome:
    label = "Visual Studio Build Tools"
    vswhere_candidates = [
        Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)"))
        / "Microsoft Visual Studio"
        / "Installer"
        / "vswhere.exe",
        Path(os.environ.get("ProgramFiles", r"C:\Program Files"))
        / "Microsoft Visual Studio"
        / "Installer"
        / "vswhere.exe",
    ]

    for vswhere in vswhere_candidates:
        if vswhere.exists():
            try:
                completed = run_subprocess(
                    [
                        str(vswhere),
                        "-latest",
                        "-products",
                        "*",
                        "-requires",
                        "Microsoft.Component.MSBuild",
                        "-property",
                        "catalog_productLineVersion",
                    ]
                )
            except OSError as exc:
                return CheckOutcome(
                    name=label,
                    status="warn",
                    version=None,
                    location=str(vswhere),
                    message=f"vswhere.exe encontrado, mas não executou: {exc}",
                )

            version = extract_version(completed.stdout or completed.stderr)
            if version:
                return CheckOutcome(
                    name=label,
                    status="ok",
                    version=version,
                    location=str(vswhere),
                    message=f"Versão detectada: {version}",
                )

            env_hint = os.environ.get("VSINSTALLDIR")
            message = "Vswhere executou, mas não encontrou instalações."
            if env_hint:
                message += f" VSINSTALLDIR aponta para {env_hint}."
            return CheckOutcome(
                name=label,
                status="warn",
                version=None,
                location=str(vswhere),
                message=message,
            )

    env_hint = os.environ.get("VSINSTALLDIR")
    if env_hint:
        return CheckOutcome(
            name=label,
            status="warn",
            version=None,
            location=env_hint,
            message="VSINSTALLDIR definido, mas vswhere.exe não foi localizado para confirmar versão.",
        )

    return CheckOutcome(
        name=label,
        status="fail",
        version=None,
        location=None,
        message="Instale o Visual Studio Build Tools 2022 com o workload 'Desktop development with C++'.",
    )


DEPENDENCIES: List[Dependency] = [
    Dependency("python", "Python", check_python),
    Dependency("git", "Git", check_git),
    Dependency("cmake", "CMake", check_cmake),
    Dependency("ninja", "Ninja", check_ninja),
    Dependency("meson", "Meson", check_meson),
    Dependency("pkgconfig", "pkg-config", check_pkg_config, optional=True),
    Dependency("nasm", "NASM", check_nasm),
    Dependency("perl", "Perl", check_perl),
    Dependency("msys2", "MSYS2", check_msys2),
    Dependency("mingw", "GCC (MinGW-w64)", check_mingw),
    Dependency("visualstudio", "Visual Studio Build Tools", check_visual_studio),
    Dependency("vcpkg", "vcpkg", check_vcpkg, optional=True),
]


def run_checks(selected: Optional[Iterable[str]] = None) -> List[CheckOutcome]:
    """Executa verificações respeitando filtros de seleção."""
    selected_set = {key.lower() for key in selected} if selected else None
    outcomes: List[CheckOutcome] = []

    for dependency in DEPENDENCIES:
        if selected_set and dependency.key.lower() not in selected_set:
            continue

        try:
            result = dependency.checker()
        except Exception as exc:  # pragma: no cover - erros inesperados
            result = CheckOutcome(
                name=dependency.label,
                status="fail",
                version=None,
                location=None,
                message=f"Erro inesperado: {exc}",
            )

        result.optional = dependency.optional
        result.name = dependency.label
        outcomes.append(result)

    return outcomes


def format_status(status: str) -> str:
    """Normaliza status para exibição."""
    mapping = {
        "ok": "OK",
        "warn": "AVISO",
        "fail": "FALHA",
    }
    return mapping.get(status.lower(), status.upper())


def render_table(outcomes: List[CheckOutcome]) -> str:
    """Gera tabela legível no terminal."""
    name_width = max(len(outcome.name) for outcome in outcomes) + 2
    version_width = max(
        len(outcome.version or "-") for outcome in outcomes
    ) + 2
    status_width = max(len(format_status(outcome.status)) for outcome in outcomes) + 2

    lines = []
    header = (
        f"{'Componente'.ljust(name_width)}"
        f"{'Status'.ljust(status_width)}"
        f"{'Versão'.ljust(version_width)}"
        f"Local/Observação"
    )
    separator = "-" * len(header)
    lines.extend([header, separator])

    for outcome in outcomes:
        location = outcome.location or "-"
        version = outcome.version or "-"
        lines.append(
            f"{outcome.name.ljust(name_width)}"
            f"{format_status(outcome.status).ljust(status_width)}"
            f"{version.ljust(version_width)}"
            f"{location}"
        )

    return "\n".join(lines)


def summarize(outcomes: List[CheckOutcome]) -> Dict[str, int]:
    """Conta quantos itens tiveram cada status, ignorando opcionais nas falhas."""
    summary = {"ok": 0, "warn": 0, "fail": 0}
    for outcome in outcomes:
        key = outcome.status.lower()
        if key not in summary:
            continue
        if key == "fail" and outcome.optional:
            summary["warn"] += 1
        else:
            summary[key] += 1
    return summary


def write_json_report(path: Path, outcomes: List[CheckOutcome]) -> None:
    """Salva relatório em JSON."""
    payload = {
        "tool": "vlc-build-doctor",
        "version": "2.0.0",
        "platform": platform.platform(),
        "python": sys.version,
        "results": [asdict(outcome) for outcome in outcomes],
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def write_markdown_report(path: Path, outcomes: List[CheckOutcome]) -> None:
    """Salva relatório resumido em Markdown."""
    lines = [
        "# Relatório - VLC Build Doctor",
        "",
        f"- Plataforma: `{platform.platform()}`",
        f"- Python: `{platform.python_version()}`",
        "",
        "| Componente | Status | Versão | Opcional | Observação |",
        "|------------|--------|--------|----------|------------|",
    ]

    for outcome in outcomes:
        status = format_status(outcome.status)
        version = outcome.version or "-"
        optional = "Sim" if outcome.optional else "Não"
        message = outcome.message.replace("\n", " ").strip()
        lines.append(
            f"| {outcome.name} | {status} | {version} | {optional} | {message} |"
        )

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Audita o ambiente de compilação do VLC para Windows 10/11.",
    )
    parser.add_argument(
        "--json",
        type=Path,
        help="Salvar relatório em JSON no caminho informado.",
    )
    parser.add_argument(
        "--markdown",
        type=Path,
        help="Salvar relatório em Markdown no caminho informado.",
    )
    parser.add_argument(
        "--only",
        nargs="+",
        help="Executar apenas os identificadores informados (ex.: --only python git).",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="Listar identificadores de checks disponíveis.",
    )
    return parser.parse_args(argv)


def list_checks() -> None:
    print("Checks disponíveis:")
    for dependency in DEPENDENCIES:
        optional = " (opcional)" if dependency.optional else ""
        print(f"  - {dependency.key}{optional}: {dependency.label}")


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = parse_args(argv)

    if args.list:
        list_checks()
        return 0

    outcomes = run_checks(args.only)

    print("VLC Build Doctor - Auditoria de Ambiente")
    print(f"Sistema detectado: {platform.platform()}")
    print(f"Python em uso: {platform.python_version()}")
    print()
    print(render_table(outcomes))
    print()

    summary = summarize(outcomes)
    print(
        f"Resumo -> OK: {summary['ok']} | Avisos: {summary['warn']} | Falhas: {summary['fail']}"
    )

    issues = [
        outcome
        for outcome in outcomes
        if outcome.status.lower() != "ok"
    ]
    if issues:
        print("\nDetalhes:")
        for outcome in issues:
            optional = " [Opcional]" if outcome.optional else ""
            print(f"- {outcome.name}{optional}: {outcome.message}")

    if args.json:
        write_json_report(args.json, outcomes)
        print(f"\nRelatório JSON salvo em: {args.json}")

    if args.markdown:
        write_markdown_report(args.markdown, outcomes)
        print(f"Relatório Markdown salvo em: {args.markdown}")

    return 0 if summary["fail"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
