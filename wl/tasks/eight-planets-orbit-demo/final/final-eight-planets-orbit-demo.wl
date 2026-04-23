(* ::Package:: *)

(* ::Title:: *)
(* 八大行星运行轨迹研究课题 *)

(* ::Text:: *)
(* 本文件是当前课题的最终结构化 Wolfram 源文件，同时承担“研究说明母版”和“最终可执行源码”两种职责。生成 notebook 时，仓库级 StructuredSource 链路会先让 Front End 以 package editor 方式打开本文件，再把说明单元复制到目标 notebook，并把代码单元转换为普通 Input 单元。这样可以保证说明、源码和最终 notebook 同源维护，并规避直接重写 .nb 文本时常见的中文损坏风险。 *)

(* ::Section:: *)
(* 课题目标与适用范围 *)

(* ::Text:: *)
(* 1. 本课题的直接目标，是在 Wolfram 工作流中构建一个可复现、可讲解、可交互的八大行星运行轨迹演示模型。 *)

(* ::Text:: *)
(* 2. 当前版本优先服务于教学展示、可视化讲解、notebook 调试和后续研究扩展前的概念验证。 *)

(* ::Text:: *)
(* 3. 当前版本适合展示八大行星的大致轨道层级、相对公转快慢和多尺度视野切换，不适合承担高精度星历计算任务。 *)

(* ::Text:: *)
(* 4. 本文件中的说明会同步导出到最终 notebook，因此若后续要调整文案、章节、公式或研究背景，应优先修改本文件后重新导出。 *)

(* ::Section:: *)
(* 科学背景、核心假设与简化边界 *)

(* ::Text:: *)
(* 1. 真实的行星绕日运动属于经典天体力学问题，与开普勒定律、牛顿万有引力理论及更一般的多体摄动问题相关。 *)

(* ::Text:: *)
(* 2. 为了让 notebook 更适合教学与演示，当前模型把八大行星近似为二维共面圆轨道，并假设太阳固定在原点。 *)

(* ::Text:: *)
(* 3. 每颗行星的角速度直接由平均公转周期给出，即采用匀角速度近似，不考虑近日点更快、远日点更慢的真实速度变化。 *)

(* ::Text:: *)
(* 4. 时间参数 year 表示抽象的模拟年份，而不是绑定到某个真实历元的天文时刻。 *)

(* ::Text:: *)
(* 5. 行星可视半径、标签偏移和尾迹长度都属于视觉编码与可读性优化，不是严格的物理量。 *)

(* ::Section:: *)
(* 主要数学概念、符号与公式 *)

(* ::Text:: *)
(* 1. 设 r 表示轨道半径，T 表示公转周期，t 表示模拟时间，θ(t) 表示轨道角位置，则当前模型取 θ(t) = 2πt / T。 *)

(* ::Text:: *)
(* 2. 在该近似下，角速度可写作 ω = dθ/dt = 2π / T；因此公转周期越小，角速度越大，内行星转得更快。 *)

(* ::Text:: *)
(* 3. 行星在二维平面中的位置用参数方程表示为 x(t) = r cos θ(t)，y(t) = r sin θ(t)。 *)

(* ::Text:: *)
(* 4. 若用向量形式表示，则可写为 r_vec(t) = (r cos θ(t), r sin θ(t))。当前实现中的 planetPosition 正是在计算这个二维位置向量。 *)

(* ::Text:: *)
(* 5. 尾迹通过在时间区间 [t - Δt, t] 上离散采样若干 tau_i，再连接 r_vec(tau_i) 得到，用来近似表示“最近一段轨迹”。 *)

(* ::Text:: *)
(* 6. 当前视野半径记作 z。当某颗行星满足 r <= z 时，它被纳入当前视图；这对应代码中的 zoom 过滤逻辑。 *)

(* ::Text:: *)
(* 7. 为增强全景视图中外行星的可辨识度，绘制半径采用 R_draw = 0.045 + 0.012 ln(1 + r) 的温和对数缩放。该公式是视觉编码策略，而非真实天体半径模型。 *)

(* ::Section:: *)
(* 相关物理理论与当前模型的位置 *)

(* ::Text:: *)
(* 1. 开普勒第一定律说明真实行星轨道更接近椭圆，因此当前圆轨道模型只保留了最基础的几何骨架。 *)

(* ::Text:: *)
(* 2. 开普勒第二定律指出面积速度守恒，即 dA/dt = 常数；这意味着真实行星沿轨道并非匀速转动，而本模型显式忽略了这一点。 *)

(* ::Text:: *)
(* 3. 牛顿万有引力理论的经典形式为 F = G m1 m2 / r^2。若要进一步走向高精度模拟，就必须进入更完整的动力学建模、历元选择和数据源管理。 *)

(* ::Text:: *)
(* 4. 因此，当前 notebook 的定位是“平均轨道参数驱动的教学近似模型”，而不是观测级或研究级的高精度星历工具。 *)

(* ::Section:: *)
(* 为展示、调试和维护做的工程优化 *)

(* ::Text:: *)
(* 1. 将行星名称、颜色、轨道颜色、轨道半径、公转周期和标签偏移集中维护在 planetData 中，降低调参与扩展的成本。 *)

(* ::Text:: *)
(* 2. 通过最近尾迹、深色背景、高对比文字和多档 zoom 预设，提升 notebook 中的阅读与演示体验。 *)

(* ::Text:: *)
(* 3. 使用 Manipulate 暴露 year、showTrails 和 zoom 三个主要控制量，使最终 notebook 同时具备讲解入口和调试入口。 *)

(* ::Text:: *)
(* 4. 本文件中的章节说明和代码注释都按“功能说明、使用注意、适用边界、所用 Wolfram 特性”来组织，以满足仓库的最终文件注释规则。 *)

(* ::Section:: *)
(* 已知限制与运行注意事项 *)

(* ::Text:: *)
(* 1. 真实轨道并非完美圆轨道，因此当前模型在位置与速度层面都存在系统性近似误差。 *)

(* ::Text:: *)
(* 2. 当前没有处理轨道倾角、升交点经度、三维投影和多体摄动，空间结构被大幅简化。 *)

(* ::Text:: *)
(* 3. 初始相位未绑定真实历元，因此动画起点不对应某个具体日期下的真实行星排布。 *)

(* ::Text:: *)
(* 4. 标签布局当前偏向 Windows 中文字体环境，若目标机器字体不同，仍可能出现重叠或位置偏移。 *)

(* ::Text:: *)
(* 5. 若显著提高轨迹采样密度、增加额外图层或在较弱机器上运行，Manipulate 的交互流畅度可能下降。 *)

(* ::Section:: *)
(* 后续研究与扩展方向 *)

(* ::Text:: *)
(* 1. 可进一步引入椭圆轨道、倾角和真实历元，把当前教学近似逐步推进到半真实数据驱动版本。 *)

(* ::Text:: *)
(* 2. 可继续验证：在不明显损害交互流畅度的前提下，是否能够加入更轻量的物理真实性增强。 *)

(* ::Text:: *)
(* 3. 可进一步拆分参数层、动力学层、渲染层和导出层，为后续研究型任务提供更清晰的可复用边界。 *)

(* ::Section:: *)
(* 最终可执行代码 *)

ClearAll[
  planetData,
  planetPosition,
  trailPoints,
  planetDiskRadius,
  orbitGraphic,
  demoExpr
];

(* 这里集中维护八大行星的显示参数与近似轨道参数。
   代码作用：
   1. 为绘图、标签和动画控制提供统一的数据入口；
   2. 避免把颜色、半径和周期散落到多个函数中。
   使用注意：
   1. RadiusAU 采用天文单位 AU 的近似值；
   2. PeriodYear 采用地球年的近似值；
   3. LabelOffset 只服务于画面排版，不具备物理意义。
   当前边界：
   1. 该数据表没有记录偏心率、倾角、节点和历元；
   2. 因此它只适合驱动当前教学近似模型。
   这里主要使用了 Association、List 和 RGBColor 作为参数组织与视觉配置手段。 *)
planetData = {
  <|"Name" -> "水星", "Color" -> RGBColor["#c9b08f"], "OrbitColor" -> RGBColor["#8d7357"], "RadiusAU" -> 0.39, "PeriodYear" -> 0.241, "LabelOffset" -> {0.28, 0.18}|>,
  <|"Name" -> "金星", "Color" -> RGBColor["#d9b35d"], "OrbitColor" -> RGBColor["#9d7a2f"], "RadiusAU" -> 0.72, "PeriodYear" -> 0.615, "LabelOffset" -> {0.30, -0.20}|>,
  <|"Name" -> "地球", "Color" -> RGBColor["#4ea5ff"], "OrbitColor" -> RGBColor["#2d6dc7"], "RadiusAU" -> 1.00, "PeriodYear" -> 1.000, "LabelOffset" -> {0.34, 0.22}|>,
  <|"Name" -> "火星", "Color" -> RGBColor["#d16b4c"], "OrbitColor" -> RGBColor["#9b4127"], "RadiusAU" -> 1.52, "PeriodYear" -> 1.881, "LabelOffset" -> {0.36, -0.24}|>,
  <|"Name" -> "木星", "Color" -> RGBColor["#d7a46d"], "OrbitColor" -> RGBColor["#9d6d3a"], "RadiusAU" -> 5.20, "PeriodYear" -> 11.86, "LabelOffset" -> {0.55, 0.26}|>,
  <|"Name" -> "土星", "Color" -> RGBColor["#f0d38a"], "OrbitColor" -> RGBColor["#b39342"], "RadiusAU" -> 9.58, "PeriodYear" -> 29.46, "LabelOffset" -> {0.58, -0.28}|>,
  <|"Name" -> "天王星", "Color" -> RGBColor["#91d8e4"], "OrbitColor" -> RGBColor["#4a95a3"], "RadiusAU" -> 19.20, "PeriodYear" -> 84.01, "LabelOffset" -> {0.70, 0.32}|>,
  <|"Name" -> "海王星", "Color" -> RGBColor["#5178ff"], "OrbitColor" -> RGBColor["#2648b8"], "RadiusAU" -> 30.05, "PeriodYear" -> 164.80, "LabelOffset" -> {0.74, -0.34}|>
};

(* 使用圆轨道 + 匀角速度近似，计算某颗行星在时刻 t 的二维位置。
   代码作用：
   1. 把轨道半径和公转周期映射为当前平面位置；
   2. 为尾迹采样、行星绘制和标签定位提供基础坐标。
   使用注意：
   1. t 的单位与 PeriodYear 一致，均按“年”处理；
   2. 输入 planet 需要包含 RadiusAU 与 PeriodYear 两个键。
   当前边界：
   1. 不考虑离心率、轨道倾角、岁差和多体摄动；
   2. 因此该函数更适合教学可视化，而不是精密轨道分析。
   这里主要使用了 Module、Cos、Sin 和列表标量乘法。 *)
planetPosition[planet_, t_] := Module[
  {theta = 2 Pi t/planet["PeriodYear"]},
  planet["RadiusAU"] {Cos[theta], Sin[theta]}
];

(* 为指定行星生成“最近一段轨迹”的采样点序列。
   代码作用：
   1. 让画面显示有限长度的彩色尾迹；
   2. 用最近历史增强读者对运动方向和速度的感知。
   使用注意：
   1. 尾迹窗口长度由 1.2 年与公转周期共同限制；
   2. 采样步长会随公转周期变化，以兼顾内外行星的平滑度。
   当前边界：
   1. 当前只绘制最近一段轨迹，不显示完整历史轨道；
   2. 若进一步提高采样密度，交互性能会下降。
   这里主要使用了 Table、Max、Min 与上面的 planetPosition。 *)
trailPoints[planet_, t_] := Table[
  planetPosition[planet, tau],
  {
    tau,
    Max[0., t - Min[1.2, planet["PeriodYear"]]],
    t,
    Max[0.01, planet["PeriodYear"]/150.]
  }
];

(* 根据轨道半径给出用于绘图的行星圆盘半径。
   代码作用：
   1. 对外行星做温和的可见性增强；
   2. 避免真实尺度差异在全景视图中造成“外行星几乎看不见”。
   使用注意：
   1. 返回值只用于图形表现，不应解释为真实物理半径；
   2. 若更改该公式，应同步评估标签偏移和整体观感。
   当前边界：
   1. 这是经验型视觉缩放公式，不具备物理拟合含义。
   这里主要使用了 Log 作为非线性视觉编码。 *)
planetDiskRadius[planet_] := 0.045 + 0.012 Log[1 + planet["RadiusAU"]];

(* 这是最终的静态绘图核心函数。
   代码作用：
   1. 根据当前年份、尾迹开关和视野范围生成整幅太阳系轨道图；
   2. 把太阳、轨道、尾迹、行星圆盘和中文标签统一组织到 Graphics 中。
   使用注意：
   1. zoom 表示当前视野半径，只显示 RadiusAU 不超过该值的行星；
   2. showTrails 为 False 时只保留轨道和行星本体；
   3. 若修改字体或配色，需重新检查中文标签与深色背景的对比度。
   当前边界：
   1. 当前视图是理想化日心平面视图，不是观测者视角；
   2. 标签布局依赖经验偏移，尚未引入自动避让策略。
   这里主要使用了 Graphics、Directive、Circle、Disk、Line、Text、Style、Select、Table、With 和 Join。 *)
orbitGraphic[t_, showTrails_, zoom_] := Module[
  {visiblePlanets, range},
  visiblePlanets = Select[planetData, #["RadiusAU"] <= zoom &];
  range = 1.08 zoom;

  Graphics[
    Join[
      {
        {
          Glow[RGBColor["#ffd76a"]],
          RGBColor["#ffb300"],
          EdgeForm[None],
          Disk[{0, 0}, 0.22]
        }
      },
      Flatten @ Table[
        {
          {
            Directive[planet["OrbitColor"], Opacity[0.55], AbsoluteThickness[1.2]],
            Circle[{0, 0}, planet["RadiusAU"]]
          },

          Sequence @@ If[
            showTrails,
            {
              {
                Directive[planet["Color"], Opacity[0.38], AbsoluteThickness[2.0]],
                Line[trailPoints[planet, t]]
              }
            },
            {}
          ],

          With[{pos = planetPosition[planet, t]},
            {
              {
                EdgeForm[Directive[White, Opacity[0.18]]],
                planet["Color"],
                Disk[pos, planetDiskRadius[planet]]
              },
              Text[
                Style[
                  planet["Name"],
                  12,
                  Bold,
                  White,
                  FontFamily -> "Microsoft YaHei",
                  Background -> Darker[planet["Color"], 0.78]
                ],
                pos + planet["LabelOffset"]
              ]
            }
          ]
        },
        {planet, visiblePlanets}
      ]
    ],
    PlotRange -> {{-range, range}, {-range, range}},
    PlotRangePadding -> Scaled[0.04],
    Background -> RGBColor["#050814"],
    ImagePadding -> 42,
    ImageSize -> 860,
    Axes -> False,
    PlotLabel -> Style[
      "太阳系八大行星彩色运行轨迹",
      18,
      Bold,
      White,
      FontFamily -> "Microsoft YaHei"
    ]
  ]
];

(* 使用 Manipulate 暴露交互式调试入口。
   代码作用：
   1. 让最终 notebook 既能直接演示，也能就地调参与观察效果；
   2. 把 orbitGraphic 封装成统一的互动界面。
   使用注意：
   1. year 控制模拟时间推进；
   2. showTrails 控制是否显示最近尾迹；
   3. zoom 控制当前展示到哪一层轨道。
   当前边界：
   1. 当前交互参数仍然偏少，更适合教学演示而非批量实验；
   2. 若进一步增加控件，需要重新评估布局与响应速度。
   这里主要使用了 Manipulate、Animator、TrackedSymbols、SaveDefinitions 和 ControlPlacement。 *)
demoExpr = Manipulate[
  orbitGraphic[year, showTrails, zoom],
  {{
    year,
    0.,
    "模拟年份"
   },
   0.,
   165.,
   Animator,
   AnimationRunning -> False,
   AnimationRate -> 0.45,
   AppearanceElements -> {
     "ProgressSlider",
     "PlayPauseButton",
     "FasterSlowerButtons",
     "DirectionButton"
   }
  },
  {{
    showTrails,
    True,
    "显示彩色轨迹"
   },
   {True -> "显示", False -> "隐藏"}
  },
  {{
    zoom,
    12.,
    "视野范围（天文单位）"
   },
   {
     2. -> "内行星",
     4. -> "火星以内",
     8. -> "木星以内",
     12. -> "土星以内",
     20. -> "天王星以内",
     32. -> "全景"
   }
  },
  TrackedSymbols :> {year, showTrails, zoom},
  SaveDefinitions -> True,
  ControlPlacement -> Left,
  Paneled -> False,
  SynchronousUpdating -> False
];

(* 约定把 demoExpr 作为文件最后一个表达式。
   这样无论通过 wolframscript 执行，还是通过 notebook 打开并求值，最终都能得到同一份交互动画入口。 *)
demoExpr
