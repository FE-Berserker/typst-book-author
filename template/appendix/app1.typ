#import "@preview/bookly:5.1.1": *

= 常用命令速查

表 @tab:cmds 汇总了日常写作最常用的编译与格式化命令。

#figure(
  table(
    columns: (auto, 1fr),
    table.header([命令], [用途]),
    [`typst compile main.typ`], [编译为 PDF],
    [`typst watch main.typ`], [监视文件变化并自动重新编译],
    [`typst init @preview/bookly`], [在空目录中生成 Bookly 脚手架],
    [`typstyle -i main.typ`], [格式化 Typst 源码],
  ),
  caption: [Typst 常用命令行操作],
) <tab:cmds>

在 VS Code 中配合 Tinymist 扩展，可以直接使用 `Ctrl+K V` 打开实时预览。
