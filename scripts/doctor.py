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

# 中文 Windows 控制台默认 GBK，直接 print ✓/✗ 会 UnicodeEncodeError——
# 而且崩在「检查通过」的分支上，看起来像项目坏了。与 check_sync.py 做法一致。
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

# 历次修复中「旧拷贝最容易缺」的关键规则。
#   need  —— 代码里必须能匹配到（正规则，删了就坏）
#   forbid—— 代码里必须匹配不到（负规则，旧错法留了就坏）
# 匹配前先剥掉 // 与 /* */ 注释：规则要认的是代码，不是解释代码的注释。
# 早先有一条规则反着来——要求注释串「插图：不需要额外规则」在场——删注释
# 就误报、留注释就漏报，现在改成直接反查 show image。
CRITICAL_RULES = [
    {
        "file": "main.typ",
        "name": "表题在表格上方",
        "need": r"figure\.where\(kind: table\): set figure\.caption\(position: top\)",
        "fix": "main.typ 题注一节补：#show figure.where(kind: table): set figure.caption(position: top)",
    },
    {
        "file": "main.typ",
        "name": "插图不被重复缩放（没有多余的 show image 规则）",
        # 只认「转换型」规则：#show image: it => …（旧规则在这里 scale 一次，
        # Typst 自己又夹一次）。图注本地化的 #show figure.where(kind: image):
        # set figure(supplement: [图]) 是正解，不能误伤。
        "forbid": r"#show\s+image\b"
                  r"|#show\s+figure\.where\(\s*kind:\s*image\s*\)\s*:\s*it\b",
        "fix": "删掉 #show image: it => layout(sz => context { … scale … }) 那一段。"
                 "Typst 自身会把过宽的图夹到容器宽度，旧规则把比例缩了两次"
                 "（实际宽度 = 版心² ÷ 自然宽），越宽的图越小，6000px 只剩版心 7%。"
                 "图注本地化应写成 #show figure.where(kind: image): set figure(supplement: [图])，见技能模板",
    },
    {
        "file": "main.typ",
        "name": "代码块高亮主题（set raw(theme:) 与块级底板）",
        "need": r'set raw\(theme: "code-theme\.tmTheme"\)',
        "fix": "main.typ 补 set raw(theme: \"code-theme.tmTheme\") 与"
                 " show raw.where(block: true) 底板规则，并把 code-theme.tmTheme 复制到项目根，见技能模板",
    },
    {
        # 2026-10-04：标题里的西文曾单独指定 Arial，而 SimHei 没有粗体字形、
        # Typst 也不做伪粗——Arial 是真粗体、汉字是常规体，同一个标题里
        # 西文竖笔画比汉字粗 42%。现在中西文同走 SimHei 自带的西文。
        "file": "main.typ",
        "name": "标题中西文统一走 SimHei 自带西文",
        "need": r'#show heading: set text\(font: \("SimHei", "Noto Sans SC"\)\)',
        "forbid": r'#show heading: set text\(font: \("Arial"',
        "fix": "main.typ 标题一节改成 #show heading: set text(font: (\"SimHei\", \"Noto Sans SC\"))"
                 "——让西文走 Arial 会出现「英文明显比中文粗」（Arial 真粗体挨着 SimHei 常规体），"
                 "见技能模板 main.typ 的注释",
    },
    {
        # 2026-10-04：Bookly 把 raw 字号钉死成 0.8 倍正文（绝对 8.4pt），
        # 标题再大行内代码也不动，章标题里的 solve() 只有汉字一半高。
        "file": "main.typ",
        "name": "标题里的行内代码跟标题字体与字号",
        "need": r'#show heading: it =>[\s\S]{0,800}?show raw\.where\(block: false\)'
                r'[\s\S]{0,400}?"SimHei"',
        "fix": "main.typ 标题一节补：show heading 里套一层 show raw.where(block: false) =>"
                 " context text(font: (\"SimHei\", \"Noto Sans SC\"), size: head-raw-size.get(), …)，"
                 "并用 state 现场探标题字号。set text(size: 1.05em) 这种相对值会级联乘在钉死的"
                 " 8.4pt 上（实测 8.4×1.05=8.82，约等于没修），必须用绝对值，见技能模板",
    },
    {
        # 2026-10-03：custom-box 上游默认 breakable: true，短框顶到页尾会断成
        # 「标题牌孤悬页尾、框身跑到下页」两截。本模板把默认值反过来。
        "file": "boxes.typ",
        "name": "内置提示框默认不跨页（book-custom-box）",
        "need": r"#let book-custom-box\([\s\S]{0,400}?breakable: false",
        "forbid": r"#let book-custom-box\([\s\S]{0,400}?breakable: true",
        "fix": "boxes.typ 的 book-custom-box 默认 breakable: false（callout 同）——"
                 "上游默认 true，短框跨页会断成两截。可能超过一页的长框在调用点显式传 breakable: true",
    },
    {
        "file": "boxes.typ",
        "name": "代码清单保持可跨页（长清单不溢出页尾）",
        "need": r"#let code-box-zh = custom-box\.with\([\s\S]{0,300}?breakable: true",
        "fix": "code-box-zh 要显式传 breakable: true：默认改成 false 之后，"
                 "超过一页的代码清单会溢出页尾。长框改短框的调用点同理",
    },
    {
        "file": "colors.typ",
        "name": "六主题切换表（book-theme 一行换主题）",
        "need": r"#let themes = \(",
        "fix": "colors.typ 应有 themes 主题表与顶部 book-theme 一行切换，见技能模板",
    },
]


def strip_comments(src):
    """剥掉 Typst 的 // 与 /* */ 注释，字符串里的不误伤。

    规则匹配必须看代码：注释是解释代码的，不是代码本身。上图那条旧规则
    就是因为匹配注释串而两头不讨好。
    """
    out, i, n, in_str = [], 0, len(src), False
    while i < n:
        c = src[i]
        if in_str:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(src[i + 1])
                i += 2
                continue
            if c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if src.startswith("//", i):
            j = src.find("\n", i)
            if j < 0:
                break
            out.append("\n")
            i = j + 1
            continue
        if src.startswith("/*", i):
            j = src.find("*/", i + 2)
            if j < 0:
                break
            out.append("\n" * src.count("\n", i, j))
            i = j + 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


CORE = (
    "main.typ", "colors.typ", "boxes.typ", "chaptermark.typ",
    "figstyle.typ", "pagetabs.typ", "partpage.typ", "runninghead.typ",
    "code-theme.tmTheme",
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
            # 版本落后是「三件事」之一，必须计入 problems，否则本文件到底是
            # 「旧拷贝继续排版」的守门人，还是只打印一行提醒的观察者，说不清
            print(f"! 模板版本 {v_proj.group(1)} ≠ 技能 {v_skill.group(1)}：技能模板修过问题，"
                  f"对照技能模板逐条体检（保留你的定制），改完把版本戳设为 {v_skill.group(1)}")
            problems += 1
        else:
            print(f"✓ 模板版本 {v_proj.group(1)}（与技能一致）")

        for rule in CRITICAL_RULES:
            fpath = root / rule["file"]
            if not fpath.exists():
                continue  # 缺文件已在上面计过一次
            code = strip_comments(fpath.read_text(encoding="utf-8"))
            ok = True
            if rule.get("need") and not re.search(rule["need"], code):
                ok = False            # 该有的规则被删了
            if rule.get("forbid") and re.search(rule["forbid"], code):
                ok = False            # 该删的旧错法还在
            if ok:
                print(f"✓ {rule['name']}")
            else:
                print(f"✗ {rule['name']}——{rule['fix']}")
                problems += 1

    # 逐文件对比是信息性的：有差异可能是用户定制，也可能是旧拷贝。
    # 比较前把 CRLF 归一成 LF——Windows 上的拷贝常落成 CRLF，
    # 逐字节对比会把纯换行差异报成「有差异」，淹没真正的漂移
    if skill_tpl.is_dir():
        for f in CORE:
            a, b = root / f, skill_tpl / f
            if a.exists() and b.exists():
                same = (a.read_text(encoding="utf-8").replace("\r\n", "\n")
                        == b.read_text(encoding="utf-8").replace("\r\n", "\n"))
                print(f"- {f}: {'与技能模板一致' if same else '有差异（你的定制，或旧拷贝）'}")

    if problems:
        print(f"[doctor] 发现 {problems} 个问题——修完再开工；拿不准时对照技能模板同步（保留你的定制）")
        sys.exit(1)
    print("[doctor] 模板健康，可以开工")


if __name__ == "__main__":
    main()
