// ============================================================
// 全书配色唯一来源（colors）
// ------------------------------------------------------------
// 主题色由 book-theme 一行切换（主题表见 themes）：整本书的签名色
// （primary 与其浅底 tint）随之同步到篇章页、目录篇行、切口色标首页、
// 章号描边与数据系列首色。类型色（提示框、数据系列、切口色标的中段）
// 各主题通用，不随主题变——类型靠颜色区分，主题只换签名色。
// boxes.typ（提示框）、figstyle.typ（插图）、partpage.typ（篇章页）、
// pagetabs.typ（切口色标）共用这一套色值：改这里一处，全书同步。
// 各模块仍保留自己的局部别名（box-colors / palette / pp-colors / tab-colors），
// 引用处代码不变。
//
// SYNC: book-colors 的色值（primary/tint 取 book-theme 当前指向的主题）与
// typst-note-author/template/colors.typ 的 note-colors-base 相同，改色值要
// 同步改那边，否则两套模板的配色会悄悄漂移；
// typst-note-author/scripts/check_sync.py 可机检。
// ============================================================

// ---- 主题：换主题色只改这一行（可选值见下方 themes 表的键）----
#let book-theme = "cinnabar"

#let themes = (
  // 朱砂（默认）：经典中文技术书主题红
  cinnabar: (primary: rgb("#c1002a"), tint: rgb("#faf0f2")),
  // 靛蓝：沉稳的深蓝，教材与学术书气质
  indigo: (primary: rgb("#2b4c9b"), tint: rgb("#eef2fa")),
  // 松绿：偏墨的深绿，自然科学与环保类
  pine: (primary: rgb("#1a7a4a"), tint: rgb("#eef6f0")),
  // 赭石：暖棕，人文与历史类
  ochre: (primary: rgb("#a0521b"), tint: rgb("#faf3ec")),
  // 紫棠：深紫，设计与社科类
  zitan: (primary: rgb("#6d28d9"), tint: rgb("#f5f0fb")),
  // 石墨：蓝灰，冷静的工具书气质
  graphite: (primary: rgb("#334155"), tint: rgb("#f1f5f9")),
)

#let book-colors = (
  // 主题与正文
  primary: themes.at(book-theme).primary, // 主题色（封面、章题、篇行红标）
  tint: themes.at(book-theme).tint, // 主题色浅底
  ink: rgb("#222222"), // 线条与文字
  muted: rgb("#8f8f8f"), // 次要线条、参考线、次要文字
  hairline: rgb("#d8d8d8"), // 细分隔线
  // 类型色（提示框、数据系列、切口色标共用）
  blue: rgb("#1d90d0"),
  red: rgb("#c1002a"), // 定理环境用红，各主题保持一致（默认主题恰与 primary 同色）
  green: rgb("#00a651"),
  orange: rgb("#e58b00"),
  purple: rgb("#9865ca"),
  teal: rgb("#0d9488"),
  gray: rgb("#6b7280"),
  // 浅底
  tint-gray: rgb("#f2f2f2"),
  // 切口色标后段（第 7 章起；玫红的饱和度不能太低，否则黑白印刷难以分辨）
  navy: rgb("#1e3a8a"),
  brown: rgb("#92400e"),
  rose: rgb("#be185d"),
  sky: rgb("#0ea5e9"),
  olive: rgb("#4d7c0f"),
)
