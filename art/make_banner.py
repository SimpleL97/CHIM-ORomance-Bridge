"""CHIM ORomance Bridge - Nexus banner (1920x1080), original artwork, no third-party logos.
Left half: CHIM - cold blue AI network and dialogue (as on the CHIM OStim Bridge banner).
Right half: ORomance - love and marriage: wine and gold, two wedding rings, rose petals.
The halves meet on a 45 degree diagonal. Writes banner.html; render it to PNG with a
headless browser (see render_banner.ps1).
"""
import math, os, random

W, H = 1920, 1080
C = W // 2 + H // 2          # 45 degree divider: x + y = C, through the middle
rnd = random.Random(2610)


def inside_left(x, y, margin=0):
    return x + y < C - margin


out = []
add = out.append
add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
add(f'''<defs>
  <linearGradient id="cold" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#040b1c"/><stop offset="0.55" stop-color="#0a2348"/><stop offset="1" stop-color="#0f3a6e"/>
  </linearGradient>
  <linearGradient id="warm" x1="1" y1="1" x2="0" y2="0">
    <stop offset="0" stop-color="#16061c"/><stop offset="0.5" stop-color="#4a1240"/><stop offset="1" stop-color="#8a2a52"/>
  </linearGradient>
  <radialGradient id="coldGlow" cx="0.32" cy="0.42" r="0.55">
    <stop offset="0" stop-color="#3fc8ff" stop-opacity="0.28"/><stop offset="1" stop-color="#3fc8ff" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="warmGlow" cx="0.76" cy="0.62" r="0.5">
    <stop offset="0" stop-color="#ffcf7a" stop-opacity="0.32"/><stop offset="1" stop-color="#ffcf7a" stop-opacity="0"/>
  </radialGradient>
  <linearGradient id="seam" x1="0" y1="1" x2="1" y2="0">
    <stop offset="0" stop-color="#3fc8ff"/><stop offset="0.5" stop-color="#ffffff"/><stop offset="1" stop-color="#ffcf7a"/>
  </linearGradient>
  <linearGradient id="titleGrad" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#7fdcff"/><stop offset="0.5" stop-color="#ffffff"/><stop offset="1" stop-color="#ffd98f"/>
  </linearGradient>
  <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#fff1c2"/><stop offset="0.35" stop-color="#f2c15a"/><stop offset="0.7" stop-color="#b9822a"/><stop offset="1" stop-color="#ffe29a"/>
  </linearGradient>
  <linearGradient id="goldText" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#fff0c8"/><stop offset="0.6" stop-color="#ffcf6e"/><stop offset="1" stop-color="#e9a84a"/>
  </linearGradient>
  <radialGradient id="petal" cx="0.4" cy="0.35" r="0.8">
    <stop offset="0" stop-color="#ff8aa8"/><stop offset="0.7" stop-color="#c2224f"/><stop offset="1" stop-color="#7d0f30"/>
  </radialGradient>
  <filter id="blur8"><feGaussianBlur stdDeviation="8"/></filter>
  <filter id="blur3" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3"/></filter>
  <filter id="soft" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="22"/></filter>
  <filter id="shadow" x="-20%" y="-50%" width="140%" height="200%">
    <feDropShadow dx="0" dy="4" stdDeviation="10" flood-color="#000" flood-opacity="0.85"/>
  </filter>
  <clipPath id="leftHalf"><polygon points="0,0 {C},0 {C - H},{H} 0,{H}"/></clipPath>
  <clipPath id="rightHalf"><polygon points="{C},0 {W},0 {W},{H} {C - H},{H}"/></clipPath>
  <path id="heart" d="M0,-30 C-25,-70 -90,-55 -90,-5 C-90,40 -30,75 0,105 C30,75 90,40 90,-5 C90,-55 25,-70 0,-30 Z"/>
  <path id="petalShape" d="M0,-40 C30,-38 42,-8 30,18 C20,38 -8,46 -26,30 C-44,12 -36,-36 0,-40 Z"/>
</defs>''')

# ---------------- left: CHIM
add('<g clip-path="url(#leftHalf)">')
add(f'<rect width="{W}" height="{H}" fill="url(#cold)"/><rect width="{W}" height="{H}" fill="url(#coldGlow)"/>')
for row in range(0, 30):
    for col in range(0, 40):
        x = col * 60 + (30 if row % 2 else 0)
        y = row * 52
        if inside_left(x, y):
            pts = " ".join(f"{x + 26 * math.cos(math.radians(a)):.1f},{y + 26 * math.sin(math.radians(a)):.1f}" for a in range(30, 390, 60))
            add(f'<polygon points="{pts}" fill="none" stroke="#3fc8ff" stroke-opacity="0.05" stroke-width="1"/>')
nodes = []
while len(nodes) < 70:
    x, y = rnd.uniform(40, C), rnd.uniform(40, H - 40)
    if inside_left(x, y, 60):
        nodes.append((x, y))
for (x1, y1) in nodes:
    for (x2, y2) in sorted(nodes, key=lambda p: (p[0] - x1) ** 2 + (p[1] - y1) ** 2)[1:4]:
        add(f'<line x1="{x1:.0f}" y1="{y1:.0f}" x2="{x2:.0f}" y2="{y2:.0f}" stroke="#3fc8ff" stroke-opacity="0.22" stroke-width="1.4"/>')
for (x, y) in nodes:
    r = rnd.uniform(2.5, 6)
    add(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r * 3:.1f}" fill="#3fc8ff" opacity="0.12" filter="url(#blur3)"/>')
    add(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r:.1f}" fill="#bff0ff" opacity="0.85"/>')


def bubble(cx, cy, w, h, tail_left, opacity, heart_inside=False):
    tail = f"M{cx - w * 0.25:.0f},{cy + h / 2:.0f} l{-28 if tail_left else 28},38 l{30 if tail_left else -30},-38 Z"
    add(f'<g opacity="{opacity}"><rect x="{cx - w / 2:.0f}" y="{cy - h / 2:.0f}" width="{w}" height="{h}" rx="{h / 2:.0f}" fill="#0b2a52" stroke="#7fdcff" stroke-width="3"/>'
        f'<path d="{tail}" fill="#0b2a52" stroke="#7fdcff" stroke-width="3" stroke-linejoin="round"/>')
    if heart_inside:
        add(f'<use href="#heart" transform="translate({cx},{cy - 6}) scale(0.32)" fill="#ff8fb0"/>')
    else:
        add("".join(f'<circle cx="{cx + d:.0f}" cy="{cy:.0f}" r="9" fill="#bff0ff"/>' for d in (-34, 0, 34)))
    add('</g>')


bubble(330, 300, 230, 96, True, 0.95)
bubble(620, 190, 190, 80, False, 0.85, heart_inside=True)
bubble(250, 820, 160, 70, True, 0.6)
add('</g>')

# ---------------- right: ORomance - love and marriage
add('<g clip-path="url(#rightHalf)">')
add(f'<rect width="{W}" height="{H}" fill="url(#warm)"/><rect width="{W}" height="{H}" fill="url(#warmGlow)"/>')
for _ in range(55):  # candle-light bokeh
    x, y = rnd.uniform(C - H, W), rnd.uniform(0, H)
    if not inside_left(x, y, -40):
        r = rnd.uniform(10, 55)
        col = rnd.choice(["#ffcf7a", "#ffb36b", "#ff8fb0", "#ffe9c4"])
        add(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r:.0f}" fill="{col}" opacity="{rnd.uniform(0.05, 0.17):.2f}" filter="url(#blur3)"/>')
for _ in range(26):  # falling rose petals
    x, y = rnd.uniform(C - H + 60, W), rnd.uniform(0, H)
    if not inside_left(x, y, -50):
        s = rnd.uniform(0.35, 0.8)
        add(f'<use href="#petalShape" transform="translate({x:.0f},{y:.0f}) rotate({rnd.uniform(0, 360):.0f}) scale({s:.2f})" fill="url(#petal)" opacity="{rnd.uniform(0.55, 0.9):.2f}"/>')


def ring(cx, cy, r, tilt, opacity=1.0):
    # an ellipse band: outer gold stroke, inner shine, slight perspective
    add(f'<g transform="translate({cx},{cy}) rotate({tilt})" opacity="{opacity}">'
        f'<ellipse rx="{r}" ry="{r * 0.92:.0f}" fill="none" stroke="#5a3410" stroke-width="30" opacity="0.5"/>'
        f'<ellipse rx="{r}" ry="{r * 0.92:.0f}" fill="none" stroke="url(#gold)" stroke-width="24"/>'
        f'<ellipse rx="{r - 7}" ry="{r * 0.92 - 7:.0f}" fill="none" stroke="#fff6d8" stroke-width="3" opacity="0.7"/>'
        f'</g>')


# glow behind the rings, then two interlocked wedding rings with a small diamond
add('<circle cx="1660" cy="800" r="230" fill="#ffcf7a" opacity="0.35" filter="url(#soft)"/>')
ring(1590, 820, 120, -18)
ring(1735, 790, 120, 14)
add('<path d="M1590,690 l22,-26 l22,26 l-22,30 Z" fill="#e8fbff" stroke="#ffffff" stroke-width="2" opacity="0.95"/>')
add('<path d="M1590,690 l22,-26 l22,26 Z" fill="#bfe9ff" opacity="0.8"/>')
# redraw the front part of the first ring over the second: the rings interlock
add('<g transform="translate(1590,820) rotate(-18)"><path d="M120,0 A120,110 0 0 1 60,95" fill="none" stroke="url(#gold)" stroke-width="24"/></g>')
for (x, y, s, o) in [(1440, 230, 0.55, 0.45), (1800, 330, 0.6, 0.5), (1420, 960, 0.5, 0.45)]:
    add(f'<use href="#heart" transform="translate({x},{y}) scale({s})" fill="#ff7a9c" stroke="#ffe2b0" stroke-width="{3 / s:.2f}" opacity="{o}"/>')
for _ in range(45):  # sparkles
    x, y = rnd.uniform(C - H + 100, W), rnd.uniform(0, H)
    if not inside_left(x, y, -60):
        s = rnd.uniform(2, 5)
        add(f'<path d="M{x:.0f},{y - s * 3:.0f} L{x + s:.0f},{y:.0f} L{x:.0f},{y + s * 3:.0f} L{x - s:.0f},{y:.0f} Z" fill="#fff4d6" opacity="{rnd.uniform(0.4, 0.9):.2f}"/>')
add('</g>')

# ---------------- seam
add(f'<line x1="{C - H - 20}" y1="{H + 20}" x2="{C + 20}" y2="-20" stroke="url(#seam)" stroke-width="26" opacity="0.35" filter="url(#blur8)"/>')
add(f'<line x1="{C - H - 20}" y1="{H + 20}" x2="{C + 20}" y2="-20" stroke="url(#seam)" stroke-width="5"/>')

# ---------------- title
add('<g font-family="Georgia, Palatino Linotype, serif" text-anchor="middle" filter="url(#shadow)">')
add(f'<rect x="{W / 2 - 640}" y="{H / 2 - 150}" width="1280" height="300" rx="28" fill="#000" opacity="0.38"/>')
add(f'<text x="{W / 2 - 250}" y="{H / 2 + 10}" text-anchor="end" font-size="130" font-weight="bold" letter-spacing="10" fill="#7fdcff">CHIM</text>')
add(f'<text x="{W / 2 - 190}" y="{H / 2 + 10}" text-anchor="start" font-size="130" font-weight="bold" letter-spacing="4" fill="url(#goldText)">ORomance</text>')
add(f'<text x="{W / 2}" y="{H / 2 + 100}" font-size="64" letter-spacing="34" fill="url(#titleGrad)">BRIDGE</text>')
add(f'<text x="{W / 2}" y="{H - 48}" font-size="34" letter-spacing="6" fill="#ffffff" opacity="0.85">by SaurOff</text>')
add('</g>')
add('</svg>')

here = os.path.dirname(os.path.abspath(__file__))
svg = "\n".join(out)
open(os.path.join(here, "banner.svg"), "w", encoding="utf-8").write(svg)
open(os.path.join(here, "banner.html"), "w", encoding="utf-8").write(
    '<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;padding:0;background:#000;overflow:hidden}</style></head><body>'
    + svg + "</body></html>")
print("written", os.path.join(here, "banner.html"))
