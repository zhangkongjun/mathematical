# AGENTS.md

## 目录职责
本目录存放自动化脚本与命令行入口。

## 使用规则
- 优先使用 PowerShell 脚本，并保持参数显式、可复现。
- 脚本职责应清晰：负责调度、导出或批处理，不把大段核心 Mathematica 逻辑埋在脚本里。
- 与 Wolfram 的简单常规交互，默认优先复用 `scripts/run_wl.ps1` 与 `scripts/export_nb.ps1`。
- 常规调用 `.wl` 或 `.wls` 文件时，默认使用 `scripts/run_wl.ps1`。
- 常规生成 `.nb` 文件时，默认使用 `scripts/export_nb.ps1`；若只是检查现有 `.nb`，则在该脚本上显式追加 `-CheckOnly`。
- 不要为每次执行都重新生成新的运行脚本或新的命令包装；只有当这两个默认脚本确实不满足任务需要时，才在 `scripts/tasks/<task-slug>/` 下新增任务专属脚本或命令。
- 在默认脚本已经覆盖的场景下，优先补参数、补任务脚本或补输入文件，不要先新增第三个 wrapper。
- 调用 `wolframscript` 时默认直接使用 `C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe`，并显式传入输入、输出、参数和随机种子。
- `export_nb.ps1` 的主职责是生成 `.nb` 文件，附带负责对生成结果做 `WolframNB.exe -nogui` 检查；不要再把它当作 PDF/HTML 导出入口。
- 若需要从 `.wl` / `.wls` 产出 `.nb`，优先让生成脚本把 notebook 写到 `SCIENTIFIC_LAB_NOTEBOOK_OUTPUT` 指向的位置，再由 `export_nb.ps1` 做检查。
- `run_wl.ps1` 与 `export_nb.ps1` 应包含足够详细的中文注释，明确说明默认用途、输入输出约定、环境变量、失败模式与注意事项，便于后续直接复用和维护。
- 运行 `.wl` 或 `.wls` 时优先使用：`& 'C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe' -f <script.wls>`
- 做快速表达式验证时优先使用：`& 'C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe' -code '<wolfram code>'`
- `scripts/run_wl.ps1` 与 `scripts/export_nb.ps1` 应优先适配现有目录结构，包括 `wl/tasks/<task-slug>/`、`notebooks/tasks/<task-slug>/`、`data/processed/tasks/<task-slug>/`、`logs/tasks/<task-slug>/`、`notebooks/exports/tasks/<task-slug>/` 与 `results/*/tasks/<task-slug>/`。
- 脚本产生的日志写到 `logs/`，结果写到 `results/`、`notebooks/exports/` 或 `data/processed/`。
- 修改脚本后，至少运行一次最小可复现实验验证入口仍可用。
- 不同研究任务的启动脚本与 wrapper 优先放到 `scripts/tasks/<task-slug>/`，不要共用同一份任务启动脚本去覆盖别的任务环境。
- 若脚本依赖任务专属 Wolfram 环境设置，显式引用 `.codex/wolfram-envs/<task-slug>/` 下的文件，不要隐式依赖全局用户环境。

## Codex 使用方法
- 先判断目标：
- 运行现有 `.wl` / `.wls`，选 `run_wl.ps1`。
- 从 `.wl` / `.wls` 生成 `.nb`，选 `export_nb.ps1`。
- 检查现有 `.nb`，选 `export_nb.ps1 -CheckOnly`。
- 先判断是否应显式传 `-TaskSlug`：
- 路径已经明确位于 `tasks/<task-slug>/` 下时，可让脚本自动推断。
- 路径不标准、跨目录、或当前 shell 目录不稳定时，必须显式传 `-TaskSlug`。
- 再判断是否需要绝对路径：
- 只要存在路径歧义，就直接传绝对路径。
- 对 notebook 生成链路，默认同时传 `-NotebookPath` 与 `-SourceScriptPath`，不要只传其中一个。

## 推荐命令模板
- 运行 `.wl` / `.wls`：
- `& 'D:\WorkCode\mathematical\mathematical\scripts\run_wl.ps1' -ScriptPath 'D:\WorkCode\mathematical\mathematical\scripts\tasks\<task-slug>\<script>.wls' -TaskSlug '<task-slug>'`
- 运行 `.wl` / `.wls` 并限制最长执行时间：
- `& 'D:\WorkCode\mathematical\mathematical\scripts\run_wl.ps1' -ScriptPath '<script>.wls' -TaskSlug '<task-slug>' -ExecutionTimeoutSec 600`
- 生成 `.nb`：
- `& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' -NotebookPath 'D:\WorkCode\mathematical\mathematical\notebooks\tasks\<task-slug>\<name>.nb' -SourceScriptPath 'D:\WorkCode\mathematical\mathematical\scripts\tasks\<task-slug>\<script>.wls' -TaskSlug '<task-slug>' -Overwrite`
- 检查现有 `.nb`：
- `& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' -NotebookPath 'D:\WorkCode\mathematical\mathematical\notebooks\tasks\<task-slug>\<name>.nb' -CheckOnly`

## 使用限制
- `run_wl.ps1` 不负责 notebook 校验，不要指望它替代 `export_nb.ps1`。
- `export_nb.ps1` 不负责 PDF、HTML、Markdown 等导出，不要把无关导出需求继续堆到这个脚本里。
- `export_nb.ps1` 的生成模式依赖源脚本正确写出 `SCIENTIFIC_LAB_NOTEBOOK_OUTPUT`；若源脚本忽略这个环境变量，生成结果可能落错位置。
- 这两个脚本只覆盖常规单入口任务；若任务需要复杂交互式 Front End 自动化、多个外部程序协同、或特殊 license/启动参数，再考虑新增任务专属脚本。
- `scripts/run_wl.ps1` 与 `scripts/export_nb.ps1` 是默认入口，默认不要直接修改。
- 这是强制限制：当某个研究任务只需要微调入口行为时，不要直接改这两个默认脚本，以免影响其它任务或其它交互后续复用同一入口。
- 正确做法是基于默认脚本复制生成新的任务脚本或临时脚本，再在复制出的脚本中调整参数、流程或额外逻辑。
- 只有在用户明确要求修复、重构或统一升级仓库级默认入口时，才允许直接修改 `scripts/run_wl.ps1` 与 `scripts/export_nb.ps1`。
- 对于临时生成并实际运行过的最终脚本，默认保留文件，由用户后续手工删除；Codex 默认不要在执行完成后自动删除这些脚本。

## 使用注意事项
- 优先把复杂实验流程写进 `.wl` / `.wls`，不要把复杂逻辑散落在 PowerShell 参数里。
- 若要复现实验，显式保留输入文件、随机种子、关键参数和输出路径，不要依赖脚本内部默认值隐式变化。
- 若脚本会修改或生成 notebook，优先把目标路径放到 `notebooks/tasks/<task-slug>/` 或 `notebooks/exports/tasks/<task-slug>/`。
- 若脚本执行后需要人工检查结果，先看 `logs/` 中对应日志，再看 `results/` 或 notebook 输出，不要只看终端最后一行。
- 若默认脚本执行失败，先看日志和传参是否正确，再判断是否真的需要新建 wrapper；不要把“参数传错”误判为“默认脚本能力不足”。
- 若需要临时变体，优先放到 `scripts/tasks/<task-slug>/`，并在文件名中明确用途，例如 `run_wl_custom.ps1`、`export_nb_debug.ps1`，不要覆盖默认入口文件。
- 若生成了临时脚本，执行完成后只需在答复中说明文件位置和用途，不要自行清理文件，除非用户明确要求删除。
