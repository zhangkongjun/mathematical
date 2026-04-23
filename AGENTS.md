# AGENTS.md

## 目标
本仓库用于 Mathematica / Wolfram 研究、批量实验、公开数据分析、notebook 生成与结果导出。

## 核心规则
- 修改前先阅读目录结构、现有脚本和任务文档，不要先改文件再补理解。
- 默认使用 PowerShell。
- 可复现实验与批处理优先走 `wolframscript`。
- `data/raw/` 视为只读。
- 输出统一写入 `results/`、`notebooks/exports/`、`data/processed/` 或 `logs/`。
- 每次改动完成后，先跑最小可复现实验，再给出结论。
- 只有在用户明确要求时，才执行本地 Git 提交或远程推送。
- 已验证通过的最终文件默认保留在工作区，便于用户直接检查 diff。
- 结束任务前，必须显式停止本次启动的 `wolframscript`、`WolframKernel`、Front End 或其他后台进程。

## 文档与语言规则
- `docs/` 中的文档必须与 `wl/`、`scripts/`、`notebooks/` 的实际实现保持一致。
- 不能把稳定规则只留在聊天答复里，必须写回 Markdown 文档。
- 这是一条强制规则：仓库中的 Markdown 文档与 `AGENTS.md` 规则文档，默认使用简体中文，不要默认改成英文。
- 若确需同时保留英文内容，必须以简体中文为主，并明确英文只是辅助说明。
- 每个任务完成时，都应维护 `docs/tasks/<task-slug>/FINAL_FILES.md`，明确推荐查看的最终文件、推荐命令，以及最值得回溯的过程文件与目录。
- `docs/tasks/<task-slug>/DECISIONS.md` 应写成正式的研究与实现决策说明，最终目的是方便我学习与研究，要包括这个研究课题的科学背景，涉及到的具体的数学知识与物理理论知识，若涉及公式，请详细介绍公式并尽量使用标准的数学公式，当前课题研究的现状与遗留问题，将来可能的发展方向。
- 若任务经历多轮迭代，默认维护 `docs/tasks/<task-slug>/ITERATIONS.md`，按轮次记录目标、优化点、结果、实现路径、过程文件、日志和失败尝试。
- `FINAL_FILES.md` 应显式指向 `DECISIONS.md` 与 `ITERATIONS.md`。

## 最终文件与过程文件分层
- 最终交付文件与 probe、debug、repair、compare、analysis、临时导出等过程文件必须分层存放，不能混放。
- 最终文件默认放在 `final/`。
- 过程文件默认放在 `scratch/` 或 `analysis/`。
- 过程文件默认保留，不自动删除。
- 过程文件应继续按阶段或时间分层，例如：`scratch/01-initial/`、`scratch/02-repair/`、`scratch/20260422-1545/`。
- 最终文件优先使用 `final-` 前缀；过程文件优先使用 `scratch-`、`probe-`、`debug-`、`repair-`、`compare-`、`analysis-` 等前缀。

## Notebook 规则
- `.nb` 主要用于展示、说明和交互式探索。
- 不要直接修改最终 `.nb` 文件；默认应通过 `scripts/export_nb.ps1` 或 `.wl/.wls` 源文件链路来生成、更新或修复 `.nb`。
- 若 notebook 同时承担阅读入口和调试入口，应保留结构化说明单元，而不是只导出裸代码。
- 若 notebook 由源码自动生成，说明文档默认先写入 `.wl` 或 `.wls`，再生成 `.nb`，并同步更新doc目录中的文档信息。
- 若只是调整章节、文案、列表格式、公式表达或代码展示方式，默认回到源文件或生成链路中修改，不要直接补丁 `.nb`，并同步更新doc目录中的文档信息。
- 若需要程序化写入 notebook 单元，直接使用 `NotebookWrite`，并优先配合 `ToBoxes`。

## 如何选择 `export_nb.ps1`
### 1. 目标只是运行 `.wl` / `.wls`
- 使用 `scripts/run_wl.ps1`。

### 2. 目标是生成 notebook
- 使用 `scripts/export_nb.ps1`。

### 3. 选择 `GenerationMode`
- `ScriptOutput`
  - 适用于源脚本本身负责写出 notebook 的场景。
  - 源脚本必须把 notebook 写到 `SCIENTIFIC_LAB_NOTEBOOK_OUTPUT` 指向的路径。
  - 这是默认模式。
- `PackageEditorInput`
  - 适用于源文件是 `.wl` 或 `.m`，且目标是得到接近手工在 Front End 中输入体验的 `Input` 单元。
  - 适合代码体验优先、不强调完整说明文档的 notebook。
  - 只支持 `.wl` 或 `.m`。
  - 不接受 `SourceScriptArguments`。
- `StructuredSource`
  - 适用于 notebook 同时需要结构化说明文档和可执行代码，且两者希望同源维护的场景。
  - 源文件通常应包含 `::Title::`、`::Section::`、`::Text::` 等 package editor 单元标记。
  - Front End 会复制说明单元，并把 `Code` 单元转换为 notebook 中的 `Input` 单元。
  - 只支持 `.wl` 或 `.m`。
  - 不接受 `SourceScriptArguments`。
  - 只要 notebook 需要稳定保留中文说明、公式、假设、限制或后续方向，就优先选择这个模式。

### 4. 目标只是检查现有 `.nb`
- 使用 `scripts/export_nb.ps1 -CheckOnly`。

## `export_nb.ps1` 使用规则
- `export_nb.ps1` 只负责 notebook 的生成与检查，不是 PDF / HTML / Markdown 通用导出器。
- `PackageEditorInput` 与 `StructuredSource` 都依赖 Wolfram Front End。
- `export_nb.ps1` 会通过 `WolframNB.exe -nogui` 做启动级检查；这不是完整人工检查。
- `WolframNB.exe -nogui` 可能不会自行退出；超时但无显式错误，只表示启动检查通过，不表示所有单元都已执行。在检查完成后，立即尝试关闭WolframNB，以便释放资源，也确保nb文件不被WolframNB锁定。
- 若路径不在 `tasks/<task-slug>/` 结构下，或当前路径上下文不稳定，应显式传 `-TaskSlug`。
- 只要路径可能有歧义，就直接传绝对路径。
- 若目标 notebook 已存在，重新生成时通常需要 `-Overwrite`。
- 只有 `ScriptOutput` 模式接受 `SourceScriptArguments`。

## 默认脚本稳定性规则
- `scripts/run_wl.ps1` 与 `scripts/export_nb.ps1` 是仓库级默认入口。
- 除非用户明确要求修复、重构或升级默认入口，否则不要直接修改这两个脚本。
- 若默认脚本不能覆盖当前任务，再在 `scripts/tasks/<task-slug>/` 下新增任务脚本。
- 若差异只是参数、输入输出路径或任务流程，优先传参数或新增任务脚本，不要先改仓库级入口。
- 修改默认脚本后，至少验证：
  - 一条 `.wl/.wls` 运行链路。
  - 一条 `.nb` 生成或检查链路。

## 默认命令模板
- 运行 `.wl` / `.wls`
  - `& 'D:\WorkCode\mathematical\mathematical\scripts\run_wl.ps1' -ScriptPath '<script.wls>' -TaskSlug '<task-slug>'`
- 运行 `.wl` / `.wls` 并显式指定工作目录或超时
  - `& 'D:\WorkCode\mathematical\mathematical\scripts\run_wl.ps1' -ScriptPath '<script.wls>' -TaskSlug '<task-slug>' -WorkingDirectory '<dir>' -ExecutionTimeoutSec 600`
- 通过 `ScriptOutput` 生成 `.nb`
  - `& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' -NotebookPath '<target.nb>' -SourceScriptPath '<script.wls>' -TaskSlug '<task-slug>' -Overwrite`
- 通过 `PackageEditorInput` 生成 `.nb`
  - `& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' -NotebookPath '<target.nb>' -SourceScriptPath '<script.wl>' -TaskSlug '<task-slug>' -GenerationMode PackageEditorInput -Overwrite`
- 通过 `StructuredSource` 生成 `.nb`
  - `& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' -NotebookPath '<target.nb>' -SourceScriptPath '<script.wl>' -TaskSlug '<task-slug>' -GenerationMode StructuredSource -Overwrite`
- 检查现有 `.nb`
  - `& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' -NotebookPath '<target.nb>' -CheckOnly`

## 任务目录约定
- 每个新任务至少应建立：
  - `.codex/wolfram-envs/<task-slug>/`
  - `wl/tasks/<task-slug>/`
  - `notebooks/tasks/<task-slug>/`
  - `scripts/tasks/<task-slug>/`
  - `data/processed/tasks/<task-slug>/`
  - `logs/tasks/<task-slug>/`
- 多轮迭代任务通常还应建立：
  - `wl/tasks/<task-slug>/final/`
  - `wl/tasks/<task-slug>/scratch/`
  - `scripts/tasks/<task-slug>/final/`
  - `scripts/tasks/<task-slug>/scratch/`
  - `notebooks/tasks/<task-slug>/final/`
  - `notebooks/tasks/<task-slug>/scratch/`
- notebook 导出优先写入 `notebooks/exports/tasks/<task-slug>/`。
- 结果按类型分开写入：
  - `results/figures/tasks/<task-slug>/`
  - `results/tables/tasks/<task-slug>/`
  - `results/reports/tasks/<task-slug>/`

## Wolfram 环境
- 默认可执行文件：
  - `C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe`
  - `C:\Program Files\Wolfram Research\Wolfram\14.3`
- 当前版本：
  - `14.3.0 for Microsoft Windows (64-bit) (July 8, 2025)`
- 当前系统标识：
  - `Windows-x86-64`
- 默认优先使用 `wolframscript`；若失败，再检查路径、权限和 license 状态。

## Wolfram 代码与注释
- 公共函数放在 `wl/common/`。
- 数据处理入口放在 `wl/data/`。
- 领域代码分别放在 `wl/physics/`、`wl/astronomy/`、`wl/weather/`、`wl/probability/` 与 `wl/ai/`。
- 对于 Codex 生成且已验证通过的最终 `.wl`、`.wls` 与 `.nb` 代码，补充详细的简体中文注释。
- 注释至少应说明：
  - 代码做什么。
  - 使用或维护时要注意什么。
  - 当前实现的限制或适用边界。
  - 说明当前使用到的wolfram的功能和函数。