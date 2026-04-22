# AGENTS.md

## 目录职责
本目录存放可交付结果，包括图形、报告和表格。

## 使用规则
- 这里只放结果产物，不要把脚本、原始数据或临时缓存写进来。
- 输出文件名应包含主题、实验标识、日期或参数摘要，便于回溯。
- 正式结果应能追溯到对应 notebook、`wl` 代码或脚本入口。
- 覆盖历史结果前先确认是否需要保留版本化副本。

## 子目录约定
- 任务结果优先按课题隔离：`results/figures/tasks/<task-slug>/`、`results/tables/tasks/<task-slug>/`、`results/reports/tasks/<task-slug>/`
- `results/figures/` 只保留结果图，默认导出为 `PNG`；只有打印或投稿需求明确时才补充 `PDF`。
- `results/reports/` 报告应引用真实结果文件，并标出数据来源、实验日期和对应脚本或 notebook。
- `results/tables/` 默认导出为 `CSV`，列名保持稳定、可解释，文件名中明确版本或日期。
