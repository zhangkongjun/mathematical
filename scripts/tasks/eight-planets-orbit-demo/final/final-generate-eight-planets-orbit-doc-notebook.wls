Needs["JLink`"];

sourcePath = Environment["SCIENTIFIC_LAB_NOTEBOOK_SOURCE"];
notebookPath = Environment["SCIENTIFIC_LAB_NOTEBOOK_OUTPUT"];
titleText = Environment["SCIENTIFIC_LAB_NOTEBOOK_TITLE"];

If[StringLength[sourcePath] == 0,
  Print["SCIENTIFIC_LAB_NOTEBOOK_SOURCE is empty."];
  Exit[2];
];

If[StringLength[notebookPath] == 0,
  Print["SCIENTIFIC_LAB_NOTEBOOK_OUTPUT is empty."];
  Exit[3];
];

If[StringLength[titleText] == 0,
  titleText = FileBaseName[sourcePath];
];

notebookDir = DirectoryName[notebookPath];

If[!DirectoryQ[notebookDir],
  CreateDirectory[notebookDir, CreateIntermediateDirectories -> True];
];

(* 合并 CellTags，确保从结构化源文件复制出的说明单元和代码单元在目标 notebook 中仍可被稳定标识。
   使用注意：
   1. 旧标签可能是 None、Missing、单个字符串或字符串列表；
   2. 这里会统一归一化后再去重合并。
   当前边界：
   1. 这里只处理标签合并，不处理其他单元选项的语义冲突。 *)
mergeCellTags[existing_, extra_List] := Module[
  {normalized},
  normalized = Replace[
    existing,
    {
      None -> {},
      _Missing -> {},
      s_String :> {s},
      values_List :> values,
      other_ :> {other}
    }
  ];
  DeleteDuplicates @ Join[normalized, extra]
];

(* 把 package editor 中的 Code 单元转换成普通 notebook 可执行的 Input 单元。
   代码作用：
   1. 保留源代码内容；
   2. 保留除 CellTags 以外的既有选项；
   3. 将额外标签合并回目标 Input 单元。
   这里主要使用了 Replace、Cases、Select 和 Cell 构造。 *)
convertCodeCellToInput[cell_Cell, extraTags_List : {}] := Replace[
  cell,
  Cell[data_, "Code", opts___] :> Module[
    {optionRules, existingTags, keptRules, mergedTags},
    optionRules = {opts};
    existingTags = Replace[
      Cases[optionRules, Rule[CellTags, value_] :> value, 1],
      {
        {value_} :> value,
        {} -> None
      }
    ];
    keptRules = Select[optionRules, !MatchQ[#, Rule[CellTags, _]] &];
    mergedTags = mergeCellTags[existingTags, extraTags];
    Cell[
      data,
      "Input",
      Sequence @@ keptRules,
      CellTags -> mergedTags
    ]
  ]
];

(* 从 Notebook 表达式里收集可见单元。
   这里显式展开 CellGroupData，是为了让后续转换阶段只面对扁平单元列表。 *)
collectVisibleCells[elements_List] := Flatten[collectVisibleCell /@ elements, 1];

collectVisibleCell[Cell[CellGroupData[groupCells_List, ___], ___]] := collectVisibleCells[groupCells];
collectVisibleCell[cell_Cell] := {cell};
collectVisibleCell[_] := {};

(* 将结构化源 notebook 中的单元转换成目标 notebook 的单元列表。
   当前策略是：
   1. 说明性单元原样保留；
   2. Code 单元转成 Input 单元；
   3. 第一段主代码补上额外标签，便于后续识别。 *)
convertSourceCellsToTargetCells[sourceCells_List] := Module[
  {codeIndex = 0},
  sourceCells /. cell_Cell :> Module[{extraTags = {}},
    If[MatchQ[cell, Cell[_, "Code", ___]],
      codeIndex += 1;
      extraTags = If[codeIndex == 1, {"main-source-input", "source-code"}, {}];
      convertCodeCellToInput[cell, extraTags],
      cell
    ]
  ]
];

(* 这个任务脚本只做 Front End 侧的“复制结构化源文件单元并保存 notebook”。
   设计原因：
   1. 最终说明和代码都先保存在结构化 `.wl` 源文件里；
   2. Front End 会以 package editor 方式打开该源文件；
   3. 说明单元直接复制，Code 单元转换为普通 Input 单元；
   4. 全流程避免直接重写已有 `.nb` 文本，从而降低中文说明损坏风险。
   当前边界：
   1. 该脚本依赖可用的 Wolfram Front End；
   2. 它解决的是 notebook 结构转换问题，不负责修改课题代码逻辑。 *)
$FrontEndLaunchCommand =
  "'C:\\Program Files\\Wolfram Research\\Wolfram\\14.3\\WolframNB.exe' -server";

connectResult = Quiet @ Check[ConnectToFrontEnd[ForceLaunch -> True], $Failed];

If[connectResult === $Failed,
  Print["Unable to connect to Wolfram Front End."];
  Exit[4];
];

result = Check[
  UseFrontEnd @ Module[
    {
      sourceNotebook,
      sourceExpression,
      sourceCells,
      targetCells,
      targetNotebook
    },

    sourceNotebook = NotebookOpen[sourcePath, Visible -> False];
    sourceExpression = NotebookGet[sourceNotebook];
    sourceCells = Replace[sourceExpression, Notebook[cells_List, ___] :> collectVisibleCells[cells]];
    NotebookClose[sourceNotebook];

    If[Length[sourceCells] == 0,
      Return[$Failed];
    ];

    targetCells = convertSourceCellsToTargetCells[sourceCells];

    If[FileExistsQ[notebookPath],
      DeleteFile[notebookPath];
    ];

    targetNotebook = NotebookPut @ Notebook[
      targetCells,
      WindowTitle -> titleText,
      Saveable -> True,
      StyleDefinitions -> "Default.nb",
      Magnification -> 1.1
    ];

    NotebookSave[targetNotebook, notebookPath];
    NotebookSave[targetNotebook];

    <|
      "SourceCellCount" -> Length[sourceCells],
      "InputCellCount" -> Length @ Cases[targetCells, Cell[_, "Input", ___], Infinity],
      "TextCellCount" -> Length @ Cases[targetCells, Cell[_, "Text", ___], Infinity],
      "SectionCellCount" -> Length @ Cases[targetCells, Cell[_, "Section", ___], Infinity],
      "NotebookSaved" -> FileExistsQ[notebookPath]
    |>
  ],
  $Failed
];

Quiet[CloseFrontEnd[]];

If[result === $Failed,
  Print["Notebook generation failed."];
  Exit[5];
];

If[!TrueQ[result["NotebookSaved"]],
  Print["Notebook file was not created."];
  Exit[6];
];

Print["Structured source notebook generated: " <> notebookPath];
Print["SourceCellCount=" <> ToString[result["SourceCellCount"], InputForm]];
Print["InputCellCount=" <> ToString[result["InputCellCount"], InputForm]];
Print["TextCellCount=" <> ToString[result["TextCellCount"], InputForm]];
Print["SectionCellCount=" <> ToString[result["SectionCellCount"], InputForm]];
Exit[0];
