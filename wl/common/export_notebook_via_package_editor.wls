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
   1. 让 Front End 以 package editor 方式打开 `.wl` / `.m`；
   2. 直接复用其中已经解析好的 Code 单元盒子结构；
   3. 把这些单元转换成普通 notebook 里的 Input 单元并保存。
   这样生成出来的 `.nb` 更接近手工在 notebook 中直接键入代码的效果，
   既保留中文注释和语法着色，也支持后续在 notebook 中直接 Shift+Enter。 *)
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
