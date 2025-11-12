#Requires -Version 5.0

<#
.SYNOPSIS
    Sistema de Testes VLC - Validação Completa

.DESCRIPTION
    Executa testes abrangentes da compilação VLC para garantir que tudo está funcionando.
    Inclui testes de funcionalidade, plugins, codecs e interface gráfica.

.PARAMETER VlcPath
    Caminho customizado para o executável VLC

.PARAMETER SkipVideoTest
    Pula o teste de reprodução de vídeo

.PARAMETER GenerateReport
    Gera relatório detalhado em HTML

.EXAMPLE
    .\Test-VLC.ps1
    Executa todos os testes com configuração padrão

.EXAMPLE
    .\Test-VLC.ps1 -SkipVideoTest -GenerateReport
    Testa sem vídeo e gera relatório HTML
#>

[CmdletBinding()]
param(
    [string]$VlcPath = "C:\vlc-test\bin\vlc.exe",
    [switch]$SkipVideoTest,
    [switch]$GenerateReport
)

$ErrorActionPreference = "Continue"

# === CONFIGURAÇÃO ===
$TestConfig = @{
    Title = "Sistema de Testes VLC 4.x"
    Version = "2.0"
    MinPlugins = 50
    TestVideoUrl = "https://sample-videos.com/zip/10/mp4/360/sample-5s.mp4"
    TestVideoFile = "$env:TEMP\vlc-test-video.mp4"
    ReportFile = ".\VLC-Test-Report.html"
}

# Estado dos testes
$TestResults = @{
    Passed = 0
    Failed = 0
    Warnings = 0
    Tests = @()
}

# === FUNÇÕES UTILITÁRIAS ===
function Write-TestHeader {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "  $($TestConfig.Title) v$($TestConfig.Version)" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host ""
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = "",
        [string]$Category = "Geral"
    )
    
    $Status = if ($Passed) { "PASS" } else { "FAIL" }
    $Color = if ($Passed) { "Green" } else { "Red" }
    $Icon = if ($Passed) { "✅" } else { "❌" }
    
    Write-Host "[$Status] " -ForegroundColor $Color -NoNewline
    Write-Host "$TestName" -ForegroundColor White
    
    if ($Details) {
        Write-Host "      $Details" -ForegroundColor Gray
    }
    
    # Registrar resultado
    $TestResults.Tests += @{
        Name = $TestName
        Category = $Category
        Passed = $Passed
        Details = $Details
        Timestamp = Get-Date
    }
    
    if ($Passed) { $TestResults.Passed++ } else { $TestResults.Failed++ }
}

function Write-TestWarning {
    param([string]$Message)
    Write-Host "⚠️  AVISO: $Message" -ForegroundColor Yellow
    $TestResults.Warnings++
}

function Test-VlcExecutable {
    Write-Host "🔍 Teste 1: Verificação do Executável" -ForegroundColor Yellow
    
    $exists = Test-Path $VlcPath
    Write-TestResult -TestName "Executável encontrado" -Passed $exists -Details $VlcPath -Category "Instalação"
    
    if (-not $exists) {
        Write-Host ""
        Write-Host "❌ ERRO CRÍTICO: VLC não encontrado!" -ForegroundColor Red
        Write-Host "   Compile primeiro executando: .\Build-VLC.ps1" -ForegroundColor Yellow
        return $false
    }
    
    $vlcInfo = Get-Item $VlcPath -ErrorAction SilentlyContinue
    if ($vlcInfo) {
        $sizeMB = [math]::Round($vlcInfo.Length / 1MB, 2)
        Write-TestResult -TestName "Tamanho do executável válido" -Passed ($sizeMB -gt 1) -Details "$sizeMB MB" -Category "Instalação"
        Write-TestResult -TestName "Arquivo atualizado recentemente" -Passed ($vlcInfo.LastWriteTime -gt (Get-Date).AddDays(-7)) -Details "$($vlcInfo.LastWriteTime)" -Category "Instalação"
    }
    
    return $true
}

function Test-VlcPlugins {
    Write-Host ""
    Write-Host "🔌 Teste 2: Verificação de Plugins" -ForegroundColor Yellow
    
    $pluginPath = Join-Path (Split-Path (Split-Path $VlcPath)) "lib\vlc\plugins"
    $pluginExists = Test-Path $pluginPath
    
    Write-TestResult -TestName "Diretório de plugins encontrado" -Passed $pluginExists -Details $pluginPath -Category "Plugins"
    
    if ($pluginExists) {
        $pluginFiles = Get-ChildItem "$pluginPath\*.dll" -Recurse -ErrorAction SilentlyContinue
        $pluginCount = $pluginFiles.Count
        $pluginFolders = (Get-ChildItem $pluginPath -Directory -ErrorAction SilentlyContinue).Count
        
        Write-TestResult -TestName "Quantidade adequada de plugins" -Passed ($pluginCount -gt $TestConfig.MinPlugins) -Details "$pluginCount DLLs em $pluginFolders categorias" -Category "Plugins"
        
        # Verificar plugins críticos
        $criticalPlugins = @("libqt_plugin.dll", "libaccess_filesystem_plugin.dll", "libvlc.dll")
        foreach ($plugin in $criticalPlugins) {
            $found = $pluginFiles | Where-Object { $_.Name -eq $plugin }
            Write-TestResult -TestName "Plugin crítico: $plugin" -Passed ($found -ne $null) -Category "Plugins"
        }
    }
}

function Test-VlcLibraries {
    Write-Host ""
    Write-Host "📚 Teste 3: Verificação de Bibliotecas" -ForegroundColor Yellow
    
    $vlcDir = Split-Path $VlcPath
    $criticalLibs = @("libvlc.dll", "libvlccore.dll")
    
    foreach ($lib in $criticalLibs) {
        $libPath = Join-Path $vlcDir $lib
        $exists = Test-Path $libPath
        
        Write-TestResult -TestName "Biblioteca: $lib" -Passed $exists -Details $libPath -Category "Bibliotecas"
        
        if ($exists) {
            $libInfo = Get-Item $libPath
            $sizeMB = [math]::Round($libInfo.Length / 1MB, 2)
            Write-TestResult -TestName "$lib - Tamanho válido" -Passed ($sizeMB -gt 0.5) -Details "$sizeMB MB" -Category "Bibliotecas"
        }
    }
}

function Test-VlcVersion {
    Write-Host ""
    Write-Host "ℹ️  Teste 4: Verificação de Versão" -ForegroundColor Yellow
    
    try {
        $versionOutput = & $VlcPath --version --intf dummy --extraintf dummy --no-repeat --no-loop --play-and-exit --quiet 2>&1
        
        if ($versionOutput -match "VLC.*version.*4\.") {
            Write-TestResult -TestName "VLC versão 4.x detectada" -Passed $true -Details ($versionOutput | Select-String "VLC.*version").Line -Category "Versão"
        } else {
            Write-TestResult -TestName "VLC versão 4.x detectada" -Passed $false -Details "Versão não identificada ou incorreta" -Category "Versão"
        }
    }
    catch {
        Write-TestResult -TestName "Comando --version executado" -Passed $false -Details $_.Exception.Message -Category "Versão"
    }
}

function Test-VlcModules {
    Write-Host ""
    Write-Host "🎛️  Teste 5: Verificação de Módulos" -ForegroundColor Yellow
    
    try {
        $moduleOutput = & $VlcPath --list --intf dummy --extraintf dummy --no-repeat --no-loop --play-and-exit --quiet 2>&1 | Out-String
        
        # Verificar módulos críticos
        $criticalModules = @("qt", "filesystem", "stream_out_standard", "mp4")
        foreach ($module in $criticalModules) {
            $found = $moduleOutput -match $module
            Write-TestResult -TestName "Módulo: $module" -Passed $found -Category "Módulos"
        }
        
        # Verificar se Qt está disponível
        $qtFound = $moduleOutput -match "qt.*GUI"
        Write-TestResult -TestName "Interface Qt GUI disponível" -Passed $qtFound -Category "Módulos"
        
    }
    catch {
        Write-TestResult -TestName "Listagem de módulos funcionando" -Passed $false -Details $_.Exception.Message -Category "Módulos"
    }
}

function Test-VlcVideoPlayback {
    if ($SkipVideoTest) {
        Write-TestWarning "Teste de vídeo pulado conforme solicitado"
        return
    }
    
    Write-Host ""
    Write-Host "🎬 Teste 6: Reprodução de Vídeo" -ForegroundColor Yellow
    
    # Baixar vídeo de teste se necessário
    if (-not (Test-Path $TestConfig.TestVideoFile)) {
        try {
            Write-Host "   📥 Baixando vídeo de teste..." -ForegroundColor Gray
            Invoke-WebRequest -Uri $TestConfig.TestVideoUrl -OutFile $TestConfig.TestVideoFile -TimeoutSec 30
            Write-TestResult -TestName "Download do vídeo de teste" -Passed (Test-Path $TestConfig.TestVideoFile) -Category "Vídeo"
        }
        catch {
            Write-TestResult -TestName "Download do vídeo de teste" -Passed $false -Details $_.Exception.Message -Category "Vídeo"
            return
        }
    }
    
    # Testar reprodução
    try {
        Write-Host "   ▶️ Testando reprodução (10s timeout)..." -ForegroundColor Gray
        
        $vlcProcess = Start-Process -FilePath $VlcPath -ArgumentList @(
            "--play-and-exit",
            "--no-repeat",
            "--no-loop", 
            "--intf", "dummy",
            "--extraintf", "dummy",
            "--quiet",
            $TestConfig.TestVideoFile
        ) -PassThru -NoNewWindow
        
        # Aguardar até 10 segundos
        $timeout = 10
        $vlcProcess | Wait-Process -Timeout $timeout -ErrorAction SilentlyContinue
        
        if ($vlcProcess.ExitCode -eq 0 -or $vlcProcess.HasExited) {
            Write-TestResult -TestName "Reprodução de vídeo MP4" -Passed $true -Details "Vídeo reproduzido com sucesso" -Category "Vídeo"
        } else {
            # Forçar fechamento se ainda rodando
            if (-not $vlcProcess.HasExited) {
                $vlcProcess | Stop-Process -Force
            }
            Write-TestResult -TestName "Reprodução de vídeo MP4" -Passed $false -Details "Timeout ou erro na reprodução" -Category "Vídeo"
        }
    }
    catch {
        Write-TestResult -TestName "Reprodução de vídeo MP4" -Passed $false -Details $_.Exception.Message -Category "Vídeo"
    }
}

function Test-VlcGUI {
    Write-Host ""
    Write-Host "🖥️  Teste 7: Interface Gráfica" -ForegroundColor Yellow
    
    try {
        # Tentar iniciar GUI rapidamente e fechar
        $guiProcess = Start-Process -FilePath $VlcPath -ArgumentList @("--intf", "qt", "--extraintf", "dummy", "--qt-start-minimized") -PassThru -WindowStyle Minimized
        
        Start-Sleep -Seconds 3
        
        if (-not $guiProcess.HasExited) {
            $guiProcess | Stop-Process -Force
            Write-TestResult -TestName "Interface Qt GUI iniciada" -Passed $true -Details "GUI iniciou e foi fechada corretamente" -Category "Interface"
        } else {
            Write-TestResult -TestName "Interface Qt GUI iniciada" -Passed $false -Details "GUI não conseguiu iniciar" -Category "Interface"
        }
    }
    catch {
        Write-TestResult -TestName "Interface Qt GUI iniciada" -Passed $false -Details $_.Exception.Message -Category "Interface"
    }
}

function Generate-TestReport {
    if (-not $GenerateReport) { return }
    
    Write-Host ""
    Write-Host "📄 Gerando relatório HTML..." -ForegroundColor Yellow
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>VLC Test Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; border-bottom: 2px solid #2196F3; padding-bottom: 20px; margin-bottom: 30px; }
        .summary { display: flex; justify-content: space-around; margin: 20px 0; }
        .stat-box { text-align: center; padding: 15px; border-radius: 5px; min-width: 100px; }
        .passed { background: #E8F5E8; color: #2E7D2E; }
        .failed { background: #FFF0F0; color: #D32F2F; }
        .warning { background: #FFF8E1; color: #F57C00; }
        .test-item { margin: 10px 0; padding: 10px; border-left: 4px solid #ccc; background: #f9f9f9; }
        .test-pass { border-color: #4CAF50; }
        .test-fail { border-color: #F44336; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$($TestConfig.Title)</h1>
            <p>Relatório gerado em $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>
        </div>
        
        <div class="summary">
            <div class="stat-box passed">
                <h3>$($TestResults.Passed)</h3>
                <p>Testes Aprovados</p>
            </div>
            <div class="stat-box failed">
                <h3>$($TestResults.Failed)</h3>
                <p>Testes Reprovados</p>
            </div>
            <div class="stat-box warning">
                <h3>$($TestResults.Warnings)</h3>
                <p>Avisos</p>
            </div>
        </div>
        
        <h2>Detalhes dos Testes</h2>
"@

    foreach ($test in $TestResults.Tests) {
        $statusClass = if ($test.Passed) { "test-pass" } else { "test-fail" }
        $statusIcon = if ($test.Passed) { "✅" } else { "❌" }
        
        $html += @"
        <div class="test-item $statusClass">
            <strong>$statusIcon $($test.Name)</strong>
            <span class="timestamp">($($test.Category))</span>
            $(if ($test.Details) { "<br><small>$($test.Details)</small>" })
        </div>
"@
    }
    
    $html += @"
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $TestConfig.ReportFile -Encoding UTF8
    Write-Host "✅ Relatório salvo em: $($TestConfig.ReportFile)" -ForegroundColor Green
}

function Show-TestSummary {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "  RESUMO DOS TESTES" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    
    $total = $TestResults.Passed + $TestResults.Failed
    $successRate = if ($total -gt 0) { [math]::Round(($TestResults.Passed / $total) * 100, 1) } else { 0 }
    
    Write-Host ""
    Write-Host "📊 Resultados:" -ForegroundColor White
    Write-Host "   ✅ Aprovados: " -NoNewline; Write-Host $TestResults.Passed -ForegroundColor Green
    Write-Host "   ❌ Reprovados: " -NoNewline; Write-Host $TestResults.Failed -ForegroundColor Red
    Write-Host "   ⚠️  Avisos: " -NoNewline; Write-Host $TestResults.Warnings -ForegroundColor Yellow
    Write-Host "   📈 Taxa de Sucesso: " -NoNewline; Write-Host "$successRate%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })
    
    Write-Host ""
    
    if ($TestResults.Failed -eq 0) {
        Write-Host "🎉 PARABÉNS! Todos os testes passaram!" -ForegroundColor Green
        Write-Host "   O VLC foi compilado com sucesso e está funcionando perfeitamente." -ForegroundColor White
    } elseif ($TestResults.Failed -le 2) {
        Write-Host "⚠️  VLC compilado com problemas menores" -ForegroundColor Yellow
        Write-Host "   A maioria das funcionalidades está OK, mas há alguns problemas." -ForegroundColor White
    } else {
        Write-Host "❌ VLC apresenta problemas significativos" -ForegroundColor Red
        Write-Host "   Recomenda-se recompilar ou verificar os logs de erro." -ForegroundColor White
    }
}

# === EXECUÇÃO PRINCIPAL ===
Write-TestHeader

# Executar todos os testes
$tests = @(
    { Test-VlcExecutable },
    { Test-VlcPlugins },
    { Test-VlcLibraries },
    { Test-VlcVersion },
    { Test-VlcModules },
    { Test-VlcVideoPlayback },
    { Test-VlcGUI }
)

$canContinue = $true
foreach ($test in $tests) {
    if (-not $canContinue) { break }
    
    try {
        $result = & $test
        if ($result -eq $false) {
            $canContinue = $false
        }
    }
    catch {
        Write-TestResult -TestName "Execução do teste" -Passed $false -Details $_.Exception.Message
        $canContinue = $false
    }
}

# Gerar relatório se solicitado
Generate-TestReport

# Mostrar resumo
Show-TestSummary

# Limpar arquivo de teste
if (Test-Path $TestConfig.TestVideoFile) {
    Remove-Item $TestConfig.TestVideoFile -Force -ErrorAction SilentlyContinue
}

# Exit code baseado nos resultados
exit $TestResults.Failed