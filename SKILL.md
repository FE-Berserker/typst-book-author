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

## 工作流程

### 1. 搭脚手架

把本技能的 `template/` 整个目录复制到用户项目里（不要改动技能目录本身），
然后编辑入口文件 `main.typ`：

- `title` / `author`：书名与作者；
- `title-page`：副书名、版次、丛书、机构、封面图与 logo；
- `paper-size`：`"a4"` 或 `"a5"`；
- 主题色：`template/colors.typ` 顶部的 `book-theme` 一行切换，内置六主题——
  朱砂（默认红）、靛蓝、松绿、赭石、紫棠、石墨。为避免每本书千篇一律，
  创建新书时按内容气质挑选一个主题（或与用户确认），不要默认总是朱砂红；
  换非默认主题时建议一并更换 `images/book-cover.jpg`（默认封面图按朱砂红调）；
- 篇章结构：`#part-page([篇名], desc: [一两句导读])` + `#include "chapters/….typ"`。

示例章节就是用法文档：`chapters/ch1.typ`（语言速览）、`chapters/ch2.typ`
（版式元素实践）、`appendix/`（速查、字体、提示框、工程绘图等六个附录）
覆盖了正文里可用的全部版式元素，照抄写法即可。

**已有书稿项目开工前先体检**：脚手架复制出去的模板不会随技能更新——技能里
修复的规则（如表题在表格上方）到不了旧拷贝，旧项目会带着旧问题继续排版。
在**不是本次新建**的书稿项目上干活（改稿、加内容、编译）之前，先跑：

```bash
python <技能目录>/scripts/doctor.py --root <用户项目>
```

缺什么按提示补（提示带具体规则写法）；doctor 全绿再开工。

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
字体依赖：Noto Serif SC（正文）、SimHei + Arial（标题）、KaiTi/STKaiti（强调）、
New Computer Modern（西文与数学）、DejaVu Sans Mono（代码）——非 Windows 系统
需要思源黑体/思源宋体兜底（字体链已配好）。

### 4. 定稿检查

改动内容后必须重做一次，样板里有两处「按物理页码手工维护」的设置：

- `template/pagetabs.typ` 的 `tab-skip-pages`：open-right 自动插入的空白衬页
  不该印切口色标，翻一遍 PDF 把空白衬页的物理页码填进去；
- 章数超过 12 章时色标颜色开始循环（`tab-colors`），可按需补色。

## 模板文件一览

| 文件 | 职责 |
| --- | --- |
| `main.typ` | 入口：书籍元数据、字体、行内样式、目录规则、篇章结构 |
| `colors.typ` | 全书配色唯一来源：顶部一行切换主题（六主题内置），改色只改这里 |
| `boxes.typ` | 提示框/定理环境/加框公式，Heroicons 图标 |
| `figstyle.typ` | CeTZ 示意图、Fletcher 流程图、Lilaq 数据图的统一样式 |
| `partpage.typ` | 篇章页（满版浅底 + 空心篇次数字 + 本篇小目录）与目录「篇」行 |
| `chaptermark.typ` | 章首页装饰章号；装订边距（inside/outside）也定义在这里 |
| `runninghead.typ` | 书眉：偶页章名/奇页节名，节标题在页顶时回退章名 |
| `pagetabs.typ` | 切口色标（拇指索引），颜色与位置随章次递增 |

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
