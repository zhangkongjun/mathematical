# AGENTS.md

## 目录职责
本目录存放自动化脚本与命令行入口。

## 使用规则
- 优先使用 PowerShell 脚本，并保持参数显式、可复现。
- 脚本职责应清晰：负责调度、导出或批处理，不把大段核心 Mathematica 逻辑埋在脚本里。
- 调用 `wolframscript` 时显式传入输入、输出、参数和随机种子。
- 脚本产生的日志写到 `logs/`，结果写到 `results/`、`notebooks/exports/` 或 `data/processed/`。
- 修改脚本后，至少运行一次最小可复现实验验证入口仍可用。
