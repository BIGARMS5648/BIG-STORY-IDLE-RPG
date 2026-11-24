#!/usr/bin/env python3
"""Cut a UI-kit sprite sheet (elements on a flat dark background, no alpha) into elements.

usage: slice.py sheet.png outdir prefix
- background colour = median of the border pixels; pixels close to it and connected to the border
  become transparent (dark fills inside frames stay opaque), edges get a soft alpha
- every connected element (area >= MIN_AREA) is saved as <prefix>_<n>.png (RGBA, tight crop)
- <outdir>/<prefix>_index.png shows the sheet with numbered boxes
"""
import sys, os
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

MIN_AREA = 120


def main():
    src, outdir, prefix = sys.argv[1], sys.argv[2], sys.argv[3]
    os.makedirs(outdir, exist_ok=True)
    im = np.asarray(Image.open(src).convert("RGB")).astype(np.int32)
    h, w, _ = im.shape
    border = np.concatenate([im[0], im[-1], im[:, 0], im[:, -1]])
    bg = np.median(border, axis=0)
    dist = np.sqrt(((im - bg) ** 2).sum(axis=2))
    near = dist < 22
    lab, n = ndimage.label(near)
    edge_labels = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    outside = np.isin(lab, list(edge_labels))
    # soft edge: pixels within 2 px of the outside get alpha from their colour distance
    grown = ndimage.binary_dilation(outside, iterations=2)
    alpha = np.where(outside, 0, 255).astype(np.float32)
    ring = grown & ~outside
    alpha[ring] = np.clip((dist[ring] - 10) / 40.0, 0, 1) * 255
    fg = ~outside
    lab2, n2 = ndimage.label(fg, structure=np.ones((3, 3)))
    objs = ndimage.find_objects(lab2)
    rgba = np.dstack([im.astype(np.uint8), alpha.astype(np.uint8)])
    Image.fromarray(rgba).save(os.path.join(outdir, "%s_rgba.png" % prefix))
    index = Image.fromarray(im.astype(np.uint8)).convert("RGB")
    d = ImageDraw.Draw(index)
    k = 0
    rows = []
    for i, sl in enumerate(objs):
        if sl is None:
            continue
        ys, xs = sl
        area = int((lab2[sl] == i + 1).sum())
        if area < MIN_AREA:
            continue
        y0, y1 = max(0, ys.start - 1), min(h, ys.stop + 1)
        x0, x1 = max(0, xs.start - 1), min(w, xs.stop + 1)
        crop = rgba[y0:y1, x0:x1].copy()
        mask = (lab2[y0:y1, x0:x1] == i + 1) | (alpha[y0:y1, x0:x1] < 255) & (lab2[y0:y1, x0:x1] == 0)
        crop[..., 3] = np.where(mask, crop[..., 3], 0)
        Image.fromarray(crop).save(os.path.join(outdir, "%s_%03d.png" % (prefix, k)))
        rows.append((k, x0, y0, x1 - x0, y1 - y0))
        d.rectangle([x0, y0, x1 - 1, y1 - 1], outline=(0, 255, 255))
        d.text((x0 + 2, y0 + 1), str(k), fill=(255, 255, 0))
        k += 1
    index.save(os.path.join(outdir, "%s_index.png" % prefix))
    with open(os.path.join(outdir, "%s_boxes.txt" % prefix), "w") as f:
        for r in rows:
            f.write("%d %d %d %d %d\n" % r)
    print(prefix, "elements:", k, "bg", bg)


if __name__ == "__main__":
    main()
