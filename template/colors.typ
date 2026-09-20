// ============================================================
// 全书配色唯一来源（colors）
// ------------------------------------------------------------
// boxes.typ（提示框）、figstyle.typ（插图）、partpage.typ（篇章页）、
// pagetabs.typ（切口色标）共用这一套色值：改这里一处，全书同步。
// 各模块仍保留自己的局部别名（box-colors / palette / pp-colors / tab-colors），
// 引用处代码不变。
// ============================================================

#let book-colors = (
  // 主题与正文
  primary: rgb("#c1002a"), // 主题红（封面、章题、红标）
  ink: rgb("#222222"), // 线条与文字
  muted: rgb("#8f8f8f"), // 次要线条、参考线、次要文字
  hairline: rgb("#d8d8d8"), // 细分隔线
  // 类型色（提示框、数据系列、切口色标共用）
  blue: rgb("#1d90d0"),
  red: rgb("#c1002a"), // 与 primary 同色
  green: rgb("#00a651"),
  orange: rgb("#e58b00"),
  purple: rgb("#9865ca"),
  teal: rgb("#0d9488"),
  gray: rgb("#6b7280"),
  // 浅底
  tint: rgb("#faf0f2"), // 主题色浅底
  tint-gray: rgb("#f2f2f2"),
  // 切口色标后段（第 7 章起；玫红的饱和度不能太低，否则黑白印刷难以分辨）
  navy: rgb("#1e3a8a"),
  brown: rgb("#92400e"),
  rose: rgb("#be185d"),
  sky: rgb("#0ea5e9"),
  olive: rgb("#4d7c0f"),
)
