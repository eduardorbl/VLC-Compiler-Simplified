#Requires -Version 5.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Instalador Automático do Ambiente VLC

.DESCRIPTION
    Instala e configura automaticamente todo o ambiente necessário para compilar VLC 4.x:
    - MSYS2 com MinGW-w64
    - Todas as dependências de build
    - Ferramentas Qt 6.x
    - Configuração otimizada

.PARAMETER InstallPath
    Diretório de instalação do MSYS2 (padrão: C:\msys64)

.PARAMETER SkipMSYS2Download
    Pula download do MSYS2 se já existir

.PARAMETER Quiet
    Instalação silenciosa sem interação

.EXAMPLE
    .\Install-Environment.ps1
    Instalação interativa padrão

.EXAMPLE
    .\Install-Environment.ps1 -Quiet
    Instalação automatizada para CI/CD
#>

[CmdletBinding()]
param(
    [string]$InstallPath = "C:\msys64",
    [switch]$SkipMSYS2Download,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

# === CONFIGURAÇÕES ===
$Config = @{
    MSYS2Version = "2024-01-13"
    MSYS2Url = "https://github.com/msys2/msys2-installer/releases/download/2024-01-13/msys2-x86_64-20240113.exe"
    RequiredPackages = @(
        "mingw-w64-ucrt-x86_64-toolchain",
        "mingw-w64-ucrt-x86_64-meson",
        "mingw-w64-ucrt-x86_64-ninja",
        "mingw-w64-ucrt-x86_64-cmake", 
        "mingw-w64-ucrt-x86_64-qt6-base",
        "mingw-w64-ucrt-x86_64-qt6-tools",
        "mingw-w64-ucrt-x86_64-qt6-svg",
        "mingw-w64-ucrt-x86_64-qt6-declarative",
        "mingw-w64-ucrt-x86_64-qt6-5compat",
        "mingw-w64-ucrt-x86_64-qt6-shadertools",
        "mingw-w64-ucrt-x86_64-ffmpeg",
        "mingw-w64-ucrt-x86_64-nasm",
        "mingw-w64-ucrt-x86_64-bison",
        "mingw-w64-ucrt-x86_64-flex",
        "mingw-w64-ucrt-x86_64-lua",
        "perl",
        "git",
        "python3"
    )
    MinDiskSpace = 10GB
}

# === FUNÇÕES UTILITÁRIAS ===
function Write-Header {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "=" * 70 -ForegroundColor Green
        Write-Host "  $Message" -ForegroundColor Green  
        Write-Host "=" * 70 -ForegroundColor Green
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

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Test-Prerequisites {
    Write-Step 1 6 "Verificando pré-requisitos"
    
    # Verificar privilégios de administrador
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        throw "Este script deve ser executado como Administrador"
    }
    Write-Host "  ✓ Privilégios de administrador confirmados" -ForegroundColor Gray
    
    # Verificar sistema operacional
    $OS = Get-WmiObject -Class Win32_OperatingSystem
    if ([System.Version]$OS.Version -lt [System.Version]"10.0") {
        throw "Windows 10 ou superior é necessário"
    }
    Write-Host "  ✓ Windows $($OS.Caption) compatível" -ForegroundColor Gray
    
    # Verificar espaço em disco
    $Drive = (Get-Item $InstallPath -ErrorAction SilentlyContinue)?.PSDrive?.Name
    if (-not $Drive) {
        $Drive = $InstallPath.Substring(0,1)
    }
    
    $FreeSpace = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$Drive`:'").FreeSpace
    if ($FreeSpace -lt $Config.MinDiskSpace) {
        $FreeSpaceGB = [math]::Round($FreeSpace / 1GB, 1)
        $RequiredGB = [math]::Round($Config.MinDiskSpace / 1GB, 1)
        throw "Espaço insuficiente no drive $Drive`: $FreeSpaceGB GB disponível, $RequiredGB GB necessário"
    }
    Write-Host "  ✓ Espaço em disco suficiente ($([math]::Round($FreeSpace / 1GB, 1)) GB disponível)" -ForegroundColor Gray
    
    # Verificar conexão com internet
    try {
        $null = Test-NetConnection -ComputerName "github.com" -Port 443 -InformationLevel Quiet -ErrorAction Stop
        Write-Host "  ✓ Conexão com internet verificada" -ForegroundColor Gray
    }
    catch {
        throw "Conexão com internet necessária para download de dependências"
    }
    
    Write-Success "Pré-requisitos atendidos"
}

function Install-MSYS2 {
    if (Test-Path "$InstallPath\usr\bin\bash.exe") {
        if ($SkipMSYS2Download) {
            Write-Host "  ✓ MSYS2 já instalado em $InstallPath" -ForegroundColor Gray
            return
        }
        
        if (-not $Quiet) {
            $response = Read-Host "MSYS2 já existe em $InstallPath. Reinstalar? [s/N]"
            if ($response -notmatch '^[Ss]') {
                Write-Host "  ✓ Mantendo instalação existente do MSYS2" -ForegroundColor Gray
                return
            }
        }
    }
    
    Write-Step 2 6 "Instalando MSYS2"
    
    $installerPath = "$env:TEMP\msys2-installer.exe"
    
    try {
        Write-Host "  📥 Baixando MSYS2..." -ForegroundColor Gray
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Config.MSYS2Url -OutFile $installerPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        
        Write-Host "  ⚙️ Executando instalador..." -ForegroundColor Gray
        $installArgs = @(
            "in", "--confirm-command", "--accept-messages", "--root", $InstallPath
        )
        
        $process = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -ne 0) {
            throw "Instalação do MSYS2 falhou (Exit Code: $($process.ExitCode))"
        }
        
        Write-Success "MSYS2 instalado com sucesso"
    }
    finally {
        if (Test-Path $installerPath) {
            Remove-Item $installerPath -Force
        }
    }
}

function Update-MSYS2 {
    Write-Step 3 6 "Atualizando MSYS2"
    
    $bashPath = "$InstallPath\usr\bin\bash.exe"
    
    if (-not (Test-Path $bashPath)) {
        throw "MSYS2 bash não encontrado em $bashPath"
    }
    
    Write-Host "  🔄 Atualizando sistema base..." -ForegroundColor Gray
    & $bashPath -lc "pacman -Syu --noconfirm --needed"
    
    Write-Host "  🔄 Atualizando pacotes restantes..." -ForegroundColor Gray  
    & $bashPath -lc "pacman -Su --noconfirm --needed"
    
    Write-Success "MSYS2 atualizado"
}

function Install-BuildTools {
    Write-Step 4 6 "Instalando ferramentas de build"
    
    $bashPath = "$InstallPath\usr\bin\bash.exe"
    
    Write-Host "  📦 Instalando pacotes necessários..." -ForegroundColor Gray

    # Pacman package selection helper: try candidates in order and return first that exists
    function Select-Package {
        param(
            [string]$bash,
            [string[]]$candidates
        )

        foreach ($p in $candidates) {
            # Check package info using pacman -Si (returns non-zero if not found)
            & $bash -lc "pacman -Si $p > /dev/null 2>&1"
            if ($LASTEXITCODE -eq 0) {
                return $p
            }
        }

        return $null
    }

    # Start with the configured list, but adapt bison/flex to available repo names
    $effectivePackages = @()
    foreach ($p in $Config.RequiredPackages) {
        if ($p -match "bison$") {
            $candidates = @("mingw-w64-ucrt-x86_64-bison", "mingw-w64-x86_64-bison", "bison")
            $chosen = Select-Package -bash $bashPath -candidates $candidates
            if ($chosen) { $effectivePackages += $chosen } else { $effectivePackages += "bison" }
            continue
        }

        if ($p -match "flex$") {
            $candidates = @("mingw-w64-ucrt-x86_64-flex", "mingw-w64-x86_64-flex", "flex")
            $chosen = Select-Package -bash $bashPath -candidates $candidates
            if ($chosen) { $effectivePackages += $chosen } else { $effectivePackages += "flex" }
            continue
        }

        $effectivePackages += $p
    }

    $packageList = $effectivePackages -join " "

    & $bashPath -lc "pacman -S --noconfirm --needed $packageList"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Falha na instalação dos pacotes (Exit Code: $LASTEXITCODE)"
    }
    
    Write-Success "Ferramentas de build instaladas"
}

function Test-Installation {
    Write-Step 5 6 "Verificando instalação"
    
    $bashPath = "$InstallPath\usr\bin\bash.exe"
    
    # Testar ferramentas críticas
    $tools = @{
        "GCC" = "gcc --version"
        "Meson" = "meson --version"
        "Qt6" = "pkg-config --modversion Qt6Core"
        "Git" = "git --version"
        "Python" = "python3 --version"
        "Bison" = "bison --version"
        "Flex" = "flex --version"
    }
    
    foreach ($tool in $tools.Keys) {
        try {
            $output = & $bashPath -lc $tools[$tool] 2>&1 | Select-Object -First 1
            Write-Host "  ✓ $tool`: $output" -ForegroundColor Gray
        }
        catch {
            Write-Host "  ❌ $tool`: Não encontrado" -ForegroundColor Red
        }
    }
    
    Write-Success "Verificação da instalação concluída"
}

function Configure-Environment {
    Write-Step 6 6 "Configurando ambiente"
    
    # Criar script de ativação do ambiente
    $activateScript = @"
@echo off
REM Ativar ambiente de desenvolvimento VLC
set MSYSTEM=MINGW64
set PATH=$InstallPath\mingw64\bin;$InstallPath\usr\bin;%PATH%
echo.
echo ================================
echo   Ambiente VLC Development
echo ================================
echo.
echo MSYS2: $InstallPath
echo Sistema: %MSYSTEM%
echo.
echo Para compilar VLC:
echo   cd /caminho/para/vlc-project
echo   .\Build-VLC.ps1
echo.
cmd /k
"@
    
    $activateScriptPath = "$InstallPath\activate-vlc-env.bat"
    $activateScript | Out-File -FilePath $activateScriptPath -Encoding ASCII
    
    Write-Host "  ✓ Script de ativação criado: $activateScriptPath" -ForegroundColor Gray
    
    # Adicionar ao PATH do sistema se solicitado
    if (-not $Quiet) {
        $response = Read-Host "Adicionar MSYS2 ao PATH do sistema? [S/n]"
        if ($response -notmatch '^[Nn]') {
            $systemPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
            $msys2Paths = "$InstallPath\mingw64\bin;$InstallPath\usr\bin"
            
            if ($systemPath -notlike "*$InstallPath*") {
                [Environment]::SetEnvironmentVariable("PATH", "$systemPath;$msys2Paths", "Machine")
                Write-Host "  ✓ PATH do sistema atualizado" -ForegroundColor Gray
            } else {
                Write-Host "  ✓ PATH já contém MSYS2" -ForegroundColor Gray
            }
        }
    }
    
    Write-Success "Ambiente configurado"
}

function Show-CompletionMessage {
    Write-Header "INSTALAÇÃO CONCLUÍDA COM SUCESSO! 🎉"
    
    Write-Host "🛠️  Ambiente de desenvolvimento VLC configurado:" -ForegroundColor White
    Write-Host "   📍 MSYS2 instalado em: $InstallPath" -ForegroundColor Gray
    Write-Host "   📋 Todas as dependências instaladas" -ForegroundColor Gray
    Write-Host "   ⚙️ Ambiente otimizado para compilação" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "🚀 Próximos passos:" -ForegroundColor White
    Write-Host "   1. Clone este projeto VLC em sua máquina" -ForegroundColor Cyan
    Write-Host "   2. Execute: .\Build-VLC.ps1" -ForegroundColor Cyan
    Write-Host "   3. Aguarde a compilação (30-60 min)" -ForegroundColor Cyan
    Write-Host "   4. Teste com: .\scripts\Test-VLC.ps1" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "💡 Dicas:" -ForegroundColor Yellow
    Write-Host "   - Use '$InstallPath\activate-vlc-env.bat' para abrir terminal otimizado" -ForegroundColor Gray
    Write-Host "   - Reinicie o terminal para PATH atualizado" -ForegroundColor Gray
    Write-Host "   - Consulte docs\ para troubleshooting" -ForegroundColor Gray
}

# === EXECUÇÃO PRINCIPAL ===
try {
    Write-Header "Instalador Automático - Ambiente VLC 4.x"
    
    if (-not $Quiet) {
        Write-Host "🎯 Este script instalará:" -ForegroundColor White
        Write-Host "   • MSYS2 MinGW-w64" -ForegroundColor Gray
        Write-Host "   • Ferramentas de build (GCC, Meson, etc.)" -ForegroundColor Gray
        Write-Host "   • Qt 6.x e dependências" -ForegroundColor Gray
        Write-Host "   • Configuração otimizada" -ForegroundColor Gray
        Write-Host ""
        Write-Host "⚠️  Requer conexão com internet e ~5GB de espaço" -ForegroundColor Yellow
        Write-Host ""
        
        $response = Read-Host "Continuar com a instalação? [S/n]"
        if ($response -match '^[Nn]') {
            Write-Host "❌ Instalação cancelada pelo usuário" -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Executar instalação
    Test-Prerequisites
    Install-MSYS2
    Update-MSYS2
    Install-BuildTools
    Test-Installation
    Configure-Environment
    
    Show-CompletionMessage
}
catch {
    Write-Header "ERRO NA INSTALAÇÃO" "Red"
    Write-Host "❌ $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Para resolver:" -ForegroundColor Yellow
    Write-Host "   1. Verifique conexão com internet" -ForegroundColor Gray
    Write-Host "   2. Execute como Administrador" -ForegroundColor Gray
    Write-Host "   3. Libere espaço em disco se necessário" -ForegroundColor Gray
    Write-Host "   4. Tente novamente" -ForegroundColor Gray
    
    exit 1
}