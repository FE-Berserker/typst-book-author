# 踩坑记录

按「症状 → 原因 → 修法」组织。改样板出问题时先来这里找，多数是实际翻过
车的点。相关背景见 design.md。

## 编译

**warning: document did not converge within five attempts**
内容较多时某处版面在多轮排版间来回摆动，多由「不跨页的提示框正好卡在页尾」
引起（伴随 marginalia 的 state 提示）。输出 PDF 不受影响；要消除告警，
微调该处内容或挪动小节位置（实测挪一节即可恢复收敛）。

**首次编译拉取依赖失败 / 随机字形**
`@preview` 包（bookly、cetz、fletcher、lilaq、tiptoe、heroic）需联网；
系统缺 Noto Serif SC / SimHei 等字体时 Typst 会乱挑替代。先确认
`typst compile` 联网跑通一次，再查字体。

## 标题与主题

**插入的图冲出了版心**

不设 `width` 的 `image` 按自然尺寸渲染（1 像素 = 1pt），随手插入的截图
动辄远超版心，整张图向右冲出页面。模板已自动把「不设宽度且自然宽度超过
当前位置可用宽度」的图等比缩到刚好放下；显式写了 `width` 的图不受保护——
想全宽就明写 `width: 100%`。

**给章标题加 show 规则后标题整块消失**
Bookly 的章标题由主题的 show 规则整块渲染，外部再加 `#show heading` 会把它
顶掉。页面级装饰（章号、色标）一律画在 `set page(background:)` 层；
标题作用域内只能用 `set`（如 `#show heading: set text(size: 0.7em)` 缩小）。

**标题页四行文字左缘不齐 / 整块右移**
Bookly 的标题页在 main.typ 作用域里生成，正文的 2em 首行缩进会漏进去。
title-page 外面套一层 `set par(first-line-indent: 0em)`（main.typ 已做）。

**版权行出现「, 2026.」西文标点**
Bookly 源码写死了「, 年份.」。用 `show regex(...)` 拦下改写成
「　年份」（main.typ 的 title-page 里）。

**「第 N 章」变回「章节 N」/ 插图目录变回「图表目录」**
两个 localization 更新都有时机要求：`lof` 必须写在前置部分渲染之前
（插图目录在前置部分里生成）；`num-heading` 的「 章」后缀必须在
`#show: main-matter` **之后**更新——main-matter 会把它重置为 "1"，
写早了被覆盖。

## 字体

**正文整体特粗**
字体链里放了只装单一粗字重的字体族（如仅 Heavy 的思源宋体），找不到常规
字重就退到粗字重。链里只放完整字重族的字体。

**代码块或公式里的中文变成隶书等奇怪字体**
raw 与 math.equation 的字体是纯西文的，Typst 在系统字体里随机挑中文。
显式补中文字体回退：`#show raw: set text(font: ("DejaVu Sans Mono",
"Noto Serif SC"))`。

**强调没有效果（还是正体）**
汉字没有斜体字形，套斜体只得正体。中文强调用楷体：
`#show emph: set text(font: ("New Computer Modern", "KaiTi", "STKaiti",
"Noto Serif SC"))`。加粗同理不要用换黑体冒充（那是换字体，删字重后失效）。

**中英混排标题「不是一个整体」**
标题西文走 NCM 时 bold 落在衬线粗体上，挨着黑体像两个年代。西文单独
指定无衬线：`#show heading: set text(font: ("Arial", "SimHei",
"Noto Sans SC"))`。

## 表格

**表格题注跑到了表格下方**

表题在上是中文技术文档惯例。Typst 0.12 起表格的 `position: auto` 默认就是
top，但更老的编译器对所有题注一律 bottom——在低于 0.12 的 Typst 上编译会
看到表题掉到表格底下。模板已显式设置
`#show figure.where(kind: table): set figure.caption(position: top)`，
不依赖版本默认；若仍见题注在下，先 `typst --version` 确认编译器版本，
再检查是不是主题或别的包改了 `figure.caption` 的默认。

**同一本书各表列对齐不一致（左/中/右混用）**
不设列对齐时由行文环境决定。统一 `#set table(align: (left, left, left))`，
个别列在各自 table 里单独指定。

**加列间距后三线表多出竖线**
Typst 会把 table 的 stroke 画进 column-gutter。用单元格内边距
（`table.cell(inset: ...)`）留气口，不用 gutter。

**窄格里最后一行被撑开**
表格单元格继承两端对齐。逐格关掉：`#show table.cell: set par(justify: false)`。

## 目录

**长条目被两端对齐撑开、留下孤零零的末行**
`#show outline.entry: set par(justify: false)`。注意：一旦有接管 figure
条目的 show 规则，规则内要**自己再设一次** justify: false——set 规则被
show 规则接管后轮不到它。

**图表目录里图号带西文句点（「图 1.1. 标题」）**
Bookly 目录规则写死了句点。在 outline.entry 的 show 规则里对 figure 条目
重排 prefix 与 inner（main.typ 已做）。

**篇行与章条目混在一起认不出**
用 states.is-toc-part 判断篇行，交给 `toc-part-entry()` 排成浅底色条。
判断要排在 figure 分支之前（篇行的 element 也是标题）。

## 页面装饰（色标 / 章号 / 书眉）

**切口色标比章次晚一页**
页面背景的 here() 解析在页面内容之前，`before(here())` 漏掉本页开头的章。
用物理页号比较：`h.location().page() <= here().page()`。

**空白衬页印了色标**
「本页是否空白」无法用查询稳定判定（par 查询触发收敛告警），只能按物理
页码手工列 `tab-skip-pages`。**改动内容后空白页会移动，定稿前重核。**

**分部页角落出现上一章的色标**
分部页没有页眉页码，色标是上一篇末章的，摆着像印错。pagetabs 里用
is-toc-part 判断后跳过。

**某页书眉突然空着**
被跟踪的那级标题正好从页顶起步时，hydra 内置规则整页不印眉。runninghead
的回退：此时改印章名（starts-at-top 判断）。

**装订后色标跑到了订口侧**
单面打印/装订方向不同时，把 pagetabs 的 `outer-side-only` 改成 false
（全部贴右边）。

**open-right 补出的空白衬页被铺了主题浅底**
`set page(fill:)` 写在 pagebreak 之前会染到衬页。篇章页里 fill 必须写在
换页**之后**（partpage.typ 已按此顺序）。

**末篇的小目录把附录也列了进去**
小目录边界必须同时找「下一个分部页标记**或**附录首章」——末篇之后没有
分部页了，少了 isappendic 判断附录会被算进末篇。

## 提示框与定理

**提示框断成三截（标题在上页、正文在下页、中间吊空框）**
短框默认 `breakable: false` 整体不跨页。内容确实超过一页时显式传
`breakable: true`。

**证明结尾的 ∎ 掉到下一行左端**
正文以行间公式结尾时 ∎ 会换行。proof 里结尾写 `#h(1fr) #sym.qed` 靠右。

**想要「定理 1.1」式的章内编号**
不可行：需要每章重置计数器，而外部 show 规则会顶掉主题章标题（见上）；
query 统计章内次序又会让 marginalia 多一轮编译触发收敛告警。样板用全书
连续编号（定理 1、定理 2…），引用稳定。

**自定义提示框不显示图标**
图标名必须是 Heroicons（heroic 包）里存在的名字，
见 https://heroicons.com/。

## 本地化

**raw 代码块或英文引文里的 "Figure" 也被改成了「图」**
不要用字符串替换 `#show "Figure": [图]`。用定向 set：
`#show figure.where(kind: image): set figure(supplement: [图])`。
subfigure 例外——它的 supplement 在 Bookly 定义处绑死，set 够不着，
用 boxes.typ 的 `subfigure-zh`（`.with` 重绑定）。

## 导出

**PDF/UA-1 无障碍导出**
目前不可用：要求每个公式（含行内 $…$）带 alt 文本，行内公式无处安放。
存档用 `--pdf-standard a-2b`。
