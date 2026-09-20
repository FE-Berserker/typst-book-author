#import "@preview/bookly:5.1.1": *
#import "../boxes.typ": box-colors, code-box-zh, subfigure-zh
#import "@preview/heroic:0.1.2": hi

= Typst 语言速览 <ch:overview>

本章以最短的篇幅介绍 Typst 的核心概念，并演示公式、表格与子图的排版效果。

#minitoc

#pagebreak()

== 标记模式与代码模式

Typst 区分标记模式、代码模式与数学模式三种上下文。正文中调用函数需要前缀 `#`，例如 `#text(fill: red)[红色文字]`；行内代码则用反引号包裹，如 `#set page(paper: "a5")`。

#code-box-zh[
  ```typst
  #set page(paper: "a5")
  #set par(first-line-indent: 2em)
  ```
]

== 数学公式

公式 @eq:sum 与 @eq:gauss 演示行间公式的编号与引用机制：

$ sum_(k=1)^n k = (n(n+1))/2 $ <eq:sum>

$ integral_0^infinity e^(-x^2) dif x = sqrt(pi)/2 $ <eq:gauss>

重要的结论可以加框突出，例如欧拉恒等式：

#boxeq[$ e^(i pi) + 1 = 0 $]

== 表格与子图

表 @tab:fonts 汇总了样板默认的字体配置；图 @fig:sub 演示两个子图并排的排版方式。

#figure(
  table(
    columns: (auto, 1fr, auto),
    table.header([用途], [字体族], [说明]),
    [正文], [Noto Serif SC], [思源宋体，中文正文],
    [西文], [New Computer Modern], [拉丁字母与数字],
    [标题], [SimHei], [黑体，标题与强调],
    [数学], [New Computer Modern Math], [公式与符号],
    [代码], [DejaVu Sans Mono], [等宽代码片段],
  ),
  caption: [样板默认字体配置],
) <tab:fonts>

#subfigure-zh(
  figure(
    image("../images/typst-logo.svg", width: 60%, alt: "Typst 标志（左）"),
    caption: [],
  ),
  figure(
    image("../images/typst-logo.svg", width: 60%, alt: "Typst 标志（右）"),
    caption: [],
  ),
  <sub-b>,
  columns: (1fr, 1fr),
  caption: [(a) 左图与 (b) 右图并排展示],
  label: <fig:sub>,
)

表格单元格里同样可以排公式与图标。表 @tab:math-icons 把常用公式与状态标记放在一起：公式走数学字体（与正文公式同源），图标是矢量图，可随文字缩放、按需换色。

#figure(
  table(
    columns: (auto, 1fr, auto, auto),
    table.header([项目], [说明], [公式], [状态]),
    [质能方程],
    [质量与能量的关系],
    [$E = m c^2$],
    [#hi("check-circle", color: box-colors.green)],

    [高斯积分],
    [概率论中的常用结果],
    [$integral_0^infinity e^(-x^2) dif x = sqrt(pi)/2$],
    [#hi("check-circle", color: box-colors.green)],

    [欧拉恒等式],
    [复分析中的著名等式],
    [$e^(i pi) + 1 = 0$],
    [#hi("x-circle", color: box-colors.red)],

    [求和公式],
    [与中文混排：$alpha$、$beta$ 等希腊字母],
    [$sum_(i=1)^n i = (n(n+1))/2$],
    [#hi("exclamation-triangle", color: box-colors.orange)],
  ),
  caption: [表格中的公式与图标],
) <tab:math-icons>

== 提示框

模板内置七类提示框。以下依次演示信息、提示与警告三类；另有八类带矢量图标的提示框（定义、定理、示例等），见附录 @app:boxes。

#info-box[信息框适合放补充说明，标题文字会跟随文档语言自动本地化。]

#tip-box[正文首行缩进已按中文习惯设为两个汉字宽度，无需在每个段落手动调整。]

#warning-box[更换主题（theme）前请先预览，不同主题的页边距与标题样式差异较大。]

#custom-box(title: [重要], icon: "stop", color: rgb("#f74242"))[
  这行文字用于演示自定义标题与颜色的提示框；Bookly 允许通过 `custom-box` 定义任意风格。
]

#proof-box[
  设 $a, b, c$ 为直角三角形三边，其中 $c$ 为斜边。由勾股定理 $a^2 + b^2 = c^2$ 可直接验证三边关系，证明略。
]

#custom-box(title: [思考], icon: "question", color: purple)[
  若需要竖排正文、注音符号或中日韩标点挤压，应改用专门的中文排版方案。
]
