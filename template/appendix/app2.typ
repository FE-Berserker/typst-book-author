#import "@preview/bookly:5.1.1": *
#import "../boxes.typ": code-box-zh

= 字体与配置要点 <app:fonts>

字体在 `main.typ` 的 `fonts` 字段中配置。`body` 接受字体数组，Typst 会按顺序回退：先匹配拉丁字体，未覆盖的汉字再回退到中文字体。

#code-box-zh[
  ```typst
  fonts: (
    size: 10.5pt,
    body: ("New Computer Modern", "Noto Serif SC", "SimSun"),
    math: "New Computer Modern Math",
  ),
  ```
]

#warning-box[字体族名称必须与系统安装名称完全一致，可用 `typst fonts` 列出系统全部字体。若出现缺字告警（unknown font family），说明该名称有误或字体未安装，此时 Typst 会回退到默认字体，不会中断编译。]

#tip-box[思源宋体的 Adobe 发行版名为 `Source Han Serif SC`，Google 发行版名为 `Noto Serif SC`，两者是同一款字体。本样板使用后者（已安装到当前用户的字体目录），它同时提供 Regular 与 Bold 两个字重，可直接用于加粗。]
