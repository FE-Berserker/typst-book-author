#import "@preview/bookly:5.1.1": *
#import "../figstyle.typ": *
#import "@preview/zap:0.6.0" as zap
#import "@preview/bone:0.1.0" as bone
#import "@preview/mechanical-system-cetz-34j:1.1.5": damper, spring, wall, wire
// 振动系统那张图要用与 mechanical-system 配套的 cetz 0.5.0
#import "@preview/cetz:0.5.0" as cetz

= 工程绘图：机械与电气 <app:eng>

Typst 没有笼统的"工程制图模板"，但有一批专用绘图库能画出符合行业惯例的机械图与电气图（表 @tab:eng-libs 汇总）。这类图遵循各自的制图规范，不必套用正文插图的样式；需要统一的只有*字体*。下面三张图分别演示三类图形：图 @fig:circuit 是 zap 画的 RC 电路，图 @fig:beam 是 bone 画的简支梁受力图（标注要用 `label()` 自己放，该库的 `dforce` 并不使用它的 `label` 参数），图 @fig:msd 是 mechanical-system 画的质量—弹簧—阻尼模型。

#figure(
  {
    set text(font: fig-font, size: fig-size)
    zap.circuit(length: 1.05cm, {
      import zap: *
      // zap 的元件是“画在两个给定点之间、居中对齐”的：
      // 先把四个角节点显式放好，再把元件挂到对应边上，回路才闭合得方正。
      // （用链式相对坐标（rel: …）逐个接元件时，端点会与预期错位，底边会画成斜线。）
      node("a", (0, 0))
      node("b", (0, 3))
      node("c", (4, 3))
      node("d", (4, 0))
      battery("V", "a", "b")
      resistor("R1", "b", "c", i: $i$)
      capacitor("C", "c", "d")
      wire("d", "a")
    })
  },
  caption: [RC 电路（zap 绘制，符号遵循 IEC/IEEE 惯例）],
) <fig:circuit>

#figure(
  {
    set text(font: fig-font, size: fig-size)
    bone.diagram(length: 1.05cm, {
      import bone: *
      beam((0, 0), (6, 0))
      support((0, 0))
      support((6, 0))
      // 均布载荷只覆盖左半跨，给右段的集中力让出位置
      dforce((0.5, 0), (3.5, 0))
      // 注意：bone 的 dforce 虽接受 label 参数，但实现里并未使用，
      // 载荷标注要用 label() 自行放置
      label((2, 1.3), $q$)
      force((5, 0), length: 0.7)
      label((5.25, 0.55), $F$, anchor: "west")
    })
  },
  caption: [简支梁、均布载荷与集中力（bone 绘制）],
) <fig:beam>

#figure(
  {
    set text(font: fig-font, size: fig-size)
    cetz.canvas(length: 1.05cm, {
      import cetz.draw: *
      circle((0, 0), radius: 0.34, name: "mass1")
      spring((0.55, 0), name: "spring1", n: 8)
      circle((2, 0), radius: 0.34, name: "mass2")
      damper((2.85, 0), name: "damper")
      wall((4.1, -1), b: (4.1, 1), name: "wall")
      wire("mass2", "damper")
      wire("damper", "wall")
      content("mass1", $M_1$)
      content("mass2", $M_2$)
      // 参数标注放在轴线下方，避开弹簧锯齿与阻尼器方框
      content((1.25, -0.9), $k$)
      content((3.2, -0.9), $c$)
    })
  },
  caption: [质量—弹簧—阻尼系统（mechanical-system-cetz-34j 绘制）],
) <fig:msd>

#figure(
  table(
    columns: (auto, auto, 1fr),
    table.header([库], [方向], [能画什么]),
    [zap 0.6.0], [电气], [电阻、电容、电感、二极管、晶体管等],

    [circuiteria 0.2.1], [电气], [方框级电路：系统框图之间的连线],
    [typed-physics 0.1.1], [力学 / 电路], [斜面、滑轮、绳、弹簧与直流电路],

    [mechanical-system-cetz-34j 1.1.5], [机械], [振动：弹簧、阻尼器、墙体],
    [bone 0.1.0], [结构 / 运动学], [梁、支座、分布载荷、铰链],
  ),
  caption: [机械与电气绘图常用库],
) <tab:eng-libs>
