#!/usr/bin/env python3
"""typst-book-author 模板体检：书稿项目里的模板拷贝是否落后于技能模板。

脚手架把 template/ 复制进书稿项目后就断了联系——技能里修复的规则
（如「表题在表格上方」）不会自动到达旧项目，旧拷贝会带着旧问题继续排版。
已有书稿项目开工前（改稿、编译、加内容之前）先跑：

  python doctor.py --root <书稿项目>

检查三件事：核心文件在不在、main.typ 的版本戳是否落后于技能模板、
历次修复的关键规则是否缺失。任一问题以非零码退出并给出补法。
纯标准库，Python 3.8+。
"""

import argparse
import re
import sys
from pathlib import Path

# 历次修复中「旧拷贝最容易缺」的关键规则（文件, 名称, 匹配, 补法）
CRITICAL_RULES = [
    (
        "main.typ",
        "表题在表格上方",
        r"figure\.where\(kind: table\): set figure\.caption\(position: top\)",
        "main.typ 题注一节补：#show figure.where(kind: table): set figure.caption(position: top)",
    ),
    (
        "main.typ",
        "过宽插图自动缩进版心",
        r"#show image: it => layout",
        "main.typ 补插图保护规则（#show image: it => layout(sz => context { … })），见技能模板",
    ),
    (
        "colors.typ",
        "六主题切换表（book-theme 一行换主题）",
        r"#let themes = \(",
        "colors.typ 应有 themes 主题表与顶部 book-theme 一行切换，见技能模板",
    ),
]

CORE = (
    "main.typ", "colors.typ", "boxes.typ", "chaptermark.typ",
    "figstyle.typ", "pagetabs.typ", "partpage.typ", "runninghead.typ",
)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=".", help="书稿项目目录，默认当前目录")
    args = ap.parse_args()
    root = Path(args.root).resolve()
    skill_tpl = Path(__file__).resolve().parent.parent / "template"

    print(f"[doctor] 项目：{root}")
    print(f"[doctor] 技能模板：{skill_tpl}")
    problems = 0

    for f in CORE:
        if not (root / f).exists():
            print(f"✗ 缺核心文件 {f}——这个项目可能不是本技能搭的脚手架")
            problems += 1

    main_typ = root / "main.typ"
    if main_typ.exists():
        src = main_typ.read_text(encoding="utf-8")
        skill_src = (skill_tpl / "main.typ").read_text(encoding="utf-8") if (skill_tpl / "main.typ").exists() else ""

        v_proj = re.search(r'#let template-version = "([^"]*)"', src)
        v_skill = re.search(r'#let template-version = "([^"]*)"', skill_src)
        if not v_proj:
            print("✗ main.typ 没有版本戳——技能修复之前的旧拷贝，强烈建议对照技能模板逐条体检并同步")
            problems += 1
        elif v_skill and v_proj.group(1) != v_skill.group(1):
            print(f"! 模板版本 {v_proj.group(1)} ≠ 技能 {v_skill.group(1)}：技能模板修过问题，逐条做规则体检")
        else:
            print(f"✓ 模板版本 {v_proj.group(1)}（与技能一致）")

        for fname, name, pat, fix in CRITICAL_RULES:
            text = src if fname == "main.typ" else (root / fname).read_text(encoding="utf-8")
            if re.search(pat, text):
                print(f"✓ {name}")
            else:
                print(f"✗ {name}——{fix}")
                problems += 1

    # 逐字节对比是信息性的：有差异可能是用户定制，也可能是旧拷贝
    if skill_tpl.is_dir():
        for f in CORE:
            a, b = root / f, skill_tpl / f
            if a.exists() and b.exists():
                print(f"- {f}: {'与技能模板一致' if a.read_bytes() == b.read_bytes() else '有差异（你的定制，或旧拷贝）'}")

    if problems:
        print(f"[doctor] 发现 {problems} 个问题——修完再开工；拿不准时对照技能模板同步（保留你的定制）")
        sys.exit(1)
    print("[doctor] 模板健康，可以开工")


if __name__ == "__main__":
    main()
