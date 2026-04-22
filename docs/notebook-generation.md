# Notebook 生成约定

## 目标
当目标是从 `.wl` 源码生成一个 `.nb`，并且希望 notebook 中的代码单元尽量接近“手工直接在 Wolfram notebook 里输入”的效果时，优先使用 `scripts/export_nb.ps1` 的 `PackageEditorInput` 模式。

这个模式的重点不是把源码当纯文本塞进 notebook，而是：
- 先由 Wolfram Front End 把 `.wl` 打开成 package editor notebook。
- 直接复用 Front End 已经解析好的 `Code` 单元盒子结构。
- 再把这些单元转换成普通 `.nb` 中可执行的 `Input` 单元并保存。

这样生成出来的 notebook 通常会同时保留：
- 中文注释可读性。
- 接近手工输入时的语法着色。
- 在 notebook 中直接 `Shift+Enter` 的执行体验。

## 何时使用
- 源文件是 `.wl` 或 `.m`。
- 需要把完整源码直接展示在 notebook 里。
- 需要 notebook 中的源码单元既可读、又可执行。
- 不希望退回到“纯文本 Input 单元”导致的显示退化。

## 命令模板
- 默认脚本输出模式：

```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' `
  -NotebookPath '<target.nb>' `
  -SourceScriptPath '<script.wls>' `
  -TaskSlug '<task-slug>' `
  -Overwrite
```

- package editor 输入单元模式：

```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' `
  -NotebookPath '<target.nb>' `
  -SourceScriptPath '<script.wl>' `
  -TaskSlug '<task-slug>' `
  -GenerationMode PackageEditorInput `
  -Overwrite
```

- 检查现有 notebook：

```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' `
  -NotebookPath '<target.nb>' `
  -CheckOnly
```

## 模式说明
- `ScriptOutput`
  - 这是 `export_nb.ps1` 的兼容模式。
  - 源脚本自己负责把 notebook 写到 `SCIENTIFIC_LAB_NOTEBOOK_OUTPUT`。
  - 适合已经存在成熟 notebook 导出逻辑的 `.wl` / `.wls`。

- `PackageEditorInput`
  - 这是面向“源码单元体验”的模式。
  - 源文件必须是 `.wl` 或 `.m`。
  - `export_nb.ps1` 会调用 [export_notebook_via_package_editor.wls](/D:/WorkCode/mathematical/mathematical/wl/common/export_notebook_via_package_editor.wls)。
  - helper 会把 package editor notebook 中的 `Code` 单元转成目标 `.nb` 中的 `Input` 单元。
  - 这个模式不接受 `SourceScriptArguments`；如果需要复杂行为，应把逻辑写回源文件或另写显式任务脚本。

## 使用注意
- `PackageEditorInput` 生成的是可执行源码单元，不会默认替你跑出所有输出结果。
- 若需要 notebook 打开后立即附带结果，应在源文件本身设计清楚“最后一个表达式输出什么”，或者另写任务级 notebook 生成脚本。
- 修改 `scripts/export_nb.ps1` 后，至少应跑一条 `.wl/.wls` 链路和一条 `.nb` 检查链路。
- 若需要最小回归样例，可参考：
  - [package_editor_source.wl](/D:/WorkCode/mathematical/mathematical/wl/tasks/codex-smoke/package_editor_source.wl)
  - [smoke_generate_notebook.wls](/D:/WorkCode/mathematical/mathematical/scripts/tasks/codex-smoke/smoke_generate_notebook.wls)
