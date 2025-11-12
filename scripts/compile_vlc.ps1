# Script para compilar o VLC usando MSYS2
# Execute este script no PowerShell

$ErrorActionPreference = "Continue"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Compilador VLC - Wrapper PowerShell para MSYS2" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se MSYS2 esta instalado
$msys2Paths = @(
    "C:\msys64\usr\bin\bash.exe",
    "C:\msys32\usr\bin\bash.exe",
    "$env:USERPROFILE\msys64\usr\bin\bash.exe"
)

$msys2Bash = $null
foreach ($path in $msys2Paths) {
    if (Test-Path $path) {
        $msys2Bash = $path
        break
    }
}

if (-not $msys2Bash) {
    Write-Host "ERRO: MSYS2 nao encontrado!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Instale o MSYS2 de: https://www.msys2.org/" -ForegroundColor Yellow
    Write-Host "Depois execute este script novamente." -ForegroundColor Yellow
    exit 1
}

Write-Host "MSYS2 encontrado em: $msys2Bash" -ForegroundColor Green
Write-Host ""

# Verificar se o script de compilacao existe
$compileScript = Join-Path $PSScriptRoot "compile_vlc.sh"
if (-not (Test-Path $compileScript)) {
    Write-Host "ERRO: Script compile_vlc.sh nao encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host "Script de compilacao: $compileScript" -ForegroundColor Green
Write-Host ""

# Converter caminho do Windows para MSYS2 (C:\path -> /c/path)
$drive = $compileScript.Substring(0,1).ToLower()
$pathWithoutDrive = $compileScript.Substring(2) -replace '\\', '/'
$compileScriptMsys = "/$drive$pathWithoutDrive"

Write-Host "==================================================================" -ForegroundColor Yellow
Write-Host "  ATENCAO: A compilacao pode demorar 30-60 minutos!" -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "O processo ira:" -ForegroundColor Cyan
Write-Host "  1. Clonar o repositorio do VLC (~1 GB)" -ForegroundColor White
Write-Host "  2. Configurar o build com Meson" -ForegroundColor White
Write-Host "  3. Compilar o codigo fonte (DEMORADO)" -ForegroundColor White
Write-Host "  4. Instalar em C:\vlc-test\" -ForegroundColor White
Write-Host ""

$response = Read-Host "Deseja continuar? (S/N)"
if ($response -notmatch '^[Ss]') {
    Write-Host "Compilacao cancelada pelo usuario." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Iniciando compilacao via MSYS2 MinGW 64-bit..." -ForegroundColor Cyan
Write-Host ""

# Executar o script de compilacao no MSYS2 MinGW 64-bit
$env:MSYSTEM = "MINGW64"
$env:CHERE_INVOKING = "1"

& $msys2Bash -lc "chmod +x '$compileScriptMsys' && '$compileScriptMsys'"

$exitCode = $LASTEXITCODE

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "  COMPILACAO CONCLUIDA COM SUCESSO!" -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Execute os testes automatizados:" -ForegroundColor Cyan
    Write-Host "  .\test_vlc_build.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "Ou inicie o VLC manualmente:" -ForegroundColor Cyan
    Write-Host "  & 'C:\vlc-test\bin\vlc.exe'" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host "  ERRO NA COMPILACAO (Exit Code: $exitCode)" -ForegroundColor Red
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Consulte as mensagens de erro acima." -ForegroundColor Yellow
    Write-Host "Ou consulte: docs\COMPILAR_VLC_GUI.md" -ForegroundColor Yellow
    Write-Host ""
}

exit $exitCode
