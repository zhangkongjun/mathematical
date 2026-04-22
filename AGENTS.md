# AGENTS.md

## 目标
本仓库用于 Mathematica 研究、批量实验、公开数据分析与结果导出。

## 工作方式
- 修改前先阅读目录结构与已有脚本，不要直接动手改文件。
- notebook 中引用的核心逻辑默认保存在对应单元格里；若以程序方式写入 notebook，直接使用 `NotebookWrite`，并优先配合 `ToBoxes` 生成单元格内容，保证语法正确且尽量接近手工在 notebook 中直接编写的效果。
- `.nb` 主要用于展示、说明和交互式探索。
- 可复现实验与批处理任务优先走 `wolframscript`。
- 默认使用 PowerShell；只有现成 bash 脚本或 GNU 工具确实必要时才切换。
- 输出统一写入 `results/`、`notebooks/exports/`、`data/processed/` 或 `logs/`。
- 不要修改 `data/raw/` 下的原始数据。
- 批量实验必须显式保留参数、随机种子、输入文件名与输出路径。
- 每次改动完成后，先跑最小可复现实验，再给出结论。
- 对于已经验证通过的最终代码文件与脚本文件，默认提交到当前本地 Git 仓库，便于追踪仓库状态与回滚；除非用户明确要求，否则不要主动推送到远程仓库。
- 涉及联网时，先说明用途与数据来源，再执行下载或抓取。
- 完成所有相关工作后，必须主动结束本次 agent 会话，不保留空闲常驻进程。
- 若本次任务启动了 `wolframscript`、`WolframKernel`、并行内核、监听器或其他后台进程，结束前必须显式关闭并确认资源已释放。
- 除非用户明确要求持续监控、定时任务或常驻服务，否则不要让 Codex 在任务完成后继续运行、等待或轮询。
- 针对 Codex 生成且已经自动测试通过的最终 `.wl`、`.wls` 与 `.nb` 代码，默认补充简体中文注释，说明代码功能、使用或阅读时的注意事项，以及当前实现的限制或边界。
- 上述中文注释应跟随最终交付代码保留，不要只写在临时草稿、日志或答复说明里。

## 配置维护
- `AGENTS.md` 以少量父级文件集中维护为主，优先在顶层目录表达通用规则，避免在每个叶子目录重复复制模板。
- 只有当子目录存在明显不同于父目录的额外约束时，才新增该目录自己的 `AGENTS.md`。
- 若父目录规则已经覆盖当前场景，优先删除冗余子目录 `AGENTS.md`，而不是复制一份近似内容继续维护。
- `docs/` 中的文档应与 `wl/`、`scripts/`、`notebooks/` 的实际实现保持一致，优先写清使用方法、输入输出约定和复现实验步骤，不复制大段源码。
- `logs/` 只放运行日志与实验追踪信息；日志文件名应包含任务名、时间或批次，并记录参数、随机种子、输入文件和输出路径。
- `.idea/` 这类 IDE 元数据目录仅在确有需要时最小改动，避免让核心流程依赖 IDE 配置，也不要主动覆盖用户本地偏好。

## Wolfram 环境
- 默认使用 PowerShell 调用 Wolfram，不优先猜测 bash 或其他 shell。
- 下列信息仅表示本机共享安装信息，不等于所有研究任务共用同一份 Wolfram 环境设置。
- 首选可执行文件：`C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe`
- 已安装 Wolfram Kernel 目录：`C:\Program Files\Wolfram Research\Wolfram\14.3`
- 当前 Wolfram 版本：`14.3.0 for Microsoft Windows (64-bit) (July 8, 2025)`
- 当前系统标识：`Windows-x86-64`

## Wolfram 调用约定
- 与 Wolfram 的简单常规交互默认优先使用 `scripts/run_wl.ps1` 与 `scripts/export_nb.ps1`，不要每次都重新生成新的运行脚本。
- 常规调用 `.wl` / `.wls` 时默认使用 `scripts/run_wl.ps1`。
- 常规生成 `.nb` 时默认使用 `scripts/export_nb.ps1`；仅当需要检查现有 `.nb` 时，才在该脚本上显式使用 `-CheckOnly`。
- 若目标 notebook 需要尽量接近“手工直接在 Wolfram notebook 里键入的可执行代码单元”效果，优先使用 `scripts/export_nb.ps1 -GenerationMode PackageEditorInput`，让 Front End 先把 `.wl` 作为 package editor notebook 打开，再把解析好的源码单元转换为 `.nb` 中的 `Input` 单元。
- 只有当默认脚本不能满足任务需要时，才在 `scripts/tasks/<task-slug>/` 下新增任务专属脚本或命令。
- 在默认脚本已能覆盖的场景下，优先补参数、补任务输入或补任务脚本，不要先重新生成新的 wrapper。
- 默认先用 `wolframscript` 执行 `.wl` 与 `.wls`，不要先花时间搜索 Wolfram 安装路径。
- 批处理、导出和复现实验优先使用：`& 'C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe' -f <script.wls>`
- 快速表达式验证优先使用：`& 'C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe' -code '<wolfram code>'`
- 若任务需要操作 notebook 单元格，直接使用 `NotebookWrite`，并优先配合 `ToBoxes`。
- 若 `wolframscript` 调用失败，再检查 Kernel 路径、权限和 license 状态，不要先切换到其他工具链。

## 默认脚本选择规则
- 目标是运行现有 `.wl` / `.wls` 并产出数据、图表、表格或日志时，直接使用 `scripts/run_wl.ps1`。
- 目标是从 `.wl` / `.wls` 生成 `.nb` 时，直接使用 `scripts/export_nb.ps1`，不要先手写一段 `wolframscript` 命令再包一层。
- 若源文件是 `.wl`，且 notebook 中需要保留中文注释、语法着色以及 `Shift+Enter` 直接执行的体验，优先在 `scripts/export_nb.ps1` 上显式追加 `-GenerationMode PackageEditorInput`，不要退回到“把源码当纯文本写入 notebook 单元”的做法。
- 目标是检查现有 `.nb` 是否能被 `WolframNB.exe -nogui` 正常打开时，使用 `scripts/export_nb.ps1 -CheckOnly`。
- 只有在以下情况出现时，才允许新增任务专属脚本或命令：
- 默认脚本缺少当前任务必需的多阶段流程控制。
- 默认脚本无法表达当前任务必需的 Front End 操作或特殊启动参数。
- 默认脚本无法满足当前任务的输入输出协议，且补充参数后仍不够。

## 默认脚本命令模板
- 运行 `.wl` / `.wls`：
- `& 'D:\WorkCode\mathematical\mathematical\scripts\run_wl.ps1' -ScriptPath '<script.wls>' -TaskSlug '<task-slug>'`
- 运行 `.wl` / `.wls` 并显式指定工作目录或超时：
- `& 'D:\WorkCode\mathematical\mathematical\scripts\run_wl.ps1' -ScriptPath '<script.wls>' -TaskSlug '<task-slug>' -WorkingDirectory '<dir>' -ExecutionTimeoutSec 600`
- 从 `.wl` / `.wls` 生成 `.nb`：
- `& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' -NotebookPath '<target.nb>' -SourceScriptPath '<script.wls>' -TaskSlug '<task-slug>' -Overwrite`
- 从 `.wl` 生成带 package editor 风格可执行源码单元的 `.nb`：
- `& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' -NotebookPath '<target.nb>' -SourceScriptPath '<script.wl>' -TaskSlug '<task-slug>' -GenerationMode PackageEditorInput -Overwrite`
- 检查现有 `.nb`：
- `& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' -NotebookPath '<target.nb>' -CheckOnly`

## 默认脚本限制与注意事项
- `run_wl.ps1` 只负责执行 `.wl` / `.wls`，不会自动检查 `.nb` 是否可打开，也不负责 PDF/HTML 导出。
- `export_nb.ps1` 的主用途是生成或检查 `.nb`，不要把它当作通用导出器。
- `scripts/run_wl.ps1` 与 `scripts/export_nb.ps1` 是仓库级默认入口，默认视为稳定接口；当需要为某个任务微调入口行为时，不要直接修改这两个脚本文件。
- 若当前任务确实需要调整默认入口逻辑，应基于这两个脚本复制生成新的任务专属或临时脚本，再在新脚本中修改；不要把任务特有改动直接写回默认入口。
- 这是一条强制限制：除非用户明确要求重构或修复仓库级默认入口，否则不要直接改动 `scripts/run_wl.ps1` 与 `scripts/export_nb.ps1`，以避免其它交互再次调用这两个脚本时出现混乱。
- 对于为当前任务临时生成的最终脚本，运行完成后默认保留在仓库中，由用户手工删除；Codex 默认不要在任务结束时自动删除这些临时脚本。
- 使用 `export_nb.ps1 -SourceScriptPath ...` 时，源脚本必须把 notebook 写到 `SCIENTIFIC_LAB_NOTEBOOK_OUTPUT` 指向的路径；不要在脚本里硬编码别的 notebook 输出位置。
- 上一条仅适用于 `export_nb.ps1` 的默认 `ScriptOutput` 模式；若显式使用 `-GenerationMode PackageEditorInput`，则由 `export_nb.ps1` 内部调用通用 helper 把 `.wl` package editor 单元转换为 `.nb` 中的 `Input` 单元，源文件本身不需要再手动写出 notebook 文件。
- `PackageEditorInput` 模式要求源文件是 `.wl` 或 `.m`；它依赖 Wolfram Front End 对 package editor 单元的解析结果，不适用于 `.wls` 脚本。
- 若路径不在 `tasks/<task-slug>/` 体系内，Codex 可能无法自动推断 `TaskSlug`；此时应显式传入 `-TaskSlug`。
- 若脚本路径、工作目录或输出路径存在歧义，优先传绝对路径，不要依赖当前 shell 目录猜测。
- 若任务需要多个连续步骤，优先把流程写进单个 `.wl` / `.wls` 或任务脚本，再调用默认 PowerShell 脚本；不要把复杂业务逻辑直接塞进命令行参数。
- `export_nb.ps1` 使用 `WolframNB.exe -nogui` 做启动级检查；它能发现一部分 notebook 文件问题，但不等于完整人工检查。
- `WolframNB.exe -nogui` 在部分情况下不会自行退出；脚本会按超时策略结束进程，因此“超时后无显式错误”只表示启动检查通过，不表示 notebook 中所有单元都已完整执行。
- 修改默认脚本后，必须至少用一条 `.wl/.wls` 链路和一条 `.nb` 链路做最小验证，再结束任务。

## 课题隔离
- 不同研究课题不得共用同一份 Wolfram 环境设置；共享的只有安装路径与版本信息，课题级设置必须隔离。
- 新研究任务开始时，先创建唯一的任务目录名 `task-slug`，再为该任务建立独立目录，而不是复用其他任务已有配置。
- 任务级 Wolfram 环境设置统一放在 `.codex/wolfram-envs/<task-slug>/`，只服务当前任务。
- 不要默认修改全局 Wolfram 用户配置、全局 `init.m`、共享 Paclet 设置或其他会污染后续任务的用户级环境。
- 若需要任务专属启动参数、初始化逻辑、环境变量说明或 wrapper 脚本，写入当前任务目录，不要回写到全局配置。

## 任务目录约定
- 每个新研究任务至少建立以下目录：`.codex/wolfram-envs/<task-slug>/`、`wl/tasks/<task-slug>/`、`notebooks/tasks/<task-slug>/`、`scripts/tasks/<task-slug>/`、`data/processed/tasks/<task-slug>/`、`logs/tasks/<task-slug>/`
- notebook 导出优先写入：`notebooks/exports/tasks/<task-slug>/`
- 任务结果按类型分开写入：`results/figures/tasks/<task-slug>/`、`results/tables/tasks/<task-slug>/`、`results/reports/tasks/<task-slug>/`
- 如需任务文档，放到 `docs/tasks/<task-slug>/`
- 只有在代码或流程已证明可跨任务复用后，才从 `tasks/<task-slug>/` 上收至 `wl/common/` 或领域目录。

## Wolfram 快速自检
- 检查版本：`& 'C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe' -code '$Version'`
- 检查系统标识：`& 'C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe' -code '$SystemID'`
- 运行脚本：`& 'C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe' -f '.\scripts\example.wls'`

## 本机硬件摘要
- CPU：`Intel Core i9-13980HX`，`24` cores，`32` logical processors
- RAM：约 `48 GB`
- GPU：`NVIDIA GeForce RTX 4070 Laptop GPU`
- 机器型号：`ASUS ROG Strix G814JI_G814JI`

## 资源使用建议
- 中小型 Mathematica 任务默认直接本机运行，不需要先保守降配。
- 并行或大规模数值任务可以考虑使用多核，但必须显式控制内核数和输出路径。
- 若任务涉及大图形导出、数值实验或并行计算，先说明预计资源占用，再执行。

## Mathematica 约定
- 公共函数放在 `wl/common/`。
- 数据处理入口放在 `wl/data/`。
- 领域代码分别放在 `wl/physics/`、`wl/astronomy/`、`wl/weather/`、`wl/probability/`、`wl/ai/`。
- 图形默认导出为 PNG；确有打印需求时再补 PDF。
- 表格默认导出为 CSV。
- notebook 中引用的核心逻辑默认直接保存在单元格里；若以程序方式生成或更新这类单元格，直接使用 `NotebookWrite`，并优先配合 `ToBoxes` 保持语法与排版接近手工编写。若同时维护 `.wl` 或 `.wls` 版本，应保证 notebook 单元格内容与其一致。
- 对于 Codex 生成且已自动测试通过的最终 Mathematica 代码，优先在模块、函数、关键代码块或 notebook 代码单元附近添加简体中文注释，至少覆盖“这段代码做什么”“使用时要注意什么”“当前限制是什么”。
