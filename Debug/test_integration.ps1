#Requires -Version 5.1
<#
.SYNOPSIS
    Lightweight integration checks for sisou-runner examples and ISO validation.

.DESCRIPTION
    This script avoids network, Python bootstrap, SISOU execution, and Ventoy
    hardware. It validates checked-in example configs, confirms the runner exposes
    the advanced parameters, and exercises the ISO-9660 CD001 header rule with
    temporary files.
#>

param(
    [string]$RepoRoot = "$PSScriptRoot\.."
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path $RepoRoot).Path
$ScriptPath = Join-Path $RepoRoot 'sisou-runner.ps1'
$RunnerConfigPath = Join-Path $RepoRoot 'Examples\runner-config.json'
$SisouConfigPath = Join-Path $RepoRoot 'Examples\sisou-config.toml'

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) { throw $Message }
}

function Test-LocalIsoHeader {
    param([string]$Path)

    $stream = $null
    try {
        $item = Get-Item -Path $Path -ErrorAction Stop
        if ($item.Length -lt 34817) { return $false }
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open,
                  [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $null = $stream.Seek(32769, [System.IO.SeekOrigin]::Begin)
        $buf = New-Object byte[] 5
        $read = $stream.Read($buf, 0, 5)
        return ([System.Text.Encoding]::ASCII.GetString($buf, 0, $read) -eq 'CD001')
    } finally {
        if ($stream) { $stream.Dispose() }
    }
}

Write-Host 'Checking example runner config...' -ForegroundColor Cyan
Assert-True (Test-Path $RunnerConfigPath) 'Examples/runner-config.json is missing.'
$runnerConfig = Get-Content -Path $RunnerConfigPath -Raw | ConvertFrom-Json
Assert-True ($runnerConfig.RetryCount -ge 1) 'RetryCount must be at least 1.'
Assert-True ($runnerConfig.TimeoutSeconds -ge 30) 'TimeoutSeconds must be at least 30.'
Assert-True ($runnerConfig.HashThrottle -ge 1) 'HashThrottle must be at least 1.'
Assert-True ($runnerConfig.IsoScanDepth -ge -1) 'IsoScanDepth must be -1 or greater.'

Write-Host 'Checking example SISOU config...' -ForegroundColor Cyan
Assert-True (Test-Path $SisouConfigPath) 'Examples/sisou-config.toml is missing.'
$sisouConfig = Get-Content -Path $SisouConfigPath -Raw
Assert-True ($sisouConfig -match '(?m)^directory\s*=\s*"\."') 'SISOU example config needs a root directory.'
Assert-True ($sisouConfig -match '\[OperatingSystems\.Linux\.Ubuntu\]') 'SISOU example config should include a valid updater section.'

Write-Host 'Checking runner parameter surface...' -ForegroundColor Cyan
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$parseErrors)
Assert-True (-not $parseErrors) 'sisou-runner.ps1 has parse errors.'
$paramBlock = $ast.ParamBlock
$paramNames = @($paramBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
foreach ($name in @('AdvancedConfigFile','IsoScanDepth','IncludeIsoPattern','ExcludeIsoPattern','ValidateIsoHeaders')) {
    Assert-True ($paramNames -contains $name) "Missing runner parameter: $name"
}

Write-Host 'Checking ISO header validation contract...' -ForegroundColor Cyan
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("sisou-runner-test-{0}" -f [System.Guid]::NewGuid())
New-Item -ItemType Directory -Path $tempDir | Out-Null
try {
    $validIso = Join-Path $tempDir 'valid.iso'
    $invalidIso = Join-Path $tempDir 'invalid.iso'
    $bytes = New-Object byte[] 40000
    [System.Text.Encoding]::ASCII.GetBytes('CD001').CopyTo($bytes, 32769)
    [System.IO.File]::WriteAllBytes($validIso, $bytes)
    [System.IO.File]::WriteAllBytes($invalidIso, (New-Object byte[] 40000))

    Assert-True (Test-LocalIsoHeader -Path $validIso) 'Expected valid.iso to pass CD001 validation.'
    Assert-True (-not (Test-LocalIsoHeader -Path $invalidIso)) 'Expected invalid.iso to fail CD001 validation.'
} finally {
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host '[OK] Integration checks passed.' -ForegroundColor Green
