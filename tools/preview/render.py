#!/usr/bin/env python3
"""Draws the operations written by tools/preview/layout.lua into a PNG.

usage: render.py ops.txt out.png [--crop l,b,r,t] [--scale 1.0]
Icons (Interface\\Icons\\*) are fetched once from the WoW icon CDN into tools/preview/.cache.
3D models are drawn as labelled silhouettes (the real client renders them).
"""
import os, re, sys, urllib.request
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, ".cache")
FONT_DIR = os.environ.get("BSI_FONT_DIR", CACHE)
os.makedirs(CACHE, exist_ok=True)
_fonts = {}


def font(size, bold=False):
    key = (int(size), bold)
    if key not in _fonts:
        name = "NanumGothic-Bold.ttf" if bold else "NanumGothic-Regular.ttf"
        path = os.path.join(FONT_DIR, name)
        try:
            _fonts[key] = ImageFont.truetype(path, max(6, int(size)))
        except OSError:
            _fonts[key] = ImageFont.load_default()
    return _fonts[key]


def rgba(s, alpha=1.0):
    r, g, b, a = [float(x) for x in s.split(",")]
    return (int(r * 255), int(g * 255), int(b * 255), int(max(0, min(1, a * alpha)) * 255))


_icons = {}
ADDON_ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "BigStoryIdleRPG"))
_addon = {}


def addon_tex(path):
    """Interface\\AddOns\\BigStoryIdleRPG\\Media\\... -> the local .tga"""
    p = path.replace("/", "\\")
    low = p.lower()
    key = "\\addons\\bigstoryidlerpg\\"
    i = low.find(key)
    if i < 0:
        return None
    rel = p[i + len(key):].replace("\\", os.sep)
    if rel in _addon:
        return _addon[rel]
    img = None
    for ext in ("", ".tga", ".TGA", ".blp"):
        fn = os.path.join(ADDON_ROOT, rel + ext)
        if os.path.exists(fn):
            try:
                img = Image.open(fn).convert("RGBA")
            except Exception:
                img = None
            break
    _addon[rel] = img
    return img


def icon(path):
    name = path.replace("/", "\\").split("\\")[-1].lower()
    if name in _icons:
        return _icons[name]
    img = None
    if "\\icons\\" in path.lower().replace("/", "\\"):
        fn = os.path.join(CACHE, name + ".jpg")
        if not os.path.exists(fn):
            try:
                url = "https://wow.zamimg.com/images/wow/icons/large/%s.jpg" % name
                req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=15) as r, open(fn, "wb") as f:
                    f.write(r.read())
            except Exception:
                fn = None
        if fn and os.path.exists(fn):
            try:
                img = Image.open(fn).convert("RGBA")
            except Exception:
                img = None
    _icons[name] = img
    return img


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), (20, 22, 28, 255))

    def box(self, l, b, r, t):
        x0, x1 = sorted((int(round(l)), int(round(r))))
        y0, y1 = sorted((int(round(self.h - t)), int(round(self.h - b))))
        return (x0, y0, max(x1, x0 + 1), max(y1, y0 + 1))

    def layer(self):
        return Image.new("RGBA", self.img.size, (0, 0, 0, 0))

    def put(self, lay):
        self.img = Image.alpha_composite(self.img, lay)


def draw_text(cv, l, b, r, t, size, color, alpha, jh, jv, flags, text):
    text = text.replace("\\n", "\n")
    bold = size >= 13 or "OUTLINE" in flags
    f = font(size * 1.05, bold)
    base = rgba(color, alpha)
    # split into runs: (kind, value, color)
    lines = text.split("\n")
    lay = cv.layer()
    d = ImageDraw.Draw(lay)
    lh = int(size * 1.25)
    total_h = lh * len(lines)
    x0, y0, x1, y1 = cv.box(l, b, r, t)
    if jv == "TOP":
        y = y0
    elif jv == "BOTTOM":
        y = y1 - total_h
    else:
        y = (y0 + y1) / 2 - total_h / 2
    for line in lines:
        runs = []
        cur = base
        pos = 0
        for m in re.finditer(r"\|c([0-9a-fA-F]{8})|\|r|\|T([^|]*)\|t", line):
            if m.start() > pos:
                runs.append(("t", line[pos:m.start()], cur))
            if m.group(1):
                h = m.group(1)
                cur = (int(h[2:4], 16), int(h[4:6], 16), int(h[6:8], 16), base[3])
            elif m.group(0) == "|r":
                cur = base
            else:
                runs.append(("i", m.group(2).split(":")[0], cur))
            pos = m.end()
        if pos < len(line):
            runs.append(("t", line[pos:], cur))
        width = 0
        for k, v, c in runs:
            width += int(size) + 2 if k == "i" else d.textlength(v, font=f)
        if jh == "LEFT":
            x = x0
        elif jh == "RIGHT":
            x = x1 - width
        else:
            x = (x0 + x1) / 2 - width / 2
        for k, v, c in runs:
            if k == "i":
                ic = icon(v)
                s = int(size)
                if ic:
                    lay.alpha_composite(ic.resize((s, s)), (int(x), int(y + (lh - s) / 2)))
                else:
                    d.rectangle([x, y + 2, x + s, y + 2 + s], fill=(90, 90, 110, 255))
                x += s + 2
            else:
                shadow = (0, 0, 0, min(255, c[3]))
                d.text((x + 1, y + 1), v, font=f, fill=shadow)
                d.text((x, y), v, font=f, fill=c)
                x += d.textlength(v, font=f)
        y += lh
    cv.put(lay)


def main():
    ops_path, out = sys.argv[1], sys.argv[2]
    crop = None
    scale = 1.0
    args = sys.argv[3:]
    for i, a in enumerate(args):
        if a == "--crop":
            crop = [float(x) for x in args[i + 1].split(",")]
        if a == "--scale":
            scale = float(args[i + 1])
    rows = [line.rstrip("\n").split("\t") for line in open(ops_path, encoding="utf-8") if line.strip()]
    w, h = int(rows[0][1]), int(rows[0][2])
    cv = Canvas(w, h)
    for row in rows[1:]:
        op = row[0]
        try:
            l, b, r, t = [float(x) for x in row[1:5]]
        except ValueError:
            continue
        if r - l < 0.5 or t - b < 0.5:
            if op != "text":
                continue
        x0, y0, x1, y1 = cv.box(l, b, r, t)
        if op == "fill":
            lay = cv.layer()
            ImageDraw.Draw(lay).rectangle([x0, y0, x1 - 1, y1 - 1], fill=rgba(row[5], float(row[6])))
            cv.put(lay)
        elif op == "backdrop":
            bg, border, a, bgfile, edge, esize = row[5], row[6], float(row[7]), row[8], row[9], float(row[10] or 0)
            lay = cv.layer()
            d = ImageDraw.Draw(lay)
            rounded = "tooltip" in edge.lower() or "dialog" in edge.lower()
            rad = max(3, int(esize / 2.2)) if rounded else 0
            if bgfile:
                if rad:
                    d.rounded_rectangle([x0, y0, x1 - 1, y1 - 1], radius=rad, fill=rgba(bg, a))
                else:
                    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=rgba(bg, a))
            if edge:
                wdt = 1 if esize <= 10 else 2
                if rad:
                    d.rounded_rectangle([x0, y0, x1 - 1, y1 - 1], radius=rad, outline=rgba(border, a), width=wdt)
                else:
                    d.rectangle([x0, y0, x1 - 1, y1 - 1], outline=rgba(border, a), width=wdt)
            cv.put(lay)
        elif op == "tex":
            path, vc, a, desat, tc = row[5], rgba(row[6], float(row[7])), float(row[7]), row[8] == "1", row[9] if len(row) > 9 else ""
            lay = cv.layer()
            pl = path.lower()
            ic = icon(path) if "\\icons\\" in pl.replace("/", "\\") else addon_tex(path)
            bw, bh = max(1, x1 - x0), max(1, y1 - y0)
            if ic:
                src = ic
                if tc:
                    c = [float(v) for v in tc.split(",")]
                    if len(c) == 4:
                        W, H = src.size
                        src = src.crop((int(c[0] * W), int(c[2] * H), int(c[1] * W), int(c[3] * H)))
                src = src.resize((bw, bh))
                if desat:
                    src = src.convert("LA").convert("RGBA")
                if vc[:3] != (255, 255, 255) or vc[3] < 255:
                    from PIL import ImageChops
                    rgb = ImageChops.multiply(src.convert("RGB"), Image.new("RGB", src.size, vc[:3]))
                    alpha_ch = src.getchannel("A").point(lambda v: int(v * vc[3] / 255))
                    src = rgb.convert("RGBA")
                    src.putalpha(alpha_ch)
                lay.alpha_composite(src, (x0, y0))
            elif "white8x8" in pl or "ui-statusbar" in pl or "colorblind" in pl:
                ImageDraw.Draw(lay).rectangle([x0, y0, x1 - 1, y1 - 1], fill=vc)
            elif "loadingscreens" in pl or "glues" in pl:
                top, bot = (52, 74, 110), (28, 36, 30)
                d = ImageDraw.Draw(lay)
                for yy in range(y0, y1):
                    k = (yy - y0) / max(1, (y1 - y0))
                    c = tuple(int(top[i] * (1 - k) + bot[i] * k) for i in range(3)) + (int(255 * a),)
                    d.line([(x0, yy), (x1, yy)], fill=c)
                d.text((x0 + 6, y0 + 4), path.split("\\")[-1], font=font(10), fill=(255, 255, 255, 90))
            elif "border" in pl or "highlight" in pl:
                pass
            else:
                ImageDraw.Draw(lay).rectangle([x0, y0, x1 - 1, y1 - 1], outline=(255, 255, 255, 40))
            cv.put(lay)
        elif op == "bar":
            frac, color, a = float(row[5]), rgba(row[6], float(row[7])), float(row[7])
            lay = cv.layer()
            d = ImageDraw.Draw(lay)
            d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=(0, 0, 0, int(120 * a)))
            fw = int((x1 - x0) * frac)
            art = addon_tex(row[8]) if len(row) > 8 and row[8] else None
            if fw >= 1 and art:
                bb = art.getbbox()
                src = art.crop(bb) if bb else art
                src = src.crop((0, 0, max(1, int(src.width * frac)), src.height)).resize((fw, max(1, y1 - y0)))
                lay.alpha_composite(src, (x0, y0))
            elif fw >= 1:
                d.rectangle([x0, y0, x0 + fw - 1, y1 - 1], fill=color)
            cv.put(lay)
        elif op == "model":
            lay = cv.layer()
            d = ImageDraw.Draw(lay)
            cx, w2 = (x0 + x1) / 2, (x1 - x0)
            hh = y1 - y0
            if row[5].startswith("file"):
                # scenery / effect model: a soft blob in place of the doodad
                d.ellipse([x0 + w2 * 0.1, y0 + hh * 0.1, x1 - w2 * 0.1, y1 - 2], fill=(90, 140, 80, 120), outline=(160, 210, 140, 160))
                d.text((x0 + 2, y1 - 12), row[5], font=font(9), fill=(255, 255, 255, 150))
                cv.put(lay)
                continue
            col = (210, 210, 225, 170)
            d.ellipse([cx - w2 * 0.12, y0 + hh * 0.12, cx + w2 * 0.12, y0 + hh * 0.3], fill=col)
            d.rounded_rectangle([cx - w2 * 0.2, y0 + hh * 0.3, cx + w2 * 0.2, y0 + hh * 0.7], radius=6, fill=col)
            d.rectangle([cx - w2 * 0.15, y0 + hh * 0.7, cx - w2 * 0.03, y1 - 4], fill=col)
            d.rectangle([cx + w2 * 0.03, y0 + hh * 0.7, cx + w2 * 0.15, y1 - 4], fill=col)
            d.ellipse([cx - w2 * 0.3, y1 - 8, cx + w2 * 0.3, y1], fill=(0, 0, 0, 90))
            d.text((x0 + 2, y1 - 12), "3D " + row[5], font=font(9), fill=(255, 255, 255, 140))
            cv.put(lay)
        elif op == "wowbutton":
            lay = cv.layer()
            d = ImageDraw.Draw(lay)
            enabled = row[6] == "1"
            d.rounded_rectangle([x0, y0, x1 - 1, y1 - 1], radius=3, fill=(120, 18, 12, 255) if enabled else (60, 60, 60, 255),
                                outline=(200, 160, 40, 255), width=1)
            cv.put(lay)
        elif op == "text":
            draw_text(cv, l, b, r, t, float(row[5]), row[6], float(row[7]), row[8], row[9], row[10], row[11] if len(row) > 11 else "")
    img = cv.img
    if crop:
        l, b, r, t = crop
        img = img.crop((int(l), int(h - t), int(r), int(h - b)))
    if scale != 1.0:
        img = img.resize((int(img.width * scale), int(img.height * scale)), Image.LANCZOS)
    img.convert("RGB").save(out)
    print(out, img.size)


if __name__ == "__main__":
    main()
