# AGENTS.md

## 目标
本仓库用于 Mathematica 研究、批量实验、公开数据分析与结果导出。

## 工作方式
- 修改前先阅读目录结构与已有脚本，不要直接动手改文件。
- 优先维护 `.wl` 与 `.wls`，不要把核心逻辑只留在 `.nb` 里。
- `.nb` 主要用于展示、说明和交互式探索。
- 可复现实验与批处理任务优先走 `wolframscript`。
- 默认使用 PowerShell；只有现成 bash 脚本或 GNU 工具确实必要时才切换。
- 输出统一写入 `results/`、`notebooks/exports/`、`data/processed/` 或 `logs/`。
- 不要修改 `data/raw/` 下的原始数据。
- 批量实验必须显式保留参数、随机种子、输入文件名与输出路径。
- 每次改动完成后，先跑最小可复现实验，再给出结论。
- 涉及联网时，先说明用途与数据来源，再执行下载或抓取。

## Mathematica 约定
- 公共函数放在 `wl/common/`。
- 数据处理入口放在 `wl/data/`。
- 领域代码分别放在 `wl/physics/`、`wl/astronomy/`、`wl/weather/`、`wl/probability/`、`wl/ai/`。
- 图形默认导出为 PNG；确有打印需求时再补 PDF。
- 表格默认导出为 CSV。
- notebook 中引用的核心逻辑，优先来自 `.wl` 或 `.wls`，不要只保存在单元格里。
- notebook 中引用的核心逻辑，保存在单元格里，需要保证语法正确性，结果尽量接近手工在notebook里编写代码一样。
