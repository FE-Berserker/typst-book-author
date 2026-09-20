// ============================================================
// 提示框样式（boxes）
// ------------------------------------------------------------
// 沿用 Bookly 提示框的框体外观（细边框、浅色底、左上角圆角标题牌），
// 图标换成 Heroicons 矢量图标（约 300 个可选，可缩放、可换色、无需装字体），
// 因此提示框类型可以按需自由扩充：
//   #definition-box[ … ]      #theorem-box[ … ]      #example-box[ … ]
// 图标名见 https://heroicons.com/；要自定义时用：
//   #callout(title: [标题], icon: "rocket-launch", color: rgb("#0ea5e9"))[ … ]
//
// 配色原则：框身一律用同一种极浅中性底，颜色只出现在标题牌和一道细边上。
// 早先每个类型的底、边、标题牌都上饱和度色，一页排六个框就是一页彩虹，
// 正文反倒被压住；现在类型靠图标与标题文字区分，版面安静得多。
// 同一套框体也接管 Bookly 内置框（#info-box / #tip-box / #warning-box …），
// 见文件末尾的 book-custom-box，它在 main.typ 里挂进 theme。
// ============================================================

#import "@preview/bookly:5.1.1": *
#import "@preview/heroic:0.1.2": hi
#import "colors.typ": book-colors

// 与正文图形、篇章页、切口色标共用一套配色（见 colors.typ）
#let box-colors = book-colors

// ---- 统一框体：三个调用点（callout / thm-env / proof）共用，改一处即全改 ----
#let box-body-fill = rgb("#f7f7f8") // 所有框共用的框身底色

#let box-frame(color) = (
  title-color: color,
  border-color: color.lighten(40%), // 细边比标题牌淡一档，不喧宾夺主
  body-color: box-body-fill,
  thickness: 1pt,
  radius: 3pt,
  body-inset: (top: 2em, left: 1em, right: 1em, bottom: 1em),
)

// 标题牌：挂在框线上，只有右下角一个圆角
#let box-tab-style = (
  boxed-style: (
    anchor: (x: left, y: horizon),
    offset: (x: -1em, y: 1.15em),
    radius: (
      top-left: 0pt,
      top-right: 0pt,
      bottom-left: 0pt,
      bottom-right: 5pt,
    ),
  ),
)

// 通用提示框：统一框体 + 矢量图标
#let callout(
  title: none,
  icon: "information-circle",
  color: box-colors.blue,
  // 短提示框默认整体不跨页：否则撞到页尾时会出现“标题留在上一页、
  // 正文跑到下一页、中间吊着空框”的难看结果。内容确实很长
  // （可能超过一页）时，显式传 breakable: true 允许跨页。
  breakable: false,
  body,
) = showybox(
  title: box-title(hi(icon, height: 1em, color: white), [*#title*]),
  title-style: box-tab-style,
  frame: box-frame(color),
  align: center,
  breakable: breakable,
)[#body]

// ---- 常用类型：中文标题 + 对应图标 ----
// 要点
#let keypoint-box = callout.with(
  title: [要点],
  icon: "light-bulb",
  color: box-colors.orange,
)
// 易错
#let pitfall-box = callout.with(
  title: [易错],
  icon: "bug-ant",
  color: box-colors.purple,
)
// 结论
#let conclusion-box = callout.with(
  title: [结论],
  icon: "flag",
  color: box-colors.teal,
)
// 公式
#let formula-box = callout.with(
  title: [公式],
  icon: "calculator",
  color: box-colors.blue,
)
// 参考
#let reference-box = callout.with(
  title: [参考],
  icon: "link",
  color: box-colors.gray,
)

// ============================================================
// 编号定理环境
// ------------------------------------------------------------
// 定义、定理、引理、推论、命题、例共用一套连续编号（定理 1、定理 2 …），
// 可用 @标签 交叉引用：
//
//   #theorem[勾股定理：……]<thm:pyth>
//   由定理 @thm:pyth 可得……
//
// 为什么是全书连续编号而不是「章号.章内序号」：后者需要在每章开头重置计数器，
// 而 Bookly 的章标题由主题的 show 规则渲染，外部再加 show 规则会把章标题块整个
// 顶掉（实测标题会消失）；改用 query 统计章内次序则会让文档多出一轮编译，
// 触发依赖库 marginalia 的收敛警告。连续编号只需读计数器，编译干净、引用稳定。
// ============================================================

#let thm-kind = "theorem-env"

#let thm-env(
  body,
  supplement: [定理],
  icon: "academic-cap",
  color: box-colors.red,
  title: none,
  breakable: false,
) = figure(
  kind: thm-kind,
  supplement: supplement,
  caption: none,
  outlined: false,
  numbering: "1",
  showybox(
    title: box-title(
      hi(icon, height: 1em, color: white),
      [*#supplement #context counter(figure.where(kind: thm-kind)).get().first()*#if title != none [　#title]],
    ),
    title-style: box-tab-style,
    frame: box-frame(color),
    align: center,
    breakable: breakable,
  )[#body],
)

#let definition = thm-env.with(
  supplement: [定义],
  icon: "book-open",
  color: box-colors.blue,
)
#let theorem = thm-env.with(
  supplement: [定理],
  icon: "academic-cap",
  color: box-colors.red,
)
#let lemma = thm-env.with(
  supplement: [引理],
  icon: "puzzle-piece",
  color: box-colors.purple,
)
#let corollary = thm-env.with(
  supplement: [推论],
  icon: "arrow-path",
  color: box-colors.teal,
)
#let proposition = thm-env.with(
  supplement: [命题],
  icon: "scale",
  color: box-colors.orange,
)
#let example = thm-env.with(
  supplement: [例],
  icon: "pencil-square",
  color: box-colors.green,
)

// 证明：不编号，结尾自动加 ∎（QED 符号，靠右对齐——正文以行间公式
// 结尾时，不加 h(1fr) 的话 ∎ 会掉到下一行左端）
#let proof(body, title: none) = showybox(
  title: box-title(
    hi("check-badge", height: 1em, color: white),
    [*证明#if title != none [（#title）]*],
  ),
  title-style: box-tab-style,
  frame: box-frame(box-colors.gray),
  align: center,
  breakable: false,
)[#body #h(1fr) #sym.qed]

// ============================================================
// 代码框与子图的本地化
// ------------------------------------------------------------
// code-box-zh：内置 code-box 的标题固定为英文 Code，这里换成中文「代码」，
// 颜色即内置 code-box 的紫色（与 box-colors.purple 同值）。
// subfigure-zh：内置 subfigure 的 supplement 在 Bookly 定义处就绑死为英文
// Figure，set 规则够不着，只能用 .with 重绑定（main.typ 的图注本地化
// 规则管不到它，见 main.typ 的说明）。
// ============================================================

#let code-box-zh = custom-box.with(
  title: [代码],
  icon: "code",
  color: box-colors.purple,
)

#let subfigure-zh = subfigure.with(supplement: [图])

// ============================================================
// 加框公式（#boxeq）
// ------------------------------------------------------------
// Bookly 默认只给它一道 0.75pt 的直角细框，和旁边的提示框一比显得寒酸。
// 这里换成同一套框体（浅底、细边、圆角），只是不带标题牌。
// 通过 theme: (boxeq: book-boxeq) 挂进去，正文里的 #boxeq 写法不变。
// ============================================================

#let book-boxeq(body) = context _boxeq(
  stroke: 0.75pt + box-colors.gray.lighten(35%),
  fill: box-body-fill,
  radius: 3pt,
  inset: (x: 1em, y: 0.7em),
  body,
)

// ============================================================
// 接管 Bookly 内置提示框
// ------------------------------------------------------------
// Bookly 的 info-box / tip-box / warning-box / proof-box 等都是 custom-box
// 的偏应用（颜色写死在 bookly-themes.typ 里），而 custom-box 最终落到
// theme.custom-box。所以 main.typ 里写 theme: (custom-box: book-custom-box)
// 就能把内置框统一成上面这套框体，第 1 章那些演示文字一个字都不用改。
//
// 唯一做了改写的是「证明」：内置的证明框是青色（eastern），而本书自己的
// #proof 是灰色。同一个词在一本书里出现两种颜色，读者会以为印错了，
// 这里把青色也归到灰色。
// ============================================================

#let book-custom-box(
  title: none,
  icon: "info",
  color: box-colors.blue,
  breakable: true,
  body,
) = {
  let color = if color == eastern { box-colors.gray } else { color }
  showybox(
    title: box-title(
      color-svg("resources/images/icons/" + icon + ".svg", white, width: 1em),
      [*#title*],
    ),
    title-style: box-tab-style,
    frame: box-frame(color),
    align: center,
    breakable: breakable,
  )[#body]
}
