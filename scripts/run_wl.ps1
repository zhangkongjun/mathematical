[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ScriptPath,

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$ScriptArguments = @(),

    [string]$WorkingDirectory,

    [string]$OutputDir,

    [string]$LogDir,

    [string]$WolframScriptPath = "wolframscript",

    [switch]$PrintCommand
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-PathFlexible {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue,

        [Parameter(Mandatory = $true)]
        [string[]]$Bases
    )

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return [System.IO.Path]::GetFullPath($PathValue)
    }

    foreach ($base in $Bases) {
        if ([string]::IsNullOrWhiteSpace($base)) {
            continue
        }

        $candidate = Join-Path $base $PathValue
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return [System.IO.Path]::GetFullPath((Join-Path $Bases[0] $PathValue))
}

function New-DirectoryIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue
    )

    if (-not (Test-Path -LiteralPath $PathValue)) {
        New-Item -ItemType Directory -Force -Path $PathValue | Out-Null
    }
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$defaultWorkingDirectory = $repoRoot
$defaultOutputDir = Join-Path $repoRoot "results"
$defaultLogDir = Join-Path $repoRoot "logs"

if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) {
    $WorkingDirectory = $defaultWorkingDirectory
}
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = $defaultOutputDir
}
if ([string]::IsNullOrWhiteSpace($LogDir)) {
    $LogDir = $defaultLogDir
}

$WorkingDirectory = Resolve-PathFlexible -PathValue $WorkingDirectory -Bases @($PWD.Path, $repoRoot)
$OutputDir = Resolve-PathFlexible -PathValue $OutputDir -Bases @($PWD.Path, $repoRoot)
$LogDir = Resolve-PathFlexible -PathValue $LogDir -Bases @($PWD.Path, $repoRoot)

New-DirectoryIfMissing -PathValue $OutputDir
New-DirectoryIfMissing -PathValue $LogDir

$scriptBases = @(
    $PWD.Path,
    $WorkingDirectory,
    (Join-Path $repoRoot "wl"),
    $repoRoot
)
$resolvedScriptPath = Resolve-PathFlexible -PathValue $ScriptPath -Bases $scriptBases

if (-not (Test-Path -LiteralPath $resolvedScriptPath)) {
    throw "未找到 Wolfram 脚本: $ScriptPath"
}

$command = Get-Command $WolframScriptPath -ErrorAction Stop
$resolvedWolframScript = $command.Source
$runId = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $LogDir ("run_wl_{0}.log" -f $runId)

$header = @"
[run_wl]
run_id = $runId
timestamp = $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
wolframscript = $resolvedWolframScript
script = $resolvedScriptPath
working_directory = $WorkingDirectory
output_dir = $OutputDir
arguments = $($ScriptArguments -join " ")
"@

$header | Out-File -LiteralPath $logFile -Encoding utf8

$previousOutputDir = $env:SCIENTIFIC_LAB_OUTPUT_DIR
$previousLogDir = $env:SCIENTIFIC_LAB_LOG_DIR
$previousRunId = $env:SCIENTIFIC_LAB_RUN_ID

$env:SCIENTIFIC_LAB_OUTPUT_DIR = $OutputDir
$env:SCIENTIFIC_LAB_LOG_DIR = $LogDir
$env:SCIENTIFIC_LAB_RUN_ID = $runId

$commandArguments = @("-file", $resolvedScriptPath) + $ScriptArguments
$exitCode = 1

if ($PrintCommand) {
    Write-Host ("执行命令: {0} {1}" -f $resolvedWolframScript, ($commandArguments -join " "))
}

$originalLocation = Get-Location

try {
    Set-Location -LiteralPath $WorkingDirectory

    & $resolvedWolframScript @commandArguments 2>&1 | Tee-Object -FilePath $logFile -Append
    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }

    $summary = @"

[summary]
exit_code = $exitCode
log_file = $logFile
"@
    $summary | Out-File -LiteralPath $logFile -Encoding utf8 -Append

    if ($exitCode -ne 0) {
        throw "Wolfram 脚本执行失败，退出码: $exitCode"
    }

    Write-Host ("执行完成。日志: {0}" -f $logFile)
    exit 0
}
catch {
    $message = $_.Exception.Message
    "[error] $message" | Out-File -LiteralPath $logFile -Encoding utf8 -Append
    Write-Error $message
    exit $exitCode
}
finally {
    Set-Location -LiteralPath $originalLocation

    $env:SCIENTIFIC_LAB_OUTPUT_DIR = $previousOutputDir
    $env:SCIENTIFIC_LAB_LOG_DIR = $previousLogDir
    $env:SCIENTIFIC_LAB_RUN_ID = $previousRunId
}
