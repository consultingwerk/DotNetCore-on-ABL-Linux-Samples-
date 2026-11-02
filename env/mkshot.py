#!/usr/bin/env python3
"""Render captured demo output as an SVG 'screenshot'.
SVG so it stays sharp on any projector; convert to PNG if your deck prefers raster.
Usage: mkshot.py <title> <input.txt> <output.svg>"""
import sys, html

title, src, dst = sys.argv[1], sys.argv[2], sys.argv[3]
lines = open(src).read().rstrip("\n").split("\n")

FS, LH, PAD, TOP = 23, 33, 34, 76
W = 1920
H = max(600, TOP + len(lines) * LH + PAD)

BG, FG, DIM, ACC, OK, BAD = "#11151c", "#d8dee9", "#6b7684", "#7fb3ff", "#8fd98f", "#ff8a8a"

def colour(s):
    t = s.strip()
    if t.startswith("==") or t.startswith("----------"): return ACC
    if ": no" in s or "FAILED" in s or "cannot access" in s or "reason" in s: return BAD
    if ": yes" in s or "exit code: 2" in s: return OK
    if t.startswith("--"): return DIM
    return FG

out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
       f'<rect width="{W}" height="{H}" rx="14" fill="{BG}"/>',
       f'<rect width="{W}" height="46" rx="14" fill="#1b212b"/>',
       '<circle cx="28" cy="23" r="7" fill="#ff5f57"/><circle cx="52" cy="23" r="7" fill="#febc2e"/>'
       '<circle cx="76" cy="23" r="7" fill="#28c840"/>',
       f'<text x="104" y="30" font-family="monospace" font-size="19" fill="{DIM}">{html.escape(title)}</text>']
for i, ln in enumerate(lines):
    out.append(f'<text x="{PAD}" y="{TOP + i*LH}" font-family="DejaVu Sans Mono,Menlo,monospace" '
               f'font-size="{FS}" fill="{colour(ln)}" xml:space="preserve">{html.escape(ln)}</text>')
out.append("</svg>")
open(dst, "w").write("\n".join(out))
print(f"{dst}  ({W}x{H}, {len(lines)} lines)")
