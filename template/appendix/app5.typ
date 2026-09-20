#import "@preview/bookly:5.1.1": *
#import "../figstyle.typ": *
#import "@preview/arch-plotter:0.2.0": *

= 土木工程绘图

Typst 没有土木专业的成套模板，能用的是一组拼图：结构受力图用 bone（见附录 @app:eng），建筑平面图与地块测绘用 arch-plotter，地图数据用 mercator，施工进度横道图用 gantty，学院论文模板可用 vienna-tech（维也纳工业大学土木与环境工程学院）。配筋图、桥梁、岩土剖面、道路平纵横断面目前没有现成库，需要自行绘制或由专业软件出图后插入。

arch-plotter 是其中能力最强的一个：它把 CAD 的作图习惯（右移、上移、闭合、打标记）搬进了 Typst，平面图能自动生成墙线交接、门窗与尺寸标注，测绘地块能自动算面积并输出汇总表。图 @fig:plot 是一块矩形地的完整示例——描出边界之后，尺寸与面积随即标出，同一份数据还生成了表 @tab:plot-summary 的面积汇总，全部只用六行代码。

// 顺时针描出地块边界并闭合（R 右移、U 上移、L 左移、C 闭合）
#let 地块 = p.trace-plot(
  start: (0, 0),
  mark-steps: true,
  (R(24), U(18), L(24), C()),
)

#figure(
  {
    set text(font: fig-font, size: fig-size)
    p.plot-canvas(scale: 0.26cm, {
      p.draw-plot(
        地块,
        name: "Plot A",
        fill: rgb("#eef6ee"),
        show-area: true,
        show-dim: true,
      )
    })
  },
  caption: [地块测绘图（arch-plotter 绘制）],
) <fig:plot>

#figure(
  {
    set text(font: fig-font, size: fig-size)
    p.plot-summary-table(地块)
  },
  caption: [面积汇总表（arch-plotter 自动生成）],
) <tab:plot-summary>

#warning-box[注意：arch-plotter 的尺寸、面积与汇总表表头固定为英制与英文（英尺、英寸、`Plot No.` 等），库内没有米制或中文化的开关。要在中文图纸里使用，需要自行替换标注文字，或只借用它的 CAD 绘图与自动算面积能力，标注另写。]
