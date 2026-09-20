#import "@preview/bookly:5.1.1": *
#import "../figstyle.typ": *
#import "../boxes.typ": *

= 版式元素实践

本章演示列表、引用、脚注与链接等行文元素的组合使用。

#minitoc

#pagebreak()

== 行内样式

中文的字体渲染与西文不同：汉字没有真正的斜体字形，硬套斜体只会得到正体。模板据此重定义了四种行内样式，西方文字仍遵循各自语言的常规做法。

- *加粗*：中文用思源宋体的粗体字重——字形不变、笔画加粗；系统没有思源宋体时回退到黑体。西文用 New Computer Modern 的粗体。
- _强调_：中文改用楷体（楷体表强调是中文书籍的传统做法），西文仍是斜体。因此 `_中文_` 与 `_Latin_` 走的是两套机制，各自符合本语言的惯例。
- #underline[下划线]：与字身留出距离，并在标点与下伸笔画处自动避让，不会与字形相碰。
- #strike[删除线]：同样抬高，避免压在字身上。

混排示例：模板把*同类元素的样式*集中到 `figstyle.typ` 与 `boxes.typ`，需要提示时可以用 #highlight[高亮]；上下标写作 H#sub[2]O 与 x#super[2]；行内代码如 `#set page(paper: "a4")` 用等宽字体，字号自动小一号。

== 列表

排版中常用的两类列表：

- 无序列表适合并列要点，条目之间地位平等；
- 条目较长时可以分成多行，缩进由模板自动维持。

+ 有序列表适合步骤说明；
+ 步骤之间的换行不会打断编号。

== 引用

#quote(block: true, attribution: [一位排版师])[
  排版是把内容放进格子里，而好的排版让人忘记格子的存在。
]

== 脚注

正文中的补充说明可以写成脚注#footnote[脚注随正文自动排版，编号连续，适合作简短的出处或补充说明。]，读者视线不必离开正文。

#tip-box[若需要把注文排到页边空白处（旁注），可启用 Bookly 的 Tufte 版式（`tufte: true`）；该版式需要较宽的切口边距，因此在大开本或单面印刷时效果更好。]

== 链接与交叉引用

访问 #link("https://typst.app/universe/")[Typst Universe] 可以浏览全部官方模板与社区包。文档内部的交叉引用则统一使用 `@` 语法，例如前文中的公式 @eq:sum 与表格 @tab:fonts，编号均自动生成。

== 图形与绘图

书中的插图统一由 `figstyle.typ` 定义样式：配色取自主题红与提示框的同族颜色，线宽、圆角、箭头与图内文字（黑体，9pt）固定不变。示意图、流程图与数据图分别交给 CeTZ、Fletcher、Lilaq 三个绘图包完成——三者共用同一套参数，换包不换风格。

*流程图*用 Fletcher（图 @fig:flow）。它按"节点—箭头"描述关系，改一处连线不必重算坐标：图中正文改动后重新编译、检查排版，虚线回边表示回到修改，是一个完整的写作循环。

#figure(
  flow(
    node((0, 0), [撰写内容]),
    node((1, 0), [编译]),
    node((2, 0), [检查排版]),
    edge((0, 0), (1, 0), "->", label: [`.typ`]),
    edge((1, 0), (2, 0), "->", label: [PDF]),
    edge((2, 0), (0, 0), "-->", label: [修改], bend: -30deg),
  ),
  caption: [写作与排版循环（Fletcher 绘制的节点—箭头图）],
) <fig:flow>

*示意图*用 CeTZ，适合需要精确坐标的几何图。图 @fig:page-layout 把书籍的版心与四周页边距标注出来——这张图也是用样式模块里的参数画的，所以它与本书其他插图共用同一套线宽与颜色。

#figure(
  sketch(
    {
      import draw: *
      rect(
        (-2.2, -1.6),
        (2.2, 1.6),
        fill: palette.tint-gray,
        stroke: 0.8pt + palette.muted,
      )
      rect((-1.4, -1.05), (1.4, 1.05), fill: white, stroke: 0.9pt + palette.ink)
      content((0, 0), [版心])
      content((0, 1.32), text(size: 8pt)[天头])
      content((0, -1.32), text(size: 8pt)[地脚])
      content((-1.8, 0), text(size: 8pt)[订口])
      content((1.8, 0), text(size: 8pt)[切口])
    },
    length: 12mm,
  ),
  caption: [书籍版心与页边距（CeTZ 绘制的示意图）],
) <fig:page-layout>

*数据图*用 Lilaq，坐标轴沿绘图区边框。图 @fig:chars-per-line 对比 a4 与 a5 两种开本在不同字号下的每行字数：开本越大每行字数越多，同一开本下字号越大每行字数越少，两条曲线的取色来自样式模块的 `series` 数组。

#figure(
  chart(
    xlabel: [字号（pt）],
    ylabel: [每行字数],
    lq.plot(
      (8, 10, 12, 14),
      (56.7, 45.4, 37.8, 32.4),
      color: series.at(0),
      mark: "o",
      label: [a4],
    ),
    lq.plot(
      (8, 10, 12, 14),
      (39.0, 31.2, 26.0, 22.3),
      color: series.at(1),
      mark: "s",
      label: [a5],
    ),
  ),
  caption: [字号与每行字数：按中文全角估算，a4 版心 16cm、a5 版心 11cm（Lilaq 绘制的数据图）],
) <fig:chars-per-line>

*函数图象*换用教材式的过原点坐标轴，即图 @fig:sine 中 $y = sin x$ 的曲线：轴线在原点相交、轴端带箭头，适合经过或接近原点的函数。

#figure(
  fn-plot(
    xlabel: [$x$],
    ylabel: [$sin x$],
    lq.plot(
      range(0, 25).map(i => 0.25 * i),
      range(0, 25).map(i => calc.sin(0.25 * i)),
      color: series.at(0),
      mark: none,
      label: [$sin x$],
    ),
  ),
  caption: [函数曲线：$y = sin x$（教材式过原点坐标轴，适合经过原点的函数图象）],
) <fig:sine>

同一批数据也能换图表类型：图 @fig:bar 把 a4 开本的每行字数画成柱状图，样式与折线图完全一致。

#figure(
  chart(
    xlabel: [字号（pt）],
    ylabel: [每行字数],
    lq.bar(
      (9, 10.5, 12, 14),
      (50.4, 43.2, 37.8, 32.4),
      fill: series.at(0),
    ),
  ),
  caption: [同一批数据的另一种画法：a4 开本各字号下的每行字数（柱状图）],
) <fig:bar>

图表样式分两类，不能混用：*数据图*（`chart`）用边框式坐标轴，适合取值范围任意的数据；*函数图*（`fn-plot`）用教材式的过原点坐标轴，只用于经过或接近原点的曲线。把过原点样式套在远离原点的数据上，轴线会被推到数据区之外，两个坐标轴之间留下大片空白——图 @fig:chars-per-line 与图 @fig:sine 正是分别采用了这两种样式。

五张图都直接复用了样式模块里的 `palette`、`flow`、`sketch`、`chart`、`fn-plot`，因此配色与线宽完全一致。`chart` 对折线、柱状等各类数据图通用——把 `lq.plot` 换成 `lq.bar`、`lq.scatter` 即可（对比图 @fig:chars-per-line 与图 @fig:bar）。多系列数据按 `series` 数组取色；若以后要换绘图库或调整颜色，只需改 `figstyle.typ` 一处，全书插图随之统一。

== 编号环境与交叉引用

技术内容常需要编号的定义与定理，并希望后文能够引用。它们由 `boxes.typ` 提供，编号全书连续生成，引用沿用 `@` 语法：

#definition[
  若两条直线相交成直角，则称它们*互相垂直*。
]<def:perpendicular>

#theorem[（勾股定理）直角三角形两直角边的平方和等于斜边的平方。]<thm:pythagoras>

#proof[
  设两直角边为 $a, b$，斜边为 $c$。把四个全等的直角三角形拼成边长为 $a + b$ 的正方形，中间留出的正方形面积为 $c^2$；用同一块面积作另一种计算，得 $(a+b)^2 - 2 a b = c^2$，整理即 $a^2 + b^2 = c^2$。
]

定义 @def:perpendicular 与定理 @thm:pythagoras 的编号都由模板维护：插入或删除一个环境，后续编号与全文引用会一起更新（全书连续编号，附录里的环境接着本章继续数），不需要手工核对。附录 @app:boxes 汇总了全部环境类型。

== 本章小结

本章演示的元素可以直接复制到你自己的书籍项目中。若需调整版面密度，可修改 `main.typ` 中的 `fonts.size` 与纸张开本（`paper-size`）两项配置。
