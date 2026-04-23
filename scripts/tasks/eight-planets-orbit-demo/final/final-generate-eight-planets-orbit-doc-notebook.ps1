[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\..\.."))
$taskSlug = "eight-planets-orbit-demo"
$sourcePath = Join-Path $repoRoot "wl\tasks\$taskSlug\final\final-eight-planets-orbit-demo.wl"
$notebookPath = Join-Path $repoRoot "notebooks\tasks\$taskSlug\final\final-eight-planets-orbit-demo.nb"
$exportScriptPath = Join-Path $repoRoot "scripts\export_nb.ps1"

<#
.SYNOPSIS
使用仓库级默认入口生成带结构化说明单元的最终八大行星 notebook。
.DESCRIPTION
当前推荐链路已经固化到 `scripts/export_nb.ps1 -GenerationMode StructuredSource` 中，
因此这里不再维护单独的 Front End 复制逻辑，而是直接复用默认入口。
#>

& $exportScriptPath `
  -NotebookPath $notebookPath `
  -SourceScriptPath $sourcePath `
  -TaskSlug $taskSlug `
  -GenerationMode StructuredSource `
  -Overwrite
