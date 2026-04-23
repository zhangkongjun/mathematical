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

sourceDir = DirectoryName[sourcePath];
notebookDir = DirectoryName[notebookPath];

If[!DirectoryQ[notebookDir],
  CreateDirectory[notebookDir, CreateIntermediateDirectories -> True];
];

(* 合并 CellTags，确保从 package editor 源文件复制出的主代码单元在目标 notebook 中仍能被稳定识别。
   使用注意：
   1. 旧标签可能是 None、Missing、单个字符串或字符串列表；
   2. 这里会统一归一化后再去重合并。
   当前边界：
   1. 这里只处理标签合并，不处理其他单元选项冲突。 *)
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
   1. 复用 Front End 已解析好的源码盒子结构；
   2. 保留除 CellTags 外的大部分原始选项；
   3. 给目标 notebook 中的 Input 单元补上稳定标签。
   使用注意：
   1. 这里只转换样式为 "Code" 的单元；
   2. extraTags 只做追加，不会删除源单元已有标签。
   当前边界：
   1. 若源单元带有 package editor 专有的交互语义，转换后可能仍需人工检查。
   这里主要使用了 Replace 做样式替换，Cases/Select 抽取与清洗选项，Cell 构造目标 Input 单元。 *)
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

(* 这个 helper 的职责很单一：
   代码作用：
   1. 让 Front End 以 package editor 方式打开 `.wl` / `.m`；
   2. 直接复用其中已经解析好的 Code 单元盒子结构；
   3. 把这些单元转换成普通 notebook 里的 Input 单元并保存。
   使用注意：
   1. 该模式适合“代码优先”的 notebook，不会复制结构化说明单元；
   2. 依赖可用的 Wolfram Front End，纯 kernel 环境无法完成该转换。
   当前边界：
   1. 这里只提取 Code 单元，不负责保留源文件中的章节说明与文本单元；
   2. 因此当任务 notebook 同时承担讲解职责时，应优先改用 StructuredSource 模式。
   这里主要使用了 ConnectToFrontEnd/UseFrontEnd 建立 Front End 会话，NotebookOpen/NotebookGet 抓取 Code 单元，NotebookPut/NotebookSave 生成目标 notebook。
   这样生成出来的 `.nb` 更接近手工在 notebook 中直接键入代码的效果，既保留中文注释和语法着色，也支持后续在 notebook 中直接 Shift+Enter。 *)
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
      codeCells,
      inputCells,
      targetNotebook
    },

    sourceNotebook = NotebookOpen[sourcePath, Visible -> False];
    sourceExpression = NotebookGet[sourceNotebook];
    codeCells = Cases[sourceExpression, Cell[_, "Code", ___], Infinity];
    NotebookClose[sourceNotebook];

    If[Length[codeCells] == 0,
      Return[$Failed];
    ];

    inputCells = MapIndexed[
      convertCodeCellToInput[
        #1,
        If[#2[[1]] == 1, {"main-source-input", "source-code"}, {}]
      ] &,
      codeCells
    ];

    targetNotebook = NotebookPut @ Notebook[
      Join[
        {
          Cell[titleText, "Title"],
          Cell["\:6e90\:7801\:6587\:4ef6\:ff1a" <> sourcePath, "Text"]
        },
        inputCells
      ],
      WindowTitle -> titleText,
      Saveable -> True,
      StyleDefinitions -> "Default.nb",
      Magnification -> 1.1
    ];

    NotebookSave[targetNotebook, notebookPath];
    NotebookSave[targetNotebook];
    NotebookClose[targetNotebook];

    <|
      "CodeCellCount" -> Length[codeCells],
      "NotebookSaved" -> FileExistsQ[notebookPath]
    |>
  ],
  $Failed
];

Quiet[CloseFrontEnd[]];

If[result === $Failed,
  Print["No Code cells were found or notebook generation failed."];
  Exit[5];
];

If[!TrueQ[result["NotebookSaved"]],
  Print["Notebook file was not created."];
  Exit[6];
];

Print["Package editor notebook generated: " <> notebookPath];
Print["CodeCellCount=" <> ToString[result["CodeCellCount"], InputForm]];
Exit[0];
