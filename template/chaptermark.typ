// ============================================================
// 章首页的装饰章号（chapter mark）
// ------------------------------------------------------------
// 章首页（含附录）只有标题、导语和内容小目录，下半页空着。这里在章首页
// 右上角印一枚放大的空心章号，与篇章页（partpage.typ）那枚篇次数字同一套
// 语言——「篇」用大号、「章」用小一号，读者一眼就能认出两级结构。
//
// 为什么画在页面背景里，而不是给标题加 show 规则：Bookly 的章标题整块由
// 主题的 show 规则渲染，外面再加一条 show heading 规则会把整块标题顶掉
// （模板里踩过这个坑）。画在背景层既不动主题，也不会挤动正文。
//
// 只画在「本页有编号一级标题」的页面上：分部页、前言、摘要、参考文献
// 这些无编号标题不会有章号，空白衬页也不会。
// ============================================================

#import "@preview/bookly:5.1.1": *

// 与 partpage.typ 的底纹数字同一处理：空心字（浅色描边、白色字身），
// 描边取主题红调淡，与红标、章题同源。
#let chapter-mark-size = 7em
#let chapter-mark-dy = 1.2cm // 自版心顶端下移的距离：与「第 N 章」＋章题那一块齐平

// 背景层里 place 的基准是**纸张**（切口色标就是靠这一点贴到纸边的），
// 而章号要对齐版心右缘，所以要减掉一个页边距。
// 订口/切口边距（inside/outside）在 main.typ 里设置，这里定义并导出数值，
// 改边距只需改这一处。天头/地脚仍是 Typst 的 auto：「2.5cm」与
// 「短边 × 2.5/21」中的较小值（a4 = 2.5cm、a5 ≈ 1.76cm）——改过的话
// auto-margin 也要跟着改。
#let margin-inside = 2.8cm // 订口：装订侧留多一些
#let margin-outside = 2.2cm // 切口：翻阅侧留窄一些，版心宽度与原先 2.5+2.5 相同

#let paper-short-side = (a4: 21cm, a5: 14.8cm)
#let auto-margin(paper) = {
  let short = paper-short-side.at(paper, default: 21cm)
  let preferred = 2.5cm
  let proportional = short * 2.5 / 21
  if proportional < preferred { proportional } else { preferred }
}

// 某页的右侧（right）边距：奇数页右侧是切口，偶数页右侧是订口
#let right-margin(pg) = if calc.odd(pg) {
  margin-outside
} else {
  margin-inside
}

// 章号文字：取标题编号图案的第一段渲染（"1.1." → "3"，"A.1." → "C"），
// 普通章得数字、附录章得字母，且不依赖对编号图案写法的假设。
// 与 pagetabs.typ 的切口色标共用（那里 import 本函数）。
#let chapter-label(h) = numbering(
  h.numbering.split(".").first(),
  counter(heading).at(h.location()).first(),
)

#let chapter-mark = context {
  let pg = here().page()

  // 本页有没有「有编号的一级标题」＝本页是不是章首页
  let heads = query(selector(heading.where(level: 1))).filter(h => (
    h.numbering != none and h.location().page() == pg
  ))
  if heads.len() == 0 { return }

  let h = heads.first()
  let label = chapter-label(h)

  place(
    top + right,
    dx: -right-margin(pg),
    dy: auto-margin(states.paper-size.get()) + chapter-mark-dy,
    text(
      font: ("Arial", "SimHei"),
      size: chapter-mark-size,
      weight: "regular",
      fill: white,
      stroke: 1pt + states.colors.get().primary.lighten(72%),
    )[#label],
  )
}
