# AGENTS.md

## 目录职责
本目录存放 Mathematica notebook，用于展示、说明和交互式探索。

## 使用规则
- notebook 以展示和探索为主，核心逻辑优先下沉到 `wl/` 或 `.wls`。
- 若 notebook 依赖仓库代码，优先引用已有脚本，不要只把关键实现保存在单元格里。
- 导出产物统一放到 `notebooks/exports/` 或 `results/`，不要散落在各子目录。
- notebook 中涉及数据输入时，优先使用 `data/raw/` 与 `data/processed/` 的规范路径。
