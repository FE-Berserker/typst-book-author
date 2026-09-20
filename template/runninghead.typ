// ============================================================
// 书眉（running head）
// ------------------------------------------------------------
// Bookly classic 的书眉规则是「偶数页跟章名，奇数页跟小节名」，靠 hydra 取标题。
// 但 hydra 有一条内置规则：被跟踪的那一级标题如果正好在本页顶端开始，整页书眉
// 都不印，免得书眉与紧挨在下面的标题重复。于是像 2.6「图形与绘图」这种恰好
// 从页顶起步的小节，那一页顶端空着，夹在前后两页都有书眉的页面之间很扎眼。
//
// 这一版接管页眉：奇偶规则不变，只加一条回退——小节从页顶起步时改印章名，
// 书眉不断，翻页时页面顶端的家具是连续的。（章首页依旧不印，那一页有大字标题，
// 而且 Bookly 在标题处就把页眉关掉了，这里也碰不到。）
// 另外把文字改成贴切口对齐（奇右偶左），与页码同侧——classic 主题是恒定左对齐，
// 那样偶数页书眉与页码同在外侧，奇数页却一左一右，翻页时不齐。
//
// 接管意味着这里的样式要跟着 Bookly 走：文字沿用当前正文样式，细线 0.75pt、
// 宽 100%、下沉 12%，末尾留 0.5em，与 classic 主题的页眉一致。
// （tufte 布局的宽页眉没有照搬——本书没用 tufte；要用 tufte 的话这里得补上
// 那支 wideblock，否则页眉在宽页边距下会缩在正文栏里。）
// ============================================================

#import "@preview/bookly:5.1.1": *
#import "chaptermark.typ": auto-margin // 「版心从哪里开始」的算法与章号模块共用

// 本页是不是「某一级标题正好从页顶开始」。
// 写成普通函数（不加 context 包装），由调用处的 context 提供 here() 与 query 的上下文
// —— Bookly 自己的 is-chapter-page() 就是这个写法；加 context 包装反而不行：
// Typst 会把它的返回值当成内容，`if` 里就用不了了。
#let starts-at-top(level) = {
  let pg = here().page()
  let heads = query(selector(heading.where(level: level))).filter(h => (
    h.location().page() == pg
  ))
  if heads.len() == 0 { return false }
  heads.first().location().position().y <= auto-margin(states.paper-size.get())
}

#let book-header = context {
  set par(first-line-indent: 0em)
  show metadata.where(label: <bookly-title>): it => it.value.short
  show linebreak: none

  // 偶数页跟章名（一级标题），奇数页跟小节名（二级标题）；
  // 小节正好从页顶起步时退回章名
  let level = if calc.odd(here().page()) { 2 } else { 1 }
  if starts-at-top(level) { level = 1 }

  // 书眉贴切口：奇数页（右页）靠右、偶数页（左页）靠左，与页码同在一侧。
  // 注意那条通栏细线不能跟着文字走：它由 place 单独铺在整块上，
  // 所以这里只动 align 的目标，线的长度仍是版心的 100%。
  align(
    if calc.odd(here().page()) { right } else { left },
    hydra(level, display: (_, it) => [
      #let head = if it.numbering != none {
        numbering(it.numbering, ..counter(heading).at(it.location())) + " " + it.body
      } else {
        it.body
      }
      #head
      #place(dx: 0%, dy: 12%)[#line(length: 100%, stroke: 0.75pt)]
    ]),
  )
  v(0.5em)
}
