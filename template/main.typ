// Typst 中文书籍样板 —— 基于 Bookly 模板
//
// 编译：typst compile main.typ 中文书籍样板.pdf
// 存档级导出（PDF/A-2b，投图书馆/长期保存用）：
//   typst compile main.typ 中文书籍样板.pdf --pdf-standard a-2b
// 无障碍（PDF/UA-1）目前不可用：它要求每个公式（含行内 $…$）都带 alt 文本，
// 行内公式无处安放 alt，需改写成 #math.equation(block: false, alt: […])。
// 文档：https://typst.app/universe/package/bookly

// 关于收敛告警：本书内容较多，若出现
//   warning: document did not converge within five attempts
//   （通常伴随 marginalia 的 state 提示），说明某处版面在多次排版之间来回摆动，
//   多由「不跨页的提示框正好卡在页尾」引起。经验做法是微调该处内容或挪动小节位置
//   （实测挪一节的位置即可恢复收敛），输出 PDF 本身不受影响。
#import "@preview/bookly:5.1.1": *
#import "pagetabs.typ": page-tab, page-tab-off
#import "partpage.typ": part-page, toc-part-entry
#import "chaptermark.typ": chapter-mark, margin-inside, margin-outside
#import "runninghead.typ": book-header
#import "boxes.typ": book-boxeq, book-custom-box

// 模板版本：scripts/doctor.py 用它判断书稿项目里的这份拷贝是否落后于技能模板。
// 旧拷贝可能缺已修复的规则（如「表题在表格上方」），开工前先跑 doctor 体检。
#let template-version = "2026-09-23"

// ---- 标题页（封面 + 版权页）----
// 外面套一层 set par：Bookly 的标题页是在本文档的作用域里生成的，正文那条
// 2em 首行缩进会漏进标题页——封面四行文字本该左缘对齐，加上缩进后「作者姓名」
// 比上面三行多出半格，整块标题也被推右了几毫米。
// 版权行还带一个西文逗号与句点（Bookly 源码里写死的「, 2026.」），
// 中文该写成「© 作者姓名　2026」，这里用 show regex 拦下来改写。
#let title-page = {
  set par(first-line-indent: 0em)
  show regex("[,，]\\s*\\d{4}\\."): it => {
    // 匹配到的文本形如「, 2026.」：留下数字，丢掉逗号句号
    let year = it.text.clusters().filter(c => c >= "0" and c <= "9").join()
    [　#year]
  }
  book-title-page(
    subtitle: "基于 Bookly 模板的成书样板",
    edition: "第一版",
    series: "Typst 排版系列",
    institution: "Typst 中文社区",
    logo: image("images/typst-logo.svg", alt: "Typst 标志"),
    cover: image(
      "images/book-cover.jpg",
      width: 45%,
      alt: "样板封面插图：科技感的圆形声波图案",
    ),
    show-cover-author: true,
    version-usage: "本样板演示中文书籍的完整排版流程：封面、目录、篇章结构、图表公式、脚注、参考文献与附录均已配置就绪，可直接替换为你的内容。",
  )
}

#show: bookly.with(
  title: "Typst 中文书籍排版",
  author: "作者姓名",
  fonts: (
    size: 10.5pt,
    body: ("New Computer Modern", "Noto Serif SC", "SimSun"),
    math: "New Computer Modern Math",
    raw: "DejaVu Sans Mono",
  ),
  theme: (
    part: part-page, // 分部页换成自定义版式（见 partpage.typ）
    custom-box: book-custom-box, // 内置提示框换成统一框体（见 boxes.typ）
    boxeq: book-boxeq, // 加框公式也换成同一套框体（见 boxes.typ）
  ), // 其余沿用 classic 主题
  lang: "zh",
  title-page: title-page,
  config-options: (
    open-right: true, // 章首从右页（奇数页）开始
    par-indent: true,
    paper-size: "a4", // 图书开本，可改为 "a5"
    alt-margins: false, // 是否启用 Tufte 旁注版式的交替边距（本书未用旁注，保持关闭）
  ),
)

// 装订书的左右边距不对称：订口（装订侧）宽、切口（翻阅侧）窄，
// 两侧之和与原先的对称 2.5cm + 2.5cm 相同，版心宽度不变。
// 数值定义在 chaptermark.typ（章号定位要用），改边距去那里改。
// 天头地脚未设，沿用 Typst auto 的 2.5cm。
#set page(margin: (inside: margin-inside, outside: margin-outside))

// 中文排版惯例：正文首行缩进两个汉字宽度（Bookly 默认 1.5em）
#set par(first-line-indent: (amount: 2em, all: true))

// 图注标签本地化：Bookly 把 image 类插图的 supplement 写死为英文 Figure
// （见 bookly-defaults.typ 的 fig-supplement；表格的「表」由 Typst 按语言
// 自动本地化，不受影响）。这里用定向 set 规则改回「图」。
// 注意不要用字符串替换 #show "Figure": [图]——它会连 raw 代码块和英文
// 引文里的 "Figure" 一起改写。
// 唯一的例外是 subfigure：它的 supplement 在 Bookly 定义处就绑定死了，
// set 规则够不着，需要用 boxes.typ 里的 subfigure-zh 代替。
#show figure.where(kind: image): set figure(supplement: [图])

// 插图保护：不设 width 的 image 按自然尺寸渲染（1 像素 = 1pt），随手插入的
// 截图动辄远超版心，向右冲出页面、盖住页边距。这里把「不设宽度且自然宽度
// 超过当前位置可用宽度」的图等比缩到刚好放下（用 scale 而不是重建 image：
// 相对路径按原文件解析，换了文件重建会解析错位置）。显式写了 width 的图
// 一律不动——有意设置哪怕超宽也尊重；想全宽就明写 width: 100%。
#show image: it => layout(sz => context {
  if it.width != auto { return it }
  let w = measure(it).width
  if w <= sz.width { return it }
  let f = (sz.width / w) * 100%
  scale(it, x: f, y: f)
})

// 中文排版惯例：正文思源宋体（Noto Serif SC）、标题与强调用黑体。
// 注意：字体链中不要放入只安装了单一粗字重的字体族（例如仅装 Heavy 的思源宋体），
// 否则 Typst 找不到常规字重时会退回该粗字重，导致正文整体显示为特粗。
// 标题里的西文单独指定无衬线字体：Typst 的标题自带 bold，若让西文走
// New Computer Modern，字重落在它的粗体上，衬线明显、笔画对比强，
// 挨着黑体像是另一个年代的字；换成 Arial（SimHei 自带的西文也是同族的无衬线）后，
// 「Typst 语言速览」这种中英混排的标题才是一整块黑。
// 链尾的 Noto Sans SC 是给非 Windows 系统的兜底（SimHei 是 Windows 字体）。
#show heading: set text(font: ("Arial", "SimHei", "Noto Sans SC"))
#show table.cell.where(y: 0): set text(font: (
  "New Computer Modern",
  "SimHei",
  "Noto Sans SC",
))

// ---- 行内样式：中文与西文分别按各自惯例处理 ----
// 加粗：中文用思源宋体的粗体字重（笔画加粗、字形不变），系统没有该字体时回退黑体；
// 西文用 New Computer Modern 的粗体。注意不要用「换成黑体」冒充加粗——
// 那是换字体，不是加粗，删掉黑体字重后会失效。
#show strong: set text(font: ("New Computer Modern", "Noto Serif SC", "SimHei"))

// 强调（斜体）：汉字没有斜体字形，直接套用斜体只会得到正体，
// 因此中文改用楷体（中文书籍的强调传统），西文仍用 New Computer Modern 的斜体。
// KaiTi/STKaiti 分别是 Windows/macOS 的楷体；链尾的思源宋体是 Linux 兜底——
// 楷体缺失时宁可退回正文字体（强调效果丢失），也不让 Typst 在系统字体里乱挑。
#show emph: set text(font: (
  "New Computer Modern",
  "KaiTi",
  "STKaiti",
  "Noto Serif SC",
))

// 下划线：抬高与字身的距离，并在标点、下伸笔画处自动避让，避免与字形相碰。
#show underline: set underline(offset: 0.13em, evade: true, stroke: 0.7pt)

// 删除线：同样抬高，避免压在字身上。
#show strike: set strike(offset: 0.22em, stroke: 0.7pt)

// 章／附录标题整体缩小到 0.7 倍：Bookly 默认标题为 2em（21pt），
// 对 10.5pt 的正文偏大。标题内的字号都是相对值（1.5em / 2em），
// 所以在标题作用域里缩小基础字号即可等比缩放整块标题。
#show heading.where(level: 1): set text(size: 0.7em)

// 代码与公式里的中文：必须显式补中文字体回退。
// 否则这两处的字体是纯西文的，Typst 会在系统字体里随机挑选（实测会落到隶书 LiSu）。
#show raw: set text(font: ("DejaVu Sans Mono", "Noto Serif SC"))
#show math.equation: set text(font: (
  "New Computer Modern Math",
  "Noto Serif SC",
))

// ---- 表格：统一列对齐，禁止单元格两端对齐 ----
// 列默认左对齐，需要居中的列（公式、图标、数字）在各自的 table 里单独指定；
// 早先不设这一条，各表的列对齐由行文环境决定，结果表 1.1 是「左/中/右」、
// 表 C.1 是「左/左/左」、表 D.1 是「中/中/左」，同一本书三套规矩。
#set table(align: (left, left, left))
// 列与列之间留点气口：不设列间距时图标列会顶到下一列的文字上
// （表 C.1 的「▮ 定义 | 章内编号」最明显）。用单元格内边距而不是 column-gutter：
// Typst 会把 table 的 stroke 画进 gutter 里，一加 gutter 就多出竖线，
// 三线表就破了；内边距只是留白，不动线。首列不加左内边距，表格左缘仍与正文对齐。
#show table.cell: set table.cell(inset: (x: 0.5em, y: 0.15em))
#show table.cell.where(x: 0): set table.cell(inset: (left: 0pt, right: 0.5em, y: 0.15em))
// 窄格里两端对齐会把最后一行撑开（表 F.1 的「……材质都在源码里调」就是），
// 逐格关掉：表格里的文字本来就该左齐、右边自然参差。
#show table.cell: set par(justify: false)

// ---- 题注与目录条目 ----
// 中文题注惯例是「图 1.1　标题」，用的是全角空格，不是西文的连接号
// （Bookly 默认给的是「–」，见 bookly 的 figure.caption(separator: [ -- ])）。
#show figure: set figure.caption(separator: [　])
// 表题在上、图题在下（中文技术文档惯例）。表格的 auto 默认虽已是 top
// （Typst 0.12 起），仍显式写死——不依赖版本默认，也不给主题/外部包留改默认的空间；
// 图题保持 Typst 默认的 bottom，不走这条规则。
#show figure.where(kind: table): set figure.caption(position: top)
// 目录条目不该两端对齐：长条目被撑开后会留下孤零零的末行
// （图表目录里「图 2.3」那一条最明显）。
#show outline.entry: set par(justify: false)
// 图表目录里的图号不再跟一个西文句点（Bookly 的目录规则写的是「图 1.1. 标题」），
// 与页内题注、与中文惯例保持一致。
// 注意：这条规则一旦接管 figure 条目，前面的 set par(justify: false) 就轮不到它了，
// 所以这里要自己再设一次，否则长条目（如「图 2.3」）又会被两端对齐撑开。
// 目录里的「篇」行：整行铺主题浅底、左缘压一道主题红，与篇章页同一套语言
// （版式见 partpage.typ 的 toc-part-entry）。判断是不是篇行用 states.is-toc-part，
// 那枚隐形标题由 part-page 写在篇章页开头，与 pagetabs.typ 判断分部页是同一招。
// 注意这条要排在下面 figure 分支之前判断：篇行的 element 也是标题，不是图形。
#show outline.entry: it => {
  if it.element.func() == figure {
    set par(justify: false)
    block(above: 1.25em, below: 0em)
    v(0.25em)
    link(it.element.location(), [#it.prefix()　#it.inner()])
  } else if it.level == 1 and states.is-toc-part.at(it.element.location()) {
    toc-part-entry(it)
  } else {
    it
  }
}

// 页面背景：切口色标 + 章首页的装饰章号（见 pagetabs.typ / chaptermark.typ）
#set page(background: {
  page-tab
  chapter-mark
})

// 书眉换成自己的一版：小节正好从页顶起步时改印章名（见 runninghead.typ）
#set page(header: book-header)

// 页码贴切口：奇数页（右页）靠右、偶数页（左页）靠左。成书的惯例，也让全书
// 「外侧」的语言统一——切口色标、章号本来就都在外侧。Bookly classic 的页脚
// 是居中，这里接管；页码图案不动（前置部分罗马数字、正文阿拉伯数字，由
// front-matter / main-matter 设置，counter.display() 会跟着走）。
// 篇章页、封面、封底自己关了页脚，不受影响。
#set page(footer: context {
  let pg = counter(page).at(here()).first()
  set align(if calc.odd(pg) { right } else { left })
  counter(page).display()
})

#show: front-matter

// 界面标签本地化：章名前缀用「第」（语言包默认「章节 N」，后缀「章」
// 在 main-matter 之后由 num-heading 补上）；插图目录改叫「插图目录」
// （语言包的「图表目录」名不副实——它只列图，表另有一页「表格目录」）。
// 必须写在前置部分渲染之前：插图目录在前置部分里生成，更新写晚了轮不到它。
#states.localization.update(l => (..l, chapter: "第", lof: "插图目录"))

// 前置部分整段不印页眉。Bookly 的约定是「一级标题所在的那一页不印页眉，续页才印」，
// 于是前言、摘要、图表目录这些单页小节本来就是光的，只有跨两页的目录第二页带着
// 页眉「目录」——同一段里唯独一页有页眉，翻页时反而更跳。前置部分整体做光，
// 正文部分再恢复书眉（那里章首页光、续页有眉，本来就是自洽的）。
// 用一层代码块把 set 圈住：set page 一旦写在流程里就会一直管下去，
// 不圈起来会连正文的书眉一起关掉。
#{
  set page(header: none)
  include "front_matter/front_main.typ"
  tableofcontents
  listoffigures
  listoftables
}

#show: main-matter

// 章号后缀补「章」字：必须在 main-matter 之后更新——main-matter 会把
// num-heading 重置为 "1"，写早了会被覆盖掉
#states.num-heading.update(n => n + " 章")

#part-page(
  [入门篇],
  desc: [先交代写作环境与全书结构，再速览 Typst 的语言核心：标记与代码两种模式、数学公式、表格与子图，以及提示框与代码框的用法。],
)

#include "chapters/intro.typ"

#include "chapters/ch1.typ"

#part-page(
  [实践篇],
  desc: [把零散的元素组合成完整版面：行内样式、列表、引用、脚注与交叉引用，再到插图、绘图与编号环境，最后交代把本书内容搬进正式项目的方法。],
)

#include "chapters/ch2.typ"

#include "chapters/conclusion.typ"

#show: appendix

#include "appendix/app_main.typ"

// 参考文献用国标 GB/T 7714（Typst 自带该 CSL 样式）
#page-tab-off()

#bibliography("bibliography/sample.bib", style: "gb-7714-2015-numeric")

#back-cover(
  abstracts: (
    (
      title: [内容简介：],
      text: [本样板以 Bookly 模板为基础，演示中文技术书籍的排版要点——从篇章结构、图表公式，到字体配置与参考文献，帮助你把内容直接放进一套经过调校的版式中。],
    ),
  ),
  logo: (image("images/typst-logo.svg", width: 60%, alt: "Typst 标志"),),
)

