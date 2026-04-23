# AGENTS.md

## 目录职责
本目录存放仓库级默认脚本与任务级脚本入口。

## 默认原则
- 优先复用 `scripts/run_wl.ps1` 与 `scripts/export_nb.ps1`。
- 只有默认入口无法覆盖当前任务时，才在 `scripts/tasks/<task-slug>/` 下新增任务脚本。
- 脚本职责要单一明确。
- 可复现实验所需的关键路径和参数应显式可见。
- 这是一条强制规则：本目录下的规则文档默认使用简体中文。

## 脚本选择顺序
1. 目标只是运行 `.wl` / `.wls`
   - 使用 `scripts/run_wl.ps1`。
2. 目标是生成 `.nb`
   - 使用 `scripts/export_nb.ps1`。
3. 目标是检查现有 `.nb`
   - 使用 `scripts/export_nb.ps1 -CheckOnly`。

## `export_nb.ps1` 模式选择
1. `ScriptOutput`
   - 源脚本自己写出 notebook。
   - 源脚本必须写到 `SCIENTIFIC_LAB_NOTEBOOK_OUTPUT`。
   - 这是默认模式。
2. `PackageEditorInput`
   - 将 `.wl/.m` 源码转换为 notebook `Input` 单元。
   - 适合代码优先的 notebook。
   - 只支持 `.wl` / `.m`。
   - 不接受 `SourceScriptArguments`。
3. `StructuredSource`
   - 将带结构化说明单元的 `.wl/.m` 转换为同时包含说明与可执行代码的 notebook。
   - 适合 notebook 同时承担说明入口和执行入口的场景。
   - 只支持 `.wl` / `.m`。
   - 不接受 `SourceScriptArguments`。

## 稳定规则
- 不要把直接重写 `.nb` 文本当作默认方法。
- 若 notebook 的说明、章节、列表、公式或代码展示方式有变化，应回到源文件或生成链路中修改。
- `scripts/run_wl.ps1` 与 `scripts/export_nb.ps1` 视为稳定入口，除非用户明确要求，否则不要直接修改。
- 若确需任务专属 wrapper，放到 `scripts/tasks/<task-slug>/`，并在文件名中说明用途。

## 推荐命令
- 运行 `.wl` / `.wls`
  - `& 'D:\WorkCode\mathematical\mathematical\scripts\run_wl.ps1' -ScriptPath '<script.wls>' -TaskSlug '<task-slug>'`
- 生成 `.nb`
  - `& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' -NotebookPath '<target.nb>' -SourceScriptPath '<script.wls>' -TaskSlug '<task-slug>' -Overwrite`
- 通过 `StructuredSource` 生成 `.nb`
  - `& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' -NotebookPath '<target.nb>' -SourceScriptPath '<script.wl>' -TaskSlug '<task-slug>' -GenerationMode StructuredSource -Overwrite`
- 检查现有 `.nb`
  - `& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' -NotebookPath '<target.nb>' -CheckOnly`

## 使用注意事项
- 只要路径可能有歧义，就传绝对路径。
- 若任务不在标准 `tasks/<task-slug>/` 路径下，应显式传 `-TaskSlug`。
- 重新生成已存在的 notebook 时，通常需要 `-Overwrite`。
- 修改默认脚本后，至少验证一条 `.wl/.wls` 链路与一条 `.nb` 链路。