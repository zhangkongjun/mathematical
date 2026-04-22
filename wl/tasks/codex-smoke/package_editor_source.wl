(* 这个 smoke 源文件专门用于验证：
   1. `export_nb.ps1 -GenerationMode PackageEditorInput` 能否通过 package editor 打开 `.wl`；
   2. 复制出来的代码单元是否会被保存成普通 notebook 里的可执行 Input 单元；
   3. 中文注释在转换到 `.nb` 后是否仍然保持可读。 *)

ClearAll[smokeValue];

(* 这里故意保留中文注释和简单表达式，
   便于观察生成后的 notebook 是否保留了接近手工键入时的显示效果。 *)
smokeValue = 2 + 2;

smokeValue
