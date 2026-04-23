# notebook-generation 文档重写 最终文件索引

## 推荐先看的最终文件
1. `notebook 规则文档`
   `D:\WorkCode\mathematical\mathematical\docs\notebook-generation.md`
2. `本次任务的决策说明`
   `D:\WorkCode\mathematical\mathematical\docs\tasks\notebook-generation-doc-rules\DECISIONS.md`
3. `本次任务的迭代记录`
   `D:\WorkCode\mathematical\mathematical\docs\tasks\notebook-generation-doc-rules\ITERATIONS.md`

## 推荐命令
1. 查看最终规则文档
```powershell
Get-Content -Raw 'D:\WorkCode\mathematical\mathematical\docs\notebook-generation.md'
```

2. 查看本次任务文档
```powershell
Get-Content -Raw 'D:\WorkCode\mathematical\mathematical\docs\tasks\notebook-generation-doc-rules\DECISIONS.md'
Get-Content -Raw 'D:\WorkCode\mathematical\mathematical\docs\tasks\notebook-generation-doc-rules\ITERATIONS.md'
```

3. 查看本次改动 diff
```powershell
git diff -- 'docs/AGENTS.md' 'docs/tasks/notebook-generation-doc-rules'
```

## 最值得回溯的过程文件与目录
1. `规则文档所在目录`
   `D:\WorkCode\mathematical\mathematical\docs`
2. `本次任务文档目录`
   `D:\WorkCode\mathematical\mathematical\docs\tasks\notebook-generation-doc-rules`
3. `无额外 scratch 或 analysis 过程文件`
   本轮任务为文档纠偏与重写，未单独生成脚本、notebook 或中间产物。

## 回溯顺序建议
1. 先看 `docs/notebook-generation.md`，确认新的目录职责与 notebook 生成边界。
2. 再看 `DECISIONS.md`，理解为什么要把 `docs/` 与实现目录严格分开。
3. 最后看 `ITERATIONS.md`，了解本轮如何从“文档内容不对”收敛到当前版本。
