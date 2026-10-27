#!/usr/bin/env python3
"""把技能里的 template/ 复制成一本新书，顺手写好书名、作者与主题色。

用法：
    python scaffold.py --to ../我的新书 --title "书名" --author "作者"
    python scaffold.py --to ../我的新书 --title "书名" --author "作者" \
        --subtitle "副书名" --institution "机构" --theme indigo
    python scaffold.py --list-themes        # 看可选主题键

目标目录不存在就建；已存在且非空则拒绝（确认要往里覆盖加 --force）。
复制完会打印下一步（改哪几个文件、怎么编译），不替你编译。
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
TEMPLATE = HERE.parent / "template"

# 顺手把控制台切成 UTF-8：中文 Windows 的 GBK 控制台打印非 GBK 字符会直接崩；
# 报错走 stderr，两个流都得改，否则错别字变成乱码
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8")

# main.typ 里可以安全改写的元数据：字段名 -> (文件, 行内注释)
FIELDS = {
    "title": "main.typ",
    "author": "main.typ",
    "subtitle": "main.typ",
    "institution": "main.typ",
}


def fail(msg: str) -> "NoReturn":  # type: ignore[valid-type]
    print(f"scaffold: {msg}", file=sys.stderr)
    raise SystemExit(1)


def themes_in(colors: Path) -> list[str]:
    """从 colors.typ 的 themes 表里取主题键，避免这份脚本和模板各记一套。"""
    if not colors.exists():
        fail(f"找不到 {colors}，技能目录结构不对")
    src = colors.read_text(encoding="utf-8")
    block = re.search(r"#let themes = \((.*?)\n\)", src, re.S)
    if not block:
        fail("colors.typ 里没找到 themes 表，模板结构变了？请同步改 scaffold.py")
    keys = re.findall(r"^\s*(\w+):\s*\(", block.group(1), re.M)
    if not keys:
        fail("themes 表解析出 0 个主题，模板结构变了？请同步改 scaffold.py")
    return keys


def patch_field(path: Path, field: str, value: str) -> bool:
    """只改带引号的那次赋值（`title: "…",`），别误伤列表里的 `title: [...]`。"""
    src = path.read_text(encoding="utf-8")
    pattern = re.compile(rf'^(\s*){re.escape(field)}:\s*"[^"]*",', re.M)
    hits = pattern.findall(src)
    if len(hits) != 1:
        print(f"  ! {path.name} 里 `{field}: \"…\"` 命中 {len(hits)} 处（应为 1），跳过")
        return False
    src = pattern.sub(lambda m: f'{m.group(1)}{field}: "{value}",', src, count=1)
    path.write_text(src, encoding="utf-8", newline="\n")
    return True


def patch_theme(path: Path, theme: str, known: list[str]) -> bool:
    if theme not in known:
        fail(f"没有叫 {theme!r} 的主题，可选：{'、'.join(known)}")
    src = path.read_text(encoding="utf-8")
    pattern = re.compile(r'^#let book-theme = "\w+"', re.M)
    if len(pattern.findall(src)) != 1:
        print(f"  ! {path.name} 里 `#let book-theme` 命中数异常，跳过")
        return False
    path.write_text(pattern.sub(f'#let book-theme = "{theme}"', src), encoding="utf-8", newline="\n")
    return True


def main() -> int:
    ap = argparse.ArgumentParser(
        description="把 Bookly 中文书籍样板复制成一本新书",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="例：python scaffold.py --to ../我的书 --title 你好世界 --author 张三",
    )
    ap.add_argument("--to", metavar="目录", help="新书目录（不存在会自动创建）")
    ap.add_argument("--title", help="书名，写进 main.typ 的 bookly.with(title: …)")
    ap.add_argument("--author", help="作者，写进 bookly.with(author: …)")
    ap.add_argument("--subtitle", help="副书名，写进 title-page 的 subtitle")
    ap.add_argument("--institution", help="机构/单位，写进 title-page 的 institution")
    ap.add_argument("--theme", help="主题色键（见 --list-themes）")
    ap.add_argument("--force", action="store_true", help="目标目录非空时仍往里写（不删多余文件）")
    ap.add_argument("--list-themes", action="store_true", help="列出可选主题键后退出")
    args = ap.parse_args()

    if not TEMPLATE.is_dir():
        fail(f"找不到模板目录 {TEMPLATE}")

    themes = themes_in(TEMPLATE / "colors.typ")
    if args.list_themes:
        print("可选主题：" + "、".join(themes) + "（默认 cinnabar 朱砂）")
        return 0

    if not args.to:
        ap.print_help()
        return 1

    # 参数先全验完再动磁盘：主题写错时不该留下半拉子的目录
    if args.theme and args.theme not in themes:
        fail(f"没有叫 {args.theme!r} 的主题，可选：{'、'.join(themes)}")

    for field, value in (("title", args.title), ("author", args.author),
                         ("subtitle", args.subtitle), ("institution", args.institution)):
        if value and any(ch in value for ch in '"\r\n'):
            fail(f"--{field} 里不能有英文双引号或换行")

    dest = Path(args.to).expanduser()
    if dest.exists():
        if not dest.is_dir():
            fail(f"{dest} 已存在且不是目录")
        if any(dest.iterdir()) and not args.force:
            fail(f"{dest} 非空，拒绝往里写；确认要合并请加 --force")
    else:
        dest.mkdir(parents=True)

    shutil.copytree(TEMPLATE, dest, dirs_exist_ok=True)

    changed: list[str] = []
    for field, value in (("title", args.title), ("author", args.author),
                         ("subtitle", args.subtitle), ("institution", args.institution)):
        if value and patch_field(dest / FIELDS[field], field, value):
            changed.append(field)
    if args.theme and patch_theme(dest / "colors.typ", args.theme, themes):
        changed.append("theme")

    print(f"[scaffold] 已复制到 {dest}")
    print("  写入：" + ("、".join(changed) if changed else "无（只复制了模板）"))
    print()
    print("下一步：")
    print(f"  cd {dest}")
    print("  python <技能目录>/scripts/doctor.py --root .   # 体检（新书应全绿）")
    pdf = f"{args.title}.pdf" if args.title else "book.pdf"
    print(f'  typst compile main.typ "{pdf}"                # 首次编译约 10 秒')
    print()
    print("要改的地方：main.typ 的 title-page（封面图/logo）、paper-size（a4/a5）、"
          "chapters/ 正文、bibliography/sample.bib 文献库。")
    print("正式出版加 --pdf-standard a-2b 导出存档级 PDF/A；PDF/UA 暂不可用（公式缺 alt）。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
