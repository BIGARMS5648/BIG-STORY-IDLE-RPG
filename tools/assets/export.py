#!/usr/bin/env python3
"""Export the chosen pieces of the user's UI kit as WoW textures.

usage: export.py <dir with aNN_rgba.png from slice.py> <addon dir>
writes <addon>/Media/UI/<name>.tga (32-bit, power-of-two canvas, image at top-left) and
<addon>/Data/UIArt.lua with D.UIArt[name] = { file, w, h, cw, ch, slice = {l, r, t, b}, ot, ob }
(w/h = exported image size in pixels, cw/ch = canvas size; slice/ornaments in exported pixels).
"""
import os, sys
from PIL import Image

# name: (sheet, x, y, w, h, max_dim, slice(l, r, t, b) in source px or None, ornament top / bottom width in source px)
PIECES = {
    # frames / panels
    "frame_big":   ("a00", 18, 7, 678, 472, 512, (96, 96, 96, 112), 150, 190),
    "frame_title": ("a00", 712, 9, 527, 250, 512, (70, 70, 80, 60), 330, 90),
    "frame_rivet": ("a00", 711, 266, 322, 187, 256, (44, 44, 44, 44), 0, 0),
    "plate_red":   ("a00", 14, 459, 488, 156, 512, (80, 80, 40, 40), 0, 0),
    "bar_ribbon":  ("a00", 511, 475, 721, 85, 512, (110, 110, 20, 30), 0, 0),
    "bar_stone":   ("a00", 514, 568, 718, 52, 512, (60, 60, 14, 14), 0, 0),
    "box_bubble":  ("a00", 1007, 633, 231, 105, 256, (30, 30, 24, 40), 0, 0),
    "box_red":     ("a00", 1005, 745, 233, 77, 256, (30, 30, 22, 22), 0, 0),
    "box_dark":    ("a00", 1007, 826, 230, 49, 256, (24, 24, 14, 14), 0, 0),
    "box_row":     ("a00", 25, 994, 414, 86, 512, (30, 30, 22, 22), 0, 0),
    # buttons
    "btn_bronze":  ("a03", 190, 451, 173, 60, 256, (26, 26, 18, 18), 0, 0),
    "btn_red":     ("a03", 195, 520, 170, 60, 256, (26, 26, 18, 18), 0, 0),
    "btn_gold":    ("a03", 191, 660, 172, 64, 256, (26, 26, 18, 18), 0, 0),
    "btn_gray":    ("a03", 537, 521, 152, 60, 256, (26, 26, 18, 18), 0, 0),
    "btn_close":   ("a07", 853, 969, 69, 72, 128, None, 0, 0),
    "toggle_off":  ("a07", 31, 892, 143, 63, 256, None, 0, 0),
    "toggle_on":   ("a07", 195, 892, 139, 62, 256, None, 0, 0),
    # bars: empty troughs + plain fills
    "bar_frame":   ("a05", 619, 11, 441, 102, 512, (90, 90, 30, 30), 0, 0),
    "bar_orbs":    ("a05", 372, 866, 310, 47, 512, (40, 40, 10, 10), 0, 0),
    "bar_trough":  ("a05", 818, 827, 103, 27, 128, (12, 12, 8, 8), 0, 0),
    "fill_red":    ("a05", 707, 827, 103, 26, 128, None, 0, 0),
    "fill_green":  ("a05", 706, 856, 103, 28, 128, None, 0, 0),
    "fill_blue":   ("a05", 707, 886, 103, 28, 128, None, 0, 0),
    "fill_cyan":   ("a05", 707, 915, 103, 28, 128, None, 0, 0),
    "fill_purple": ("a05", 707, 944, 103, 28, 128, None, 0, 0),
    "fill_orange": ("a05", 707, 973, 103, 28, 128, None, 0, 0),
    # slots (grade frames: silver, blue, purple, gold, green, orange, red)
    "slot_bronze": ("a01", 11, 5, 160, 155, 128, None, 0, 0),
    "slot_round":  ("a01", 9, 160, 165, 161, 128, None, 0, 0),
    "portrait":    ("a01", 369, 506, 184, 172, 128, None, 0, 0),
    "slot_g1":     ("a01", 16, 775, 89, 87, 64, None, 0, 0),
    "slot_g2":     ("a01", 225, 775, 89, 86, 64, None, 0, 0),
    "slot_g3":     ("a01", 329, 776, 89, 85, 64, None, 0, 0),
    "slot_g4":     ("a01", 433, 775, 90, 87, 64, None, 0, 0),
    "slot_g5":     ("a01", 121, 776, 88, 86, 64, None, 0, 0),
    "slot_g6":     ("a01", 538, 776, 89, 86, 64, None, 0, 0),
    "slot_g8":     ("a01", 642, 775, 89, 87, 64, None, 0, 0),
    # currency capsules
    "cap_gold":    ("a15", 8, 377, 335, 95, 256, None, 0, 0),
    "cap_dark":    ("a15", 8, 567, 336, 95, 256, None, 0, 0),
    # menu medallions
    "med_character": ("a14", 139, 587, 127, 125, 64, None, 0, 0),
    "med_equipment": ("a14", 174, 313, 149, 153, 64, None, 0, 0),
    "med_skills":    ("a14", 654, 466, 118, 121, 64, None, 0, 0),
    "med_weapons":   ("a14", 14, 313, 152, 155, 64, None, 0, 0),
    "med_companions": ("a14", 941, 314, 150, 152, 64, None, 0, 0),
    "med_income":    ("a14", 405, 465, 125, 123, 64, None, 0, 0),
    "med_summon":    ("a14", 521, 587, 121, 123, 64, None, 0, 0),
    "med_content":   ("a14", 514, 710, 109, 126, 64, None, 0, 0),
    "med_arena":     ("a14", 890, 587, 118, 122, 64, None, 0, 0),
    "med_menu":      ("a14", 1125, 465, 122, 122, 64, None, 0, 0),
    "med_chapters":  ("a14", 631, 711, 116, 127, 64, None, 0, 0),
    "med_mapleRank": ("a14", 305, 179, 120, 135, 64, None, 0, 0),
    "med_medals":    ("a14", 1070, 171, 174, 151, 64, None, 0, 0),
    "med_mastery":   ("a14", 643, 587, 123, 123, 64, None, 0, 0),
    "med_growth":    ("a14", 1128, 587, 120, 121, 64, None, 0, 0),
    "med_auto":      ("a14", 8, 587, 129, 125, 64, None, 0, 0),
    "med_bell":      ("a14", 272, 465, 128, 123, 64, None, 0, 0),
    "plate_trophy":  ("a14", 14, 4, 288, 178, 256, None, 0, 0),
}


# frames drawn over an icon: their filled centre is cut out (shape, inner size as a fraction)
HOLES = {
    "slot_bronze": ("rect", 0.70), "slot_g1": ("rect", 0.74), "slot_g2": ("rect", 0.74), "slot_g3": ("rect", 0.74),
    "slot_g4": ("rect", 0.74), "slot_g5": ("rect", 0.74), "slot_g6": ("rect", 0.74), "slot_g8": ("rect", 0.74),
    "portrait": ("circle", 0.66), "slot_round": ("circle", 0.70),
    "bar_trough": ("rect", 0.88, 0.5), "bar_orbs": ("rect", 0.78, 0.42),
}


def punch(im, shape, frac, frac_h=None):
    from PIL import ImageDraw
    w, h = im.size
    mask = Image.new("L", (w, h), 255)
    d = ImageDraw.Draw(mask)
    iw, ih = w * frac, h * (frac_h or frac)
    box = [(w - iw) / 2, (h - ih) / 2, (w + iw) / 2, (h + ih) / 2]
    if shape == "circle":
        d.ellipse(box, fill=0)
    else:
        d.rounded_rectangle(box, radius=max(2, int(min(iw, ih) * 0.2)), fill=0)
    a = Image.composite(im.getchannel("A"), Image.new("L", (w, h), 0), mask)
    im.putalpha(a)
    return im


def pot(n):
    p = 1
    while p < n:
        p *= 2
    return p


def main():
    src, addon = sys.argv[1], sys.argv[2]
    media = os.path.join(addon, "Media", "UI")
    os.makedirs(media, exist_ok=True)
    sheets = {}
    lines = ["-- Generated by tools/assets/export.py from the user's UI kit (Media/UI/*.tga). Do not edit.",
             "local ADDON, ns = ...", "ns.Data = ns.Data or {}", "local D = ns.Data", "local P = \"Interface\\\\AddOns\\\\\" .. ADDON .. \"\\\\Media\\\\UI\\\\\"", "D.UIArt = {"]
    total = 0
    for name in sorted(PIECES):
        sheet, x, y, w, h, maxd, sl, ot, ob = PIECES[name]
        if sheet not in sheets:
            sheets[sheet] = Image.open(os.path.join(src, sheet + "_rgba.png")).convert("RGBA")
        im = sheets[sheet].crop((x, y, x + w, y + h))
        k = min(1.0, maxd / max(w, h))
        ew, eh = max(1, round(w * k)), max(1, round(h * k))
        if k < 1:
            im = im.resize((ew, eh), Image.LANCZOS)
        if name in HOLES:
            im = punch(im, *HOLES[name])
        cw, ch = pot(ew), pot(eh)
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        canvas.paste(im, (0, 0))
        path = os.path.join(media, name + ".tga")
        canvas.save(path, compression=None)
        total += os.path.getsize(path)
        s = ""
        if sl:
            s = ", slice = { %d, %d, %d, %d }" % tuple(round(v * k) for v in sl)
        o = ""
        if ot or ob:
            o = ", ot = %d, ob = %d" % (round(ot * k), round(ob * k))
        lines.append('    %s = { file = P .. "%s", w = %d, h = %d, cw = %d, ch = %d%s%s },' % (name, name, ew, eh, cw, ch, s, o))
    lines.append("}")
    with open(os.path.join(addon, "Data", "UIArt.lua"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("pieces", len(PIECES), "bytes", total)


if __name__ == "__main__":
    main()
