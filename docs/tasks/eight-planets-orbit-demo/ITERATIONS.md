# 八大行星轨道演示 迭代记录

## 1. 文档用途
本文档用于记录 `eight-planets-orbit-demo` 每轮迭代中的优化目标、实现路径、过程文件、失败尝试、最终结果与关键日志，方便后续回溯为什么这样修改、试过哪些方案、哪些方案失败以及最终稳定方案如何形成。

## 2. 迭代总览
1. 初始目标是在仓库内重建八大行星运行轨迹动画，并生成可阅读、可调试的 `.nb`。
2. 初始方法是“先把 `.wl` 转成代码 notebook，再补充说明单元”。
3. 中期暴露出的关键问题是旧 `.nb` 重写链路会破坏中文说明。
4. 转折点是确认 package editor 结构化单元标记可以被 Front End 正确识别。
5. 最终稳定方法收敛为“一个 `.wl` 文件同时包含说明与最终代码”，再通过 `scripts/export_nb.ps1 -GenerationMode StructuredSource` 生成 `.nb`。
6. 随后又把这套方法上收到仓库级规则和默认脚本中。

## 3. 第一轮：初始源码恢复与基础导出链路
### 3.1 目标
1. 恢复动画本身的 Wolfram 实现。
2. 先得到一份可以导出的 `.nb`，即使说明文档还不完整。

### 3.2 实现路径
1. 参考 `D:\WorkCode\wolfram\generate_planet_demo_via_server.wl`。
2. 参考 `D:\WorkCode\wolfram\EightPlanetsOrbitDemo_server.nb`。
3. 先收敛任务源码，再通过仓库默认入口测试 notebook 导出。

### 3.3 关键文件
1. 最终源码起点
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.wl`
2. 早期 notebook 输出
   `D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\scratch\01-initial\probe-export.nb`
3. 早期文档版 notebook 输出
   `D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\scratch\01-initial\probe-doc-export.nb`

### 3.4 关键日志
1. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\run_wl_20260422_172916.log`
2. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\run_wl_20260422_172957.log`
3. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\run_wl_20260422_173113.log`

### 3.5 结果
1. 动画逻辑已经能够运行。
2. 可导出的源码和早期 probe notebook 已经存在。
3. 但说明文档与最终 notebook 的组织方式仍不稳定。

## 4. 第二轮：先生成代码 notebook，再注入说明单元
### 4.1 目标
1. 把适用范围、假设、限制和后续方向等说明内容补进 notebook。
2. 让 notebook 同时承担阅读入口和调试入口。

### 4.2 实现路径
1. 先通过 package editor 链路生成代码 notebook。
2. 再通过任务级 `.wls` 脚本在 kernel 侧解析 notebook 并注入说明单元。

### 4.3 关键文件
1. 旧任务级生成脚本
   `D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\final\final-generate-eight-planets-orbit-doc-notebook.wls`
2. 旧任务级外层入口
   `D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\final\final-generate-eight-planets-orbit-doc-notebook.ps1`

### 4.4 关键日志
1. Front End 生成失败日志
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\generate_doc_notebook_20260422_173115.log`
2. 说明注入成功日志
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\inject_doc_notebook_20260422_174007.log`

### 4.5 问题与失败点
1. `generate_doc_notebook_20260422_173115.log` 记录了 Front End 连接异常：
   - `ConnectToFrontEnd=True`
   - `FAILED: notebook generation raised a message`
   - `MessageList={HoldForm[LinkObject::linkd], HoldForm[LinkObject::linkn], HoldForm[LinkObject::linkn]}`
2. 即使某些批次注入成功，整体方法仍依赖“先生成 `.nb`，再解析或重写 `.nb`”。
3. 这条路径后来证明对中文说明不稳定，维护成本也偏高。

### 4.6 相对上一轮的优化点
1. notebook 首次拥有了结构化说明内容。
2. notebook 开始同时承担展示、说明和调试功能。

### 4.7 结果
1. 说明注入在部分运行中成功。
2. 但该方法仍不够稳定，不适合成为仓库默认方案。

## 5. 第三轮：定位中文损坏问题并验证结构化源文件可行性
### 5.1 目标
1. 确认中文损坏到底发生在编码层、Wolfram 读取阶段，还是 notebook 重写阶段。
2. 验证 package editor 是否能直接从 `.wl` 识别结构化说明单元。

### 5.2 实现路径
1. 检查源文件字节内容，确认 `.wl/.wls` 仍是 UTF-8。
2. 做一个最小探针，验证 `::Title::`、`::Section::`、`::Text::` 是否能被 Front End 识别。

### 5.3 关键过程文件
1. 探针源文件
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\scratch\02-repair\probe-package-editor-structured-source.wl`
2. 探针脚本
   `D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\scratch\02-repair\probe-package-editor-structured-source.wls`

### 5.4 关键日志
1. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\probe_package_editor_structured_source_20260423_092448.log`

### 5.5 关键结论
1. 源文件本身没有在内容层面提前损坏。
2. Front End 可以识别：
   - `Title`
   - `Text`
   - `Section`
   - `Code`
3. 因此，“先把说明写入 `.wl`，再让 Front End 复制到 `.nb`”是可行的。

### 5.6 相对上一轮的优化点
1. 诊断方向从“怀疑编码问题”转成“生成方法错误”。
2. 为彻底放弃直接重写 `.nb` 提供了证据。

## 6. 第四轮：收敛到单一结构化 `.wl` 源文件
### 6.1 目标
1. 把说明文档和最终代码放进同一个 `.wl` 源文件。
2. 停止直接解析和重写现有 `.nb` 文本。

### 6.2 实现路径
1. 在最终 `.wl` 中加入 `::Title::`、`::Section::`、`::Text::` 说明单元标记。
2. 构建 Front End 复制脚本，复制说明单元并把 `Code` 单元转成 `Input` 单元。

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
2. 说明与最终代码成为真正的同源维护。
3. 这为后续仓库级复用提供了直接原型。

## 7. 第五轮：迭代说明文档格式与公式风格
### 7.1 目标
1. 让说明文档更适合阅读。
2. 收敛出稳定的列表、章节和公式写法。

### 7.2 关键优化
1. 新增“主要数学概念与物理公式”章节。
2. 把旧列表改成逐项换行结构。
3. 进一步统一为编号列表。
4. 把代码式公式描述改成标准数学表达，例如：
   - `x(t) = r cos theta(t)`
   - `theta(t) = 2 pi t / T`
   - `omega = d theta / dt = 2 pi / T`
   - `F = G m1 m2 / r^2`

### 7.3 发现的问题
1. 曾尝试把多条列表项塞进同一个多行 `::Text::` 注释中。
2. Front End 会把这种写法拆成不理想的单元结构。
3. 稳定结论是每条列表项必须各自使用一个 `::Text::` 单元。

### 7.4 关键日志
1. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_093258.log`
2. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_093407.log`
3. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_093725.log`

### 7.5 额外记录
1. 曾在并行执行两个 notebook 相关 `run_wl.ps1` 验证时触发临时 stdout/stderr 文件名冲突。
2. 这没有改变最终方案，但说明 notebook 验证更适合串行执行。

### 7.6 结果
1. 文档格式最终收敛为“结构化章节 + 单项 Text 单元 + 编号列表 + 标准数学公式”。
2. 这套格式后来被写入通用规则文档。

## 8. 第六轮：将方法上收到仓库级默认入口
### 8.1 目标
1. 不再为 `eight-planets-orbit-demo` 单独维护一套 notebook 复制逻辑。
2. 将已验证的方法上收到仓库级默认入口，供后续任务复用。

### 8.2 实现路径
1. 在 `scripts/export_nb.ps1` 中新增 `StructuredSource`。
2. 新增共享 helper：
   `D:\WorkCode\mathematical\mathematical\wl\common\export_notebook_via_structured_source.wls`
3. 将任务级 wrapper 改成直接复用仓库级默认脚本。

### 8.3 关键文件
1. 默认入口
   `D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1`
2. 共享 helper
   `D:\WorkCode\mathematical\mathematical\wl\common\export_notebook_via_structured_source.wls`
3. 规则文档
   `D:\WorkCode\mathematical\mathematical\docs\notebook-generation.md`

### 8.4 验证链路
1. 运行基础 `run_wl.ps1` 链路。
2. 运行 `export_nb.ps1 -GenerationMode PackageEditorInput` 做回归验证。
3. 运行 `export_nb.ps1 -GenerationMode StructuredSource` 验证新模式。

### 8.5 关键日志
1. `D:\WorkCode\mathematical\mathematical\logs\tasks\codex-smoke\run_wl_20260423_094735.log`
2. `D:\WorkCode\mathematical\mathematical\logs\tasks\codex-smoke\export_nb_20260423_094742.log`
3. `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_094752.log`

### 8.6 结果
1. `StructuredSource` 成为仓库级默认能力。
2. 任务级脚本不再需要维护核心复制逻辑。
3. 后续 Codex 可以直接通过默认入口复用这套方法。

## 9. 本任务沉淀出的稳定规则
1. 不要直接修改最终 `.nb` 文件。
2. 优先把说明文档和最终代码写进同一个结构化 `.wl` 源文件。
3. 优先使用 `scripts/export_nb.ps1 -GenerationMode StructuredSource` 生成需要说明文档和执行代码并存的 notebook。
4. 若 notebook 文档需要改章节、列表、公式或文案，应修改 `.wl` 源文件后重新导出 `.nb`。
5. 每条说明项单独使用一个 `::Text::` 单元。
6. 列表默认使用编号形式。
7. 文档公式优先使用标准数学表达，而不是代码变量式描述。
8. 重要优化和失败尝试必须记录到 `docs/tasks/<task-slug>/` 中，不能只留在聊天答复里。

## 10. 最值得回溯的文件
1. 稳定最终源码
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.wl`
2. 稳定最终 notebook
   `D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.nb`
3. 结构化探针源文件
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\scratch\02-repair\probe-package-editor-structured-source.wl`
4. 仓库级共享 helper
   `D:\WorkCode\mathematical\mathematical\wl\common\export_notebook_via_structured_source.wls`
5. 最关键的验证日志
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\probe_package_editor_structured_source_20260423_092448.log`
6. 最终仓库级验证日志
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_094752.log`
