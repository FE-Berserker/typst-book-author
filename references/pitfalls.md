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

**中英混排标题「英文明显比中文粗」/「不是一个整体」**
标题西文走 NCM 时 bold 落在衬线粗体上，挨着黑体像两个年代；换成 Arial 更
隐蔽但更糟——SimHei 没有粗体字形而 Typst 不做伪粗体，标题的 bold 对汉字
无效，汉字是常规字重，Arial 却是真粗体，实测同一标题里 Arial Bold 竖笔画
比 SimHei 汉字粗 42%。正解：西文也用 SimHei 自带西文（与汉字同文件、同
字重，实测笔画 5px = 5px）：`#show heading: set text(font: ("SimHei",
"Noto Sans SC"))`，非 Windows 兜底落思源黑体（中西文同族同粗）。

**标题里的行内代码只有汉字一半高 / 等宽字体在标题里很突兀**
Bookly 把所有 raw 的字号钉死在 0.8 倍正文字号（绝对值 8.4pt）——正文里
这是惯例，但标题再大代码也不跟着走；而 DejaVu Sans Mono 的等宽字形放在
黑体标题里风格突兀。标题作用域里要把行内代码换成 SimHei（与标题一体）、
字号与标题正文相同。注意 `set text(size: 1.05em)` 没用：set size 的相对值
会级联乘在钉死值上（8.4×1.05=8.82，约等于没修），必须用绝对值才能盖掉。
正解是用 state 探出标题当前字号再设绝对值（规则见 main.typ「标题里的
行内代码」一节），一级标题正文按 classic 主题的 text(2em) 结构再乘 2。

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

**加列间距后表格多出竖线**
Typst 会把 table 的 stroke 画进 column-gutter。用单元格内边距
（`table.cell(inset: ...)`）留气口，不用 gutter。

**窄格里最后一行被撑开**
表格单元格继承两端对齐。逐格关掉：`#show table.cell: set par(justify: false)`。

**跨页长表被静默截断（行凭空消失）**
`figure` 默认是「不可断」的块。长表一页放不下时，Typst 不会把表拆到下一页，
而是整块推到新页继续排——超出页面的行被画在页面之外：PDF 文本层里还在，
打印和屏显都看不见，页数也不增加。实测 60 行的表只印出 22 行，剩下 38 行
就这么没了，只看页数完全发现不了。

两件事一起做才完整：
1. 让表格可以断开（模板已在 `main.typ` 设好，且只对 table 放开）：
   `#show figure.where(kind: table): set block(breakable: true)`
2. 表头用 `table.header(…)` 包起来，Typst 才会在每一段续表的顶部重画表头。

只做 1 会得到「续表没有表头」，只做 2 则根本没有续表（整块还是被推走）。
一次写全就用 `tables.typ` 里的 `long-table`（章文件各自 import，不共享主文件作用域）：

```typst
#import "../tables.typ": long-table

#long-table(
  columns: (auto, 1fr, 1fr),
  head: ([序号], [名称], [说明]),
  caption: [长表题注，照样编号、照样能被 @ 引用],
  ..rows.flatten(),
)
```

「（续表）」标记模板不自动加：要判断「这一段是不是第一段」只能记录表格起始页
再与当页比较，而起始页随分页变化，实测会让整本书五轮不收敛
（`state ... did not converge`）。真要标就手写在表头最后一格，代价是它也出现在第一段。

## 插图

**图太大 → 页底空出一大块**
Typst 的 `figure` 默认（`placement: auto`）**本来就浮动**：图放不进当前页剩余版面时
挪到下一页顶部，正文接着往下排把空白补满。实测同一页：默认排法页底只空 0.5cm，
换成 `placement: none` 会空出 17cm。所以「页底一大块空白」几乎都是浮动被关掉了，
有两个静默的关掉方式：

排查顺序（9 成是前两条）：

1. 图有没有写 `placement: none`——临时钉死原位的写法，写完忘了删就是它；
2. figure 有没有被容器包住——`#box(...)`、`#block(...)`、`#columns(...)`，以及
   `boxes.typ` 里的提示框（`keypoint-box` 之类），都会把图关进盒子里，浮动静默失效
   （实测 `#box(figure(...))` 让同一页空出 17.7cm）。想把图放进带框的区块，就得接受
   它不浮动；要么图和框分开写；
3. 图本身比正文高度（A4 约 24.9cm）还高——这时浮不浮动都放不进一页，该缩图或改整页插图。

注意「留白」和「越界」是两件事，别混着治：`auto-image`（下一节）只管图比版面还宽/还高
时的越界，**不管页底留白**——拿它去修空白只会把图缩小，空白照旧。

模板 `<template>/main.typ` 的开关只用来关掉浮动：

```typst
#let float-images = true          // 改成 false 等于 placement: none：图回原位、页底留白
```

要严格保序（图必须紧跟引用它的段落）就关掉它，代价是页底可能出现空白带；
否则别动它。单张图临时浮动写 `placement: top`，临时钉死原位写 `placement: none`。

**竖图越出右边距 / 图被页面裁掉**
只写 `width` 的竖图会被按比例推高，超过版心就落到页面外（PDF 文本层还在，
纸上没有）；只写 `height` 的横图会被按比例推宽，越过右边距。两种写法各有一个坑。

用 `figures.typ` 里的 `auto-image` 一次避开（章文件各自 import）：

```typst
#import "../figures.typ": auto-image

#figure(auto-image("images/photo.png"), caption: [竖图按高度收，横图撑满版心宽])
```

注意路径口径：`auto-image` 内部才去读文件，所以**路径按 `figures.typ` 所在的
项目根解析**，不是按调用它的章文件。「章在 `chapters/`、图在 `images/`」这种
常规布局正好写 `images/photo.png`；写成 `../images/photo.png` 会报
`path would escape the project root`。

它是拿图量出来的自然宽高比做二选一：横图撑满版心宽，竖图收到版心高度的
88%（剩下留给图注）。实测 1:4 的竖图渲染成 5.4 × 21.7cm、4:1 的横图
16.0 × 4.0cm，都不越界。

## 题注

**题注写成两三行小摘要 → 图表块被推高、题注孤在页尾**

题注的职责是**指称**（让 `@` 引用和图表目录里有个短名字），不是解释图表。
写作助手生成题注时习惯把「图里有什么 + 结论 + 适用边界」全塞进去：题注折
成两三行，把图表块整体推高，跨页时容易出现「题注留在本页、表体推到下页」
的分离。

修法按信息分层：

| 内容 | 去处 |
| --- | --- |
| 图/表是什么（名词短语，≤1 行；版心 16cm 约 28 字） | 题注 |
| 怎么看、怎么读这张图 | 图前的正文段落 |
| 适用边界、数据来源、免责 | 脚注 |
| 多句解释 | 拆成正文小节 |

自检：题注里出现句号「。」或分号「；」，几乎必是段落冒充题注。

## 指称、数值与符号

**正文写「下图」，增删一轮后图就不在下方了**

书稿会反复增删内容，「如下图」「见上图」这类方位词在下一轮修订里就过期。
指称一律 `@fig:x` / `@tab:x`（自带「图 N」标签，前面不要再手写「图」字，
否则印出「图 图 3」——源码读起来通顺，只有编译出来才看得见）。

**表头单位在每列重复，表头被撑成两行**

单位只出现一次：并入表题（「涂色层厚度上限（μm）」）或合并单元格的单位
行。五列表头各带「mm」，换行后表格撑高一倍。

**表格数值没有对象、条件与版本**

裸数值必须能回答「谁、什么条件下、出自哪版文件」；来源列给文件版本号
（「SDS 2021 Ver03」「JJG 177—2016」），没有版本号的来源标注视为无效。

**符号混排：范围、年份、负号**

数值范围用「～」（0.5～3.0 μm）；标准／文献年份连接用全角一字线「—」
（GB/T 19001—2016，不是连字符 -）；负号与数学量进数学模式（`$-40$`）。

**同一句边界声明全文重复了四五次**

「A 不等于 B」类免责在每个论断后都挂一遍，会稀释真正重要的边界。全文
只挂一次，其余归脚注。

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
分部页了，少了 isappendix 判断附录会被算进末篇。

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
