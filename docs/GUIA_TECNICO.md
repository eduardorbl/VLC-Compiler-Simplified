# 🔧 Guia Técnico — VLC Build Doctor

Este documento descreve a organização interna do script `vlc_build_doctor.py`
e oferece referências para manutenção, extensão e integração com pipelines.

---

## Arquitetura resumida

O projeto segue filosofia minimalista: apenas um arquivo Python com funções puras
e sem dependências externas.

- **`CheckOutcome`** – dataclass que armazena resultado de cada verificação
  (status, versão, caminho encontrado e mensagem).
- **`Dependency`** – dataclass que associa um identificador curto (`key`),
  rótulo humano (`label`) e a função `checker`.
- **Funções de utilidade** – `check_command`, `check_msys2`, `check_mingw`,
  etc. Cada função retorna um `CheckOutcome`.
- **Lista `DEPENDENCIES`** – registra todas as verificações disponíveis,
  mantendo a ordem exibida ao usuário.
- **CLI (`argparse`)** – interpreta parâmetros `--json`, `--markdown`,
  `--only` e `--list`.
- **Relatórios** – `write_json_report` e `write_markdown_report` geram artefatos
  portáveis com as mesmas informações mostradas no terminal.

### Descoberta de caminhos

- Utilize `discover_msys2_roots()` sempre que for necessário localizar arquivos
  dentro do MSYS2. A função considera `MSYS2_ROOT`, caminhos padrão (`C:\msys64`
  e `C:\msys32`) e todas as entradas do `PATH` que contenham `msys*`.
- Para evitar duplicação ou dependência do nome do usuário/drive, os caminhos
  são normalizados por `deduplicate_paths()`. Reaproveite essas funções em
  novas checagens que procurem executáveis dentro do MSYS2/MinGW.

---

## Adicionando uma nova verificação

1. Crie uma função que retorne `CheckOutcome`. Utilize `check_command` sempre
   que possível para reduzir duplicação.

   ```python
   def check_foobar() -> CheckOutcome:
       return check_command(
           "Foobar",
           ("foobar",),
           ("--version",),
           min_version="1.2",
           hint="Instale via https://example.com/foobar",
       )
   ```

2. Registre a função na lista `DEPENDENCIES`:

   ```python
   DEPENDENCIES.append(
       Dependency("foobar", "Foobar CLI", check_foobar, optional=True)
   )
   ```

3. Execute `python vlc_build_doctor.py --only foobar` para validar.

4. Atualize documentação (`README.md` e tabelas deste guia) se necessário.

---

## Regras de compatibilidade

- Todos os comandos precisam rodar no Windows 10/11 com PowerShell padrão.
- Evite recursos exclusivos de versões recentes do Python; mantenha
  compatibilidade com 3.8.
- Sempre que possível, forneça mensagens em português com instruções diretas
  (links, comandos `winget`, `choco`, `pacman`, etc.).
- Dependências opcionais devem ser marcadas com `optional=True` para evitar
  alarmes falsos no resumo.

---

## Integração contínua (CI)

### Execução headless

Utilize o parâmetro `--json` para gerar artefato que possa ser consumido por
pipelines ou scripts de automação.

Exemplo em YAML (Azure Pipelines):

```yaml
- script: |
    python vlc_build_doctor.py --json $(Build.ArtifactStagingDirectory)\auditoria.json
  displayName: "Auditar ambiente"
- publish: $(Build.ArtifactStagingDirectory)\auditoria.json
  artifact: vlc-auditoria
```

Avalie o conteúdo do JSON para interromper um job quando houver `status == "fail"`
em dependências obrigatórias.

### Parceiros internos

Para equipes que utilizam self-hosted agents, recomenda-se executar o Build
Doctor a cada atualização de imagem base. O relatório deve ficar arquivado
junto ao changelog do agente.

---

## Estrutura da saída JSON

```json
{
  "tool": "vlc-build-doctor",
  "version": "2.0.0",
  "platform": "Windows-10-10.0.19045-SP0",
  "python": "3.11.4 (...)", 
  "results": [
    {
      "name": "Python",
      "status": "ok",
      "version": "3.11.4",
      "location": "C:\\Python311\\python.exe",
      "message": "Python 3.11.4",
      "optional": false
    }
  ]
}
```

Todos os campos seguem tipos simples (`str`, `bool`) para facilitar parsing em
qualquer linguagem.

---

## Convenções de mensagens

- Use frases curtas, na ordem **ação → motivo → referência**.
- Prefira links oficiais (MSYS2, Visual Studio, etc.).
- Quando houver alternativa via gerenciador (`winget`, `choco`, `pacman`),
  cite o comando sugerido.
- Evite caracteres especiais fora do ASCII básico.

---

## Roadmap sugerido

- Acrescentar detecção de SDKs opcionais (DirectX, Windows SDK 10.0.22621).
- Suporte a exportação em CSV.
- Criação de módulo separado para dependências opcionais específicas de
  features (ex.: Qt para interface gráfica).

Contribuições são muito bem-vindas. Abra issues com descrições claras ou envie
pull requests mantendo o estilo minimalista.
