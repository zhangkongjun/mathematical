# 八大行星运行轨迹研究课题 最终文件索引

## 1. 推荐先读的文档
1. 研究背景、数学模型、工程决策、限制与扩展方向  
   `D:\WorkCode\mathematical\mathematical\docs\tasks\eight-planets-orbit-demo\DECISIONS.md`
2. 各轮目标、实现路径、失败尝试、关键日志与稳定结论  
   `D:\WorkCode\mathematical\mathematical\docs\tasks\eight-planets-orbit-demo\ITERATIONS.md`

## 2. 推荐查看的最终文件
1. 最终结构化 Wolfram 源文件  
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.wl`
2. 最终可阅读、可调试 notebook  
   `D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.nb`
3. 任务级 notebook 生成入口  
   `D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\final\final-generate-eight-planets-orbit-doc-notebook.ps1`
4. 仓库级 notebook 生成入口  
   `D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1`

## 3. 推荐命令
### 3.1 运行最小可复现实验
```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\run_wl.ps1' `
  -ScriptPath 'D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.wl' `
  -TaskSlug 'eight-planets-orbit-demo'
```

### 3.2 通过任务级入口重新生成最终 notebook
```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\final\final-generate-eight-planets-orbit-doc-notebook.ps1'
```

### 3.3 直接通过仓库级入口重新生成最终 notebook
```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' `
  -NotebookPath 'D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.nb' `
  -SourceScriptPath 'D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.wl' `
  -TaskSlug 'eight-planets-orbit-demo' `
  -GenerationMode StructuredSource `
  -Overwrite
```

### 3.4 检查最终 notebook 是否能正常打开
```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' `
  -NotebookPath 'D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.nb' `
  -CheckOnly
```

## 4. 最值得回溯的过程文件与目录
1. 结构化探针源文件  
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\scratch\02-repair\probe-package-editor-structured-source.wl`
2. 结构化探针脚本  
   `D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\scratch\02-repair\probe-package-editor-structured-source.wls`
3. 早期 notebook 探针目录  
   `D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\scratch\01-initial\`
4. Front End 失败日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\generate_doc_notebook_20260422_173115.log`
5. 结构化探针验证日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\probe_package_editor_structured_source_20260423_092448.log`
6. 仓库级 StructuredSource 验证日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_094752.log`
7. 当前轮次最终 notebook 重导出日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_193443.log`
8. 当前轮次最小运行验证日志  
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\run_wl_20260423_193457.log`

## 5. 推荐回溯顺序
1. 先读 `DECISIONS.md`，理解当前模型为什么定位为教学近似、为什么采用结构化 `.wl` 同源方案。
2. 再读 `ITERATIONS.md`，了解旧方案为何被放弃、当前导出链路如何收敛。
3. 然后查看最终 `.wl`，理解结构化说明单元、参数组织和图形逻辑。
4. 最后根据需要运行任务级或仓库级脚本，复现最终 notebook。

## 6. 维护提醒
1. 若只改说明、章节、公式或注释，应优先修改最终 `.wl` 和任务文档，再重新导出 notebook。
2. 若改动影响展示逻辑、参数含义或适用边界，应同步更新 `DECISIONS.md` 与 `ITERATIONS.md`。
3. `FINAL_FILES.md` 必须始终与当前最终文件路径、推荐命令和回溯入口保持一致。
