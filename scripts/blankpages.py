#!/usr/bin/env python3
"""找出书稿里的空白衬页，核对 pagetabs.typ 的 tab-skip-pages。

背景
----
书页从右页起排，open-right 会自动插空白衬页。这类页面没有页眉页码，
更不该印切口色标。但「本页是否空白」在 Typst 里没法稳定地自动判定
（段落位置逐轮摆动，par 查询会触发 convergence 告警），所以
template/pagetabs.typ 里是一行手工清单 `tab-skip-pages`。
手工清单一改内容就漂：漏一页，空白页上就多出一枚色标。

本脚本把清单变成可复算的：编译出页图，逐页数非白像素。
- 纯白的页 = 空白衬页；
- 「几乎全白、只有切口边一条实心色块」= 那就是漏网的色标。

用法
----
  python scripts/blankpages.py --root <书稿目录>            # 只报告
  python scripts/blankpages.py --root <书稿目录> --write    # 回填清单
  python scripts/blankpages.py --root <书稿目录> --check    # CI：漂移即 exit 1

`--root` 是含 main.typ 与 pagetabs.typ 的目录（scaffold.py 生成的书稿根目录，
或本技能的 template/ 目录）。

退出码
------
  0  没有问题（或报告模式发现的问题不致命）
  1  仅 --check：清单漂移 / 空白页仍印色标
  2  环境问题：找不到 typst 或文件、PNG 解不开
"""

from __future__ import annotations

import argparse
import math
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib
from pathlib import Path

# Windows 中文控制台默认 GBK：不先切 UTF-8，打印中文/符号会直接崩。
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8")

# 任一通道低于 FLOOR 就算「非白」。纯白页是 255/255/255；
# 浅色色标（橙、黄）也至少有一个通道明显低于 243。
FLOOR = 243
# 正文页的非白像素是几万起；空白页是 0。这两个阈值只作保险。
MIN_DARK = 20          # 低于此：判为空白页
MIN_TAB_PIXELS = 100   # 切口条带里超过此：判为画着色标
LIST_RE = re.compile(r"^(#let\s+tab-skip-pages\s*=\s*\()([^)]*)(\).*)$", re.M | re.S)
WIDTH_RE = re.compile(r"#let\s+tab-width\s*=\s*([\d.]+)\s*mm")


def fail(msg: str, code: int = 2) -> "NoReturn":  # type: ignore[name-defined]
    print(f"错误：{msg}", file=sys.stderr)
    sys.exit(code)


# --------------------------------------------------------------------------
# PNG：只读 IHDR / IDAT，支持 typst 输出的 8 bit 灰度 / RGB / RGBA
# --------------------------------------------------------------------------
def png_stats(path: Path, strip_px: int) -> tuple[int, int]:
    """返回 (全页非白像素数, 左/右切口条带内的非白像素数)。"""
    raw = path.read_bytes()
    if raw[:8] != b"\x89PNG\r\n\x1a\n":
        fail(f"{path} 不是 PNG")
    pos, idat, width, height, depth, ctype = 8, bytearray(), 0, 0, 8, 2
    while pos < len(raw):
        (length,) = struct.unpack(">I", raw[pos : pos + 4])
        kind = raw[pos + 4 : pos + 8]
        body = raw[pos + 8 : pos + 8 + length]
        if kind == b"IHDR":
            width, height, depth, ctype = struct.unpack(">IIBB", body[:10])
        elif kind == b"IDAT":
            idat += body
        elif kind == b"IEND":
            break
        pos += 12 + length
    if depth != 8 or ctype not in (0, 2, 4, 6):
        fail(f"{path.name}: 暂不支持 depth={depth} colortype={ctype} 的 PNG")
    channels = {0: 1, 2: 3, 4: 2, 6: 4}[ctype]
    pixels = zlib.decompress(bytes(idat))
    stride = width * channels
    # 切口条带：左边缘和右边缘各 strip_px 列（色标贴奇数页右、偶数页左）
    inside = [
        range(0, min(strip_px, width) * channels, channels),
        range(max(0, width - strip_px) * channels, stride, channels),
    ]
    prev = bytearray(stride)
    total = tab = 0
    at = 0
    for _y in range(height):
        ftype = pixels[at]
        at += 1
        line = bytearray(pixels[at : at + stride])
        at += stride
        if ftype == 1:  # Sub
            for i in range(channels, stride):
                line[i] = (line[i] + line[i - channels]) & 0xFF
        elif ftype == 2:  # Up
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif ftype == 3:  # Average
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif ftype == 4:  # Paeth
            for i in range(stride):
                a = line[i - channels] if i >= channels else 0
                b = prev[i]
                c = prev[i - channels] if i >= channels else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 0xFF
        elif ftype != 0:
            fail(f"{path.name}: 未知的 PNG 行过滤类型 {ftype}")
        for x in range(0, stride, channels):
            if channels >= 3:
                dark = line[x] < FLOOR or line[x + 1] < FLOOR or line[x + 2] < FLOOR
            else:
                dark = line[x] < FLOOR
            if dark:
                total += 1
        for rng in inside:
            for x in rng:
                if line[x] < FLOOR or (channels >= 3 and (line[x + 1] < FLOOR or line[x + 2] < FLOOR)):
                    tab += 1
        prev = line
    return total, tab


# --------------------------------------------------------------------------
def render_pages(root: Path, main: Path, ppi: int, outdir: Path) -> list[Path]:
    typst = shutil.which("typst")
    if not typst:
        fail("找不到 typst。装好后重试：https://github.com/typst/typst#installation")
    cmd = [typst, "compile", "--format", "png", "--ppi", str(ppi), str(main), str(outdir / "p{p}.png")]
    done = subprocess.run(cmd, cwd=root, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if done.returncode != 0:
        sys.stderr.write(done.stdout or "")
        sys.stderr.write(done.stderr or "")
        fail(f"编译失败（{done.returncode}）：{main}")
    shots = []
    for p in outdir.glob("p*.png"):
        m = re.fullmatch(r"p(\d+)\.png", p.name)
        if m:
            shots.append((int(m.group(1)), p))
    if not shots:
        fail("没有生成任何页图，检查 main.typ 是否能编出页面")
    # typst 的 {p} 不补零，p10 会排在 p2 前面，这里必须按数字排序
    return [p for _, p in sorted(shots)]


def read_list(tabs: Path) -> list[int]:
    m = LIST_RE.search(tabs.read_text(encoding="utf-8"))
    if not m:
        fail(f"{tabs.name} 里找不到 `#let tab-skip-pages = (...)`")
    return [int(n) for n in re.findall(r"\d+", m.group(2))]


def write_list(tabs: Path, pages: list[int]) -> None:
    text = tabs.read_text(encoding="utf-8")
    m = LIST_RE.search(text)
    if not m:
        fail(f"{tabs.name} 里找不到 `#let tab-skip-pages = (...)`")
    new = f"{m.group(1)}{', '.join(str(n) for n in pages)}{m.group(3)}"
    tabs.write_text(text[: m.start()] + new + text[m.end() :], encoding="utf-8")


def tab_strip_px(tabs: Path, ppi: int) -> int:
    m = WIDTH_RE.search(tabs.read_text(encoding="utf-8"))
    width_mm = float(m.group(1)) if m else 6.5
    return math.ceil(width_mm * ppi / 25.4) + 1


def main() -> int:
    ap = argparse.ArgumentParser(description="找出空白衬页并核对 pagetabs.typ 的清单")
    ap.add_argument("--root", default=".", help="含 main.typ 与 pagetabs.typ 的目录")
    ap.add_argument("--main", default="main.typ", help="主文件（相对 --root）")
    ap.add_argument("--tabs", default="pagetabs.typ", help="清单所在文件（相对 --root）")
    ap.add_argument("--ppi", type=int, default=50, help="页图分辨率，越大越慢（默认 50）")
    ap.add_argument("--min-dark", type=int, default=MIN_DARK, help="低于此非白像素数即判为空白")
    ap.add_argument("--write", action="store_true", help="把检测结果回填到 pagetabs.typ")
    ap.add_argument("--check", action="store_true", help="清单漂移或无空白页出斑时以非零码退出")
    ap.add_argument("--keep", metavar="DIR", help="把页图留在这个目录里，便于肉眼核对")
    args = ap.parse_args()

    root = Path(args.root).resolve()
    main_file = (root / args.main).resolve()
    tabs_file = (root / args.tabs).resolve()
    for f, what in ((main_file, "主文件"), (tabs_file, "清单文件")):
        if not f.is_file():
            fail(f"找不到{what}：{f}")

    tmpdir = Path(args.keep).resolve() if args.keep else Path(tempfile.mkdtemp(prefix="blankpages-"))
    tmpdir.mkdir(parents=True, exist_ok=True)
    shots = render_pages(root, main_file, args.ppi, tmpdir)
    strip = tab_strip_px(tabs_file, args.ppi)

    blank, stray = [], []
    for page_no, png in enumerate(shots, start=1):
        total, in_strip = png_stats(png, strip)
        if total < args.min_dark:
            blank.append(page_no)
        elif total - in_strip < args.min_dark and in_strip >= MIN_TAB_PIXELS:
            # 整页几乎全白，只有切口边一条实心色块
            stray.append(page_no)

    listed = read_list(tabs_file)
    missing = [p for p in blank if p not in listed]
    extra = [p for p in listed if p not in blank and p not in stray]

    print(f"书稿：{root}")
    print(f"页数：{len(shots)}    空白衬页：{blank or '（无）'}")
    print(f"清单：{listed or '（空）'}")
    if stray:
        print(f"空白页上残留色标：{stray}  ← 这些页是空白页却印了色标（真 bug）")
    if extra:
        print(f"清单多出：{extra}  ← 这些页并不空白，属过期项（无害，说明内容动过）")
    if missing:
        print(f"清单漏掉：{missing}  ← 空白衬页，但不在清单里")
    if not (stray or extra or missing):
        print("清单与页面一致。")

    if args.write:
        write_list(tabs_file, blank)
        print(f"已回填 {tabs_file}：{blank}")
    if args.keep:
        print(f"页图留在 {tmpdir}")
    else:
        shutil.rmtree(tmpdir, ignore_errors=True)

    if args.check and (stray or missing or extra):
        print("结论：清单漂移，按提示修；加 --write 可直接回填。", file=sys.stderr)
        return 1
    if not args.write and not args.check and (stray or missing):
        print("提示：加 --write 自动回填，或 --check 放进 CI。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
