#!/usr/bin/env python3
"""doctor.py 的自检：拿技能模板当「健康项目」，逐条故意改坏，看 doctor 抓不抓得到。

  python scripts/test_doctor.py

为什么要它：doctor.py 的规则是「旧拷贝缺了什么」的唯一定义，规则写歪了没人
会发现——改坏的 doctor 依旧报「模板健康」。这个自检把每条规则正反都验一遍：
该报的必须报，不该误伤的（比如图注本地化的 set 规则）必须放过。
模板本身就是一份能编译的健康脚手架，所以不需要额外 fixture。
纯标准库，Python 3.8+。
"""

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
DOCTOR = HERE / "doctor.py"
TEMPLATE = HERE.parent / "template"

sys.path.insert(0, str(HERE))
sys.dont_write_bytecode = True  # 别在技能目录里留 __pycache__
import doctor  # noqa: E402  复用它的 strip_comments，保证与体检口径一致


def run_doctor(root):
    """跑一次 doctor.py，返回 (退出码, 报出的失败项列表)。"""
    r = subprocess.run(
        [sys.executable, str(DOCTOR), "--root", str(root)],
        capture_output=True, text=True,
        encoding="utf-8", errors="replace",
        env={"PYTHONIOENCODING": "utf-8"},
    )
    fails = [ln for ln in r.stdout.splitlines() if ln.startswith("✗")]
    return r.returncode, fails


def patch(project, fname, old, new, regex=False):
    """改动一处并断言真的改到了——模板演进后用例失效要响，不能静默通过。"""
    p = project / fname
    src = p.read_text(encoding="utf-8")
    out = re.sub(old, new, src, count=1) if regex else src.replace(old, new, 1)
    if out == src:
        raise AssertionError(f"补丁没生效（模板可能已变）：{fname} / {old[:60]}")
    p.write_text(out, encoding="utf-8")


def fresh(tmp, name):
    d = tmp / name
    shutil.copytree(TEMPLATE, d)
    return d


def strip_all_comments(project, names=("main.typ", "boxes.typ", "colors.typ")):
    for f in names:
        p = project / f
        p.write_text(doctor.strip_comments(p.read_text(encoding="utf-8")), encoding="utf-8")


def build_cases(tmp):
    """(用例名, 项目目录, 期望退出码, 失败项里必须出现的片段)。"""
    cases = [("健康模板", fresh(tmp, "ok"), 0, [])]

    # 旧 doctor 靠注释串「插图：不需要额外规则」判断，删注释就误报。
    # 这条保证「规则只认代码」不会退回去。
    d = fresh(tmp, "nocomment")
    strip_all_comments(d)
    cases.append(("注释全删（旧规则会误报）", d, 0, []))

    d = fresh(tmp, "arial")
    patch(d, "main.typ", '(font: ("SimHei", "Noto Sans SC"))',
          '(font: ("Arial", "SimHei", "Noto Sans SC"))')
    cases.append(("标题退回 Arial 混排", d, 1, ["SimHei"]))

    d = fresh(tmp, "headraw")
    patch(d, "main.typ", "show raw.where(block: false)",
          "show raw.where(block: false, nothing)")
    cases.append(("标题行内代码规则被改坏", d, 1, ["行内代码"]))

    d = fresh(tmp, "breakable")
    patch(d, "boxes.typ", r"(#let book-custom-box\([\s\S]{0,300}?)breakable: false",
          r"\1breakable: true", regex=True)
    cases.append(("内置框退回可跨页", d, 1, ["不跨页"]))

    d = fresh(tmp, "codebox")
    patch(d, "boxes.typ", "  breakable: true,\n)\n\n#let subfigure-zh",
          "  breakable: false,\n)\n\n#let subfigure-zh")
    cases.append(("代码清单被改成不跨页", d, 1, ["代码清单"]))

    d = fresh(tmp, "showimg")
    p = d / "main.typ"
    p.write_text(p.read_text(encoding="utf-8")
                 + "\n#show image: it => layout(sz => context { scale(x: 50%) })\n",
                 encoding="utf-8")
    cases.append(("加回 show image 缩放", d, 1, ["重复缩放"]))

    # 反例的另一半：图注本地化是正解，换成转换型才该报
    d = fresh(tmp, "caption")
    p = d / "main.typ"
    src = p.read_text(encoding="utf-8")
    line = "#show figure.where(kind: image): set figure(supplement: [图])"
    p.write_text(src.replace(line, "") + "\n" + line + "\n", encoding="utf-8")
    cases.append(("图注本地化换个位置（不许误伤）", d, 0, []))

    return cases


def check_template_invariants():
    """模板自己的红线（不是 doctor 的规则）：文档里反复强调的两条行为约定。"""
    bad = []
    want = "placement: if float-images { auto } else { none }"
    main_typ = (TEMPLATE / "main.typ").read_text(encoding="utf-8").replace("\r\n", "\n")
    if want not in main_typ:
        bad.append(f"main.typ 的插图浮动开关不是 `{want}`")
    for p in sorted(TEMPLATE.rglob("*.typ")):
        text = p.read_text(encoding="utf-8").replace("\r\n", "\n")
        if re.search(r"set figure\(\s*placement:\s*none\s*\)", text):
            bad.append(f"{p.relative_to(TEMPLATE)}：无条件关掉了插图浮动（页底会留白）")
    return bad


def main():
    if not TEMPLATE.is_dir():
        sys.exit(f"找不到技能模板目录：{TEMPLATE}")
    tmp = Path(tempfile.mkdtemp(prefix="doctor-selftest-"))
    failed = 0
    try:
        for name, project, want_code, want_frag in build_cases(tmp):
            code, fails = run_doctor(project)
            ok = code == want_code
            for frag in want_frag:
                if not any(frag in f for f in fails):
                    ok = False
            if want_code == 0 and fails:
                ok = False
            print(f"[{'PASS' if ok else 'FAIL'}] {name:<26} 退出码 {code}（期望 {want_code}）")
            for f in fails:
                print("        " + f[:100])
            if not ok:
                failed += 1
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    inv = check_template_invariants()
    print(f"[{'PASS' if not inv else 'FAIL'}] {'模板不变量（浮动开关/无全局 none）':<22} {len(inv)} 处不合")
    for line_ in inv:
        print("        " + line_)
    if inv:
        failed += 1

    if failed:
        sys.exit(f"{failed} 个用例失败——doctor.py 的规则与模板的实际写法脱节了")
    print("doctor 自检通过：规则该报的报、不该误伤的放过")


if __name__ == "__main__":
    main()
