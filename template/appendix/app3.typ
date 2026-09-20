#import "@preview/bookly:5.1.1": *
#import "../boxes.typ": *

= 提示框与图标样式 <app:boxes>

正文第 @ch:overview 章演示了 Bookly 内置的七类提示框。此外本书还预置了两组样式：*不编号提示框*用于强调、提醒与参考；*编号定理环境*用于定义、定理这类需要编号与交叉引用的内容。两组共用同一套配色与图标——图标取自 Heroicons（约 300 个，可缩放、可换色、无需安装字体）。

== 不编号提示框

不编号提示框沿用 Bookly 的框体外观，只把图标换成矢量图标，适合随手一放、不需要被引用的强调与备注。以下五类覆盖了最常见的场景。

#keypoint-box[
  要点框强调需要记住的结论。例如：正文用思源宋体、标题用黑体、公式用 New Computer Modern Math。
]

#pitfall-box[
  易错框提醒容易踩的坑。例如：把只装了单一粗字重的字体族放进字体链，会让整段文字显示为特粗。
]

#conclusion-box[
  结论框收束一段推理。例如：以上各类提示框共用同一套配色、线宽与圆角。
]

#formula-box[
  公式框突出关键公式，例如下面的高斯积分：

  $ integral_0^infinity e^(-x^2) dif x = sqrt(pi) / 2 $
]

#reference-box[
  参考框指向外部资料，例如：图标名称与预览可在 #link("https://heroicons.com/")[heroicons.com] 检索。
]

== 编号定理环境

定义、定理、引理、推论、命题、例共用一套连续编号，按全书出现顺序生成（定理 1、定理 2 …）。用 `@` 标签即可引用，引用处显示的数字与框上完全一致，插入或删除内容时自动重排。

#definition[
  把一段内容按语义分类并赋予统一外观的处理，称为*样式*。
]<def:style>

#theorem[（样式一致性）同一本书内，同类元素的字体、线宽与配色应当一致。]<thm:consistency>

#proof[
  设全书有 $n$ 类元素，每类各自指定样式。若每类样式互不相同，读者就要在 $n$ 套规则之间来回切换；把样式集中到 `figstyle.typ` 与 `boxes.typ` 之后，每类只剩一处定义，切换成本降为一次。
]

由定理 @thm:consistency 可知：改一处样式模块，全书同类元素随之更新；新增内容时也不必重复设置字体与线宽——这正是定义 @def:style 所指的"统一外观"。

#example[
  图 @fig:page-layout 与图 @fig:flow 分别由 CeTZ 与 Fletcher 绘制，但因为共用样式模块，线宽与配色完全一致。
]

#lemma[
  引理、推论与命题的用法与定义、定理相同，只是类型名不同。
]

#corollary[
  由定理 @thm:consistency 可直接推出：样式模块的真正服务对象，是以后要改样式的人。
]

#proposition[
  命题框适合陈述未必需要证明的判断，例如：编号环境的数量够用即可，不必求全。
]

== 全部类型一览

表 @tab:box-icons 汇总了本书预置的全部提示样式。

#figure(
  table(
    columns: (auto, auto, 1fr),
    table.header([样式], [编号], [适用场景]),
    [#hi("book-open", color: box-colors.blue) 定义],
    [全书连续],
    [术语与概念的界定],

    [#hi("academic-cap", color: box-colors.red) 定理],
    [全书连续],
    [命题与公式的陈述],

    [#hi("puzzle-piece", color: box-colors.purple) 引理],
    [全书连续],
    [为证明定理服务的中间结论],

    [#hi("arrow-path", color: box-colors.teal) 推论],
    [全书连续],
    [由定理直接推出的结论],

    [#hi("scale", color: box-colors.orange) 命题],
    [全书连续],
    [未必需要证明的判断],

    [#hi("pencil-square", color: box-colors.green) 例],
    [全书连续],
    [具体用例与操作步骤],

    [#hi("check-badge", color: box-colors.gray) 证明],
    [不编号],
    [推理过程，结尾自动加 ∎],

    [#hi("light-bulb", color: box-colors.orange) 要点],
    [不编号],
    [需要记住的结论],

    [#hi("bug-ant", color: box-colors.purple) 易错], [不编号], [常见错误与陷阱],
    [#hi("flag", color: box-colors.teal) 结论], [不编号], [推理过程的收束],
    [#hi("calculator", color: box-colors.blue) 公式], [不编号], [关键公式],
    [#hi("link", color: box-colors.gray) 参考], [不编号], [外部资料与出处],
  ),
  caption: [本书预置的提示样式一览],
) <tab:box-icons>

#tip-box[需要新的类型时：不编号的用 `callout.with(…)` 一行定义，编号的用 `thm-env.with(supplement: [类型名], …)` 一行定义，图标名可在 #link("https://heroicons.com/")[heroicons.com] 检索。Bookly 内置的七类（注释、提示、警告、重要、证明、问题、代码）仍然可用。]
