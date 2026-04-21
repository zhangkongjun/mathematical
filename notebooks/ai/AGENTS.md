# AGENTS.md

## 目录职责
本目录存放 AI 主题的探索型 notebook。

## 使用规则
- 这里只放 AI 主题 notebook，不要把可复用核心逻辑长期留在 notebook 单元格里。
- 复用代码优先迁移到 `wl/ai/`，notebook 负责演示调用与结果解释。
- 若 notebook 产生图表、表格或中间文件，导出到 `notebooks/exports/` 或 `results/`。
- 记录模型参数、数据来源和随机种子，保证实验可复现。
