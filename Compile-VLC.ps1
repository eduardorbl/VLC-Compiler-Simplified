#Requires -Version 5.1
<#
.SYNOPSIS
    Ponto de entrada único para compilar o VLC no Windows

.DESCRIPTION
    Este script automatiza completamente o processo de compilação do VLC:
    - Verifica se MSYS2 está instalado (oferece instalar se não estiver)
    - Instala automaticamente todas as dependências necessárias
    - Compila o VLC
    - Valida a instalação

    É o único comando que você precisa executar!

.EXAMPLE
    .\Compile-VLC.ps1
    Compila o VLC do zero, instalando tudo automaticamente

.EXAMPLE
    .\Compile-VLC.ps1 -SkipTests
    Compila mas não executa os testes de validação

.NOTES
    Primeira execução pode levar 1-2 horas (download + compilação)
    Execuções seguintes são mais rápidas (~15-30 minutos)
#>

[CmdletBinding()]
param(
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

# Configurar encoding para UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Banner {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║          VLC 4.x - Sistema de Compilação Automática         ║" -ForegroundColor White
    Write-Host "║                     Windows 10/11                            ║" -ForegroundColor White
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🎯 Objetivo: Compilar VLC 4.x com interface Qt6" -ForegroundColor Gray
    Write-Host "⚙️  Sistema: MSYS2 + MinGW-w64 (UCRT64)" -ForegroundColor Gray
    Write-Host "📦 Tudo será instalado automaticamente!" -ForegroundColor Gray
    Write-Host ""
}

function Write-Step {
    param([int]$Current, [int]$Total, [string]$Message)
    Write-Host ""
    Write-Host "[$Current/$Total] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

# === EXECUÇÃO PRINCIPAL ===
try {
    Write-Banner
    
    Write-Step 1 3 "Verificando e configurando ambiente"
    Write-Info "Executando Build-VLC.ps1 (instalação automática de dependências)..."
    Write-Host ""
    
    # Executar Build-VLC.ps1 que já faz tudo automaticamente
    $BuildScript = Join-Path $PSScriptRoot "Build-VLC.ps1"
    
    if (-not (Test-Path $BuildScript)) {
        throw "Build-VLC.ps1 não encontrado em $BuildScript"
    }
    
    & $BuildScript
    
    if ($LASTEXITCODE -ne 0) {
        throw "Falha na compilação do VLC"
    }
    
    Write-Host ""
    Write-Step 2 3 "Compilação concluída com sucesso!"
    Write-Success "VLC 4.x compilado e instalado"
    
    # Testar instalação se não for solicitado pular
    if (-not $SkipTests) {
        Write-Host ""
        Write-Step 3 4 "Validando instalação"
        
        $TestScript = Join-Path $PSScriptRoot "scripts\Test-VLC.ps1"
        if (Test-Path $TestScript) {
            Write-Info "Executando testes de validação..."
            & $TestScript
        } else {
            Write-Info "Script de teste não encontrado, pulando validação"
        }
        
        # Validar reprodução de vídeo
        Write-Host ""
        Write-Step 4 4 "Validando reprodução de vídeo"
        
        $PlaybackScript = Join-Path $PSScriptRoot "scripts\Validate-VLC-Playback.ps1"
        if (Test-Path $PlaybackScript) {
            Write-Info "Testando capacidade de reprodução..."
            & $PlaybackScript
        } else {
            Write-Info "Script de validação de reprodução não encontrado"
        }
    }
    
    # Mensagem final de sucesso
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                                                              ║" -ForegroundColor Green
    Write-Host "║               ✅ COMPILAÇÃO CONCLUÍDA COM SUCESSO!           ║" -ForegroundColor White
    Write-Host "║                                                              ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "📍 VLC instalado em:" -ForegroundColor White
    Write-Host "   C:\vlc-test\bin\vlc.exe" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🚀 Para executar o VLC:" -ForegroundColor White
    Write-Host '   & "C:\vlc-test\bin\vlc.exe"' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📊 Para ver relatório de testes:" -ForegroundColor White
    Write-Host "   .\VLC-Test-Report.html" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 Dica: Para recompilar após mudanças no código:" -ForegroundColor Yellow
    Write-Host "   .\Compile-VLC.ps1" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                                                              ║" -ForegroundColor Red
    Write-Host "║                   ❌ ERRO NA COMPILAÇÃO                      ║" -ForegroundColor White
    Write-Host "║                                                              ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Para diagnóstico detalhado:" -ForegroundColor Yellow
    Write-Host "   python tools\vlc_build_doctor.py" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📖 Para solução de problemas:" -ForegroundColor Yellow
    Write-Host "   docs\TROUBLESHOOTING.md" -ForegroundColor Cyan
    Write-Host ""
    
    exit 1
}
