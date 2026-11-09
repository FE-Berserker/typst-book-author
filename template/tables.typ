// 跨页长表
//
// 问题：figure 默认是「不可断」的块。长表包进 #figure(…) 以后，一页放不下时
// Typst 不会把表拆到下一页，而是把整块推到新页继续排——超出页面的行被画在
// 页面之外（PDF 文本层里还在，打印与屏显都看不见）。版面看上去只是「表变短了」，
// 行是静默丢的。实测：60 行放进 figure，页面上只印出 22 行，其余 38 行不见，
// 页数也不增加，很容易漏过去。
//
// 修好它要两件事一起做：
//   1. 让 figure 可以断开：main.typ 里那条
//      `#show figure.where(kind: table): set block(breakable: true)`
//   2. 让表头跟着每一段续画：table.header(…)——Typst 会在每段顶部重画表头
// 只做 1 会得到「续表没有表头」的表；只做 2 则根本没有续表，因为整块被推走了。
//
// long-table 把这两件事包成一次调用，并在函数自己作用域里再钉一次 breakable
// （不依赖调用方有没有保留 main.typ 的那条 set）。
//
// 章文件里要用它得自己 import（本模板的章节文件各自带 import，不共享主文件作用域）：
//   #import "../tables.typ": long-table

// ---- 表头跨行守卫 ----
// table.header 会被整段复制到每一段续表的顶部，所以表头里的跨行没有「下一行」
// 可以伸过去：Typst 0.15 不报错，直接把 rowspan 丢掉，后面的表头格按顺序各左移
// 一格，单位行就落到错误的列下面（实测，见 references/pitfalls.md「表头跨行」）。
// 跨行只在正文行里生效。守卫把错位变成编译错误——错位的表看着像「内容挤在一起」，
// 比编译失败难查得多，也最容易在出片之后才被发现。
// main.typ 的表格重建规则也 import 这两个名字，两处共用一套判据与一条报错。
#let head-rowspan-msg = (
  "表格表头里不能跨行（rowspan 只在正文行生效）：table.header 会被复制到每页"
    + "续表顶部，跨行无处安放，Typst 会静默丢弃它，导致这一行后面的表头格各"
    + "左移一格、单元格落到错误的列下。单位行请并进表题，或用 table.cell(colspan: …) "
    + "合并成一格；确实要跨行合并，就把它写成正文的第一行，不要放进 table.header。"
)

#let table-head-takes-rowspan(kids) = kids.any(kid =>
  kid.func() == table.header and kid.children.any(c =>
    c.func() == table.cell and c.fields().at("rowspan", default: 1) != 1
  )
)

/// 跨页长表：可断 + 逐段重复表头 + 题注。
///
/// - columns: 列定义，与 #table 相同（必填）。
/// - head: 表头单元格内容组成的数组；空数组表示不要重复表头。
///   只能用 colspan 合并，不能有 rowspan——表头会被复制到每段顶部，
///   跨行无处安放，Typst 会静默丢弃它并让后面的表头格错列（守卫会报错）。
/// - caption: 题注；给了就按「表 x.y　题注」编号，可被 @标签 引用。
/// - cells: 其余单元格，与 #table 相同。跨行合并写在这里才生效。
///
/// 用法：
/// ```
/// #long-table(
///   columns: (auto, 1fr, 1fr),
///   head: ([列一], [列二], [列三]),
///   caption: [跨页长表的题注],
///   ..rows.flatten(),
/// )
/// ```
///
/// 关于「（续表）」标记：不作自动支持。要判断「这一段是不是第一段」只能靠
/// 记录表格起始页再与当页比较，而起始页会随分页变化——实测让整本书五轮
/// 不收敛（state did not converge）。需要标记的话，在表头最后一格里手写，
/// 但它会同时出现在第一段。
#let long-table(
  columns: none,
  head: (),
  caption: none,
  ..cells,
) = {
  if columns == none { panic("long-table: 必须给 columns") }
  // 表头只有一格时容易写成 head: table.cell(…)，没包数组；统一成数组再往下走，
  // 否则会在 head.len() 上抛 "element cell has no method len"。
  let head = if type(head) == array { head } else { (head,) }
  // 在构表之前拦一道，报错直接指向 head: 参数（main.typ 的重建规则还会兜一层）。
  if head.len() > 0 and table-head-takes-rowspan((table.header(..head),)) {
    panic(head-rowspan-msg)
  }
  let head-block = if head.len() > 0 { (table.header(..head),) } else { () }
  show figure.where(kind: table): set block(breakable: true)
  figure(
    kind: table,
    caption: caption,
    table(
      columns: columns,
      ..head-block,
      ..cells,
    ),
  )
}
