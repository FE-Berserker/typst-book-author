# 常见定制任务

按任务找对应小节。所有路径以 template/ 为根。改之前若涉及模块间接线，
先读 design.md 对应小节。

## 换主题色

整本书的主题色由 `colors.typ` 顶部的 `book-theme` 一行切换，内置六个主题：

| 主题 | 键名 | primary | 气质 |
| --- | --- | --- | --- |
| 朱砂（默认） | `cinnabar` | `#c1002a` | 经典中文技术书主题红 |
| 靛蓝 | `indigo` | `#2b4c9b` | 沉稳深蓝，教材与学术书 |
| 松绿 | `pine` | `#1a7a4a` | 偏墨深绿，自然科学与环保类 |
| 赭石 | `ochre` | `#a0521b` | 暖棕，人文与历史类 |
| 紫棠 | `zitan` | `#6d28d9` | 深紫，设计与社科类 |
| 石墨 | `graphite` | `#334155` | 蓝灰，冷静的工具书 |

切换后签名色（篇章页、目录篇行、切口色标首页、章号描边、数据系列首色）
全书自动同步，各主题自带配套浅底 tint。

- **自定义主题**：往 `themes` 表加一行 `(primary: rgb("#…"), tint: rgb("#…"))`，
  再把 `book-theme` 指过去。tint 取 primary 极浅的色洗（大约 95% 以上亮度），
  保证深色文字与空心数字描边在其上清晰可读；
- 类型色（提示框的蓝/绿/橙…、定理红）各主题通用，不随主题变——
  类型靠颜色区分，主题只换签名色；
- 切口色标循环自动以主题色打头、跳过与主题色相同的类型色，无需维护；
- 换非默认主题时建议一并换 `images/book-cover.jpg`（默认封面图按朱砂红调）。

微调类型色、后段切口色时同样只改 `colors.typ`：各模块顶部的
`box-colors` / `palette` / `pp-colors` / `tab-colors` 只是别名，不用动。
类型色与后段色的饱和度不能太低——黑白印刷时低饱和度颜色难分辨。

## 换开本（a4 → a5）

`main.typ` 里 `paper-size: "a5"`。左右边距是固定 cm 值（见下节）不用动；
天头地脚走 auto 会自动按比例缩小（chaptermark.typ 的 auto-margin 复现了
该算法并已处理 a5）。换完翻一遍 PDF：章号大小（7em 相对值）与篇章页
版面是按版心高度撑的，一般无需调。

## 调页边距

`chaptermark.typ` 的 `margin-inside`（订口 2.8cm）/ `margin-outside`
（切口 2.2cm）。定义在这里而不是 main.typ，是因为章号定位要减右侧页距；
main.typ import 这两个值去 set page，改一处即可。注意两侧之和决定版心
宽度，只改一侧会变版心。若改过天头/地脚（不再是 auto），`auto-margin()`
也要跟着改，否则章号与书眉判断会错位。

## 扩充提示框类型

`boxes.typ` 里加一个 `callout.with(...)` 偏应用：

```typst
#let exercise-box = callout.with(
  title: [练习],
  icon: "pencil",        // 图标名见 https://heroicons.com/
  color: box-colors.green,
)
```

编号定理环境同理（`thm-env.with`，supplement 换「习题」「注记」等）。
新类型记得在 `appendix/app3.typ` 的「全部类型一览」里补一行展示。

## 增删章节 / 调整篇章

- 正文章节：`chapters/` 加文件，`main.typ` 里 `#include`；
- 篇章：`#part-page([篇名], desc: [一两句导读])`——导读两三行以内，
  版面按版心高度定死不随内容伸缩，写长了会压到底部小目录；
- 篇内小目录自动跟随（query 现算），无需维护；
- **定稿前重核 `pagetabs.typ` 的 `tab-skip-pages`**（空白衬页位置变了）；
- 章数超过 12 章颜色循环，需要更多色就在 `tab-colors` 里补。

## 改字体

| 用途 | 位置 |
| --- | --- |
| 正文/西文/数学/代码 | `main.typ` 的 `bookly(fonts: ...)` |
| 标题、表头、章号、篇章页、图内文字 | `main.typ` heading 规则、`chaptermark.typ`、`partpage.typ` 的 pp-head-font、`figstyle.typ` 的 fig-font |
| 强调（楷体） | `main.typ` 的 emph 规则 |

字体链原则：链尾放非当前系统的兜底（SimHei 是 Windows 字体，链尾补
Noto Sans SC；KaiTi 缺失时宁可退回正文宋体）。**不要放只装了单一粗字重
的字体族**（如仅 Heavy 的思源宋体）——找不到常规字重会退到粗字重，
正文整体变特粗。

## 改书眉 / 页码

- 书眉奇偶规则、回退逻辑、对齐：`runninghead.typ`；
- 页码贴切口：`main.typ` 末尾的 `#set page(footer: context { ... })`；
- 前置部分不印眉的整段处理：`main.typ` 里 `#{ set page(header: none) ... }`
  那个代码块（set 圈在块里才不会泄漏到正文）。

## 启用旁注版式（Tufte）

`main.typ` 的 `alt-margins: true`。注意本书未按 Tufte 调校：
runninghead.typ 没有实现 tufte 布局的宽页眉（wideblock），宽边距下页眉
会缩在正文栏里——要用旁注需补那支，详见该文件头注释。

## 换参考文献风格

`main.typ` 末尾 `#bibliography(..., style: "gb-7714-2015-numeric")`，
可换 Typst 自带的其它 CSL 样式名。文献库换 `bibliography/sample.bib`，
正文 `@key` 引用。

## 换封面

`images/book-cover.jpg` 直接换图（main.typ 的 title-page 里设了 45% 宽度），
或调 `title-page` 的 subtitle/edition/series/institution。封面四行文字
左缘对齐与版权行「© 作者　2026」的中文格式都已处理（见 pitfalls.md
「标题页缩进泄漏」），改文字不用管版式。

## 启用 PDF/UA 无障碍

目前不可行：PDF/UA-1 要求每个公式（含行内 $…$）带 alt 文本，行内公式
无处安放，需全部改写成 `#math.equation(block: false, alt: [...])`。
存档需求用 `--pdf-standard a-2b` 即可。
