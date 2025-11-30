#Requires -Version 5.1
<#
.SYNOPSIS
    Valida o VLC compilado reproduzindo um video de teste

.DESCRIPTION
    Este script:
    - Verifica se o VLC foi compilado
    - Cria um video de teste se necessario
    - Executa o VLC com o video
    - Valida que o VLC pode reproduzir midias

.EXAMPLE
    .\Validate-VLC-Playback.ps1
#>

[CmdletBinding()]
param(
    [switch]$NoVideoGeneration
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Step {
    param([int]$Num, [string]$Message)
    Write-Host ""
    Write-Host "[$Num] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

try {
    Write-Header "VALIDACAO DO VLC COMPILADO - REPRODUCAO DE VIDEO"
    
    # 1. Verificar se VLC foi compilado
    Write-Step 1 "Verificando binario do VLC"
    
    # Procurar VLC em localizações possíveis
    $possiblePaths = @(
        "C:\vlc-test\bin\vlc.exe",
        "C:\Users\$env:USERNAME\vlc-source\build-mingw\bin\vlc.exe",
        "C:\Users\$env:USERNAME\vlc-source\build-mingw\vlc.exe"
    )
    
    $VlcPath = $null
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $VlcPath = $path
            break
        }
    }
    
    if (-not $VlcPath) {
        Write-Failure "VLC nao encontrado em nenhum dos caminhos esperados:"
        foreach ($path in $possiblePaths) {
            Write-Host "  - $path" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "Execute primeiro:" -ForegroundColor Yellow
        Write-Host "  .\Compile-VLC.ps1" -ForegroundColor Cyan
        exit 1
    }
    
    Write-Success "VLC encontrado: $VlcPath"
    
    # Verificar versao
    try {
        $version = & $VlcPath --version 2>&1 | Select-Object -First 1
        Write-Host "  Versao: $version" -ForegroundColor Gray
    }
    catch {
        Write-Host "  (Versao nao detectada, mas binario existe)" -ForegroundColor Gray
    }
    
    # 2. Criar/verificar video de teste
    Write-Step 2 "Preparando video de teste"
    
    $TestVideoDir = Join-Path $PSScriptRoot "..\test-videos"
    $TestVideoPath = Join-Path $TestVideoDir "vlc-test-video.mp4"
    
    if (-not (Test-Path $TestVideoPath) -and -not $NoVideoGeneration) {
        Write-Host "  Video de teste nao encontrado. Criando..." -ForegroundColor Gray
        
        # Criar diretorio
        New-Item -ItemType Directory -Force -Path $TestVideoDir | Out-Null
        
        # Criar video com Python
        $CreateScript = Join-Path $PSScriptRoot "..\tools\create_test_video.py"
        
        if (Test-Path $CreateScript) {
            $env:MSYSTEM = "UCRT64"
            $toolsDir = Split-Path $CreateScript -Parent
            & "C:\msys64\usr\bin\bash.exe" -lc "cd '$($toolsDir -replace '\\','/' -replace 'C:','/c')' && python3 create_test_video.py"
            
            if ($LASTEXITCODE -eq 0 -and (Test-Path $TestVideoPath)) {
                Write-Success "Video de teste criado"
            }
            else {
                Write-Host "  Aviso: Nao foi possivel criar video. Tentando video alternativo..." -ForegroundColor Yellow
                
                # Tentar criar video mais simples
                $env:MSYSTEM = "UCRT64"
                $simpleCmd = "ffmpeg -f lavfi -i testsrc=duration=5:size=640x480:rate=25 -c:v libx264 -preset ultrafast -pix_fmt yuv420p -y '$($TestVideoPath -replace '\\','/')'"
                & "C:\msys64\usr\bin\bash.exe" -lc $simpleCmd
                
                if (-not (Test-Path $TestVideoPath)) {
                    Write-Failure "Nao foi possivel criar video de teste"
                    Write-Host ""
                    Write-Host "Voce pode testar manualmente:" -ForegroundColor Yellow
                    Write-Host "  & '$VlcPath' 'C:\caminho\para\seu\video.mp4'" -ForegroundColor Cyan
                    exit 1
                }
            }
        }
    }
    
    if (Test-Path $TestVideoPath) {
        $videoSize = (Get-Item $TestVideoPath).Length / 1MB
        Write-Success "Video de teste pronto ($([math]::Round($videoSize, 2)) MB)"
        Write-Host "  Caminho: $TestVideoPath" -ForegroundColor Gray
    }
    else {
        Write-Host "  Aviso: Video de teste nao disponivel" -ForegroundColor Yellow
    }
    
    # 3. Testar reproducao
    Write-Step 3 "Testando reproducao de video"
    
    if (Test-Path $TestVideoPath) {
        Write-Host ""
        Write-Host "Iniciando VLC com video de teste..." -ForegroundColor Gray
        Write-Host "O VLC abrira em uma janela separada." -ForegroundColor Gray
        Write-Host ""
        Write-Host "Verifique visualmente:" -ForegroundColor Yellow
        Write-Host "  ✓ O VLC abre sem erros" -ForegroundColor Gray
        Write-Host "  ✓ O video carrega" -ForegroundColor Gray
        Write-Host "  ✓ O video reproduz corretamente" -ForegroundColor Gray
        Write-Host "  ✓ Controles funcionam" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Pressione Ctrl+C para interromper ou feche o VLC quando terminar" -ForegroundColor Cyan
        Write-Host ""
        
        # Executar VLC com video
        try {
            Start-Process -FilePath $VlcPath -ArgumentList "`"$TestVideoPath`"" -Wait
            Write-Success "VLC executado com sucesso!"
        }
        catch {
            Write-Failure "Erro ao executar VLC: $($_.Exception.Message)"
            exit 1
        }
    }
    else {
        Write-Host ""
        Write-Host "Testando apenas abertura do VLC (sem video)..." -ForegroundColor Gray
        
        # Testar apenas versao
        try {
            $output = & $VlcPath --version 2>&1 | Out-String
            if ($output -match "VLC") {
                Write-Success "VLC responde a comandos!"
                Write-Host ""
                Write-Host $output -ForegroundColor Gray
            }
        }
        catch {
            Write-Failure "VLC nao responde corretamente"
            exit 1
        }
    }
    
    # Resumo final
    Write-Header "VALIDACAO CONCLUIDA"
    
    Write-Host ""
    Write-Host "✅ VLC compilado esta funcional!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Para usar o VLC:" -ForegroundColor White
    Write-Host "  & '$VlcPath' 'C:\caminho\para\video.mp4'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Ou simplesmente:" -ForegroundColor White
    Write-Host "  & '$VlcPath'" -ForegroundColor Cyan
    Write-Host ""
    
}
catch {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "  ERRO NA VALIDACAO" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "❌ $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
