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
通过仓库级默认入口重新生成八大行星研究课题的最终 notebook。
.DESCRIPTION
这个任务级脚本只承担“明确当前课题最终输入与输出路径”的职责，不再保存独立的
notebook 复制逻辑。实际生成工作统一委托给仓库级 `scripts/export_nb.ps1` 的
`StructuredSource` 模式。

这样设计的原因是：
1. 最终说明与代码都维护在同一个结构化 `.wl` 源文件中；
2. 任务级入口只负责固定路径，便于用户直接运行；
3. 核心导出逻辑上收到仓库级脚本后，更容易复用和维护。

使用注意：
1. 本脚本不会修改任何任务代码逻辑，只会基于当前 `.wl` 重新导出 `.nb`；
2. 若最终 notebook 已存在，会按仓库级脚本的 `-Overwrite` 逻辑覆盖；
3. 若 Wolfram Front End 无法启动，导出会失败并抛出错误。
#>

& $exportScriptPath `
  -NotebookPath $notebookPath `
  -SourceScriptPath $sourcePath `
  -TaskSlug $taskSlug `
  -GenerationMode StructuredSource `
  -Overwrite
