# 💡 Exemplos práticos — VLC Build Doctor

Coleções curtas para reaproveitar no dia a dia. Todos os comandos assumem que o
PowerShell está aberto na raiz do projeto.

---

## 1. Auditoria rápida (terminal)

```powershell
python vlc_build_doctor.py
```

Saída esperada:

```
Componente                 Status Versão   Local/Observação
-----------------------------------------------------------
Python                     OK     3.11.2  C:\Python311\python.exe
Git                        OK     2.45.0  C:\Program Files\Git\bin\git.exe
...
```

Use quando estiver configurando a máquina pela primeira vez.

---

## 2. Relatório para anexar em issues

```powershell
$data = Get-Date -Format "yyyyMMdd-HHmm"
python vlc_build_doctor.py --json reports\auditoria-$data.json
```

O arquivo JSON conterá versão do Windows, Python e todos os componentes
checados. Ideal para anexar ao abrir chamado interno.

---

## 3. Checklist parcial

```powershell
python vlc_build_doctor.py --only python git cmake ninja
```

Executa apenas as verificações informadas. Útil para revalidar itens após uma
atualização específica.

---

## 4. Integração com Git hooks

Arquivo `.git/hooks/pre-push` (PowerShell):

```powershell
Write-Host "Executando VLC Build Doctor..."
$result = python vlc_build_doctor.py --only python git --json tmp\doctor.json
if ($LASTEXITCODE -ne 0) {
    Write-Error "Ambiente incompleto. Corrija antes de enviar o push."
    Exit 1
}
Remove-Item tmp\doctor.json
```

Bloqueia push quando Python ou Git estão ausentes/desatualizados.

---

## 5. Monitoramento agendado

Script `Monitorar-Ambiente.ps1`:

```powershell
$logDir = "$PSScriptRoot\relatorios"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm"
$json = Join-Path $logDir "auditoria-$timestamp.json"
$md = Join-Path $logDir "auditoria-$timestamp.md"

python vlc_build_doctor.py --json $json --markdown $md
```

Agende com o **Agendador de Tarefas** do Windows para executar semanalmente em
máquinas de build compartilhadas.

---

## 6. Comparando dois relatórios

Python rápido (executar no PowerShell):

```powershell
python - <<'PY'
import json, sys

with open("reports/auditoria-ontem.json", encoding="utf-8") as f:
    old = {item["name"]: item for item in json.load(f)["results"]}
with open("reports/auditoria-hoje.json", encoding="utf-8") as f:
    new = {item["name"]: item for item in json.load(f)["results"]}

for name, current in new.items():
    previous = old.get(name)
    if not previous:
        print(f"+ {name}: novo check adicionado ({current['status']})")
        continue
    if previous["status"] != current["status"]:
        print(f"* {name}: {previous['status']} -> {current['status']}")
PY
```

Obtém um diff simples entre dois relatórios JSON consecutivos.

---

## 7. Testar build completo do VLC

Após compilar o VLC seguindo `COMPILAR_VLC_GUI.md`, valide se tudo está funcional:

```powershell
# Teste completo (recomendado) - valida 7 componentes críticos
.\test_vlc_build.ps1

# Teste rápido sem reprodução de vídeo (6 testes)
.\test_vlc_build.ps1 -SkipVideoTest

# Teste detalhado com informações extras
.\test_vlc_build.ps1 -Verbose

# Testar instalação em caminho customizado
.\test_vlc_build.ps1 -VlcPath "D:\meu-vlc\bin\vlc.exe"
```

**O que é validado:**
1. ✓ Executável existe e tem tamanho razoável
2. ✓ Plugins instalados (verifica se há 50+ DLLs)
3. ✓ Dependências principais (libvlc.dll, libvlccore.dll)
4. ✓ Comando `--version` funciona
5. ✓ Listagem de módulos responde
6. ✓ **Reprodução real de vídeo** (baixa um clipe de 5s e executa)
7. ✓ Interface Qt está disponível

**Saída esperada (sucesso):**
```
==================================================================
  TESTE DE BUILD DO VLC - Validação Completa
==================================================================

1. Verificando executável do VLC...
[✓] Executável encontrado em C:\vlc-test\bin\vlc.exe

2. Verificando plugins instalados...
[✓] Plugins encontrados: 127 DLLs em 18 categorias

3. Verificando dependências principais...
[✓] libvlc.dll
[✓] libvlccore.dll

4. Testando execução básica (--version)...
[✓] Comando --version executado com sucesso

5. Verificando módulos carregados...
[✓] Listagem de módulos funcional

6. Teste de reprodução de vídeo...
   Baixando vídeo de teste (5s, ~500KB)...
[✓] Download do vídeo de teste
   Reproduzindo vídeo (aguarde 7 segundos)...
[✓] Reprodução de vídeo concluída (exit code: 0)

7. Verificando suporte à interface Qt...
[✓] Módulo Qt detectado

==================================================================
  RESUMO DOS TESTES
==================================================================

Total de testes: 7
Aprovados: 7
Falharam: 0
Taxa de sucesso: 100%

🎉 SUCESSO! O VLC foi compilado corretamente e está funcional!

Para iniciar o VLC manualmente:
  & "C:\vlc-test\bin\vlc.exe"
```

**Troubleshooting:**
- Se falhar no teste 6 (reprodução), verifique firewall/antivírus bloqueando download
- Se falhar no teste 2 (plugins), reexecute `meson install -C build-mingw`
- Se falhar no teste 7 (Qt), recompile com `-Dqt=enabled` no meson setup

---

## 8. Executar VLC compilado manualmente

Após compilação bem-sucedida:

```powershell
# Iniciar interface gráfica
& "C:\vlc-test\bin\vlc.exe"

# Reproduzir arquivo de vídeo específico
& "C:\vlc-test\bin\vlc.exe" "C:\Videos\meu-video.mp4"

# Reproduzir e sair automaticamente
& "C:\vlc-test\bin\vlc.exe" "video.mp4" --play-and-exit

# Modo verbose para debug
& "C:\vlc-test\bin\vlc.exe" -vvv --extraintf=http

# Listar todos os módulos compilados
& "C:\vlc-test\bin\vlc.exe" --list

# Ver versão completa
& "C:\vlc-test\bin\vlc.exe" --version
```

---

Contribua com mais exemplos abrindo um pull request. Quanto mais scripts
reutilizáveis, mais previsível fica a preparação do ambiente para novos
contribuidores.
