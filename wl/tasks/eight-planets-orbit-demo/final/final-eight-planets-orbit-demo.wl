(* ::Package:: *)

(* ::Title:: *)
(* 八大行星运行轨迹动画 *)

(* ::Text:: *)
(* 这份 package editor 源文件同时承担两件事：一是作为“八大行星运行轨迹动画”的最终 Wolfram 源码，二是作为最终 notebook 的说明与源码母版。生成 notebook 时，Front End 会先打开这个 .wl，再把说明单元直接复制过去，并把代码单元转换成普通 notebook 里的 Input 单元，从而避免直接重写 .nb 文件带来的中文乱码问题。 *)

(* ::Section:: *)
(* 实现目标与适用范围 *)

(* ::Text:: *)
(* 目标： *)

(* ::Text:: *)
(* 1. 当前实现优先服务于教学演示、可视化讲解和交互式 notebook 调试。 *)

(* ::Text:: *)
(* 2. 它适合用来展示八大行星的大致轨道层级、相对运动节奏和多尺度视图切换。 *)

(* ::Text:: *)
(* 非目标： *)

(* ::Text:: *)
(* 1. 它不是高精度星历工具。 *)

(* ::Text:: *)
(* 2. 它不适合直接用于观测级预测、严肃轨道拟合或长期动力学结论。 *)

(* ::Section:: *)
(* 核心假设 *)

(* ::Text:: *)
(* 1. 所有行星轨道按二维共面圆轨道近似处理。 *)

(* ::Text:: *)
(* 2. 角速度直接由平均公转周期给出，不考虑近日点更快、远日点更慢的非匀速运动。 *)

(* ::Text:: *)
(* 3. 太阳固定在原点，不考虑太阳系质心摆动。 *)

(* ::Text:: *)
(* 4. 时间参数 year 是抽象模拟年份，不绑定具体历元。 *)

(* ::Text:: *)
(* 5. 行星大小、标签偏移和尾迹长度主要服务于可视化表达，不代表真实尺度。 *)

(* ::Section:: *)
(* 主要数学概念与物理公式 *)

(* ::Text:: *)
(* 1. 圆周运动参数化：每颗行星的位置采用二维参数方程 x(t) = r cos θ(t)，y(t) = r sin θ(t)。 *)

(* ::Text:: *)
(* 2. 角位置与周期关系：θ(t) = 2πt / T，其中 T 是公转周期；对应的角速度为 ω = dθ/dt = 2π / T。 *)

(* ::Text:: *)
(* 3. 多尺度比较：当公转周期 T 较小时，角速度 ω = 2π / T 较大，因此内行星转得更快，外行星转得更慢。 *)

(* ::Text:: *)
(* 4. 尾迹采样：在时间区间 [t - Δt, t] 上取离散时刻 τ_i，并连接对应位置点 (x(τ_i), y(τ_i))，用以近似表示最近一段轨迹。 *)

(* ::Text:: *)
(* 5. 视野裁剪：当轨道半径满足 r ≤ z 时，该行星被纳入当前视野，其中 z 表示当前视野半径。 *)

(* ::Text:: *)
(* 6. 对数缩放：绘制半径采用 R = 0.045 + 0.012 ln(1 + r)，属于视觉编码中的非线性缩放，用来缓和内外行星尺寸差异过大导致的不可读问题。 *)

(* ::Text:: *)
(* 相关科学理论与背景： *)

(* ::Text:: *)
(* 1. 开普勒第一定律说明真实行星轨道更接近椭圆，而不是当前模型中的圆。 *)

(* ::Text:: *)
(* 2. 开普勒第二定律说明真实行星沿轨道并非匀速运动，其数学表达可写作 dA/dt = 常数；因此本模型省略了面积速度守恒带来的快慢变化。 *)

(* ::Text:: *)
(* 3. 牛顿万有引力理论解释了行星绕日运动的动力学来源，基本形式为 F = G m₁m₂ / r²；当前 notebook 只保留了其可视化层面的简化结果，没有直接数值求解引力方程。 *)

(* ::Text:: *)
(* 4. 当前模型更接近“平均轨道参数驱动的教学近似”，而不是完整的天体力学积分模型。 *)

(* ::Section:: *)
(* 为展示和调试做的优化 *)

(* ::Text:: *)
(* 1. 把颜色、轨道半径、公转周期和标签偏移集中到 planetData，便于在 notebook 中直接调参。 *)

(* ::Text:: *)
(* 2. 对外行星使用温和的可见性增强，避免全景视图下几乎不可辨认。 *)

(* ::Text:: *)
(* 3. 为每颗行星保留最近一段彩色尾迹，增强“运动正在发生”的感知。 *)

(* ::Text:: *)
(* 4. 提供多档 zoom 预设，方便在内行星视图和全景视图之间快速切换。 *)

(* ::Section:: *)
(* 已知限制与运行注意事项 *)

(* ::Text:: *)
(* 1. 真实轨道不是完美圆轨道，因此当前位置和速度会有系统偏差。 *)

(* ::Text:: *)
(* 2. 当前没有处理轨道倾角和三维投影，空间结构被显著简化。 *)

(* ::Text:: *)
(* 3. 初始相位未绑定真实历元，因此动画起点不对应某个具体日期下的真实行星位置。 *)

(* ::Text:: *)
(* 4. 中文字体当前偏向 Microsoft YaHei；若目标机器字体环境不同，标签宽度和布局可能变化。 *)

(* ::Text:: *)
(* 5. 若继续提高轨迹采样密度或增加更多图层，Manipulate 交互可能变慢。 *)

(* ::Section:: *)
(* 后续研究方向 *)

(* ::Text:: *)
(* 1. 可进一步引入椭圆轨道、倾角、真实历元和更高精度数据源，形成更接近星历的版本。 *)

(* ::Text:: *)
(* 2. 可以研究如何在同一 notebook 中同时展示“教学增强版”和“物理更真实版”，帮助读者理解可读性优化与物理真实性之间的边界。 *)

(* ::Section:: *)
(* 可直接调试的源代码 *)

ClearAll[
  planetData,
  planetPosition,
  trailPoints,
  planetDiskRadius,
  orbitGraphic,
  demoExpr
];

(* 这里集中维护八大行星的显示参数。
   使用时注意：
   1. 轨道半径采用天文单位 AU 的近似值；
   2. 公转周期单位是地球年；
   3. LabelOffset 只服务于画面排版，不具有物理意义。 *)
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

(* 使用最简单的圆轨道近似计算二维位置。
   限制：
   1. 不考虑离心率、轨道倾角和摄动；
   2. 更适合教学可视化，不适合精密天体力学分析。 *)
planetPosition[planet_, t_] := Module[
  {theta = 2 Pi t/planet["PeriodYear"]},
  planet["RadiusAU"] {Cos[theta], Sin[theta]}
];

(* 为每颗行星保留一小段最近尾迹，增强“正在运动”的视觉感受。
   当前实现只显示最近一段轨迹，不显示完整历史轨道。 *)
trailPoints[planet_, t_] := Table[
  planetPosition[planet, tau],
  {
    tau,
    Max[0., t - Min[1.2, planet["PeriodYear"]]],
    t,
    Max[0.01, planet["PeriodYear"]/150.]
  }
];

(* 全景视图下外行星容易过小，因此使用温和的对数缩放增强可见性。
   这只是视觉优化，不代表真实天体尺寸比例。 *)
planetDiskRadius[planet_] := 0.045 + 0.012 Log[1 + planet["RadiusAU"]];

(* 这是实际绘图函数。
   参数说明：
   - t：模拟推进到第几年；
   - showTrails：是否显示彩色尾迹；
   - zoom：当前视野半径，仅显示轨道半径不超过该值的行星。 *)
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

(* Manipulate 提供交互式调试入口。
   建议在 notebook 中重点尝试：
   1. 修改 planetData 中的颜色和标签偏移；
   2. 调整 trailPoints 的尾迹长度和采样步长；
   3. 调整 zoom 选项，观察不同层级的轨道布局。 *)
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
   这样无论通过 wolframscript 还是 notebook 直接执行，都能得到同一份交互动画。 *)
demoExpr
