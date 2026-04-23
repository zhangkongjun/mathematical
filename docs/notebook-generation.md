# Notebook 生成规则

## 目标
本文档用于给 Codex 提供一套稳定、低歧义的 notebook 生成决策规则，重点回答三件事：

1. 什么时候使用 `scripts/export_nb.ps1`。
2. 什么时候选择 `ScriptOutput`、`PackageEditorInput`、`StructuredSource`。
3. 如何编写结构化 notebook 说明文档，才能稳定生成 `.nb`。

## 强制规则
以下内容默认视为规则，而不是建议。

1. 不要直接修改最终 `.nb` 文件。
2. 生成、更新或修复 `.nb` 时，优先使用 `scripts/export_nb.ps1`。
3. 若 notebook 说明文档有变化，应回到 `.wl` / `.wls` 源文件或 `export_nb.ps1` 生成链路中修改。
4. 只有仓库默认入口确实无法覆盖当前需求时，才新增任务级 notebook 生成脚本。
5. 若某种方法已经证明可复用，应优先上收到仓库级入口，而不是长期保留重复的任务级实现。
6. 这是一条强制规则：本说明文档及相关规则文档默认使用简体中文。

## 最短决策树
当用户提出“生成 notebook”时，按以下顺序判断。

### 1. 目标是否只是运行 `.wl` / `.wls`
- 是：使用 `scripts/run_wl.ps1`。
- 否：继续判断。

### 2. 目标是否只是检查现有 `.nb`
- 是：使用 `scripts/export_nb.ps1 -CheckOnly`。
- 否：继续判断。

### 3. 源脚本是否本身就会写出 notebook
- 是：使用 `scripts/export_nb.ps1` 的默认 `ScriptOutput` 模式。
- 否：继续判断。

### 4. 目标 notebook 是否只需要代码输入体验
- 是：使用 `-GenerationMode PackageEditorInput`。
- 否：继续判断。

### 5. 目标 notebook 是否还需要结构化说明文档
- 是：使用 `-GenerationMode StructuredSource`。
- 否：回到 `PackageEditorInput`，或重新确认需求。

## 三种模式的准确含义
### `ScriptOutput`
适用场景：
- 已有 `.wl` / `.wls` 脚本自己负责创建 notebook。
- 不需要 package editor 复制链路。

必须满足：
- 源脚本把 notebook 写到 `SCIENTIFIC_LAB_NOTEBOOK_OUTPUT` 指向的路径。

常见误用：
- 把 notebook 写到硬编码路径。
- 实际上只是想把 `.wl` 转成 `Input` 单元，却误用了这个模式。

### `PackageEditorInput`
适用场景：
- 源文件是 `.wl` 或 `.m`。
- notebook 需要接近手工在 Front End 中输入的 `Input` 单元体验。
- notebook 不强调完整的结构化说明文档。

必须满足：
- 源文件是 `.wl` 或 `.m`。
- 不要传 `SourceScriptArguments`。

不适用：
- `.wls`。
- 需要保留较多说明单元的场景。

### `StructuredSource`
适用场景：
- 最终 notebook 同时需要说明文档和可执行代码。
- 说明与代码希望同源维护。
- 需要稳定保留中文说明、公式、假设、限制和后续方向。

必须满足：
- 源文件是 `.wl` 或 `.m`。
- 源文件包含 package editor 可识别的结构化单元标记，例如 `::Title::`、`::Section::`、`::Text::`。
- 不要传 `SourceScriptArguments`。

工作方式：
1. Front End 打开结构化 `.wl` 源文件。
2. 复制 `Title`、`Section`、`Text` 等说明单元。
3. 把 `Code` 单元转换成 notebook 中的 `Input` 单元。
4. `export_nb.ps1` 再做启动级 notebook 检查。

优点：
1. 中文说明和公式更稳定。
2. 说明与代码保持同一真实来源。
3. 避免旧的“先生成 `.nb` 再重写 `.nb` 文本”路径带来的乱码和结构损坏。

## `StructuredSource` 的默认文档结构
若 notebook 承担阅读、讲解或调试入口职责，源文件通常至少应包含：

1. 标题。
2. 目标与适用范围。
3. 核心假设。
4. 主要数学概念与物理公式，或相关科学理论与公式。
5. 为展示、调试或教学做的优化。
6. 已知限制、偏差与运行注意事项。
7. 后续研究或扩展方向。
8. 最终可执行代码。

若用户没有提出其他结构要求，可把这套结构视为最低骨架。

## 结构化说明文档的格式规则
这些规则对稳定生成 notebook 很关键。

1. 每个章节标题单独使用一个 `::Section::` 单元。
2. 每条说明项单独使用一个 `::Text::` 单元。
3. 不要把多条列表项塞进同一个多行 `::Text::` 注释中。
4. 列表默认使用序号，如 `1.`、`2.`、`3.`。
5. 除非用户明确要求无序列表，否则不要默认使用 `-`。
6. 若需要小标题，例如“目标：”“非目标：”，也应单独占一个 `::Text::` 单元。
7. 说明文档默认先写入 `.wl` 源文件，再通过 `StructuredSource` 复制到 `.nb`。

## 公式规则
说明文档中涉及公式时，优先使用标准数学表达，而不是代码式描述。

推荐写法：
1. `x(t) = r cos theta(t)`
2. `y(t) = r sin theta(t)`
3. `theta(t) = 2 pi t / T`
4. `omega = d theta / dt = 2 pi / T`
5. `dA/dt = constant`
6. `F = G m1 m2 / r^2`

不推荐把以下写法直接当作文档公式：
1. `planetPosition[...]`
2. `RadiusAU <= zoom`
3. `planetDiskRadius = 0.045 + 0.012 Log[1 + r]`

若公式与代码实现有关，可先写标准公式，再补一句说明它对应到哪个参数或函数。

## 最小示例
下面是一个适合 `StructuredSource` 的最小 `.wl` 结构。

```wolfram
(* ::Package:: *)

(* ::Title:: *)
(* 示例 notebook *)

(* ::Section:: *)
(* 目标与适用范围 *)

(* ::Text:: *)
(* 1. 这是第一条说明。 *)

(* ::Text:: *)
(* 2. 这是第二条说明。 *)

(* ::Section:: *)
(* 主要数学概念与物理公式 *)

(* ::Text:: *)
(* 1. 位置参数化采用 x(t) = r cos theta(t), y(t) = r sin theta(t)。 *)

demoExpr = Plot[Sin[x], {x, 0, 2 Pi}];

demoExpr
```

## 推荐命令
### `ScriptOutput`
```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' `
  -NotebookPath '<target.nb>' `
  -SourceScriptPath '<script.wls>' `
  -TaskSlug '<task-slug>' `
  -Overwrite
```

### `PackageEditorInput`
```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' `
  -NotebookPath '<target.nb>' `
  -SourceScriptPath '<script.wl>' `
  -TaskSlug '<task-slug>' `
  -GenerationMode PackageEditorInput `
  -Overwrite
```

### `StructuredSource`
```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' `
  -NotebookPath '<target.nb>' `
  -SourceScriptPath '<script.wl>' `
  -TaskSlug '<task-slug>' `
  -GenerationMode StructuredSource `
  -Overwrite
```

### `CheckOnly`
```powershell
& 'D:\WorkCode\mathematical\mathematical\scripts\export_nb.ps1' `
  -NotebookPath '<target.nb>' `
  -CheckOnly
```

## 使用注意事项
1. `PackageEditorInput` 与 `StructuredSource` 都依赖 Wolfram Front End。
2. 两种模式都只支持 `.wl` / `.m`。
3. 两种模式都不接受 `SourceScriptArguments`。
4. `export_nb.ps1` 会在生成后执行一次 `WolframNB.exe -nogui` 启动级检查。
5. 若 notebook 只需要改说明、列表、公式或章节结构，不要直接补丁 `.nb`，而应回到源文件修改后重新导出。
6. 若修改了 `scripts/export_nb.ps1`，至少回归验证一条 `.wl/.wls` 链路和一条 `.nb` 链路。