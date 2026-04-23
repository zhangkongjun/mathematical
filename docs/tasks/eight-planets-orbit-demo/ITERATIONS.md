# 八大行星运行轨迹研究课题 迭代记录

## 1. 文档用途
本文档用于记录 `eight-planets-orbit-demo` 在不同轮次中的目标、实现路径、关键文件、验证日志、失败尝试与稳定结论。它重点回答三个问题：

1. 每一轮到底解决了什么问题。
2. 哪些方案被验证有效，哪些方案被放弃。
3. 当前最终版本是如何从早期实验逐步收敛出来的。

## 2. 迭代总览
截至当前版本，本任务已经历如下主线：

1. 恢复八大行星运行轨迹动画的 Wolfram 实现。
2. 建立最初的 notebook 导出链路。
3. 发现并定位“直接重写 `.nb` 导致中文说明不稳定”的问题。
4. 验证结构化 `.wl` 源文件可直接作为 notebook 说明与代码母版。
5. 将该方法上收到仓库级默认入口。
6. 按最新任务文档规范重写研究说明与代码注释，但不改变执行逻辑。

## 3. 第一轮：恢复基础动画与最小导出链路
### 3.1 目标
1. 在仓库内恢复八大行星运行轨迹动画本身。
2. 得到一份最小可运行、最小可导出的 Wolfram 源实现。

### 3.2 实现路径
1. 参考外部原型 `D:\WorkCode\wolfram\generate_planet_demo_via_server.wl`。
2. 参考外部 notebook 原型 `D:\WorkCode\wolfram\EightPlanetsOrbitDemo_server.nb`。
3. 先让动画逻辑可运行，再验证 notebook 导出链路。

### 3.3 关键文件
1. 最终源码雏形  
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.wl`
2. 早期 notebook 探针  
   `D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\scratch\01-initial\probe-export.nb`
3. 早期带说明探针  
   `D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\scratch\01-initial\probe-doc-export.nb`

### 3.4 关键日志
1. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\run_wl_20260422_172916.log`
2. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\run_wl_20260422_172957.log`
3. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\run_wl_20260422_173113.log`

### 3.5 结果
1. 动画逻辑已经能够运行。
2. 最初的导出链路可用，但说明与最终 notebook 的组织方式尚未稳定。

## 4. 第二轮：先生成代码 notebook，再注入说明单元
### 4.1 目标
1. 让 notebook 不仅能执行代码，也能承载研究说明。
2. 把适用范围、核心假设与限制写进 notebook。

### 4.2 实现路径
1. 先把 `.wl` 转成以代码为主的 notebook。
2. 再通过任务级 `.wls` 脚本在 kernel 侧注入说明单元。

### 4.3 关键文件
1. 旧任务级生成脚本  
   `D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\final\final-generate-eight-planets-orbit-doc-notebook.wls`
2. 旧任务级 PowerShell 入口  
   `D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\final\final-generate-eight-planets-orbit-doc-notebook.ps1`

### 4.4 关键日志
1. Front End 生成失败日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\generate_doc_notebook_20260422_173115.log`
2. 说明注入成功日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\inject_doc_notebook_20260422_174007.log`

### 4.5 暴露的问题
1. 某些运行批次出现 Front End 连接异常。
2. 整体方法仍依赖“先生成 `.nb`，再解析或重写 `.nb`”。
3. 后续证据表明，这条路径对中文说明并不稳健。

### 4.6 结果
1. notebook 首次具备结构化说明。
2. 但该方案不适合作为长期稳定的仓库默认方法。

## 5. 第三轮：定位中文损坏问题并验证结构化源文件
### 5.1 目标
1. 判断中文损坏到底发生在编码层、Wolfram 读取阶段还是 notebook 重写阶段。
2. 验证 package editor 是否能够直接识别结构化说明单元。

### 5.2 实现路径
1. 检查源文件字节内容，确认 `.wl/.wls` 本身仍是 UTF-8。
2. 编写最小探针，验证 `::Title::`、`::Section::`、`::Text::` 与 `Code` 单元的识别结果。

### 5.3 关键过程文件
1. 结构化探针源文件  
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\scratch\02-repair\probe-package-editor-structured-source.wl`
2. 结构化探针脚本  
   `D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\scratch\02-repair\probe-package-editor-structured-source.wls`

### 5.4 关键日志
1. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\probe_package_editor_structured_source_20260423_092448.log`

### 5.5 关键结论
1. 问题不在源文件 UTF-8 编码本身。
2. Front End 可以正确识别结构化单元。
3. “先把说明写入 `.wl`，再由 Front End 复制到 `.nb`”是可行路线。

## 6. 第四轮：收敛到单一结构化 `.wl` 最终源文件
### 6.1 目标
1. 用一个最终 `.wl` 同时承载说明与代码。
2. 停止直接解析和重写最终 `.nb`。

### 6.2 实现路径
1. 在最终 `.wl` 中加入 `::Title::`、`::Section::`、`::Text::` 标记。
2. 通过 Front End 复制说明单元，并把 `Code` 单元转换为普通 notebook 的 `Input` 单元。

### 6.3 关键文件
1. 最终结构化源文件  
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.wl`
2. 任务级 Front End 复制脚本  
   `D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\final\final-generate-eight-planets-orbit-doc-notebook.wls`

### 6.4 关键日志
1. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\run_wl_20260423_092713.log`
2. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_092718.log`

### 6.5 结果
1. 新 notebook 保持了正常的 Unicode 说明单元。
2. 说明与代码真正实现同源维护。

## 7. 第五轮：迭代说明格式与公式表达
### 7.1 目标
1. 让 notebook 更适合作为研究说明与教学入口。
2. 统一章节、列表与数学公式写法。

### 7.2 关键优化
1. 增加“主要数学概念与物理公式”章节。
2. 将说明整理成结构化章节与编号条目。
3. 将代码式表述改为更接近标准数学表达的形式。

### 7.3 失败尝试
1. 曾尝试把多条列表项写进单个多行 `::Text::` 注释。
2. Front End 对该写法的单元拆分效果不理想。
3. 最终结论是每个列表项分别使用单独的 `::Text::` 单元更稳定。

### 7.4 关键日志
1. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_093258.log`
2. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_093407.log`
3. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_093725.log`

### 7.5 结果
1. 文档格式收敛为“结构化章节 + 单项 Text 单元 + 编号列表 + 标准数学公式”。
2. 这套写法后来被上收为通用规则。

## 8. 第六轮：方法上收到仓库级默认入口
### 8.1 目标
1. 不再为该任务长期维护独立的 notebook 生成核心逻辑。
2. 让已验证的方法可供后续任务复用。

### 8.2 实现路径
1. 在 `scripts/export_nb.ps1` 中增加 `StructuredSource` 模式。
2. 新增共享 helper `wl/common/export_notebook_via_structured_source.wls`。
3. 把任务级 wrapper 简化为调用仓库级默认入口。

### 8.3 关键文件
1. 仓库级默认入口  
   `D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1`
2. 共享 helper  
   `D:\WorkCode\mathematical\mathematical\wl\common\export_notebook_via_structured_source.wls`
3. 任务级 wrapper  
   `D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\final\final-generate-eight-planets-orbit-doc-notebook.ps1`

### 8.4 关键日志
1. `D:\WorkCode\mathematical\mathematical\logs\tasks\codex-smoke\run_wl_20260423_094735.log`
2. `D:\WorkCode\mathematical\mathematical\logs\tasks\codex-smoke\export_nb_20260423_094742.log`
3. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_094752.log`

### 8.5 结果
1. `StructuredSource` 成为仓库级默认能力。
2. 八大行星课题的 notebook 导出逻辑转为复用默认入口。

## 9. 第七轮：按最新规则重写研究文档与代码注释
### 9.1 目标
1. 让任务文档满足最新的正式研究说明要求。
2. 在不改动任何执行逻辑的前提下，补强 `.wl` 与任务脚本的中文注释。
3. 重新导出最终 notebook，确保说明、源码与最终交付保持一致。

### 9.2 实现路径
1. 重写 `DECISIONS.md`，补齐科学背景、问题定义、公式解释、研究现状、限制与扩展方向。
2. 重写 `FINAL_FILES.md`，显式指向最终文件、推荐命令、过程文件与回溯顺序。
3. 更新最终 `.wl` 的结构化说明单元和就地代码注释，但不改函数逻辑、参数和输出行为。
4. 更新任务级 PowerShell / Wolfram 脚本中的说明性注释，统一维护意图。

### 9.3 关键日志
1. 最终 notebook 重导出日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_193443.log`
2. 最小 `wolframscript` 复现实验日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\run_wl_20260423_193457.log`

### 9.4 结果
1. 文档层将从“实现记录”提升为“可独立阅读的研究说明”。
2. 注释层将更明确地说明功能、边界、使用注意事项和所用 Wolfram 特性。
3. 最终 notebook 已根据新的结构化说明重新生成。
4. 本轮不改变任何算法、参数或渲染逻辑，只重写文档与注释。

## 10. 第八轮：按最新规则重生成最终 `.wl/.wls/.nb`
### 10.1 目标
1. 基于最新的仓库规则文档与 `wl/` 注释规范，再次收敛最终 `.wl/.wls` 的说明性注释。
2. 在不改动任何代码逻辑的前提下，重新导出最终 notebook。
3. 用当前源文件重新做最小 `wolframscript` 验证，并把本轮真实日志回写到任务文档。

### 10.2 实现路径
1. 保留 `final-eight-planets-orbit-demo.wl` 的现有算法、参数和控件定义，只维持最终排版与说明结构。
2. 为共享 helper `wl/common/export_notebook_via_structured_source.wls` 与 `wl/common/export_notebook_via_package_editor.wls` 补齐中文注释，明确代码作用、使用注意、当前边界与所用 Wolfram 功能的作用。
3. 通过任务级 PowerShell wrapper 调用仓库级 `scripts/export_nb.ps1 -GenerationMode StructuredSource` 重导出最终 `.nb`。
4. 顺序执行最小 `wolframscript` 验证，避免并行运行时的临时日志文件同秒冲突。

### 10.3 关键文件
1. 最终结构化 Wolfram 源文件  
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.wl`
2. 共享 StructuredSource helper  
   `D:\WorkCode\mathematical\mathematical\wl\common\export_notebook_via_structured_source.wls`
3. 共享 PackageEditorInput helper  
   `D:\WorkCode\mathematical\mathematical\wl\common\export_notebook_via_package_editor.wls`
4. 最终 notebook  
   `D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.nb`

### 10.4 关键日志
1. 最终 notebook 重导出与启动级检查日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_200209.log`
2. 顺序重跑后的最小 `wolframscript` 验证日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\run_wl_20260423_200211.log`

### 10.5 结果
1. 最终 `.nb` 已由当前结构化 `.wl` 源文件重新生成。
2. 共享 `.wls` helper 的中文注释已与最新规则对齐，但任何表达式逻辑均未改变。
3. 最小 `wolframscript` 验证通过，说明当前最终 `.wl` 仍可按原行为执行。

### 10.6 失败尝试
1. 曾并行触发任务级 notebook 重导出与单独的 `run_wl.ps1` 最小验证。
2. 两个流程在同一秒生成了相同命名模式的临时 stdout/stderr 文件，导致 `run_wl.ps1` 清理阶段报错。
3. 该问题属于验证脚本的临时文件碰撞，不是八大行星课题源码逻辑回归；改为顺序重跑后已通过。

## 11. 当前沉淀出的稳定规则
1. 不要直接修改最终 `.nb` 文件。
2. 优先把说明与代码写进同一个结构化 `.wl` 源文件。
3. 优先使用 `scripts/export_nb.ps1 -GenerationMode StructuredSource` 生成最终 notebook。
4. 若 notebook 的文案、章节、公式或说明发生变化，应修改 `.wl` 源文件后重新导出。
5. 重要优化、失败尝试、过程文件与关键日志必须沉淀到 `docs/tasks/<task-slug>/`。

## 12. 最值得回溯的文件
1. 稳定最终源码  
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.wl`
2. 稳定最终 notebook  
   `D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.nb`
3. 最终设计说明  
   `D:\WorkCode\mathematical\mathematical\docs\tasks\eight-planets-orbit-demo\DECISIONS.md`
4. 结构化探针源文件  
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\scratch\02-repair\probe-package-editor-structured-source.wl`
5. 结构化探针验证日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\probe_package_editor_structured_source_20260423_092448.log`
6. 当前轮次的最终 notebook 重导出日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_200209.log`
7. 当前轮次的最小运行验证日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\run_wl_20260423_200211.log`
