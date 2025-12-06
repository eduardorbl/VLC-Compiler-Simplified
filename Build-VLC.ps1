#Requires -Version 5.1
<#
Sistema principal de compilacao VLC para Windows 10/11
Versão corrigida incluindo CLONE AUTOMÁTICO do VLC
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$TestBuild,
    [switch]$SkipValidation,
    [string]$MSYS2Path = "C:\msys64\usr\bin\bash.exe"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Header {
    param([string]$Title, [string]$Color = "Cyan")
    $Border = "=" * 60
    Write-Host "`n$Border" -ForegroundColor $Color
    Write-Host " $Title" -ForegroundColor White
    Write-Host "$Border`n" -ForegroundColor $Color
}

function Write-Step {
    param([int]$Current, [int]$Total, [string]$Message)
    Write-Host "[$Current/$Total] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Success { param([string]$Message) Write-Host "OK $Message" -ForegroundColor Green }
function Write-Warning-Custom { param([string]$Message) Write-Host "AVISO $Message" -ForegroundColor Yellow }

function Find-MSYS2 {
    $PossiblePaths = @(
        "C:\msys64\usr\bin\bash.exe",
        "C:\msys32\usr\bin\bash.exe",
        "D:\msys64\usr\bin\bash.exe",
        "$env:ProgramFiles\MSYS2\usr\bin\bash.exe"
    )
    foreach ($Path in $PossiblePaths) { if (Test-Path $Path) { return $Path } }
    $bashInPath = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($bashInPath) { return $bashInPath.Source }
    return $null
}

function Test-Prerequisites {
    Write-Header "VALIDANDO AMBIENTE DE BUILD"
    Write-Step 1 4 "Verificando espaco em disco"
    $Drive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
    $FreeSpaceGB = [math]::Round($Drive.FreeSpace / 1GB, 1)
    if ($FreeSpaceGB -lt 8) {
        Write-Host "ERRO Espaco insuficiente: $FreeSpaceGB GB" -ForegroundColor Red
        if (-not $Force) { throw "Espaco insuficiente" }
        Write-Warning-Custom "Forçando continuação"
    }

    Write-Step 2 4 "Verificando PowerShell"
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.1+ requerido"
    }

    Write-Step 3 4 "Localizando MSYS2"
    $found = Find-MSYS2
    if (-not $found) {
        Write-Host "ERRO MSYS2 não encontrado" -ForegroundColor Red
        if (-not $Force) { throw "MSYS2 é obrigatório" }
    } else {
        $script:MSYS2Path = $found
    }

    Write-Step 4 4 "Verificando ferramentas MSYS2"
    $env:MSYSTEM = "UCRT64"
    & $MSYS2Path -lc "pacman -S --noconfirm --needed git make tar automake autoconf libtool mingw-w64-ucrt-x86_64-toolchain mingw-w64-ucrt-x86_64-meson mingw-w64-ucrt-x86_64-ffmpeg mingw-w64-ucrt-x86_64-qt6-base"

    Write-Success "Ambiente OK"
}

function Clone-VLC {
    Write-Header "CLONANDO/ATUALIZANDO VLC"

    $VlcDir = Join-Path $PSScriptRoot "vlc"

    if (-not (Test-Path $VlcDir)) {
        Write-Host "Clonando VLC..." -ForegroundColor Cyan
        git clone https://code.videolan.org/videolan/vlc.git $VlcDir
    }
    else {
        Write-Host "Repositório VLC já existe — atualizando..." -ForegroundColor Cyan
        git -C $VlcDir pull
    }

    Write-Success "Código-fonte do VLC pronto"
}

function Start-Build {
    Write-Header "VLC BUILD SYSTEM v2.0" "Green"

    if (-not $SkipValidation) {
        Test-Prerequisites
    }

    Clone-VLC

    if ($TestBuild) {
        Write-Success "Teste concluído"
        return
    }

    Write-Header "INICIANDO COMPILACAO VLC"

    $env:MSYSTEM = "UCRT64"

    $ScriptDir = $PSScriptRoot.Replace('\','/').Replace('C:','/c')
    $BuildCommand = "cd '$ScriptDir' && bash scripts/build_vlc.sh"

    Write-Host "Executando build via MSYS2..." -ForegroundColor Yellow
    & $MSYS2Path -lc $BuildCommand

    if ($LASTEXITCODE -ne 0) {
        Write-Header "ERRO NA COMPILACAO" "Red"
        throw "Falha no build"
    }

    Write-Header "COMPILACAO FINALIZADA!" "Green"
}

try {
    Start-Build
}
catch {
    Write-Error "ERRO CRITICO: $($_.Exception.Message)"
    exit 1
}
