# 八大行星轨道演示 最终文件索引

## 推荐查看的最终文件
1. `Wolfram 源码`
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.wl`
2. `可阅读与调试的 notebook`
   `D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.nb`
3. `任务级 notebook 生成入口`
   `D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\final\final-generate-eight-planets-orbit-doc-notebook.ps1`
4. `仓库级 notebook 生成入口`
   `D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1`
5. `StructuredSource 通用 helper`
   `D:\WorkCode\mathematical\mathematical\wl\common\export_notebook_via_structured_source.wls`

## 推荐先读的说明文档
1. `最终设计与稳定结论`
   `D:\WorkCode\mathematical\mathematical\docs\tasks\eight-planets-orbit-demo\DECISIONS.md`
2. `完整迭代过程、尝试记录与日志索引`
   `D:\WorkCode\mathematical\mathematical\docs\tasks\eight-planets-orbit-demo\ITERATIONS.md`

## 推荐命令
1. 运行最小可复现实验
```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\run_wl.ps1' `
  -ScriptPath 'D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.wl' `
  -TaskSlug 'eight-planets-orbit-demo'
```

2. 通过任务级入口重新生成最终 notebook
```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\final\final-generate-eight-planets-orbit-doc-notebook.ps1'
```

3. 直接通过仓库级入口重新生成最终 notebook
```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' `
  -NotebookPath 'D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.nb' `
  -SourceScriptPath 'D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.wl' `
  -TaskSlug 'eight-planets-orbit-demo' `
  -GenerationMode StructuredSource `
  -Overwrite
```

4. 检查最终 notebook 是否能正常打开
```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' `
  -NotebookPath 'D:\WorkCode\mathematical\mathematical\notebooks\tasks\eight-planets-orbit-demo\final\final-eight-planets-orbit-demo.nb' `
  -CheckOnly
```

## 最值得回溯的过程文件
1. `结构化 package editor 探针源文件`
   `D:\WorkCode\mathematical\mathematical\wl\tasks\eight-planets-orbit-demo\scratch\02-repair\probe-package-editor-structured-source.wl`
2. `结构化 package editor 探针脚本`
   `D:\WorkCode\mathematical\mathematical\scripts\tasks\eight-planets-orbit-demo\scratch\02-repair\probe-package-editor-structured-source.wls`
3. `早期 Front End 失败日志`
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\generate_doc_notebook_20260422_173115.log`
4. `旧注入链路成功日志`
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\inject_doc_notebook_20260422_174007.log`
5. `结构化探针验证日志`
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\probe_package_editor_structured_source_20260423_092448.log`
6. `最终仓库级 StructuredSource 验证日志`
   `D:\WorkCode\mathematical\mathematical\logs\tasks\eight-planets-orbit-demo\export_nb_20260423_094752.log`

## 推荐回溯顺序
1. 先看 `DECISIONS.md`，理解当前稳定方案为什么这样选择。
2. 再看 `ITERATIONS.md`，了解每轮优化、失败尝试与过程文件。
3. 若要复现当前最终版本，优先直接运行仓库级 `export_nb.ps1 -GenerationMode StructuredSource`。
4. 若要理解为什么最终放弃“直接修改 `.nb`”，优先回看 `ITERATIONS.md` 中第二轮到第六轮的记录。
