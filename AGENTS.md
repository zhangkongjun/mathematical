# AGENTS.md

## 适用范围
本文件定义仓库级通用规则；子目录中的 `AGENTS.md` 只补充本目录特有约束，不重复抄写根规则。

## 仓库目标
本仓库用于 Mathematica / Wolfram 研究、批量实验、公开数据分析、notebook 生成与结果导出。

## 编码与语言
- 这是强制规则：仓库内的 Markdown、`AGENTS.md`、`.wl`、`.wls`、`.m`、`.ps1`、配置文件与导出的文本类文件，默认使用 `UTF-8` 编码。
- 读取、改写或新建文本文件时，应显式按 `UTF-8` 处理，避免因 PowerShell、编辑器或外部工具的默认编码导致乱码。
- 仓库中的规则文档与任务文档默认使用简体中文。
- 若确需保留英文内容，必须以简体中文为主，并明确英文只是辅助说明。
- 不能把稳定规则只留在聊天答复里，必须回写到 Markdown 文档。

## 通用工作流
- 修改前先阅读目录结构、现有脚本和任务文档，不要先改文件再补理解。
- 默认使用 PowerShell。
- 可复现实验与批处理优先走 `wolframscript`。
- `data/raw/` 视为只读。
- 输出统一写入 `results/`、`notebooks/exports/`、`data/processed/` 或 `logs/`。
- 每次改动完成后，先跑最小可复现实验，再给出结论。
- 已验证通过的最终文件默认保留在工作区，便于用户直接检查 diff。
- 只有在用户明确要求时，才执行本地 Git 提交或远程推送。
- 结束任务前，必须显式停止本次启动的 `wolframscript`、`WolframKernel`、Front End 或其他后台进程。

## 文档要求
- `docs/` 中的文档必须与 `wl/`、`scripts/`、`notebooks/` 的实际实现保持一致。
- 每个任务完成时，都应维护 `docs/tasks/<task-slug>/FINAL_FILES.md`，明确推荐查看的最终文件、推荐命令，以及最值得回溯的过程文件与目录。
- `docs/tasks/<task-slug>/DECISIONS.md` 必须写成正式的研究与实现决策说明，既记录“为什么这样实现”，也作为后续学习、研究复盘以及与网页版 ChatGPT 持续沟通交流的背景材料。
- `DECISIONS.md` 默认至少包含：课题的科学背景与问题定义；相关数学知识、物理理论与核心概念；涉及公式时的详细解释、符号说明、适用条件与尽量标准的数学公式表达；当前研究现状、已知限制与遗留问题；未来可能的发展方向、可扩展实现路径与值得继续验证的假设。
- `DECISIONS.md` 应尽量自洽、可独立阅读，避免只写实现结论而不写背景。
- 若任务经历多轮迭代，默认维护 `docs/tasks/<task-slug>/ITERATIONS.md`，按轮次记录目标、优化点、结果、实现路径、过程文件、日志和失败尝试。
- `FINAL_FILES.md` 应显式指向 `DECISIONS.md` 与 `ITERATIONS.md`。

## 最终文件与过程文件分层
- 最终交付文件与 probe、debug、repair、compare、analysis、临时导出等过程文件必须分层存放，不能混放。
- 最终文件默认放在 `final/`。
- 过程文件默认放在 `scratch/` 或 `analysis/`。
- 过程文件默认保留，不自动删除。
- 过程文件应继续按阶段或时间分层，例如：`scratch/01-initial/`、`scratch/02-repair/`、`scratch/20260422-1545/`。
- 最终文件优先使用 `final-` 前缀；过程文件优先使用 `scratch-`、`probe-`、`debug-`、`repair-`、`compare-`、`analysis-` 等前缀。

## Notebook 与脚本总规则
- `.nb` 主要用于展示、说明和交互式探索。
- 不要直接修改最终 `.nb` 文件；默认应通过 `.wl/.wls` 源文件链路和 `scripts/` 下的默认入口生成、更新或修复。
- 若 notebook 由源码自动生成，说明文档默认先写入 `.wl` 或 `.wls`，再生成 `.nb`。
- 若只是调整章节、文案、列表格式、公式表达或代码展示方式，默认回到源文件或生成链路中修改，不要直接补丁 `.nb`。
- `scripts/run_wl.ps1` 与 `scripts/export_nb.ps1` 是仓库级默认入口；除非用户明确要求修复、重构或升级，否则不要直接修改这两个脚本。
- 若默认入口不能覆盖当前任务，再在 `scripts/tasks/<task-slug>/` 下新增任务脚本。
- `export_nb.ps1` 的具体模式选择、命令模板与注意事项，以 `scripts/AGENTS.md` 为准；notebook 内容组织与说明结构，以 `notebooks/AGENTS.md` 为准。

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

## 代码组织与注释
- 公共函数放在 `wl/common/`。
- 数据处理入口放在 `wl/data/`。
- 领域代码分别放在 `wl/physics/`、`wl/astronomy/`、`wl/weather/`、`wl/probability/` 与 `wl/ai/`。
- 对于 Codex 生成且已验证通过的最终 `.wl`、`.wls` 与 `.nb` 代码，补充详细的简体中文注释。
- 注释至少说明：代码做什么；使用或维护时要注意什么；当前实现的限制或适用边界；当前使用到的 Wolfram 功能和函数。
