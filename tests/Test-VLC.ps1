#Requires -Version 5.1

<#+
.SYNOPSIS
Verifies that the locally built VLC binary works.

.DESCRIPTION
Runs three checks (existence, version, playback) against the supplied VLC
binary. The playback test downloads a small sample video to the user's TEMP
directory unless the quick mode is requested.

.PARAMETER VlcPath
Path to the vlc.exe under test. Defaults to ..\bin\vlc\vlc.exe relative to
this script.

.PARAMETER SampleVideoPath
Location used to store the temporary sample video for the playback test.

.PARAMETER Quick
Skips the playback test and therefore the download.

.EXAMPLE
PS> .\Test-VLC.ps1
Runs all checks.

.EXAMPLE
PS> .\Test-VLC.ps1 -Quick
Runs only the existence and version checks.
#>

[CmdletBinding()]
param (
    [string]$VlcPath,
    [string]$SampleVideoPath,
    [switch]$Quick
)

$script:ScriptRoot = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    (Get-Location).Path
}

if ([string]::IsNullOrWhiteSpace($VlcPath)) {
    $VlcPath = Join-Path -Path $script:ScriptRoot -ChildPath "..\bin\vlc\vlc.exe"
}

if ([string]::IsNullOrWhiteSpace($SampleVideoPath)) {
    $SampleVideoPath = Join-Path -Path $env:TEMP -ChildPath "vlc-test-video.mp4"
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Test {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "TEST: $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Failed {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Invoke-VlcCommand {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [int]$TimeoutMilliseconds = 5000
    )

    $outputFile = [System.IO.Path]::GetTempFileName()
    $errorFile = [System.IO.Path]::GetTempFileName()

    try {
        $process = Start-Process -FilePath $VlcPath -ArgumentList $Arguments -PassThru `
            -WindowStyle Hidden -RedirectStandardOutput $outputFile -RedirectStandardError $errorFile

        if (-not $process.WaitForExit($TimeoutMilliseconds)) {
            $process.Kill()
            throw "Timeout ao executar VLC (argumentos: $($Arguments -join ' '))."
        }

        return Get-Content -LiteralPath $outputFile -ErrorAction Stop
    }
    finally {
        Remove-Item -LiteralPath $outputFile -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $errorFile -ErrorAction SilentlyContinue
    }
}

function Test-VlcExists {
    Write-Test "Checking if VLC exists at '$VlcPath'"

    if (Test-Path -LiteralPath $VlcPath) {
        $sizeMb = (Get-Item -LiteralPath $VlcPath).Length / 1MB
        Write-Success ("Found VLC ({0:N1} MB)" -f $sizeMb)
        return $true
    }

    Write-Failed "VLC not found. Run .\Build-VLC.ps1 before testing."
    return $false
}

function Test-VlcVersion {
    Write-Test "Checking VLC version output"

    try {
        $versionLines = Invoke-VlcCommand -Arguments @("--version", "--quiet")
        $line = $versionLines | Select-Object -First 1

        if ([string]::IsNullOrWhiteSpace($line) -or ($line -notmatch 'VLC')) {
            Write-Failed "VLC did not return a valid version line."
            return $false
        }

        Write-Success "Reported version: $line"
        return $true
    }
    catch {
        Write-Failed "Failed to obtain version: $($_.Exception.Message)"
        return $false
    }
}

function Test-VlcPlayback {
    Write-Test "Running playback test"

    if ($Quick) {
        Write-Host "Quick mode: playback test skipped." -ForegroundColor Gray
        return $true
    }

    $shouldCleanupVideo = $false

    try {
        if (-not (Test-Path -LiteralPath $SampleVideoPath)) {
            Write-Host "Downloading sample video..." -ForegroundColor Gray
            Invoke-WebRequest -Uri "https://download.samplelib.com/mp4/sample-5s.mp4" `
                -OutFile $SampleVideoPath -UseBasicParsing -TimeoutSec 30
            $shouldCleanupVideo = $true
        }

        Write-Host "Starting VLC sample playback..." -ForegroundColor Gray
        $process = Start-Process -FilePath $VlcPath -ArgumentList `
            "--play-and-exit", "--quiet", "--intf", "dummy", $SampleVideoPath `
            -PassThru -WindowStyle Hidden

        if ($process.WaitForExit(10000)) {
            if ($process.ExitCode -eq 0) {
                Write-Success "Playback finished successfully."
                return $true
            }

            Write-Failed "VLC exited with code $($process.ExitCode)."
            return $false
        }

        $process.Kill()
        Write-Failed "Playback timeout (10 seconds)."
        return $false
    }
    catch {
        Write-Failed "Playback test failed: $($_.Exception.Message)"
        return $false
    }
    finally {
        if ($shouldCleanupVideo -and (Test-Path -LiteralPath $SampleVideoPath)) {
            Remove-Item -LiteralPath $SampleVideoPath -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ""
Write-Host "VLC BUILD TEST" -ForegroundColor Cyan -BackgroundColor Black
Write-Host "================" -ForegroundColor Cyan -BackgroundColor Black
Write-Host ""

$tests = @()

$tests += Test-VlcExists

if ($tests[-1]) {
    $tests += Test-VlcVersion
}
else {
    $tests += $false
}

if ($tests[-1]) {
    $tests += Test-VlcPlayback
}
else {
    $tests += $false
}

$passed = @($tests | Where-Object { $_ }).Count
$total = @($tests).Count

Write-Host ""
Write-Host "TEST SUMMARY" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "============" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Passed: $passed/$total" -ForegroundColor Green
Write-Host "Failed: $($total - $passed)/$total" -ForegroundColor Red

if ($passed -eq $total) {
    Write-Host ""
    Write-Host "All tests passed. VLC build looks good." -ForegroundColor Green -BackgroundColor Black
    Write-Host "You can run: $VlcPath" -ForegroundColor Yellow
}
else {
    Write-Host ""
    Write-Host "Some tests failed. Please review the build." -ForegroundColor Red -BackgroundColor Black
    Write-Host "Hint: try running .\Build-VLC.ps1" -ForegroundColor Yellow
}

Write-Host ""
