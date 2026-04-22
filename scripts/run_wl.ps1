[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ScriptPath,

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$ScriptArguments = @(),

    [string]$TaskSlug,

    [string]$WorkingDirectory,

    [string]$OutputDir,

    [string]$LogDir,

    [int]$ExecutionTimeoutSec = 0,

    [string]$WolframScriptPath = "C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe",

    [switch]$PrintCommand
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

<#
.SYNOPSIS
默认的 .wl / .wls 执行入口。

.DESCRIPTION
本脚本用于统一调用 wolframscript 执行仓库中的 .wl / .wls。

默认职责：
1. 解析脚本路径，并尽量适配现有 tasks/<task-slug> 目录结构。
2. 自动创建日志目录、输出目录和任务相关目录。
3. 将常用目录通过环境变量暴露给 Wolfram 脚本，避免每次临时拼命令。
4. 记录完整日志、标准输出、标准错误和退出码，便于复现实验。

注意事项：
1. 常规运行 .wl / .wls 时，优先使用本脚本，而不是重新生成新的运行命令。
2. ExecutionTimeoutSec = 0 表示不设置超时；仅在明确需要时才加超时。
3. 本脚本只负责 .wl / .wls 执行；若要生成或检查 .nb，请改用 export_nb.ps1。
4. 任务脚本若需要输出结果，优先写入 SCIENTIFIC_LAB_OUTPUT_DIR 及相关目录变量。
#>

function Resolve-PathFlexible {
    <#
    .SYNOPSIS
    按给定基路径顺序解析相对路径。

    .DESCRIPTION
    若 PathValue 已是绝对路径，则直接规范化返回。
    否则依次尝试 Bases 中的目录，找到第一个存在的路径并返回其绝对路径。
    如果都不存在，则基于第一个 base 拼出一个“期望路径”返回，便于后续统一报错。
    #>
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
    <#
    .SYNOPSIS
    若目录不存在则创建。

    .DESCRIPTION
    这里统一使用 -Force，确保多次执行时行为稳定。
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue
    )

    if (-not (Test-Path -LiteralPath $PathValue)) {
        New-Item -ItemType Directory -Force -Path $PathValue | Out-Null
    }
}

function Resolve-WolframScriptExecutable {
    <#
    .SYNOPSIS
    解析 wolframscript 可执行文件。

    .DESCRIPTION
    先按显式路径查找，再退回到 PATH 中搜索。
    若都找不到，则立即报错，避免后续出现“命令不存在”的模糊失败。
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue
    )

    if (Test-Path -LiteralPath $PathValue) {
        return (Resolve-Path -LiteralPath $PathValue).Path
    }

    $command = Get-Command $PathValue -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    throw "wolframscript executable was not found: $PathValue"
}

function Get-TaskSlugFromPaths {
    <#
    .SYNOPSIS
    从路径中推断 task-slug。

    .DESCRIPTION
    若路径中存在 tasks/<task-slug>/... 结构，则直接提取 task-slug。
    这样在用户未显式传入 TaskSlug 时，脚本仍能自动落到正确的任务目录。
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$CandidatePaths,
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    foreach ($candidate in $CandidatePaths) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        $fullPath = [System.IO.Path]::GetFullPath($candidate)
        if (-not $fullPath.StartsWith($RepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        $relativePath = $fullPath.Substring($RepoRoot.Length).TrimStart('\', '/')
        if ([string]::IsNullOrWhiteSpace($relativePath)) {
            continue
        }

        $segments = $relativePath -split '[\\/]'
        for ($index = 0; $index -lt ($segments.Length - 1); $index++) {
            if ($segments[$index] -ieq "tasks") {
                return $segments[$index + 1]
            }
        }
    }

    return $null
}

function Format-ArgumentForLog {
    <#
    .SYNOPSIS
    将参数格式化为适合写入日志的单行文本。

    .DESCRIPTION
    这里只用于日志展示，不参与真实执行。
    遇到空格或双引号时会进行最小转义，方便复盘调用命令。
    #>
    param(
        [AllowNull()]
        [string]$Value
    )

    if ($null -eq $Value) {
        return '""'
    }

    if ($Value.Contains(' ') -or $Value.Contains('"')) {
        return '"' + $Value.Replace('"', '\"') + '"'
    }

    return $Value
}

function Append-FileToLog {
    <#
    .SYNOPSIS
    将临时输出文件内容追加到日志。

    .DESCRIPTION
    标准输出和标准错误统一通过临时文件收集，随后再写入主日志。
    这样即使进程超时或异常退出，也尽量保留现场信息。
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )

    if (Test-Path -LiteralPath $SourcePath) {
        Get-Content -LiteralPath $SourcePath | Tee-Object -FilePath $LogPath -Append | Out-Host
    }
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$scriptBases = @(
    $PWD.Path,
    (Join-Path $repoRoot "wl"),
    (Join-Path $repoRoot "scripts"),
    $repoRoot
)

if (-not [string]::IsNullOrWhiteSpace($TaskSlug)) {
    $scriptBases = @(
        $PWD.Path,
        (Join-Path $repoRoot ("wl\tasks\{0}" -f $TaskSlug)),
        (Join-Path $repoRoot ("scripts\tasks\{0}" -f $TaskSlug)),
        (Join-Path $repoRoot "wl"),
        (Join-Path $repoRoot "scripts"),
        $repoRoot
    )
}

$resolvedScriptPath = Resolve-PathFlexible -PathValue $ScriptPath -Bases $scriptBases
if (-not (Test-Path -LiteralPath $resolvedScriptPath)) {
    throw "Wolfram script was not found: $ScriptPath"
}

if ([string]::IsNullOrWhiteSpace($TaskSlug)) {
    $taskSlugCandidates = @($resolvedScriptPath, $WorkingDirectory) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $TaskSlug = Get-TaskSlugFromPaths -CandidatePaths $taskSlugCandidates -RepoRoot $repoRoot
}

$taskDataDir = $null
$taskLogDir = $null
$taskNotebookExportDir = $null
$taskFiguresDir = $null
$taskTablesDir = $null
$taskReportsDir = $null
$taskWolframEnvDir = $null
$taskWlDir = $null
$taskScriptsDir = $null

if (-not [string]::IsNullOrWhiteSpace($TaskSlug)) {
    $taskDataDir = Join-Path $repoRoot ("data\processed\tasks\{0}" -f $TaskSlug)
    $taskLogDir = Join-Path $repoRoot ("logs\tasks\{0}" -f $TaskSlug)
    $taskNotebookExportDir = Join-Path $repoRoot ("notebooks\exports\tasks\{0}" -f $TaskSlug)
    $taskFiguresDir = Join-Path $repoRoot ("results\figures\tasks\{0}" -f $TaskSlug)
    $taskTablesDir = Join-Path $repoRoot ("results\tables\tasks\{0}" -f $TaskSlug)
    $taskReportsDir = Join-Path $repoRoot ("results\reports\tasks\{0}" -f $TaskSlug)
    $taskWolframEnvDir = Join-Path $repoRoot (".codex\wolfram-envs\{0}" -f $TaskSlug)
    $taskWlDir = Join-Path $repoRoot ("wl\tasks\{0}" -f $TaskSlug)
    $taskScriptsDir = Join-Path $repoRoot ("scripts\tasks\{0}" -f $TaskSlug)
}

if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) {
    $WorkingDirectory = Split-Path -Parent $resolvedScriptPath
}
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = if ($null -ne $taskDataDir) { $taskDataDir } else { Join-Path $repoRoot "results" }
}
if ([string]::IsNullOrWhiteSpace($LogDir)) {
    $LogDir = if ($null -ne $taskLogDir) { $taskLogDir } else { Join-Path $repoRoot "logs" }
}

$WorkingDirectory = Resolve-PathFlexible -PathValue $WorkingDirectory -Bases @($PWD.Path, (Split-Path -Parent $resolvedScriptPath), $repoRoot)
$OutputDir = Resolve-PathFlexible -PathValue $OutputDir -Bases @($PWD.Path, $repoRoot)
$LogDir = Resolve-PathFlexible -PathValue $LogDir -Bases @($PWD.Path, $repoRoot)

foreach ($directory in @(
    $OutputDir,
    $LogDir,
    $taskDataDir,
    $taskLogDir,
    $taskNotebookExportDir,
    $taskFiguresDir,
    $taskTablesDir,
    $taskReportsDir,
    $taskWolframEnvDir,
    $taskWlDir,
    $taskScriptsDir
)) {
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        New-DirectoryIfMissing -PathValue $directory
    }
}

$resolvedWolframScript = Resolve-WolframScriptExecutable -PathValue $WolframScriptPath
$runId = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $LogDir ("run_wl_{0}.log" -f $runId)
$stdoutPath = Join-Path $env:TEMP ("run_wl_stdout_{0}.log" -f $runId)
$stderrPath = Join-Path $env:TEMP ("run_wl_stderr_{0}.log" -f $runId)
$formattedArguments = (@($ScriptArguments | ForEach-Object { Format-ArgumentForLog $_ })) -join " "
$formattedCommandArguments = (@((@("-file", $resolvedScriptPath) + $ScriptArguments) | ForEach-Object { Format-ArgumentForLog $_ })) -join " "

$header = @"
[run_wl]
run_id = $runId
timestamp = $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
wolframscript = $resolvedWolframScript
script = $resolvedScriptPath
task_slug = $TaskSlug
working_directory = $WorkingDirectory
output_dir = $OutputDir
task_data_dir = $taskDataDir
task_notebook_export_dir = $taskNotebookExportDir
task_figures_dir = $taskFiguresDir
task_tables_dir = $taskTablesDir
task_reports_dir = $taskReportsDir
task_wolfram_env_dir = $taskWolframEnvDir
execution_timeout_sec = $ExecutionTimeoutSec
arguments = $formattedArguments
"@
$header | Out-File -LiteralPath $logFile -Encoding utf8

$environmentAssignments = [ordered]@{
    SCIENTIFIC_LAB_OUTPUT_DIR = $OutputDir
    SCIENTIFIC_LAB_LOG_DIR = $LogDir
    SCIENTIFIC_LAB_RUN_ID = $runId
    SCIENTIFIC_LAB_TASK_SLUG = $TaskSlug
    SCIENTIFIC_LAB_TASK_DATA_DIR = $taskDataDir
    SCIENTIFIC_LAB_NOTEBOOK_EXPORT_DIR = $taskNotebookExportDir
    SCIENTIFIC_LAB_RESULTS_FIGURES_DIR = $taskFiguresDir
    SCIENTIFIC_LAB_RESULTS_TABLES_DIR = $taskTablesDir
    SCIENTIFIC_LAB_RESULTS_REPORTS_DIR = $taskReportsDir
    SCIENTIFIC_LAB_WOLFRAM_ENV_DIR = $taskWolframEnvDir
    SCIENTIFIC_LAB_WL_TASK_DIR = $taskWlDir
    SCIENTIFIC_LAB_SCRIPT_TASK_DIR = $taskScriptsDir
}

$previousEnvironmentValues = @{}
foreach ($entry in $environmentAssignments.GetEnumerator()) {
    $previousEnvironmentValues[$entry.Key] = [System.Environment]::GetEnvironmentVariable($entry.Key, "Process")
    [System.Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, "Process")
}

$commandArguments = @("-file", $resolvedScriptPath) + $ScriptArguments
$exitCode = 1
$failureMessage = $null
$process = $null
$originalLocation = Get-Location

if ($PrintCommand) {
    Write-Host ("Executing command: {0} {1}" -f $resolvedWolframScript, $formattedCommandArguments)
}

try {
    Set-Location -LiteralPath $WorkingDirectory

    foreach ($path in @($stdoutPath, $stderrPath)) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force
        }
    }

    $process = Start-Process -FilePath $resolvedWolframScript -ArgumentList $commandArguments -WorkingDirectory $WorkingDirectory -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

    if ($ExecutionTimeoutSec -gt 0) {
        $exited = $process.WaitForExit($ExecutionTimeoutSec * 1000)
        if (-not $exited) {
            try {
                Stop-Process -Id $process.Id -Force -ErrorAction Stop
            }
            catch {
            }

            $exitCode = 124
            $failureMessage = "Wolfram script timed out and the process was stopped. Timeout seconds: $ExecutionTimeoutSec"
        }
    }
    else {
        $process.WaitForExit()
    }

    Append-FileToLog -SourcePath $stdoutPath -LogPath $logFile
    Append-FileToLog -SourcePath $stderrPath -LogPath $logFile

    if ([string]::IsNullOrWhiteSpace($failureMessage)) {
        $exitCode = if (($null -ne $process) -and ($null -ne $process.ExitCode)) { $process.ExitCode } else { 0 }
        if ($exitCode -ne 0) {
            $failureMessage = "Wolfram script failed with exit code: $exitCode"
        }
    }
}
catch {
    if ([string]::IsNullOrWhiteSpace($failureMessage)) {
        $failureMessage = $_.Exception.Message
    }

    if (($exitCode -le 0) -or ($null -eq $exitCode)) {
        $exitCode = 1
    }
}
finally {
    if (-not [string]::IsNullOrWhiteSpace($failureMessage)) {
        "[error] $failureMessage" | Out-File -LiteralPath $logFile -Encoding utf8 -Append
    }

    $summary = @"

[summary]
exit_code = $exitCode
log_file = $logFile
"@
    $summary | Out-File -LiteralPath $logFile -Encoding utf8 -Append

    Set-Location -LiteralPath $originalLocation

    foreach ($entry in $previousEnvironmentValues.GetEnumerator()) {
        [System.Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, "Process")
    }

    foreach ($path in @($stdoutPath, $stderrPath)) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force
        }
    }
}

if (-not [string]::IsNullOrWhiteSpace($failureMessage)) {
    Write-Error $failureMessage
    exit $exitCode
}

Write-Host ("Execution completed. Log: {0}" -f $logFile)
exit 0
