[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$NotebookPath,

    [string]$SourceScriptPath,

    [ValidateSet("ScriptOutput", "PackageEditorInput", "StructuredSource")]
    [string]$GenerationMode = "ScriptOutput",

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$SourceScriptArguments = @(),

    [string]$TaskSlug,

    [string]$WorkingDirectory,

    [string]$LogDir,

    [int]$ValidationTimeoutSec = 15,

    [switch]$CheckOnly,

    [string]$WolframNBPath = "C:\Program Files\Wolfram Research\Wolfram\14.3\WolframNB.exe",

    [string]$WolframScriptPath = "C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe",

    [switch]$Overwrite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

<#
.SYNOPSIS
默认的 .nb 生成与检查入口。

.DESCRIPTION
本脚本用于统一完成两件事：
1. 从 .wl / .wls 生成 .nb。
2. 使用 WolframNB.exe -nogui 对目标 .nb 做一次启动级检查。

默认职责：
1. 常规生成 .nb 时，优先调用本脚本，而不是重新拼一条新的 notebook 生成命令。
2. 生成阶段默认复用 run_wl.ps1，以复用已有目录约定、日志约定和环境变量注入。
3. 检查阶段默认使用 WolframNB.exe -nogui，尽早发现 notebook 文件层面的明显问题。
4. 当需要把 `.wl` 源码直接转换成“像手工在 notebook 里键入”的可执行 Input 单元时，
   可通过 `-GenerationMode PackageEditorInput` 走 package editor 复制链路。
5. 当 `.wl` 源文件同时包含结构化说明单元与最终代码，并希望把这些说明也稳定复制到 `.nb` 中时，
   可通过 `-GenerationMode StructuredSource` 走“结构化源文件 -> Front End 复制单元格”链路。

注意事项：
1. 主用途是“生成 .nb”；仅在已有 notebook 需要检查时，才显式使用 -CheckOnly。
2. 生成脚本应优先读取 SCIENTIFIC_LAB_NOTEBOOK_OUTPUT，并把 notebook 写到该路径。
3. WolframNB -nogui 在部分环境中不会自行退出，因此这里采用限时检查；若超时前没有明确错误输出，则视为启动检查通过。
4. 本脚本不负责 PDF / HTML / Markdown 导出，避免职责再次膨胀。
5. `PackageEditorInput` 与 `StructuredSource` 模式都要求源文件是 `.wl` 或 `.m`，因为它们依赖 Wolfram 的 package editor notebook 解析源码单元。
6. `StructuredSource` 模式适用于 `.wl` 中同时存在 `::Title::`、`::Section::`、`::Text::` 等说明单元标记与最终代码单元的场景。
#>

function Resolve-PathFlexible {
    <#
    .SYNOPSIS
    按给定基路径顺序解析相对路径。
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
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue
    )

    if (-not (Test-Path -LiteralPath $PathValue)) {
        New-Item -ItemType Directory -Force -Path $PathValue | Out-Null
    }
}

function Resolve-Executable {
    <#
    .SYNOPSIS
    解析可执行文件路径。

    .DESCRIPTION
    先检查显式路径，再检查 PATH。
    这里同时用于解析 WolframNB.exe 和 wolframscript.exe。
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue,
        [Parameter(Mandatory = $true)]
        [string]$DisplayName
    )

    if (Test-Path -LiteralPath $PathValue) {
        return (Resolve-Path -LiteralPath $PathValue).Path
    }

    $command = Get-Command $PathValue -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    throw "未找到 $DisplayName 可执行文件: $PathValue"
}

function Get-TaskSlugFromPaths {
    <#
    .SYNOPSIS
    从路径中推断 task-slug。
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

function Read-TextFileIfPresent {
    <#
    .SYNOPSIS
    安全读取文本文件。

    .DESCRIPTION
    用于在进程结束后读取 stdout / stderr 临时文件。
    即使文件不存在，也返回空字符串，避免让日志收集阶段再次报错。
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue
    )

    if (Test-Path -LiteralPath $PathValue) {
        $content = Get-Content -LiteralPath $PathValue
        if ($null -eq $content) {
            return ""
        }

        return [string]::Join([Environment]::NewLine, @($content))
    }

    return ""
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$notebookBases = @(
    $PWD.Path,
    (Join-Path $repoRoot "notebooks\tasks"),
    (Join-Path $repoRoot "notebooks"),
    $repoRoot
)

if (-not [string]::IsNullOrWhiteSpace($TaskSlug)) {
    $notebookBases = @(
        $PWD.Path,
        (Join-Path $repoRoot ("notebooks\tasks\{0}" -f $TaskSlug)),
        (Join-Path $repoRoot "notebooks\tasks"),
        (Join-Path $repoRoot "notebooks"),
        $repoRoot
    )
}

$resolvedNotebookPath = Resolve-PathFlexible -PathValue $NotebookPath -Bases $notebookBases

if ([string]::IsNullOrWhiteSpace($TaskSlug)) {
    $taskSlugCandidates = @($resolvedNotebookPath, $SourceScriptPath, $WorkingDirectory) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $TaskSlug = Get-TaskSlugFromPaths -CandidatePaths $taskSlugCandidates -RepoRoot $repoRoot
}

$taskNotebookDir = $null
$taskLogDir = $null
$taskWolframEnvDir = $null

if (-not [string]::IsNullOrWhiteSpace($TaskSlug)) {
    $taskNotebookDir = Join-Path $repoRoot ("notebooks\tasks\{0}" -f $TaskSlug)
    $taskLogDir = Join-Path $repoRoot ("logs\tasks\{0}" -f $TaskSlug)
    $taskWolframEnvDir = Join-Path $repoRoot (".codex\wolfram-envs\{0}" -f $TaskSlug)
}

if ([string]::IsNullOrWhiteSpace($LogDir)) {
    $LogDir = if ($null -ne $taskLogDir) { $taskLogDir } else { Join-Path $repoRoot "logs" }
}
if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) {
    $WorkingDirectory = if ($null -ne $taskNotebookDir) { $taskNotebookDir } else { $repoRoot }
}

$LogDir = Resolve-PathFlexible -PathValue $LogDir -Bases @($PWD.Path, $repoRoot)
$WorkingDirectory = Resolve-PathFlexible -PathValue $WorkingDirectory -Bases @($PWD.Path, $repoRoot)

New-DirectoryIfMissing -PathValue $LogDir

$notebookDirectory = Split-Path -Parent $resolvedNotebookPath
if (-not [string]::IsNullOrWhiteSpace($notebookDirectory)) {
    New-DirectoryIfMissing -PathValue $notebookDirectory
}
if (-not [string]::IsNullOrWhiteSpace($taskWolframEnvDir)) {
    New-DirectoryIfMissing -PathValue $taskWolframEnvDir
}

$resolvedWolframNB = Resolve-Executable -PathValue $WolframNBPath -DisplayName "WolframNB"
$resolvedWolframScript = Resolve-Executable -PathValue $WolframScriptPath -DisplayName "wolframscript"
$runId = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $LogDir ("export_nb_{0}.log" -f $runId)
$stdoutPath = Join-Path $env:TEMP ("export_nb_stdout_{0}.log" -f $runId)
$stderrPath = Join-Path $env:TEMP ("export_nb_stderr_{0}.log" -f $runId)

$mode = "generate"
if (-not [string]::IsNullOrWhiteSpace($SourceScriptPath)) {
    $mode = "generate_and_check"
}
elseif ($CheckOnly) {
    $mode = "check_only"
}
elseif (Test-Path -LiteralPath $resolvedNotebookPath) {
    $mode = "check_only_existing"
}

$header = @"
[export_nb]
run_id = $runId
timestamp = $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
mode = $mode
wolfram_nb = $resolvedWolframNB
wolframscript = $resolvedWolframScript
notebook = $resolvedNotebookPath
task_slug = $TaskSlug
working_directory = $WorkingDirectory
source_script = $SourceScriptPath
generation_mode = $GenerationMode
validation_timeout_sec = $ValidationTimeoutSec
task_wolfram_env_dir = $taskWolframEnvDir
"@
$header | Out-File -LiteralPath $logFile -Encoding utf8

$previousEnvironmentValues = @{}
$environmentAssignments = [ordered]@{
    SCIENTIFIC_LAB_TASK_SLUG = $TaskSlug
    SCIENTIFIC_LAB_LOG_DIR = $LogDir
    SCIENTIFIC_LAB_RUN_ID = $runId
    SCIENTIFIC_LAB_WOLFRAM_ENV_DIR = $taskWolframEnvDir
    SCIENTIFIC_LAB_NOTEBOOK_OUTPUT = $resolvedNotebookPath
    SCIENTIFIC_LAB_NOTEBOOK_SOURCE = $null
    SCIENTIFIC_LAB_NOTEBOOK_TITLE = [System.IO.Path]::GetFileNameWithoutExtension($resolvedNotebookPath)
}

foreach ($entry in $environmentAssignments.GetEnumerator()) {
    $previousEnvironmentValues[$entry.Key] = [System.Environment]::GetEnvironmentVariable($entry.Key, "Process")
    [System.Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, "Process")
}

$exitCode = 1
$failureMessage = $null
$stdoutText = ""
$stderrText = ""
$process = $null

try {
    if (($mode -eq "generate") -and [string]::IsNullOrWhiteSpace($SourceScriptPath)) {
        throw "SourceScriptPath is required for default notebook generation mode. Use -CheckOnly to validate an existing notebook."
    }

    if ($mode -eq "generate_and_check") {
        $resolvedSourceScript = Resolve-PathFlexible -PathValue $SourceScriptPath -Bases @(
            $PWD.Path,
            (Join-Path $repoRoot "wl"),
            (Join-Path $repoRoot "wl\tasks"),
            (Join-Path $repoRoot "scripts"),
            (Join-Path $repoRoot "scripts\tasks"),
            $repoRoot
        )

        if ((Test-Path -LiteralPath $resolvedNotebookPath) -and (-not $Overwrite)) {
            throw "Target notebook already exists. Use -Overwrite to regenerate: $resolvedNotebookPath"
        }

        if ((Test-Path -LiteralPath $resolvedNotebookPath) -and $Overwrite) {
            Remove-Item -LiteralPath $resolvedNotebookPath -Force
        }

        $environmentAssignments["SCIENTIFIC_LAB_NOTEBOOK_SOURCE"] = $resolvedSourceScript
        [System.Environment]::SetEnvironmentVariable("SCIENTIFIC_LAB_NOTEBOOK_SOURCE", $resolvedSourceScript, "Process")

        if ($GenerationMode -eq "ScriptOutput") {
            & (Join-Path $PSScriptRoot "run_wl.ps1") -ScriptPath $resolvedSourceScript -TaskSlug $TaskSlug -WorkingDirectory $WorkingDirectory -LogDir $LogDir -WolframScriptPath $resolvedWolframScript @SourceScriptArguments
        }
        else {
            $allowedPackageExtensions = @(".wl", ".m")
            $sourceExtension = [System.IO.Path]::GetExtension($resolvedSourceScript)
            if ($allowedPackageExtensions -notcontains $sourceExtension.ToLowerInvariant()) {
                throw "$GenerationMode mode requires a .wl or .m source file: $resolvedSourceScript"
            }
            if ($SourceScriptArguments.Count -gt 0) {
                throw "$GenerationMode mode does not accept SourceScriptArguments. Put notebook behavior in the source file or helper logic instead."
            }

            $helperScriptPath = if ($GenerationMode -eq "PackageEditorInput") {
                Join-Path $repoRoot "wl\common\export_notebook_via_package_editor.wls"
            }
            else {
                Join-Path $repoRoot "wl\common\export_notebook_via_structured_source.wls"
            }
            & (Join-Path $PSScriptRoot "run_wl.ps1") -ScriptPath $helperScriptPath -TaskSlug $TaskSlug -WorkingDirectory $WorkingDirectory -LogDir $LogDir -WolframScriptPath $resolvedWolframScript
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Notebook generation script failed."
        }
    }

    if (-not (Test-Path -LiteralPath $resolvedNotebookPath)) {
        throw "Target notebook file was not found: $resolvedNotebookPath"
    }

    foreach ($path in @($stdoutPath, $stderrPath)) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force
        }
    }

    $process = Start-Process -FilePath $resolvedWolframNB -ArgumentList @("-nogui", $resolvedNotebookPath) -WorkingDirectory $WorkingDirectory -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    $exited = $process.WaitForExit($ValidationTimeoutSec * 1000)

    if (-not $exited) {
        try {
            Stop-Process -Id $process.Id -Force -ErrorAction Stop
        }
        catch {
        }
    }

    $stdoutText = Read-TextFileIfPresent -PathValue $stdoutPath
    $stderrText = Read-TextFileIfPresent -PathValue $stderrPath

    if (-not [string]::IsNullOrWhiteSpace($stdoutText)) {
        $stdoutText | Out-File -LiteralPath $logFile -Encoding utf8 -Append
    }
    if (-not [string]::IsNullOrWhiteSpace($stderrText)) {
        $stderrText | Out-File -LiteralPath $logFile -Encoding utf8 -Append
    }

    if ($exited) {
        $exitCode = if (($null -ne $process) -and ($null -ne $process.ExitCode)) { $process.ExitCode } else { 0 }
        if ($exitCode -ne 0) {
            $failureMessage = "WolframNB -nogui validation failed with exit code: $exitCode"
        }
    }
    else {
        if (-not [string]::IsNullOrWhiteSpace($stderrText)) {
            $exitCode = 1
            $failureMessage = "WolframNB -nogui produced stderr output before timeout. Check the log."
        }
        else {
            $exitCode = 0
            "[info] WolframNB did not exit within timeout; process was stopped after startup check." | Out-File -LiteralPath $logFile -Encoding utf8 -Append
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

Write-Host ("Notebook generated/validated: {0}" -f $resolvedNotebookPath)
Write-Host ("Log file: {0}" -f $logFile)
exit 0
