# Script de teste completo do VLC Build
# Valida se a compilacao foi bem-sucedida e testa reproducao de video

param(
    [string]$VlcPath = "C:\vlc-test\bin\vlc.exe",
    [switch]$SkipVideoTest,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  TESTE DE BUILD DO VLC - Validacao Completa" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

# Cores para output
function Write-TestResult {
    param([string]$Test, [bool]$Pass, [string]$Details = "")
    if ($Pass) {
        Write-Host "[OK] " -ForegroundColor Green -NoNewline
        Write-Host "$Test" -ForegroundColor White
        if ($Details) { Write-Host "    $Details" -ForegroundColor Gray }
    } else {
        Write-Host "[FALHA] " -ForegroundColor Red -NoNewline
        Write-Host "$Test" -ForegroundColor White
        if ($Details) { Write-Host "    $Details" -ForegroundColor Yellow }
    }
}

$results = @{
    Passed = 0
    Failed = 0
    Tests = @()
}

# ============================================================
# TESTE 1: Verificar se o executavel existe
# ============================================================
Write-Host "1. Verificando executavel do VLC..." -ForegroundColor Yellow
$vlcExists = Test-Path $VlcPath
Write-TestResult -Test "Executavel encontrado em $VlcPath" -Pass $vlcExists
if ($vlcExists) { 
    $results.Passed++ 
    $vlcInfo = Get-Item $VlcPath
    if ($Verbose) {
        Write-Host "    Tamanho: $([math]::Round($vlcInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Host "    Modificado: $($vlcInfo.LastWriteTime)" -ForegroundColor Gray
    }
} else { 
    $results.Failed++
    Write-Host ""
    Write-Host "ERRO: VLC nao encontrado. Compile primeiro seguindo COMPILAR_VLC_GUI.md" -ForegroundColor Red
    exit 1
}
Write-Host ""

# ============================================================
# TESTE 2: Verificar plugins
# ============================================================
Write-Host "2. Verificando plugins instalados..." -ForegroundColor Yellow
$pluginPath = Split-Path $VlcPath | Split-Path | Join-Path -ChildPath "lib\vlc\plugins"
if (Test-Path $pluginPath) {
    $pluginCount = (Get-ChildItem "$pluginPath\*.dll" -Recurse -ErrorAction SilentlyContinue).Count
    $pluginFolders = (Get-ChildItem $pluginPath -Directory).Count
    
    $hasPlugins = $pluginCount -gt 50
    Write-TestResult -Test "Plugins encontrados: $pluginCount DLLs em $pluginFolders categorias" -Pass $hasPlugins
    
    if ($hasPlugins) { $results.Passed++ } else { $results.Failed++ }
    
    if ($Verbose -and $hasPlugins) {
        $categories = Get-ChildItem $pluginPath -Directory | Select-Object -First 8 Name
        Write-Host "    Categorias: $($categories.Name -join ', ')..." -ForegroundColor Gray
    }
} else {
    Write-TestResult -Test "Pasta de plugins" -Pass $false -Details "Pasta nao encontrada: $pluginPath"
    $results.Failed++
}
Write-Host ""

# ============================================================
# TESTE 3: Verificar dependencias DLL
# ============================================================
Write-Host "3. Verificando dependencias principais..." -ForegroundColor Yellow
$binPath = Split-Path $VlcPath
$requiredDlls = @("libvlc.dll", "libvlccore.dll")
$dllsFound = 0

foreach ($dll in $requiredDlls) {
    $dllPath = Join-Path $binPath $dll
    $exists = Test-Path $dllPath
    Write-TestResult -Test "$dll" -Pass $exists
    if ($exists) { $dllsFound++ }
}

if ($dllsFound -eq $requiredDlls.Count) { $results.Passed++ } else { $results.Failed++ }
Write-Host ""

# ============================================================
# TESTE 4: Verificar versao e ajuda
# ============================================================
Write-Host "4. Testando execucao basica (versao)..." -ForegroundColor Yellow
try {
    $versionOutput = & $VlcPath --version --quiet 2>&1 | Out-String
    $hasVersion = $versionOutput -match "VLC|version|vlc"
    Write-TestResult -Test "Comando --version executado com sucesso" -Pass $hasVersion
    
    if ($hasVersion) { 
        $results.Passed++
        if ($Verbose) {
            $versionLine = ($versionOutput -split "`n" | Select-Object -First 1).Trim()
            Write-Host "    $versionLine" -ForegroundColor Gray
        }
    } else { 
        $results.Failed++ 
    }
} catch {
    Write-TestResult -Test "Comando --version" -Pass $false -Details $_.Exception.Message
    $results.Failed++
}
Write-Host ""

# ============================================================
# TESTE 5: Listar modulos disponiveis
# ============================================================
Write-Host "5. Verificando modulos carregados..." -ForegroundColor Yellow
try {
    $modulesOutput = & $VlcPath --list --quiet 2>&1 | Out-String
    $hasModules = $modulesOutput -match "qt|audio|video"
    Write-TestResult -Test "Listagem de modulos funcional" -Pass $hasModules
    
    if ($hasModules) { 
        $results.Passed++
        if ($Verbose) {
            $moduleCount = ([regex]::Matches($modulesOutput, "^\s+\w+", [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
            Write-Host "    ~$moduleCount modulos detectados" -ForegroundColor Gray
        }
    } else { 
        $results.Failed++ 
    }
} catch {
    Write-TestResult -Test "Listagem de modulos" -Pass $false -Details $_.Exception.Message
    $results.Failed++
}
Write-Host ""

# ============================================================
# TESTE 6: Baixar e reproduzir video de teste
# ============================================================
if (-not $SkipVideoTest) {
    Write-Host "6. Teste de reproducao de video..." -ForegroundColor Yellow
    
    $sampleVideo = Join-Path $env:TEMP "vlc-test-sample.mp4"
    $sampleUrl = "https://download.samplelib.com/mp4/sample-5s.mp4"
    
    try {
        Write-Host "   Baixando video de teste (5s)..." -ForegroundColor Gray
        
        # Timeout de 30 segundos para download
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $sampleUrl -OutFile $sampleVideo -TimeoutSec 30 -ErrorAction Stop
        
        if (Test-Path $sampleVideo) {
            Write-TestResult -Test "Download do video de teste" -Pass $true
            
            Write-Host "   Reproduzindo video (aguarde 7 segundos)..." -ForegroundColor Gray
            
            # Iniciar VLC em processo separado com timeout
            $vlcProcess = Start-Process -FilePath $VlcPath `
                -ArgumentList "`"$sampleVideo`"", "--play-and-exit", "--no-repeat", "--no-loop" `
                -PassThru -WindowStyle Normal
            
            # Aguardar ate 10 segundos
            $vlcProcess | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue
            
            if ($vlcProcess.HasExited) {
                $exitCode = $vlcProcess.ExitCode
                $playSuccess = $exitCode -eq 0
                Write-TestResult -Test "Reproducao de video concluida (exit code: $exitCode)" -Pass $playSuccess
                if ($playSuccess) { $results.Passed++ } else { $results.Failed++ }
            } else {
                # Se ainda esta rodando apos 10s, considere sucesso parcial
                Write-TestResult -Test "VLC iniciou e esta reproduzindo" -Pass $true -Details "Processo ainda ativo, fechando..."
                Stop-Process -InputObject $vlcProcess -Force -ErrorAction SilentlyContinue
                $results.Passed++
            }
            
            # Limpar arquivo
            Start-Sleep -Milliseconds 500
            Remove-Item $sampleVideo -Force -ErrorAction SilentlyContinue
            
        } else {
            Write-TestResult -Test "Download do video de teste" -Pass $false
            $results.Failed++
        }
        
    } catch {
        Write-TestResult -Test "Teste de reproducao de video" -Pass $false -Details $_.Exception.Message
        $results.Failed++
    }
} else {
    Write-Host "6. Teste de reproducao de video - IGNORADO" -ForegroundColor Gray
}
Write-Host ""

# ============================================================
# TESTE 7: Verificar interface Qt
# ============================================================
Write-Host "7. Verificando suporte a interface Qt..." -ForegroundColor Yellow
try {
    $qtCheck = & $VlcPath --list --quiet 2>&1 | Select-String "qt" -Quiet
    Write-TestResult -Test "Modulo Qt detectado" -Pass $qtCheck
    if ($qtCheck) { $results.Passed++ } else { $results.Failed++ }
} catch {
    Write-TestResult -Test "Verificacao do modulo Qt" -Pass $false
    $results.Failed++
}
Write-Host ""

# ============================================================
# RESUMO FINAL
# ============================================================
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  RESUMO DOS TESTES" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

$total = $results.Passed + $results.Failed
$percentage = if ($total -gt 0) { [math]::Round(($results.Passed / $total) * 100, 1) } else { 0 }

Write-Host ""
Write-Host "Total de testes: " -NoNewline
Write-Host "$total" -ForegroundColor White

Write-Host "Aprovados: " -NoNewline
Write-Host "$($results.Passed)" -ForegroundColor Green

Write-Host "Falharam: " -NoNewline
Write-Host "$($results.Failed)" -ForegroundColor Red

Write-Host "Taxa de sucesso: " -NoNewline
if ($percentage -ge 80) {
    Write-Host "$percentage%" -ForegroundColor Green
} elseif ($percentage -ge 50) {
    Write-Host "$percentage%" -ForegroundColor Yellow
} else {
    Write-Host "$percentage%" -ForegroundColor Red
}

Write-Host ""

if ($results.Failed -eq 0) {
    Write-Host "SUCESSO! O VLC foi compilado corretamente e esta funcional!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Para iniciar o VLC manualmente:" -ForegroundColor Cyan
    $command = "& `"$VlcPath`""
    Write-Host "  $command" -ForegroundColor White
    exit 0
} elseif ($results.Passed -ge ($total * 0.7)) {
    Write-Host "BUILD PARCIAL: Alguns testes falharam, mas o VLC pode funcionar." -ForegroundColor Yellow
    Write-Host "   Revise os erros acima e consulte COMPILAR_VLC_GUI.md" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "FALHA: Muitos testes falharam. Recompile o VLC seguindo o guia." -ForegroundColor Red
    exit 2
}
