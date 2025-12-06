#Requires -Version 5.1
<#
    Sistema de Build VLC - Versão PATCH QT 6.10
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$TestBuild,
    [switch]$SkipValidation,
    [string]$MSYS2Path = "C:\msys64\usr\bin\bash.exe"
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Title, [string]$Color = "Cyan")
    $Border = "=" * 60
    Write-Host "`n$Border" -ForegroundColor $Color
    Write-Host " $Title" -ForegroundColor White
    Write-Host "$Border`n" -ForegroundColor $Color
}

function Find-MSYS2 {
    $PossiblePaths = @("C:\msys64\usr\bin\bash.exe", "$env:ProgramFiles\MSYS2\usr\bin\bash.exe")
    foreach ($Path in $PossiblePaths) { if (Test-Path $Path) { return $Path } }
    return (Get-Command bash.exe -ErrorAction SilentlyContinue).Source
}

function Start-Build {
    Write-Header "VLC BUILD SYSTEM - QT FIX" "Green"
    
    if (-not $SkipValidation) {
        $found = Find-MSYS2
        if (-not $found) { throw "MSYS2 nao encontrado." }
        $script:MSYS2Path = $found
    }

    $VlcDir = Join-Path $PSScriptRoot "vlc"
    if (-not (Test-Path $VlcDir)) {
        git clone https://code.videolan.org/videolan/vlc.git $VlcDir
    }

    if ($TestBuild) { return }

    Write-Header "EXECUTANDO BUILD (BASH)"
    $env:MSYSTEM = "UCRT64"
    $ScriptDir = $PSScriptRoot.Replace('\','/').Replace('C:','/c')
    
    $BuildCommand = "cd '$ScriptDir' && bash scripts/build_vlc.sh"
    & $MSYS2Path -lc $BuildCommand

    if ($LASTEXITCODE -ne 0) {
        Write-Header "FALHA NO BUILD" "Red"
        Write-Host "O script tentou corrigir o erro do Qt." -ForegroundColor Yellow
        Write-Host "Se falhar novamente, poste o novo erro." -ForegroundColor Yellow
        exit 1
    }
    Write-Header "SUCESSO!" "Green"
}

try { Start-Build } catch { Write-Error $_.Exception.Message; exit 1 }