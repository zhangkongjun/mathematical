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
   使用注意：
   1. 这里只转换样式为 "Code" 的单元，说明单元不会经过这个函数；
   2. extraTags 只做追加，不会主动删除源单元已有标签。
   当前边界：
   1. 这里只处理 CellTags 的归并，不处理更复杂的样式迁移策略；
   2. 若源单元携带依赖 package editor 的特殊选项，目标 notebook 中仍可能需要额外人工检查。
   这里主要使用了 Replace 做样式模式替换，Cases 提取现有选项，Select 过滤旧标签规则，Cell 构造新的普通 Input 单元。 *)
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
   代码作用：
   1. 把 package editor notebook 的层级结构展平成顺序单元列表；
   2. 让后续转换逻辑只面对普通 Cell，而不用同时处理 CellGroupData。
   使用注意：
   1. 这里保留的是 notebook 中已经可见、可导出的单元顺序；
   2. 若源文件后续引入更复杂的动态结构，需要重新验证展开结果。
   当前边界：
   1. 这里不保留原始单元分组信息；
   2. 因此目标 notebook 目前更强调“说明与代码内容可用”，而不是完全复制源 notebook 的分组交互行为。
   这里主要使用了递归定义、Flatten 和 CellGroupData 匹配来提取扁平单元序列。 *)
collectVisibleCells[elements_List] := Flatten[collectVisibleCell /@ elements, 1];

collectVisibleCell[Cell[CellGroupData[groupCells_List, ___], ___]] := collectVisibleCells[groupCells];
collectVisibleCell[cell_Cell] := {cell};
collectVisibleCell[_] := {};

(* 将结构化源 notebook 中的单元转换成目标 notebook 的单元列表。
   代码作用：
   1. 保留结构化说明单元的原始样式；
   2. 把真正可执行的源码单元转换成普通 notebook Input 单元；
   3. 给第一段主代码补上稳定标签，便于后续检查和自动化定位。
   使用注意：
   1. 当前默认把第一段 Code 视为主入口代码；
   2. 若未来一个源文件中存在多个相互独立的主代码块，需要重新定义标签策略。
   当前边界：
   1. 当前不会根据章节语义对不同代码段做差异化标签；
   2. 目标是稳定导出，而不是建立完整的源码语义索引系统。
   这里主要使用了 Module 维护 codeIndex 计数，MatchQ 识别 Code 单元，ReplaceAll 对整个单元列表做顺序转换。 *)
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

(* 这个 helper 面向“结构化说明 + 可执行源码”并存的 package editor 源文件。
   代码作用：
   1. 调起 Front End，把 `.wl` / `.m` 按 package editor notebook 打开；
   2. 复制说明单元，并把 Code 单元转换为目标 notebook 中可直接执行的 Input 单元；
   3. 保存最终 `.nb`，供后续阅读、调试和启动级检查使用。
   使用注意：
   1. 源文件需要包含 `::Title::`、`::Section::`、`::Text::` 等结构化说明标记以及最终 `Code` 单元；
   2. 该脚本依赖可用的 Wolfram Front End，纯 kernel 环境无法完成这一步；
   3. 输出路径由 `SCIENTIFIC_LAB_NOTEBOOK_OUTPUT` 控制，调用方应提前设置好环境变量。
   当前边界：
   1. 它解决的是 notebook 结构转换问题，不负责修改课题代码逻辑；
   2. 当前默认复制可见单元，不负责保真重建 package editor 的全部编辑态元数据。
   这里主要使用了 ConnectToFrontEnd/UseFrontEnd 建立 Front End 会话，NotebookOpen/NotebookGet 读取源单元，NotebookPut/NotebookSave 生成并保存目标 notebook。 *)
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
    NotebookClose[targetNotebook];

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
  Print["Structured source notebook generation failed."];
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
