[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$NotebookPath,

    [ValidateSet("PDF", "HTML", "Markdown", "PlainText")]
    [string]$Format = "PDF",

    [string]$OutputPath,

    [string]$ExportDir,

    [string]$LogDir,

    [string]$WolframScriptPath = "wolframscript",

    [switch]$Overwrite
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
$defaultExportDir = Join-Path $repoRoot "notebooks\exports"
$defaultLogDir = Join-Path $repoRoot "logs"

if ([string]::IsNullOrWhiteSpace($ExportDir)) {
    $ExportDir = $defaultExportDir
}
if ([string]::IsNullOrWhiteSpace($LogDir)) {
    $LogDir = $defaultLogDir
}

$ExportDir = Resolve-PathFlexible -PathValue $ExportDir -Bases @($PWD.Path, $repoRoot)
$LogDir = Resolve-PathFlexible -PathValue $LogDir -Bases @($PWD.Path, $repoRoot)

New-DirectoryIfMissing -PathValue $ExportDir
New-DirectoryIfMissing -PathValue $LogDir

$notebookBases = @(
    $PWD.Path,
    (Join-Path $repoRoot "notebooks"),
    $repoRoot
)
$resolvedNotebookPath = Resolve-PathFlexible -PathValue $NotebookPath -Bases $notebookBases

if (-not (Test-Path -LiteralPath $resolvedNotebookPath)) {
    throw "未找到 notebook 文件: $NotebookPath"
}

$extensionMap = @{
    PDF = "pdf"
    HTML = "html"
    Markdown = "md"
    PlainText = "txt"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedNotebookPath)
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputPath = Join-Path $ExportDir ("{0}_{1}.{2}" -f $baseName, $timestamp, $extensionMap[$Format])
}

$resolvedOutputPath = Resolve-PathFlexible -PathValue $OutputPath -Bases @($PWD.Path, $repoRoot)
$outputDirectory = Split-Path -Parent $resolvedOutputPath
New-DirectoryIfMissing -PathValue $outputDirectory

if ((Test-Path -LiteralPath $resolvedOutputPath) -and (-not $Overwrite)) {
    throw "导出文件已存在，请使用 -Overwrite 或更换输出路径: $resolvedOutputPath"
}

$command = Get-Command $WolframScriptPath -ErrorAction Stop
$resolvedWolframScript = $command.Source
$runId = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $LogDir ("export_nb_{0}.log" -f $runId)

$header = @"
[export_nb]
run_id = $runId
timestamp = $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
wolframscript = $resolvedWolframScript
notebook = $resolvedNotebookPath
format = $Format
output = $resolvedOutputPath
"@

$header | Out-File -LiteralPath $logFile -Encoding utf8

$wlCode = @'
input = Environment["SCIENTIFIC_LAB_NB_INPUT"];
output = Environment["SCIENTIFIC_LAB_NB_OUTPUT"];
format = Environment["SCIENTIFIC_LAB_NB_FORMAT"];

If[!FileExistsQ[input],
  Print["Notebook not found: " <> input];
  Exit[2];
];

Quiet@CreateDirectory[DirectoryName[output], CreateIntermediateDirectories -> True];

nb = NotebookOpen[input, Visible -> False];
If[nb === $Failed,
  Print["Failed to open notebook: " <> input];
  Exit[3];
];

result = Export[output, nb, format];
NotebookClose[nb];

If[result === $Failed,
  Print["Export failed: " <> output];
  Exit[4];
];

Print["Exported: " <> output];
'@

$previousInput = $env:SCIENTIFIC_LAB_NB_INPUT
$previousOutput = $env:SCIENTIFIC_LAB_NB_OUTPUT
$previousFormat = $env:SCIENTIFIC_LAB_NB_FORMAT

$env:SCIENTIFIC_LAB_NB_INPUT = $resolvedNotebookPath
$env:SCIENTIFIC_LAB_NB_OUTPUT = $resolvedOutputPath
$env:SCIENTIFIC_LAB_NB_FORMAT = $Format
$exitCode = 1

try {
    & $resolvedWolframScript "-code" $wlCode 2>&1 | Tee-Object -FilePath $logFile -Append
    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }

    $summary = @"

[summary]
exit_code = $exitCode
log_file = $logFile
"@
    $summary | Out-File -LiteralPath $logFile -Encoding utf8 -Append

    if ($exitCode -ne 0) {
        throw "notebook 导出失败，退出码: $exitCode"
    }

    Write-Host ("导出完成。输出: {0}" -f $resolvedOutputPath)
    Write-Host ("日志文件: {0}" -f $logFile)
    exit 0
}
catch {
    $message = $_.Exception.Message
    "[error] $message" | Out-File -LiteralPath $logFile -Encoding utf8 -Append
    Write-Error $message
    exit $exitCode
}
finally {
    $env:SCIENTIFIC_LAB_NB_INPUT = $previousInput
    $env:SCIENTIFIC_LAB_NB_OUTPUT = $previousOutput
    $env:SCIENTIFIC_LAB_NB_FORMAT = $previousFormat
}
