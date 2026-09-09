import os, sys
import uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

FONTS = os.environ.get("INTER_FONT_DIR", os.path.join(os.path.dirname(__file__), "fonts"))
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

_cache = {}
def load(weight):
    if weight not in _cache:
        path = f"{FONTS}/Inter-{weight}.ttf"
        tt = TTFont(path)
        blob = hb.Blob.from_file_path(path)
        face = hb.Face(blob); font = hb.Font(face)
        _cache[weight] = (tt, font, tt["head"].unitsPerEm)
    return _cache[weight]

def text_path(text, weight, size, x, y, tracking=0.0):
    """Return (svg path d, advance width) for text at baseline (x,y). tracking in em."""
    tt, font, upem = load(weight)
    buf = hb.Buffer(); buf.add_str(text); buf.guess_segment_properties()
    hb.shape(font, buf, {"kern": True, "liga": True})
    glyph_set = tt.getGlyphSet()
    order = tt.getGlyphOrder()
    scale = size / upem
    pen = SVGPathPen(glyph_set)
    cx = x
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        gname = order[info.codepoint]
        tp = TransformPen(pen, (scale, 0, 0, -scale, cx + pos.x_offset * scale, y - pos.y_offset * scale))
        glyph_set[gname].draw(tp)
        cx += pos.x_advance * scale + tracking * size
    return pen.getCommands(), cx - x - tracking * size

# ---- palette -----------------------------------------------------------
TEAL_DARK, TEAL_LIGHT = "#1E5B69", "#2E7A8B"   # icon gradient
# One colour per product line (light-bg value, dark-bg value)
PRODUCTS = {
    "POS": ("#D9701A", "#F5A054"),   # orange  - commerce, caisse
    "ERP": ("#1F4E8C", "#6FA3F0"),   # blue    - gestion, finance
    "CRM": ("#6B3FA0", "#B48CE6"),   # violet  - relation client
    "BI":  ("#1F8A5B", "#5CC48F"),   # green   - données, croissance
}
INK = "#0B0B0B"
DARK_BG = "#0F1B1F"

SCHEMES = {
    "color":   dict(bg=None,    ink=INK,     suffix=0, icon=("grad", TEAL_LIGHT, TEAL_DARK), line="#9A9A9A", tag="#111111"),
    "mono":    dict(bg=None,    ink=INK,     suffix=INK,           icon=("flat", INK, INK),              line="#555555", tag=INK),
    "inverse": dict(bg=DARK_BG, ink="#FFFFFF", suffix=1, icon=("grad", "#3E97A9", "#2A7585"), line="#7A8A8E", tag="#FFFFFF"),
}

def icon_svg(s, x0=0, y0=0):
    kind, c1, c2 = s["icon"]
    fill = "url(#ig)" if kind == "grad" else c1
    defs = f'<linearGradient id="ig" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>' if kind == "grad" else ""
    # Left bar: flat top, vertical sides, bottom edge sweeping down-left with a
    # large rounded bottom-left corner.  Right bar: flat bottom, top edge sweeping
    # up-right with a rounded top-right corner.  Icon box: 205 x 317.
    X, Y = x0, y0
    left = (f'<path fill="{fill}" d="M{X+10},{Y} L{X+73},{Y+2.5} Q{X+83},{Y+3.5} {X+83},{Y+13} '
            f'L{X+83},{Y+238} Q{X+83},{Y+249} {X+72},{Y+253} '
            f'C{X+50},{Y+261} {X+30},{Y+269} {X+16},{Y+274} '
            f'Q{X},{Y+279} {X},{Y+264} L{X},{Y+10} Q{X},{Y} {X+10},{Y} Z"/>')
    right = (f'<path fill="{fill}" d="M{X+116},{Y+98} Q{X+116},{Y+88} {X+127},{Y+84} '
             f'C{X+150},{Y+73} {X+172},{Y+60} {X+193},{Y+46} '
             f'Q{X+205},{Y+39} {X+205},{Y+52} '
             f'L{X+205},{Y+307} Q{X+205},{Y+317} {X+195},{Y+317} '
             f'L{X+126},{Y+317} Q{X+116},{Y+317} {X+116},{Y+307} Z"/>')
    return defs, left + right  # icon box: 205 x 317

def build(suffix, scheme, tagline=True):
    s = SCHEMES[scheme]
    PAD = 80
    ICON_W, ICON_H = 205, 317
    GAP_ICON = 110
    base_y = PAD + 244                       # wordmark baseline relative to icon top
    x = PAD + ICON_W + GAP_ICON
    d_word, w_word = text_path("Integra", 700, 222, x, base_y, tracking=-0.025)
    x2 = x + w_word + 48
    d_suf, w_suf = text_path(suffix, 600, 148, x2, base_y, tracking=0.035)
    suffix_fill = s["suffix"] if isinstance(s["suffix"], str) else PRODUCTS[suffix][s["suffix"]]
    right_edge = x2 + w_suf
    width = right_edge + PAD
    height = PAD + ICON_H + PAD
    tag = ""
    if tagline:
        tag_y = PAD + ICON_H + 90
        cx = (PAD + right_edge) / 2
        d_pw, w_pw = text_path("Powered by ", 500, 54, 0, 0)
        d_ebs, w_ebs = text_path("EBS", 700, 54, 0, 0)
        total = w_pw + w_ebs
        tx = cx - total / 2
        d_pw, _ = text_path("Powered by ", 500, 54, tx, tag_y)
        d_ebs, _ = text_path("EBS", 700, 54, tx + w_pw, tag_y)
        ly = tag_y - 19
        L = 120; g = 60
        tag = (f'<path d="{d_pw}" fill="{s["tag"]}"/><path d="{d_ebs}" fill="{s["tag"]}"/>'
               f'<line x1="{tx-g-L}" y1="{ly}" x2="{tx-g}" y2="{ly}" stroke="url(#lg1)" stroke-width="3" stroke-linecap="round"/>'
               f'<line x1="{tx+total+g}" y1="{ly}" x2="{tx+total+g+L}" y2="{ly}" stroke="url(#lg2)" stroke-width="3" stroke-linecap="round"/>')
        height = tag_y + PAD - 20
    defs, icon = icon_svg(s, PAD, PAD)
    if tagline:
        defs += (f'<linearGradient id="lg1" gradientUnits="userSpaceOnUse" x1="{tx-g-L}" y1="0" x2="{tx-g}" y2="0"><stop offset="0" stop-color="{s["line"]}" stop-opacity="0"/><stop offset="1" stop-color="{s["line"]}"/></linearGradient>'
                 f'<linearGradient id="lg2" gradientUnits="userSpaceOnUse" x1="{tx+total+g}" y1="0" x2="{tx+total+g+L}" y2="0"><stop offset="0" stop-color="{s["line"]}"/><stop offset="1" stop-color="{s["line"]}" stop-opacity="0"/></linearGradient>')
    bg = f'<rect width="{width:.0f}" height="{height:.0f}" fill="{s["bg"]}"/>' if s["bg"] else ""
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width:.0f} {height:.0f}" width="{width:.0f}" height="{height:.0f}">'
           f'<title>Integra {suffix}</title><defs>{defs}</defs>{bg}{icon}'
           f'<path d="{d_word}" fill="{s["ink"]}"/><path d="{d_suf}" fill="{suffix_fill}"/>{tag}</svg>')
    return svg

def build_icon(scheme):
    s = SCHEMES[scheme]
    defs, icon = icon_svg(s, 40, 40)
    w, h = 285, 397
    bg = f'<rect width="{w}" height="{h}" fill="{s["bg"]}"/>' if s["bg"] else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}"><title>Integra icon</title><defs>{defs}</defs>{bg}{icon}</svg>'

files = []
for suf in PRODUCTS:
    for scheme in SCHEMES:
        name = f"integra-{suf.lower()}-{scheme}"
        open(f"{OUT}/{name}.svg", "w").write(build(suf, scheme, tagline=True))
        files.append(name)
        name = f"integra-{suf.lower()}-{scheme}-compact"
        open(f"{OUT}/{name}.svg", "w").write(build(suf, scheme, tagline=False))
        files.append(name)
for scheme in SCHEMES:
    name = f"integra-icon-{scheme}"
    open(f"{OUT}/{name}.svg", "w").write(build_icon(scheme))
    files.append(name)
print("\n".join(files))
