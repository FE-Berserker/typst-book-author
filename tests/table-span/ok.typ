// 回归：正文行的跨行 / 跨列是必须能用的写法。
// 这条用例若编译失败，说明守卫误伤了合法表格（判据写成「有 rowspan 就报错」了）。
//
// 对照 head-rowspan.typ（必须编译失败）。
// 只 import tables.typ，不碰 main.typ：后者要拉整本书的章文件，回归用例不该依赖它们。
#import "../../template/tables.typ": long-table

#set page(width: 150mm, height: auto, margin: 8mm)

== 表头只用 colspan（单格 head 也要能过）

#long-table(
  columns: (auto, 1fr, 1fr),
  head: table.cell(colspan: 3)[单位：mm],
  caption: [表头用 colspan 合并单位格],
  [试件 1], [50.0], [24.8],
)

== 跨行写在正文行

#long-table(
  columns: (auto, 1fr, 1fr),
  head: ([类别], [内容], [值]),
  caption: [跨行在正文行],
  table.cell(rowspan: 2)[甲类],
  [第一行写长一点，让它折行，检验行高是否跟着长。],
  [1],
  [第二行同样写长一点，检验跨行格是否覆盖两行。],
  [2],
  [乙类], [普通行], [3],
)
