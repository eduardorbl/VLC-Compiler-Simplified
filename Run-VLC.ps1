# Run-VLC.ps1
# Este script "empresta" as DLLs do MSYS2 para o VLC rodar
# ========================================================

$ScriptDir = $PSScriptRoot
$VlcExe = "$ScriptDir\vlc-test\bin\vlc.exe"
$MsysBin = "C:\msys64\ucrt64\bin"

# 1. Verifica se o executável existe
if (-not (Test-Path $VlcExe)) {
    Write-Error "ERRO: O arquivo vlc.exe não foi encontrado em: $VlcExe"
    Write-Warning "Você rodou o Build-VLC.ps1 com sucesso antes?"
    exit
}

# 2. Configura as variáveis de ambiente
Write-Host "Configurando ambiente de execução..." -ForegroundColor Cyan

# Adiciona as DLLs do sistema (Qt, GCC, etc) ao caminho de busca
$env:Path = "$MsysBin;$env:Path"

# Diz ao VLC onde achar os plugins (codecs, interface, etc)
$env:VLC_PLUGIN_PATH = "$ScriptDir\vlc-test\lib\vlc\plugins"
$env:VLC_DATA_PATH = "$ScriptDir\vlc-test\share"

# 3. Inicia o VLC
Write-Host "Iniciando VLC..." -ForegroundColor Green
Write-Host "--------------------------------------------------" -ForegroundColor DarkGray

# Executa e mostra logs no terminal se houver erro
& $VlcExe --verbose 2