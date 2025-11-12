#Requires -Version 5.1
<#
.SYNOPSIS
Sistema principal de compilacao VLC para Windows 10/11

.DESCRIPTION
Script profissional que automatiza a compilacao do VLC 4.x no Windows usando MSYS2.
Inclui validacao de ambiente, aplicacao automatica de patches e configuracao otimizada.

.PARAMETER Force
Forca a continuacao mesmo com avisos de ambiente

.PARAMETER TestBuild
Executa apenas teste de configuracao sem compilacao completa

.PARAMETER SkipValidation
Pula validacao inicial do ambiente (nao recomendado)

.EXAMPLE
.\Build-VLC.ps1
Execucao padrao com todas as validacoes

.EXAMPLE
.\Build-VLC.ps1 -Force
Forca execucao mesmo com avisos

.EXAMPLE
.\Build-VLC.ps1 -TestBuild
Testa configuracao sem compilar

.NOTES
- Requer MSYS2 instalado em C:\msys64
- Primeira execucao pode levar 1-2 horas
- Execucoes seguintes sao mais rapidas (~15-30min)
- Para problemas, consulte docs\TROUBLESHOOTING.md

Author: VLC Build System
Version: 2.0
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$TestBuild,
    [switch]$SkipValidation,
    
    [string]$MSYS2Path = "C:\msys64\usr\bin\bash.exe"
)

# === CONFIGURACOES ===
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# === FUNCOES AUXILIARES ===
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

function Write-Success {
    param([string]$Message)
    
    Write-Host "OK $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    
    Write-Host "AVISO $Message" -ForegroundColor Yellow
}

function Find-MSYS2 {
    <#
    .SYNOPSIS
    Localiza instalacao do MSYS2 no sistema
    #>
    
    $PossiblePaths = @(
        "C:\msys64\usr\bin\bash.exe",
        "C:\msys32\usr\bin\bash.exe",
        "D:\msys64\usr\bin\bash.exe",
        "$env:ProgramFiles\MSYS2\usr\bin\bash.exe"
    )
    
    foreach ($Path in $PossiblePaths) {
        if (Test-Path $Path) {
            return $Path
        }
    }
    
    return $null
}

function Test-Prerequisites {
    <#
    .SYNOPSIS
    Valida pre-requisitos do sistema para compilacao VLC
    #>
    
    Write-Header "VALIDANDO AMBIENTE DE BUILD"
    
    # 1. Verificar espaco em disco
    $Drive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
    $FreeSpaceGB = [math]::Round($Drive.FreeSpace / 1GB, 1)
    $RequiredSpaceGB = 8.0
    
    Write-Step 1 4 "Verificando espaco disponivel"
    
    if ($FreeSpaceGB -lt $RequiredSpaceGB) {
        Write-Host "ERRO Espaco insuficiente no drive C: $FreeSpaceGB GB disponivel, $RequiredSpaceGB GB necessario" -ForegroundColor Red
        
        if (-not $Force) {
            throw "Espaco insuficiente em disco. Use -Force para continuar."
        } else {
            Write-Warning-Custom "Continuando com espaco limitado (pode falhar)..."
        }
    } else {
        Write-Host "  OK Espaco disponivel: $FreeSpaceGB GB" -ForegroundColor Gray
    }
    
    # 2. Verificar PowerShell version
    Write-Step 2 4 "Verificando versao PowerShell"
    
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.1+ e necessario. Versao atual: $($PSVersionTable.PSVersion)"
    } else {
        Write-Host "  OK PowerShell $($PSVersionTable.PSVersion) detectado" -ForegroundColor Gray
    }
    
    # 3. Localizar MSYS2
    Write-Step 3 4 "Procurando instalacao MSYS2"
    
    $FoundMSYS2 = Find-MSYS2
    if (-not $FoundMSYS2) {
        Write-Host "ERRO MSYS2 nao encontrado! Instale de https://www.msys2.org/" -ForegroundColor Red
        Write-Host "   Ou execute: .\Install-Environment.ps1" -ForegroundColor Yellow
        
        if (-not $Force) {
            throw "MSYS2 e obrigatorio. Use -Force para pular validacao."
        }
    }
    
    # Atualizar variavel global se encontrado path diferente
    if ($FoundMSYS2 -and ($FoundMSYS2 -ne $MSYS2Path)) {
        $script:MSYS2Path = $FoundMSYS2
    }
    
    Write-Host "  OK MSYS2 encontrado em: $MSYS2Path" -ForegroundColor Gray
    
    # 4. Verificar ferramentas no MSYS2
    Write-Step 4 4 "Verificando ferramentas MSYS2"
    
    try {
        $TestCommand = "pacman -Q mingw-w64-x86_64-gcc mingw-w64-x86_64-meson mingw-w64-x86_64-qt6-base"
        $ToolCheck = & $MSYS2Path -lc $TestCommand 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning-Custom "Algumas ferramentas podem estar faltando no MSYS2"
            Write-Host "  Execute no MSYS2 MinGW 64-bit:" -ForegroundColor Yellow
            Write-Host "  pacman -S mingw-w64-x86_64-toolchain mingw-w64-x86_64-meson mingw-w64-x86_64-qt6-base" -ForegroundColor Cyan
            
            if (-not $Force) {
                throw "Ferramentas necessarias nao encontradas. Use -Force para continuar."
            }
        } else {
            Write-Host "  OK Ferramentas de build verificadas" -ForegroundColor Gray
        }
    }
    catch {
        Write-Warning-Custom "Nao foi possivel verificar ferramentas MSYS2: $($_.Exception.Message)"
        if (-not $Force) {
            throw "Erro na validacao. Use -Force para continuar."
        }
    }
    
    Write-Success "Ambiente validado com sucesso!"
}

function Start-Build {
    <#
    .SYNOPSIS
    Inicia processo principal de compilacao
    #>
    
    Write-Header "VLC BUILD SYSTEM v2.0" "Green"
    Write-Host "Sistema automatizado de compilacao VLC para Windows 10/11`n" -ForegroundColor Gray
    
    # Validacao inicial
    if (-not $SkipValidation) {
        Test-Prerequisites
        Write-Host ""
    }
    
    # Test build apenas valida e sai
    if ($TestBuild) {
        Write-Success "Teste de configuracao concluido!"
        Write-Host "Execute sem -TestBuild para compilar o VLC." -ForegroundColor Yellow
        return
    }
    
    # Verificar script de build
    $BuildScript = Join-Path $PSScriptRoot "scripts\build_vlc.sh"
    if (-not (Test-Path $BuildScript)) {
        throw "Script de build nao encontrado: $BuildScript"
    }
    
    Write-Header "INICIANDO COMPILACAO VLC"
    
    # Preparar comando de build
    $ScriptDir = $PSScriptRoot.Replace('\', '/').Replace('C:', '/c')
    $BuildCommand = "cd '$ScriptDir' && bash scripts/build_vlc.sh"
    
    Write-Host "Executando: $BuildCommand" -ForegroundColor Gray
    Write-Host "Primeira compilacao pode levar 45-90 minutos...`n" -ForegroundColor Yellow
    
    # Executar compilacao
    & $MSYS2Path -lc $BuildCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Header "COMPILACAO CONCLUIDA COM SUCESSO!" "Green"
        
        Write-Host "Para validar a compilacao:" -ForegroundColor White
        Write-Host "   .\scripts\Test-VLC.ps1" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Para executar o VLC:" -ForegroundColor White
        Write-Host '   & "C:\vlc-test\bin\vlc.exe"' -ForegroundColor Cyan
        
    } else {
        Write-Header "ERRO NA COMPILACAO" "Red"
        Write-Host "ERRO Compilacao falhou com codigo: $LASTEXITCODE" -ForegroundColor Red
        Write-Host ""
        Write-Host "Proximos passos:" -ForegroundColor Yellow
        Write-Host "   1. Verifique logs acima para detalhes" -ForegroundColor Gray
        Write-Host "   2. Consulte docs\TROUBLESHOOTING.md" -ForegroundColor Gray
        Write-Host "   3. Execute: python tools\vlc_build_doctor.py" -ForegroundColor Gray
        
        throw "Compilacao falhou"
    }
}

# === EXECUCAO PRINCIPAL ===
try {
    Start-Build
}
catch {
    Write-Error "ERRO CRITICO: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Para suporte tecnico:" -ForegroundColor Yellow
    Write-Host "   - Verifique logs acima para detalhes" -ForegroundColor Gray
    Write-Host "   - Consulte docs\TROUBLESHOOTING.md" -ForegroundColor Gray
    Write-Host "   - Execute: python tools\vlc_build_doctor.py" -ForegroundColor Gray
    
    exit 1
}