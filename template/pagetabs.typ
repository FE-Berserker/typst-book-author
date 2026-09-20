// ============================================================
// 切口色标（拇指索引 / thumb index / fore-edge tabs）
// ------------------------------------------------------------
// 每一章在页面的切口边印一枚彩色色块：颜色与纵向位置都随章次递增，
// 彩色印刷时看颜色、黑白印刷时看高低位置，都能立刻判断当前在第几章。
// 奇数页（右页）贴右边、偶数页（左页）贴左边，装订后正好都在切口一侧。
//
// 用法（main.typ 中）：
//   #import "pagetabs.typ": page-tab, page-tab-off
//   #set page(background: page-tab)
//   ……正文……
//   #page-tab-off()          // 封底之前关闭，避免封底也印色块
//   #back-cover(…)
//
// 只想让所有页面都贴右边（单面打印）时，把 outer-side-only 改成 false。
// ============================================================

// 需要读 Bookly 的状态：判断「本页是不是分部页」用的是 states.is-toc-part，
// 该状态只在分部页那枚隐形标题的位置为真（见 partpage.typ）。
#import "@preview/bookly:5.1.1": states
#import "colors.typ": book-colors
#import "chaptermark.typ": chapter-label

// 每章一色（章次超出时重复使用最后一个）：主题色打头，后接类型色循环。
// 循环自动跳过与主题色相同的一枚（如朱砂主题的 red 本就等于 primary），
// 换主题后无需回来维护这里的顺序。
// 灰色排在末位：饱和度太低，黑白与彩色都不易分辨，不宜靠前。
#let tab-colors = (
  book-colors.primary, // 第 1 章 · 主题色
  ..(book-colors.blue, book-colors.green, book-colors.orange,
     book-colors.purple, book-colors.teal, book-colors.navy,
     book-colors.brown, book-colors.rose, book-colors.sky,
     book-colors.olive, book-colors.gray)
    .filter(c => c != book-colors.primary),
)

#let outer-side-only = true

// 手动排除的物理页码（空白衬页等，见 page-tab 里的说明）。
// 当前值对应随附的示例内容；改动内容后空白页位置会移动，定稿前请重新核对。
#let tab-skip-pages = (22, 24, 30, 32, 34, 40, 44)

// 色块几何
#let tab-height = 1.05cm
#let tab-width = 6.5mm
#let tab-first-y = 1.5cm // 第一章色块的纵向位置
#let tab-step = 1.8cm // 每后一章下移的距离

#let tab-on = state("page-tab-on", true)

// 关闭色标（封底、版权页等不需要索引的页面之前调用）
#let page-tab-off() = tab-on.update(false)

#let page-tab = context {
  if not tab-on.get() { return }
  // 找到本页之前（含本页）最后出现的一级标题：那就是当前所属的章／附录
  // 判断「本页属于哪一章」必须用物理页号比较，不能用 here() 的位置查询：
  // 页面背景的 here() 解析在页面内容之前，用 before(here()) 会漏掉
  // 「本页刚开头的那一章」，导致色标比章次晚一页（第 2 章首页仍显示第 1 章）。
  let pg = here().page()
  let all-h1 = query(selector(heading.where(level: 1)))

  // 分部页（篇章页）不印色标：这类页面没有页眉页码，色标又是「上一篇末章」的，
  // 摆在角落里只会让人以为印错了。
  let on-part-page = all-h1.any(h => (
    h.location().page() == pg and states.is-toc-part.at(h.location())
  ))
  if on-part-page { return }

  // 手动排除页：open-right 自动插入的空白衬页没有页眉页脚页码，照理也不该
  // 有色标。但「本页是否空白」无法用查询稳定地自动判定（段落位置在逐轮排版
  // 之间摆动，par 查询会触发 convergence 告警），只能按物理页码手动列出。
  // 定稿前翻一遍 PDF，把空白衬页的物理页码（PDF 查看器里的页号）填进来即可。
  if pg in tab-skip-pages { return }

  // 只统计「有编号」的一级标题：分部页、前言、附录前的过渡页等无编号标题
  // 都是排版用的装饰性标题，不能当作章，否则色标会按页跳换。
  let heads = all-h1.filter(h => (
    h.numbering != none and h.location().page() <= pg
  ))
  if heads.len() == 0 { return } // 正文之前（封面、前言、目录）不印
  let idx = heads.len() - 1 // 第几章（0 起）

  // 章号文字：正文用数字，附录用字母
  let label = chapter-label(heads.at(idx))

  let col = tab-colors.at(calc.min(idx, tab-colors.len() - 1))
  let y = tab-first-y + idx * tab-step
  let on-right = not outer-side-only or calc.odd(pg)

  let block = rect(
    width: tab-width,
    height: tab-height,
    fill: col,
    radius: if on-right { (left: 2pt) } else { (right: 2pt) },
  )[
    #place(center + horizon, text(
      fill: white,
      size: 8pt,
      weight: "bold",
      label,
    ))
  ]

  if on-right {
    place(top + right, dx: 0pt, dy: y, block)
  } else {
    place(top + left, dx: 0pt, dy: y, block)
  }
}
