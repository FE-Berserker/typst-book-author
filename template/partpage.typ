// ============================================================
// 篇章页（分部页 / part page）
// ------------------------------------------------------------
// Bookly 自带的分部页只有居中两行字（「部分 N」＋篇名），整页八成留白，
// 翻到这里像翻到一张没排完的样张。这里改排成中文书籍常见的篇章页：
//
//   · 顶部：短红标、篇次、篇名，以及一段本篇导读
//   · 中部：放大的空心篇次数字，把大片空白变成版面的一部分
//   · 底部：「本篇内容」小目录，自动列出本篇的章与节，带引导点与页码
//   · 整页：铺主题浅底，翻到这一页就是「新的一篇开始」
//
// 同时提供目录里的「篇」行版式 toc-part-entry：整行铺浅底、左缘压一道主题红，
// 让篇在目录里也能一眼认出来（接线在 main.typ 的 outline.entry 规则里）。
//
// 用法（main.typ）：
//   #import "partpage.typ": part-page, toc-part-entry
//   #show: bookly.with(… theme: (part: part-page) …)
//   #part-page([入门篇], desc: [本篇导读……])
//
// 导读写一两句话就好（两三行以内）：版面按版心高度定死，不随内容伸缩，
// 写长了会压到底部的小目录上。
//
// 把 part-page 挂进 theme 之后，#part([入门篇]) 这种 Bookly 原生写法
// 也会走这套版式（只是没有导读），所以模板原有的用法不会失效。
//
// 小目录靠 query 现算，范围是「本页之后、下一个分部页或附录之前」，
// 增删章节无需手工维护；篇幅不大的篇连节一起列出，让版面饱满，
// 条目过多（超过 pp-max-entries）则只列章，免得目录把页面撑破。
// ============================================================

#import "@preview/bookly:5.1.1": *
#import "colors.typ": book-colors

// ---- 配色：与 boxes.typ / figstyle.typ / pagetabs.typ 同源（见 colors.typ）----
#let pp-colors = book-colors

// 标题字体：与正文标题同一套（黑体 + 无衬线的西文，见 main.typ 的说明）
#let pp-head-font = ("Arial", "SimHei")

#let pp-max-entries = 16 // 小目录 entry 数的上限，超过就只列章（见 pp-contents）

// 底纹数字：空心字（浅色描边、字身透明）。实心大字在纸上会糊成一团灰，
// 空心只有一个轮廓，既能占住版面又不会与正文抢注意力；描边取主题红调淡，
// 与红标、章题同源。
// 字身用全透明的白而不是 white：篇章页如今整页铺了主题浅底（见 part-page 里的
// set page(fill:)），填白的数字会变成纸上一个白块，只有透明字身才真是「空心」。
// （text 的 fill 不接受 none，要用 alpha 为 0 的颜色。）
#let pp-ghost(num) = text(
  font: pp-head-font,
  size: 17em,
  weight: "regular",
  fill: rgb(255, 255, 255, 0),
  stroke: 1pt + pp-colors.primary.lighten(72%),
)[#num]

// 本篇小目录
#let pp-contents() = context {
  let cur = here()
  let after(sel) = query(sel.after(cur, inclusive: false))
  let h1 = after(selector(heading.where(level: 1)))
  // 本页之后的第一枚「分部页标记」或附录首章，就是本篇的边界。
  // 注意不能只找分部页：末篇之后没有分部页，少了附录这层判断的话，
  // 附录会被算进末篇的小目录里。
  let stop = h1.find(h => (
    states.is-toc-part.at(h.location()) or states.isappendix.at(h.location())
  ))
  let in-part = h => (
    not states.isappendix.at(h.location())
      and (stop == none or h.location().page() < stop.location().page())
  )
  // entry 太多就把节收起来，只留章：这是防止长篇幅小目录顶穿版面的安全阀，
  // 具体多长算多，按 pp-max-entries 调。
  let h2 = after(selector(heading.where(level: 2)))
  let entries = h1.filter(in-part).len() + h2.filter(in-part).len()

  let target = selector(heading.where(outlined: true)).after(cur, inclusive: false)
  if stop != none {
    target = target.before(stop.location(), inclusive: false)
  }

  outline(title: none, target: target, depth: if entries > pp-max-entries { 1 } else { 2 })
}

// 篇章页本体。title 之外的参数都有默认值，这样才能直接挂进
// Bookly 的 theme 里（Bookly 只传 title 一个位置参数）。
#let part-page(title, desc: none) = context {
  states.counter-part.update(i => i + 1)
  let num = states.counter-part.get().first()
  let num-str = numbering(states.part-numbering.get(), num)
  // 篇次行文用中文惯例「第 1 篇」（Bookly 语言包的「部分 1」是翻译腔）；
  // 底纹数字仍只用 num-str，不带「篇」字
  let part-label = [第 #num-str 篇]

  set page(header: none, footer: none, numbering: none)
  set par(first-line-indent: 0em)

  if states.open-right.get() {
    pagebreak(weak: true, to: "odd")
  }

  // 满版浅底：整张纸铺主题浅色，翻到这一页就是「新的一篇开始了」，与白页的
  // 正文形成信号。写在换页之后是有意的——写在它前面的话，open-right 为凑奇偶
  // 补出来的那张空白衬页会跟着被染色，看着像印错了。
  set page(fill: pp-colors.tint)

  // 供目录用的隐形标题。必须排在正文之前：小目录以 here() 为起点，
  // 若把标题放在后面，它自己会被当成「下一个分部页」，目录就空了。
  // 标题体只在目录里出现（本页的标题被上面的 show heading: none 隐掉），
  // 所以版式（红字篇次 + 黑体篇名）直接写在这里，由 toc-part-entry 取用。
  // 篇名上方的留白改由 toc-part-entry 的 block(above:) 给：在这里塞一个 v(1em)
  // 会被一起涂进目录的色条里，变成条内的一段空行。
  show heading: none
  states.is-toc-part.update(true)
  heading(numbering: none)[
    #text(
      font: pp-head-font,
      size: 0.95em,
      fill: pp-colors.primary,
      tracking: 0.25em,
    )[#part-label]
    #h(0.8em)
    #text(
      font: pp-head-font,
      size: 1.05em,
      fill: pp-colors.ink,
      weight: "bold",
    )[#title]
  ]
  states.is-toc-part.update(false)

  // ---- 以下是可见版面 ----
  // 整页按版心高度撑开，头尾各占一端，中间留给底纹数字
  block(width: 100%, height: 100%)[
    // 底纹：放大的篇次数字，落在标题与页脚小目录之间的空当里。
    #place(
      horizon + right,
      dy: 0.2cm,
      pp-ghost(num-str),
    )

    #place(top + left, block(width: 100%)[
      #v(2.2em)
      #rect(width: 1.6cm, height: 3pt, fill: pp-colors.primary)
      #v(1.4em)
      #text(
        font: pp-head-font,
        size: 1em,
        fill: pp-colors.primary,
        tracking: 0.35em,
      )[#part-label]
      #v(0.55em)
      #text(
        font: pp-head-font,
        size: 2.7em,
        fill: pp-colors.ink,
        tracking: 0.12em,
      )[#title]
      // 导读：左侧一道主题红竖线，把这段话与上面的标题分开。
      // 没有传 desc 时连分隔线一起省掉，免得留下一条下面空无一物的横线。
      #if desc != none {
        v(1.6em)
        line(length: 100%, stroke: 0.5pt + pp-colors.hairline)
        v(1.3em)
        block(
          width: 86%,
          stroke: (left: 2pt + pp-colors.primary),
          inset: (left: 1em),
        )[
          #text(size: 0.95em, fill: pp-colors.muted)[#desc]
        ]
      }
    ])

    #place(bottom + left, block(width: 100%)[
      #v(1.2em)
      #text(font: pp-head-font, size: 0.95em, tracking: 0.25em)[本篇内容]
      #v(0.45em)
      #line(length: 100%, stroke: 0.75pt)
      #v(0.7em)
      #pp-contents()
      #v(0.7em)
      #line(length: 100%, stroke: 0.75pt)
      #v(1.8em)
    ])
  ]
}

// ============================================================
// 目录里的「篇」行（供 main.typ 的 outline.entry 规则调用）
// ------------------------------------------------------------
// 篇名不再和章条目一样只靠一行空行分隔：整行铺主题浅底、左缘压一道主题红，
// 在目录里一眼就能认出「这是新的一篇」。版式上与篇章页同源（红字篇次 + 黑体
// 篇名，见上面隐形标题里的写法），页码留在右端，整条可点击跳转。
//
// 条目内容由 partpage.typ 的隐形标题提供，这个函数只管版式；判断哪一条是篇行
// 由 main.typ 的规则负责（states.is-toc-part，与 pagetabs.typ 同一招）。
// ============================================================
#let toc-part-entry(it) = {
  set par(justify: false)
  block(above: 1.8em, below: 1em, width: 100%)[
    #link(
      it.element.location(),
      box(
        width: 100%,
        fill: pp-colors.tint,
        stroke: (left: 3pt + pp-colors.primary),
        inset: (left: 0.9em, right: 0.7em, y: 0.5em),
        radius: 2pt,
      )[
        #grid(
          columns: (1fr, auto),
          column-gutter: 0.8em,
          align: (left + horizon, right + horizon),
          it.element.body,
          text(font: pp-head-font, fill: pp-colors.primary, weight: "bold")[#it.page()],
        )
      ],
    )
  ]
}
