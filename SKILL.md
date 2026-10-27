---
name: typst-book-author
description: 用基于 Bookly 调校的 Typst 中文书籍样板排书：封面、目录、篇章页、切口色标、书眉、提示框、定理环境、图表公式、GB/T 7714 参考文献与附录开箱即用。当用户要写书、把笔记或书稿排成中文书籍、制作技术书/教材/手册，或提到 Typst book、成书、书稿、Bookly 时使用——即使用户只说「帮我把这些内容排成一本书」也应触发。
---

# Typst 中文书籍成书（Bookly 样板）

一套调校过的中文书籍样板：封面/版权页、目录（含「篇」行与图表目录）、
篇章页、切口色标、书眉、提示框与定理环境、图表公式、脚注、GB/T 7714 参考文献、
附录与封底均已配置就绪。当用户要写书、把笔记或书稿排成中文书籍、制作技术书/
教材/手册，或提到 Typst book、成书、书稿、Bookly 时使用——即使用户只说
「帮我把这些内容排成一本书」也应触发本技能。

想先看效果再动手：`preview/` 里有四张样图（封面、目录、篇章页、提示框），
不用编译就能判断这套版式是否对路。

## 工作流程

### 1. 搭脚手架

一条命令起新书（复制 `template/` 到项目目录，顺手把书名、作者、副书名、机构写进
`main.typ`，并按内容气质挑一个主题色）：

```bash
python <技能目录>/scripts/scaffold.py --to <新书目录> \
    --title "书名" --author "作者" --subtitle "副书名" --theme indigo
```

`--theme` 可选 `cinnabar`（朱砂，默认）/ `indigo` / `pine` / `ochre` / `zitan` /
`graphite`，`--list-themes` 随时查；目标目录非空会拒绝，确认要合并加 `--force`。
不想用脚本就把 `template/` 整个目录复制出去（不要改动技能目录本身），效果一样。

脚手架建完，仍需手工调的地方：

- `title-page`：封面图（`images/book-cover.jpg`，默认按朱砂红调，换非默认主题
  时一并更换）、logo、版次、丛书；
- `paper-size`：`"a4"` 或 `"a5"`；
- 篇章结构：`#part-page([篇名], desc: [一两句导读])` + `#include "chapters/….typ"`。

示例章节就是用法文档：`chapters/ch1.typ`（语言速览）、`chapters/ch2.typ`
（版式元素实践）、`appendix/`（速查、字体、提示框、工程绘图等六个附录）
覆盖了正文里可用的全部版式元素，照抄写法即可。

复制出来的 `main.typ` 顶部有一行 `#let template-version = "…"`，是这份拷贝的
血缘戳：`doctor.py` 靠它判断拷贝比技能落后多少。**改过模板本身的规则**（不只是
改书名、正文）就把戳一起改，否则下次体检会把你的定制误报成「版本落后」。

**已有书稿项目开工前先体检**：脚手架复制出去的模板不会随技能更新——技能里
修复的规则（如表题在表格上方、标题中西文统一字重）到不了旧拷贝，旧项目会带着
旧问题继续排版。在**不是本次新建**的书稿项目上干活（改稿、加内容、编译）之前，先跑：

```bash
python <技能目录>/scripts/doctor.py --root <用户项目>
```

缺什么按提示补（提示带具体规则写法）；doctor 全绿再开工。改过 `doctor.py` 的
规则之后，用 `python <技能目录>/scripts/test_doctor.py` 自检：它把技能模板复制
出来逐条改坏，确认该报的报、不该误伤的（如把图注本地化的 `set` 规则当成缩放
规则）不报——规则写歪了 doctor 照样会说「模板健康」，只有这个自检抓得到。

### 2. 替换内容

- 正文章节放 `chapters/`，每章一个文件，由 `main.typ` 依次 `include`；
- 前言、摘要放 `front_matter/`；附录放 `appendix/`；
- 参考文献库换 `bibliography/sample.bib`，引用风格已设为国标
  GB/T 7714-2015（数字式）；
- 图片放 `images/`，绘图数据放 `data/`。

章内可用的主要元素（完整示例见 ch1/ch2 与 app3）：

```typst
#keypoint-box[要点框] #pitfall-box[易错框]        // 提示框，另有 conclusion/formula/reference
#theorem[勾股定理……]<thm:pyth>                    // 编号定理环境，@thm:pyth 交叉引用
#callout(title: [标题], icon: "rocket-launch", color: rgb("#0ea5e9"))[自定义框]
#figure(flow(...), caption: [流程图]) <fig:flow>   // 见 figstyle.typ：sketch/flow/chart/fn-plot
```

长表（会跨页的表）别用裸 `#figure(table(...))`：figure 默认不可断，放不下时
整块被推到下一页，超出页面的行画在页面之外——打印屏显都看不见，页数却不变。
用 `tables.typ` 的 `long-table`（章文件里 `#import "../tables.typ": long-table`）：

```typst
#long-table(
  columns: (auto, 1fr, 1fr),
  head: ([序号], [名称], [说明]),
  caption: [题注，照样编号、可被 @ 引用],
  ..rows.flatten(),
)
```

### 3. 编译

```bash
typst compile main.typ 书名.pdf
# 存档级导出（投图书馆/长期保存）：
typst compile main.typ 书名.pdf --pdf-standard a-2b
```

要求 Typst 0.15+。首次编译需联网拉取 `@preview` 依赖
（bookly 5.1.1、cetz、fletcher、lilaq、tiptoe、heroic；附录 app4–app6 的
工程绘图示例另需 zap、bone、mechanical-system-cetz-34j、arch-plotter、
maquette、plotsy-3d、vmesh。注意 app4 固定用 cetz 0.5.0——mechanical-system
按它构建，与 figstyle 的 0.5.2 并存是有意的，勿合并升级）。
字体依赖：Noto Serif SC（正文）、SimHei（标题，中西文一体同字重）、KaiTi/STKaiti（强调）、
New Computer Modern（西文与数学）、DejaVu Sans Mono（代码）——非 Windows 系统
由思源黑体/思源宋体兜底（字体链已配好）。

### 4. 定稿检查

改动内容后必须重做一次：空白衬页的位置会随内容移动，而它是一份手工清单。

```bash
python <技能目录>/scripts/blankpages.py --root <书稿目录> --check
# 漂移了就直接回填（会编译页图、按非白像素找出真正的空白页）：
python <技能目录>/scripts/blankpages.py --root <书稿目录> --write
```

它报三类问题：`空白页带色标（未允许）`（真 bug：空白页印了色标，读者会当成印错）、`清单漏掉`（空白衬页没印色标，不影响观感，补不补都行）、`清单多出`（内容动过，旧项失效）。
`--check` 可以放进书稿仓库的 CI——但 CI 上多半没有 SimHei，换字会改变分页，
所以更稳的是本地定稿前跑一次。

真书里的色标是切口工艺（模切缺口，或装订后整叠刷边），空白衬页的切口本来
也带着那叠纸的颜色。这份模板是在页面角落画色块来仿真，所以默认跳过空白页；
**只做纸书、要更贴真工艺**时，把页码从 `tab-skip-pages` 挪到同一个文件里的
`tab-allow-blank`，脚本会把它们当成「有意保留」，不再报漏网。

- 章数超过 12 章时色标颜色开始循环（`tab-colors`），可按需补色。

## 模板文件一览

| 文件 | 职责 |
| --- | --- |
| `main.typ` | 入口：书籍元数据、字体、行内样式、目录规则、篇章结构 |
| `colors.typ` | 全书配色唯一来源：顶部一行切换主题（六主题内置），改色只改这里 |
| `boxes.typ` | 提示框/定理环境/加框公式，Heroicons 图标 |
| `figstyle.typ` | CeTZ 示意图、Fletcher 流程图、Lilaq 数据图的统一样式 |
| `code-theme.tmTheme` | 代码块语法高亮主题（syntect）：Typst 自带高亮，这份把配色换成调色板同源；`main.typ` 的 `set raw(theme:)` 引用 |
| `partpage.typ` | 篇章页（满版浅底 + 空心篇次数字 + 本篇小目录）与目录「篇」行 |
| `chaptermark.typ` | 章首页装饰章号；装订边距（inside/outside）也定义在这里 |
| `runninghead.typ` | 书眉：偶页章名/奇页节名，节标题在页顶时回退章名 |
| `pagetabs.typ` | 切口色标（拇指索引），颜色与位置随章次递增 |
| `tables.typ` | 跨页长表：`long-table` 把「figure 可断 + 表头逐段重复 + 题注」包成一次调用 |

技能侧的 `scripts/doctor.py`（旧拷贝体检）、`scripts/test_doctor.py`（体检规则
自检）、`scripts/blankpages.py`（空白页与切口色标核对）与 `scripts/scaffold.py`
（建新书）**都不进书稿项目**，留在技能目录里用。仓库根的
`.github/workflows/check.yml` 会在每次推送时编译样板并跑体检自检。

## 许可与出处

模板基于 **Bookly 5.1.1**（作者 Mathieu Aucejo 及贡献者，MIT，
[github.com/maucejo/bookly](https://github.com/maucejo/bookly)）调校而来；其余
`@preview` 依赖（cetz、fletcher、lilaq 等）各依其自身许可。本技能整体以 MIT
发布，见仓库根的 `LICENSE`。

对外分发书稿项目或再发布技能时保留 `LICENSE` 与这段出处——书稿项目只复制了
`template/` 的内容，并不带着 LICENSE 走，正式出版或开源时记得单独署名 Bookly。

## 深入阅读（按需）

- 动样式模块、改版面结构之前：读 `references/design.md`（模块接线与设计意图）；
- 常见定制（换主题色、改开本边距、扩充提示框、增删章节）：读 `references/customization.md`；
- 排版异常（不收敛、标题消失、字体不对、目录怪异）：先查 `references/pitfalls.md`，
  那里是踩过的坑与修法，多数问题能在里面找到现成答案。

## 注意

- 不要往字体链里放只装了单一粗字重的字体族，会导致正文整体变特粗；
- 不要用 `#show heading` 给章标题加装饰（会把 Bookly 主题的标题块整个顶掉），
  页面级装饰一律画在 `set page(background:)` 层；
- 不要用字符串替换做本地化（如 `#show "Figure": [图]`），会误伤代码块与引文；
  样板里已用定向规则处理，照抄即可。
