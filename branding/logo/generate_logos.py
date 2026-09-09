"""Generate the Integra product logo family from the official master SVG.

Every path of the master (icon, "Integra" wordmark, "Powered by EBS" tagline)
is reused verbatim.  Only the product suffix group is swapped: "ERP" keeps the
master's own outlines; the other suffixes are set in Inter SemiBold at the
master's metrics (cap height, baseline, start x, letter spacing calibrated on
the width of "ERP") and converted to outlines, so no font is needed to view
the files.

Usage:  python3 generate_logos.py <output dir>
Needs:  pip install fonttools uharfbuzz svgelements
        Inter-600.ttf in ./fonts (or $INTER_FONT_DIR)
"""
import os, re, sys
import uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from svgelements import Path, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.environ.get("INTER_FONT_DIR", os.path.join(HERE, "fonts"))
MASTER = os.path.join(HERE, "source", "integra-complet.svg")
OUT = sys.argv[1] if len(sys.argv) > 1 else HERE
os.makedirs(OUT, exist_ok=True)

# ---- master ---------------------------------------------------------------
src = open(MASTER, encoding="utf-8").read()
groups = dict(re.findall(r'<g fill="([^"]+)">(.*?)</g>', src, re.S))
ICON, WORD, SUFFIX_ERP, TAGLINE = (groups[k] for k in ("url(#g)", "#17233A", "#1f5f6e", "#64748B"))
FLIP_T = "translate(0,1374) scale(0.1,-0.1)"          # master path space -> px
FLIP = Matrix(FLIP_T)

def bbox(body):
    xs, ys = [], []
    for d in re.findall(r'd="([^"]+)"', body):
        p = Path(d); p *= FLIP; x0, y0, x1, y1 = p.bbox()
        xs += [x0, x1]; ys += [y0, y1]
    return min(xs), min(ys), max(xs), max(ys)

ix0, iy0, ix1, iy1 = bbox(ICON)          # 206, 234, 652, 923
sx0, sy0, sx1, sy1 = bbox(SUFFIX_ERP)    # 2552, 494, 2985, 670
tx0, ty0, tx1, ty1 = bbox(TAGLINE)       # 730, 1008, 2461, 1125
H = 1374
RIGHT_MARGIN = 3136 - sx1
CAP = sy1 - sy0                          # 176 px
BASELINE = sy1

# ---- type -------------------------------------------------------------------
tt = TTFont(os.path.join(FONTS, "Inter-600.ttf"))
hbfont = hb.Font(hb.Face(hb.Blob.from_file_path(os.path.join(FONTS, "Inter-600.ttf"))))
UPEM = tt["head"].unitsPerEm
SIZE = CAP / (tt["OS/2"].sCapHeight / UPEM)
GLYPHS, ORDER = tt.getGlyphSet(), tt.getGlyphOrder()

def outlines(text, x, y, tracking):
    """(svg path d in px space, ink right edge) for text on baseline (x, y)."""
    buf = hb.Buffer(); buf.add_str(text); buf.guess_segment_properties()
    hb.shape(hbfont, buf, {"kern": True})
    pen = SVGPathPen(GLYPHS); scale = SIZE / UPEM; cx = x; right = x
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        g = ORDER[info.codepoint]
        GLYPHS[g].draw(TransformPen(pen, (scale, 0, 0, -scale, cx + pos.x_offset * scale, y - pos.y_offset * scale)))
        p = Path(pen.getCommands())  # cheap enough for 2-3 glyphs
        right = p.bbox()[2]
        cx += pos.x_advance * scale + tracking * SIZE
    return pen.getCommands(), right

# calibrate tracking so Inter "ERP" is exactly as wide as the master's "ERP"
_, r0 = outlines("ERP", sx0, BASELINE, 0.0)
TRACKING = ((sx1 - sx0) - (r0 - sx0)) / (2 * SIZE)

# ---- palette ----------------------------------------------------------------
PRODUCTS = {                       # (light background, dark background)
    "POS": ("#D9701A", "#F5A054"),
    "ERP": ("#1F4E8C", "#6FA3F0"),
    "CRM": ("#6B3FA0", "#B48CE6"),
    "BI":  ("#1F8A5B", "#5CC48F"),
}
NAVY = "#17233A"
SCHEMES = {
    "color":   dict(bg=None,      word=NAVY,      tag="#64748B", icon=("#2E7D91", "#164752"), idx=0),
    "mono":    dict(bg=None,      word=NAVY,      tag=NAVY,      icon=(NAVY, NAVY),           idx=None),
    "inverse": dict(bg="#0F1622", word="#FFFFFF", tag="#A7B1C2", icon=("#3A93A8", "#1E5D6B"), idx=1),
}

def suffix_group(product, fill):
    if product == "ERP":
        return f'<g transform="{FLIP_T}" fill="{fill}">{SUFFIX_ERP}</g>', sx1
    d, right = outlines(product, sx0, BASELINE, TRACKING)
    return f'<path fill="{fill}" d="{d}"/>', right

def svg(product, scheme, tagline=True, icon_only=False):
    s = SCHEMES[scheme]
    fill = NAVY if s["idx"] is None else PRODUCTS[product][s["idx"]]
    defs = (f'<linearGradient id="g" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="{s["icon"][0]}"/><stop offset="1" stop-color="{s["icon"][1]}"/></linearGradient>')
    if icon_only:
        pad = 40; vb = (ix0 - pad, iy0 - pad, ix1 - ix0 + 2 * pad, iy1 - iy0 + 2 * pad)
        body = f'<g transform="{FLIP_T}" fill="url(#g)">{ICON}</g>'
        label = "Integra"
    else:
        suf, right = suffix_group(product, fill)
        W = right + RIGHT_MARGIN
        body = (f'<g transform="{FLIP_T}"><g fill="url(#g)">{ICON}</g><g fill="{s["word"]}">{WORD}</g></g>{suf}')
        if tagline:
            dx = ((ix0 + right) / 2) - ((tx0 + tx1) / 2)          # keep tagline centred under the whole mark
            body += f'<g transform="translate({dx:.1f},0)"><g transform="{FLIP_T}" fill="{s["tag"]}">{TAGLINE}</g></g>'
            vb = (0, 0, W, H)
        else:
            top = iy0 - 150; vb = (0, top, W, iy1 + 150 - top)
        label = f"Integra {product}"
    x, y, w, h = vb
    bg = f'<rect x="{x:.0f}" y="{y:.0f}" width="{w:.0f}" height="{h:.0f}" fill="{s["bg"]}"/>' if s["bg"] else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x:.0f} {y:.0f} {w:.0f} {h:.0f}" '
            f'width="{w/2:.0f}" height="{h/2:.0f}" role="img" aria-label="{label}">'
            f'<title>{label}</title><defs>{defs}</defs>{bg}{body}</svg>')

def write(name, content):
    open(os.path.join(OUT, name + ".svg"), "w", encoding="utf-8").write(content); print(name)

for product in PRODUCTS:
    for scheme in SCHEMES:
        write(f"integra-{product.lower()}-{scheme}", svg(product, scheme))
        write(f"integra-{product.lower()}-{scheme}-compact", svg(product, scheme, tagline=False))
for scheme in SCHEMES:
    write(f"integra-icon-{scheme}", svg("ERP", scheme, icon_only=True))
