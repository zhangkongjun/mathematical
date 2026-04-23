# notebook-generation 文档重写 迭代记录

## 第 1 轮
### 目标
修正 `docs/notebook-generation.md` 的规则方向，使其明确体现：

1. `docs/` 目录只保存文档。
2. notebook 的实现代码与导出链路不放在 `docs/`。
3. 文档仍需正确描述现有的 notebook 生成模式与命令。

### 优化点
1. 删除容易让人误读为“文档可承载实现”的表达。
2. 强化目录职责边界。
3. 保留 `export_nb.ps1` 三种模式的选择规则。
4. 增加“推荐做法”和“不推荐做法”，降低后续误用概率。

### 实现路径
1. 先检查仓库目录结构，确认只有 `docs/` 而没有单独的 `doc/` 代码目录。
2. 读取原始 `docs/notebook-generation.md` 与现有任务文档模板。
3. 重写 `docs/notebook-generation.md`，改为纯规则文档。
4. 新建本任务的 `FINAL_FILES.md`、`DECISIONS.md`、`ITERATIONS.md`。

### 结果
1. `docs/notebook-generation.md` 已完成重写。
2. 新文档已明确 `docs/` 只保存文档，不保存 `.wl`、`.wls`、`.ps1`、`.nb` 等实现文件。
3. notebook 生成入口与模式选择规则仍与仓库现状一致。

### 过程文件与日志
1. 本轮未生成额外 scratch 文件。
2. 本轮未启动 Wolfram 相关进程。
3. 本轮主要过程体现在 Git diff 与任务文档本身。

### 失败尝试
1. 无单独失败尝试。

### 最小验证
1. 计划使用 Markdown 内容检查与 Git diff 检查，确认文档已落盘且任务文档索引完整。
