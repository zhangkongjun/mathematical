Needs["JLink`"];

taskSlug = "eight-planets-orbit-demo";
repoRoot = Nest[DirectoryName, DirectoryName[$InputFileName], 5];
sourcePath = FileNameJoin[{repoRoot, "wl", "tasks", taskSlug, "scratch", "02-repair", "probe-package-editor-structured-source.wl"}];
logDir = FileNameJoin[{repoRoot, "logs", "tasks", taskSlug}];
logPath = FileNameJoin[{logDir, "probe_package_editor_structured_source_" <> DateString[{"Year", "Month", "Day", "_", "Hour", "Minute", "Second"}] <> ".log"}];

If[!DirectoryQ[logDir],
  CreateDirectory[logDir, CreateIntermediateDirectories -> True]
];

log[msg_] := PutAppend[
  DateString[{"ISODate", " ", "Time"}] <> " " <> msg,
  logPath
];

$FrontEndLaunchCommand =
  "'C:\\Program Files\\Wolfram Research\\Wolfram\\14.3\\WolframNB.exe' -server";

connectResult = Quiet @ Check[ConnectToFrontEnd[ForceLaunch -> True], $Failed];
log["ConnectToFrontEnd=" <> ToString[connectResult, InputForm]];

If[connectResult === $Failed,
  log["FAILED: unable to connect to front end"];
  Print["Unable to connect to front end."];
  Exit[2];
];

result = Check[
  UseFrontEnd @ Module[{nb, expr, styles, cells},
    nb = NotebookOpen[sourcePath, Visible -> False];
    expr = NotebookGet[nb];
    styles = DeleteDuplicates @ Cases[expr, Cell[_, style_, ___] :> style, Infinity];
    cells = Take[Cases[expr, _Cell, Infinity], UpTo[10]];
    NotebookClose[nb];
    <|
      "Styles" -> styles,
      "Cells" -> cells
    |>
  ],
  $Failed
];

Quiet[CloseFrontEnd[]];

If[result === $Failed,
  log["FAILED: probe raised a message"];
  Print["Probe failed."];
  Exit[3];
];

log["Styles=" <> ToString[result["Styles"], InputForm]];
log["Cells=" <> ToString[Short[result["Cells"], 4], InputForm]];

Print["Styles=" <> ToString[result["Styles"], InputForm]];
Print["Cells=" <> ToString[Short[result["Cells"], 4], InputForm]];
Exit[0];
