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

collectVisibleCells[elements_List] := Flatten[collectVisibleCell /@ elements, 1];

collectVisibleCell[Cell[CellGroupData[groupCells_List, ___], ___]] := collectVisibleCells[groupCells];
collectVisibleCell[cell_Cell] := {cell};
collectVisibleCell[_] := {};

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

(* 这个任务脚本只做 Front End 侧的“复制单元格生成 notebook”。
   关键点：
   1. 最终说明和代码都先保存在 .wl 源文件里；
   2. Front End 先按 package editor 方式打开该 .wl；
   3. 说明单元直接复制，代码单元转换成普通 notebook 可执行的 Input 单元；
   4. 整个过程不再解析并回写已有 .nb 文本，从而避免中文说明被写坏。 *)
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
