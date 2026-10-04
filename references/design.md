# 版式架构与设计意图

改样式模块或版面结构之前先读这份文档。这里讲清楚样板各模块如何接线、
为什么这样设计；具体的「改法」见 customization.md，出问题查 pitfalls.md。

## 总体结构

```
main.typ                     入口：元数据 + 字体 + 行内样式 + 目录规则 + 章节组装
├── colors.typ               全书配色唯一来源
├── chaptermark.typ          章首页装饰章号 + 装订边距定义
├── pagetabs.typ             切口色标（拇指索引）
├── partpage.typ             篇章页 + 目录「篇」行
├── runninghead.typ          书眉
├── boxes.typ                提示框 / 定理环境 / 加框公式
├── figstyle.typ             CeTZ / Fletcher / Lilaq 统一图形样式
├── front_matter/            前言、摘要（前置部分，罗马页码）
├── chapters/                正文章节（阿拉伯页码）
├── appendix/                附录（字母编号 A、B、C…）
├── bibliography/sample.bib  参考文献库（GB/T 7714-2015 数字式）
├── images/  data/           图片与绘图数据
└── 封底                     main.typ 末尾的 #back-cover
```

与 Bookly 5.1.1 的关系：`#show: bookly.with(...)` 提供书籍骨架（前置/正文/
附录三段式、标题页、目录、编号体系）。样板在其上做三类接管：

1. **theme 替换**：`theme: (part: part-page, custom-box: book-custom-box,
   boxeq: book-boxeq)` —— 篇章页、提示框、加框公式换成自己的版式，
   其余沿用 classic 主题；
2. **页面背景**：`set page(background: (page-tab, chapter-mark))` ——
   切口色标与装饰章号画在背景层；
3. **定向 show/set 规则**：字体、行内样式、题注与目录条目的中文本地化。

## 关键机制

### 「隐形标题 + 状态」标记法

篇章页在正文里写一枚 `heading(numbering: none)`，用
`states.is-toc-part.update(true/false)` 圈住——标题本身被 `show heading: none`
隐掉，只在查询时可见。切口色标（pagetabs）和目录规则（main.typ）都用
`states.is-toc-part.at(位置)` 判断「这一页/这一条是不是篇」，同一招两处用。
附录的识别用 Bookly 自带的 `states.isappendix`。

### 页面背景层的装饰

切口色标与章号都画在 `set page(background:)` 里而不是给标题加 show 规则：
Bookly 的章标题整块由主题的 show 规则渲染，外部再加一条会把它整个顶掉。
背景层不动主题、不挤正文，代价是 `place` 的基准是**纸张**而不是版心——
章号要对齐版心右缘，必须减去右侧页边距（见 chaptermark.typ 的 right-margin）。

### 装订边距与页边距算法

成书边距不对称：订口（装订侧）2.8cm、切口（翻阅侧）2.2cm。数值定义在
chaptermark.typ（章号定位要用），main.typ 从那里 import 后 set page。
天头/地脚不设，走 Typst 的 auto（a4 = 2.5cm，a5 ≈ 1.76cm）；
auto-margin() 复现了这个算法，供章号定位与书眉判断「标题是否在页顶」共用。

### 「本页属于哪一章」的判定

用物理页号比较（`h.location().page() <= here().page()`），不能用
`query(...before(here()))`：页面背景的 here() 解析在页面内容之前，
before 会漏掉「本页刚开头的那一章」，色标会比章次晚一页。
只统计**有编号**的一级标题——分部页、前言、过渡页的无编号标题是装饰，
算进去色标会乱跳。

### 篇章页的小目录

`pp-contents()` 用 query 现算「本页之后、下一个分部页标记或附录之前」的
标题，增删章节无需手工维护。边界必须同时找分部页标记**和**附录首章：
末篇之后没有分部页，少了附录判断会把附录算进末篇。条目超过
pp-max-entries（16）就只列章不列节，防止顶穿版面。

### 书眉规则

偶数页跟章名、奇数页跟小节名（Bookly classic 原例），加一条回退：
被跟踪的那级标题正好从页顶起步时改印章名——否则那一页书眉空着，
夹在两页有眉的页面之间很扎眼（hydra 内置「页顶标题不印眉」规则所致）。
文字贴切口对齐（奇右偶左）与页码同侧；通栏细线由 place 单独铺，
不跟着 align 走。

### 页码贴切口

`#set page(footer: context { ... })` 里按物理页号奇偶设 align：奇数页靠右、
偶数页靠左。前置部分罗马数字、正文阿拉伯数字由 front-matter / main-matter
自动切换，这里只管对齐。篇章页、封面封底自己关了页脚，不受影响。

## 中文创排决策

| 位置 | 决策 | 原因 |
| --- | --- | --- |
| 正文 | 思源宋体 + NCM 西文，10.5pt | 中文书籍惯例；西文衬线与宋体协调 |
| 标题 | SimHei + Arial（兜底 Noto Sans SC） | Typst 标题自带 bold，NCM 落到粗衬线上与黑体不搭 |
| 强调 | 楷体（KaiTi/STKaiti，兜底思源宋） | 汉字无斜体字形，套斜体只得正体；楷体是中文强调传统 |
| 加粗 | 思源宋粗体字重，兜底 SimHei | 「换黑体」是换字体不是加粗，删字重后会失效 |
| 首行缩进 | 2em 全段 | 中文惯例（Bookly 默认 1.5em） |
| 代码/公式 | 显式补思源宋回退 | 这两处字体纯西文，否则 Typst 在系统里乱挑（实测落到隶书） |
| 题注 | 「图 1.1　标题」全角空格分隔 | Bookly 默认西文连接号「–」 |
| 章标题 | 「第 N 章」；附录「附录 A」 | 语言包默认「章节 N」是翻译腔 |
| 插图目录 | lof 改名「插图目录」 | 语言包的「图表目录」名不副实（只列图，表另有目录） |
| 表格 | 列默认左对齐、格内禁两端对齐 | 三套对齐规矩混用曾是实际翻过车的点 |

## 提示框体系（boxes.typ）

统一框体：所有框共用一种极浅中性底（#f7f7f8），颜色只出现在标题牌与一道
细边上——类型靠 Heroicons 图标与标题文字区分，版面安静。三处共用
`box-frame()`（callout / thm-env / proof），改一处即全改。

- `callout`：通用框，任意 icon/color；`keypoint-box` 等是它的偏应用；
- `thm-env`：编号定理环境，**全书连续编号**（定理 1、定理 2…），可交叉引用。
  不用「章号.章内序号」是因为外部 show 规则会顶掉主题章标题（无法重置
  计数器），query 统计又会让 marginalia 多一轮编译触发收敛告警；
- `book-custom-box`：接管 Bookly 内置 info-box/tip-box 等（它们最终落到
  theme.custom-box），内置「证明」的青色归一到灰，与自家的 #proof 一致；
- `subfigure-zh`：内置 subfigure 的 supplement 在定义处绑死英文 Figure，
  set 规则够不着，只能 `.with` 重绑定。

## 图形样式（figstyle.typ）

CeTZ（示意图）/ Fletcher（流程图）/ Lilaq（数据图）共用 colors.typ 的
调色板、黑体图内文字（9pt）与约 0.9pt 线宽。Lilaq 提供两套坐标轴：

- `chart`：边框式坐标轴，刻度朝外，适合任意取值范围的数据；
- `fn-plot`：过原点的教材式坐标轴（轴端箭头），适合 y=f(x) 类曲线。
  数据远离原点时轴线会被推到数据区外，两轴间大片空白——那种数据用 chart。

## 定稿前必须人工核对的一项

open-right 自动插入的空白衬页不该有切口色标，但「本页是否空白」无法用
查询稳定判定（par 查询会触发收敛告警），只能按物理页码手工列在
pagetabs.typ 的 `tab-skip-pages`。**改动内容后空白页位置会移动**，
定稿前翻一遍 PDF 重新核对。
