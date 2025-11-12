#Requires -Version 5.0

<#
.SYNOPSIS
    Compilador VLC 4.x para Windows - Script Principal

.DESCRIPTION
    Sistema automatizado de compilação do VLC 4.x com interface Qt6.
    Inclui detecção automática de ambiente, aplicação de patches e validação.
    
    Desenvolvido para facilitar a compilação em qualquer máquina Windows 10/11.

.PARAMETER SkipEnvironmentCheck
    Pula a verificação detalhada do ambiente

.PARAMETER Force
    Força a compilação mesmo com avisos

.PARAMETER Quiet
    Execução silenciosa (menos output)

.EXAMPLE
    .\Build-VLC.ps1
    Executa compilação padrão com todas as verificações

.EXAMPLE
    .\Build-VLC.ps1 -Quiet
    Compilação silenciosa para uso em automação

.NOTES
    Versão: 2.0
    Compatibilidade: Windows 10/11, MSYS2, Qt 6.10+
    Autor: Sistema de Build VLC Automatizado
#>

[CmdletBinding()]
param(
    [switch]$SkipEnvironmentCheck,
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

# === CONFIGURAÇÕES GLOBAIS ===
$Config = @{
    ProjectName = "VLC 4.x Build System"
    Version = "2.0"
    MinMSYS2Version = "20240113"
    RequiredSpace = 8GB
    EstimatedTime = "30-60 minutos"
}

# === FUNÇÕES UTILITÁRIAS ===
function Write-Header {
    param([string]$Message, [ConsoleColor]$Color = "Cyan")
    
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "=" * 70 -ForegroundColor $Color
        Write-Host "  $Message" -ForegroundColor $Color
        Write-Host "=" * 70 -ForegroundColor $Color
        Write-Host ""
    }
}

function Write-Step {
    param([int]$Current, [int]$Total, [string]$Message)
    
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "[$Current/$Total] " -ForegroundColor Yellow -NoNewline
        Write-Host $Message -ForegroundColor White
    }
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Test-DiskSpace {
    $Drive = $env:SystemDrive
    $FreeSpace = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$Drive'").FreeSpace
    
    if ($FreeSpace -lt $Config.RequiredSpace) {
        $FreeSpaceGB = [math]::Round($FreeSpace / 1GB, 1)
        $RequiredGB = [math]::Round($Config.RequiredSpace / 1GB, 1)
        
        Write-Warning "Espaço em disco insuficiente no drive $Drive"
        Write-Host "  Disponível: $FreeSpaceGB GB | Necessário: $RequiredGB GB" -ForegroundColor Gray
        
        if (-not $Force) {
            throw "Espaço em disco insuficiente. Use -Force para ignorar."
        }
    }
}

function Find-MSYS2 {
    $PossiblePaths = @(
        "C:\msys64\usr\bin\bash.exe",
        "C:\msys32\usr\bin\bash.exe",
        "${env:ProgramFiles}\MSYS2\usr\bin\bash.exe",
        "${env:ProgramFiles(x86)}\MSYS2\usr\bin\bash.exe"
    )
    
    foreach ($Path in $PossiblePaths) {
        if (Test-Path $Path) {
            return $Path
        }
    }
    
    return $null
}

function Test-Environment {
    if ($SkipEnvironmentCheck) {
        Write-Warning "Pulando verificação de ambiente (pode causar problemas)"
        return
    }
    
    Write-Step 1 1 "Verificando ambiente de compilação"
    
    # 1. Sistema operacional
    $OS = Get-WmiObject -Class Win32_OperatingSystem
    if ($OS.Version -lt "10.0") {
        throw "Windows 10 ou superior é necessário"
    }
    
    Write-Host "  ✓ Windows $($OS.Version) detectado" -ForegroundColor Gray
    
    # 2. Espaço em disco
    Test-DiskSpace
    Write-Host "  ✓ Espaço em disco suficiente" -ForegroundColor Gray
    
    # 3. MSYS2
    $MSYS2Path = Find-MSYS2
    if (-not $MSYS2Path) {
        throw "MSYS2 não encontrado! Instale de https://www.msys2.org/"
    }
    
    Write-Host "  ✓ MSYS2 encontrado em: $MSYS2Path" -ForegroundColor Gray
    
    # 4. Verificar ferramentas no MSYS2
    $ToolCheck = & $MSYS2Path -lc "pacman -Q mingw-w64-x86_64-gcc mingw-w64-x86_64-meson mingw-w64-x86_64-qt6-base 2>/dev/null || echo 'MISSING'"
    
    if ($ToolCheck -match "MISSING") {
        Write-Warning "Algumas ferramentas estão faltando no MSYS2"
        Write-Host "  Execute no MSYS2 MinGW 64-bit:" -ForegroundColor Yellow
        Write-Host "  pacman -S mingw-w64-x86_64-toolchain mingw-w64-x86_64-meson mingw-w64-x86_64-qt6" -ForegroundColor Cyan
        
        if (-not $Force) {
            throw "Ferramentas necessárias não encontradas. Use -Force para continuar."
        }
    } else {
        Write-Host "  ✓ Ferramentas de build verificadas" -ForegroundColor Gray
    }
    
    Write-Success "Ambiente validado com sucesso!"
}

function Start-Build {
    Write-Header "$($Config.ProjectName) v$($Config.Version)"
    
    if (-not $Quiet) {
        Write-Host "🎯 Sistema automatizado de compilação do VLC" -ForegroundColor White
        Write-Host "⏱️  Tempo estimado: $($Config.EstimatedTime)" -ForegroundColor Gray
        Write-Host "🔧 Inclui patches automáticos para Qt 6.10+" -ForegroundColor Gray
        Write-Host ""
        
        $Response = Read-Host "Deseja continuar? [S/n]"
        if ($Response -match '^[Nn]') {
            Write-Host "❌ Operação cancelada pelo usuário" -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Verificar ambiente
    Test-Environment
    
    # Executar build script
    $MSYS2Path = Find-MSYS2
    $BuildScript = Join-Path $PSScriptRoot "build_vlc.sh"
    
    if (-not (Test-Path $BuildScript)) {
        throw "Script de build não encontrado: $BuildScript"
    }
    
    Write-Step 1 1 "Iniciando compilação via MSYS2"
    
    $BuildCommand = "cd '$($PSScriptRoot.Replace('\', '/').Replace('C:', '/c'))' && bash build_vlc.sh"
    
    & $MSYS2Path -lc $BuildCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Header "COMPILAÇÃO CONCLUÍDA COM SUCESSO! 🎉" "Green"
        
        Write-Host "🧪 Para validar a compilação:" -ForegroundColor White
        Write-Host "   .\scripts\Test-VLC.ps1" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "🚀 Para executar o VLC:" -ForegroundColor White
        Write-Host "   & `"C:\vlc-test\bin\vlc.exe`"" -ForegroundColor Cyan
        
    } else {
        Write-Header "ERRO NA COMPILAÇÃO" "Red"
        Write-Host "Exit Code: $LASTEXITCODE" -ForegroundColor Red
        Write-Host ""
        Write-Host "📚 Para troubleshooting, consulte:" -ForegroundColor Yellow
        Write-Host "   docs\TROUBLESHOOTING.md" -ForegroundColor Cyan
        
        exit $LASTEXITCODE
    }
}

# === EXECUÇÃO PRINCIPAL ===
try {
    Start-Build
}
catch {
    Write-Error "ERRO CRÍTICO: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "📞 Para suporte técnico:" -ForegroundColor Yellow
    Write-Host "   - Verifique logs acima para detalhes" -ForegroundColor Gray
    Write-Host "   - Consulte docs\TROUBLESHOOTING.md" -ForegroundColor Gray
    Write-Host "   - Execute tools\vlc_build_doctor.py para diagnóstico" -ForegroundColor Gray
    
    exit 1
}