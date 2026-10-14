#!/usr/bin/env python3
"""Renders the Minimal app icon (three quiet lines of text on black) into the asset catalog.

Usage: python3 scripts/make_icon.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
SCALE = 4  # supersampling for smooth edges
OUT = Path(__file__).resolve().parent.parent / "Minimal" / "Assets.xcassets" / "AppIcon.appiconset"


def render(background_top, background_bottom, line_color, transparent=False):
    s = SIZE * SCALE
    mode = "RGBA" if transparent else "RGB"
    image = Image.new(mode, (s, s), (0, 0, 0, 0) if transparent else background_bottom)
    draw = ImageDraw.Draw(image)

    if not transparent:
        # Very subtle vertical gradient, like Apple's dark materials.
        for y in range(s):
            t = y / (s - 1)
            color = tuple(round(a + (b - a) * t) for a, b in zip(background_top, background_bottom))
            draw.line([(0, y), (s, y)], fill=color)

    # Three left-aligned lines of decreasing length: a list of words, nothing else.
    left = 0.27 * s
    thickness = 0.048 * s
    lengths = [0.46, 0.34, 0.22]
    top = 0.331 * s
    gap = 0.145 * s
    for index, length in enumerate(lengths):
        y = top + index * gap
        alpha = [255, 200, 140][index]
        fill = line_color + ((alpha,) if transparent else ())
        if not transparent:
            # Blend toward the background for the fainter lines.
            bg = background_top
            fill = tuple(round(bg_c + (c - bg_c) * alpha / 255) for c, bg_c in zip(line_color, bg))
        draw.rounded_rectangle(
            [left, y, left + length * s, y + thickness],
            radius=thickness / 2,
            fill=fill,
        )

    return image.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    render((28, 28, 30), (0, 0, 0), (255, 255, 255)).save(OUT / "AppIcon.png")
    # Dark and tinted variants have transparent backgrounds; iOS draws its own behind them.
    render((0, 0, 0), (0, 0, 0), (255, 255, 255), transparent=True).save(OUT / "AppIcon-Dark.png")
    render((0, 0, 0), (0, 0, 0), (255, 255, 255), transparent=True).convert("LA").save(OUT / "AppIcon-Tinted.png")
    print(f"Icons written to {OUT}")


if __name__ == "__main__":
    main()
