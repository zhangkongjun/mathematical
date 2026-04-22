# AGENTS.md

## 目录职责
本目录存放 Mathematica notebook，用于展示、说明和交互式探索。

## 使用规则
- notebook 以展示、说明和交互式探索为主；notebook 中引用的核心逻辑默认直接保存在单元格里。
- notebook 单元格中的核心逻辑必须保证语法正确，代码风格与结构尽量接近手工在 notebook 中编写的结果，避免明显的自动生成痕迹。
- 若以程序方式写入或更新 notebook 单元格，直接使用 `NotebookWrite`，并优先配合 `ToBoxes` 生成输入内容，不要优先拼接原始字符串形式的代码单元格。
- 若 notebook 同时依赖 `wl/` 或 `.wls` 中的实现，应保持接口与单元格内容一致，避免 notebook 展示代码与实际执行逻辑脱节。
- 导出产物统一放到 `notebooks/exports/` 或 `results/`，不要散落在各子目录。
- notebook 中涉及数据输入时，优先使用 `data/raw/` 与 `data/processed/` 的规范路径。
- 针对 Codex 生成且已经自动测试通过的最终 notebook 代码单元，默认添加简体中文注释或说明性文本，介绍该单元的功能、注意事项与限制。
- 若使用代码单元内注释，应保持注释与代码一起保存；若使用相邻说明单元，也应紧邻对应代码单元，避免说明与代码脱节。
- notebook 中的核心代码单元至少要让读者能直接看出：这段代码做什么、运行时要注意什么、当前有哪些假设或限制。

## 子目录约定
- `notebooks/tasks/` 用于存放任务级 notebook；不同研究任务应各自建立 `notebooks/tasks/<task-slug>/`，不要混放。
- `notebooks/exports/` 只保存导出产物，不放源码；图形默认 `PNG`，表格默认 `CSV`，文件名包含来源 notebook 或主题信息。
- `notebooks/ai/` 记录模型参数、数据来源和随机种子。
- `notebooks/astronomy/` 标明天体参数、观测数据来源和时间范围。
- `notebooks/data/` 不直接修改原始数据，任何派生结果写到 `data/processed/`。
- `notebooks/physics/` 记录参数、初值、求解设置和输出路径。
- `notebooks/probability/` 显式记录随机种子与样本规模。
- `notebooks/weather/` 标明站点、时间范围和数据来源。
