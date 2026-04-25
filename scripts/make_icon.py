#!/usr/bin/env python3
"""Generate a 1024x1024 AppIcon PNG with a liquid-glass gradient and SF-style mark."""
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import os

SIZE = 1024
OUT = os.path.join(os.path.dirname(__file__), "..", "App", "Assets.xcassets",
                   "AppIcon.appiconset", "AppIcon-1024.png")

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def main():
    img = Image.new("RGB", (SIZE, SIZE), (10, 12, 30))
    px = img.load()
    # Diagonal gradient: deep purple -> cyan
    a = (40, 22, 80)
    b = (10, 130, 180)
    c = (210, 80, 200)
    for y in range(SIZE):
        for x in range(SIZE):
            t = (x + y) / (2 * SIZE)
            tr = (x - y) / SIZE * 0.5 + 0.5
            base = lerp(a, b, t)
            mix = lerp(base, c, max(0.0, math.sin(tr * math.pi) * 0.4))
            px[x, y] = mix

    # Soft glow radial highlight (top-left)
    glow = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r in range(220, 0, -10):
        alpha = int(255 * (r / 220) * 0.3)
        gd.ellipse((300 - r * 1.4, 200 - r * 1.2, 700 + r * 0.6, 600 + r * 0.4),
                   fill=(alpha, alpha, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    img = Image.blend(img, Image.eval(glow, lambda v: min(255, v + 30)), 0.25)

    draw = ImageDraw.Draw(img, "RGBA")
    # Glass disk
    cx, cy = SIZE // 2, SIZE // 2
    r = 360
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, 38))
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 255, 255, 90), width=4)
    # Inner highlight
    draw.ellipse((cx - r + 50, cy - r + 50, cx + r - 220, cy + r - 220),
                 fill=(255, 255, 255, 30))

    # Phone glyph (rounded rect with circles)
    phone_w, phone_h = 280, 460
    rx = cx - phone_w // 2
    ry = cy - phone_h // 2 - 20
    draw.rounded_rectangle((rx, ry, rx + phone_w, ry + phone_h), radius=58,
                           fill=(20, 20, 40, 220),
                           outline=(255, 255, 255, 200), width=8)
    # Screen
    inset = 30
    draw.rounded_rectangle((rx + inset, ry + inset + 18, rx + phone_w - inset, ry + phone_h - inset - 18),
                           radius=34, fill=(40, 60, 110, 255))

    # Three "feature" dots
    colors = [(255, 90, 110), (90, 220, 255), (200, 150, 255)]
    for i, col in enumerate(colors):
        cx2 = rx + phone_w // 2
        cy2 = ry + 130 + i * 90
        draw.ellipse((cx2 - 36, cy2 - 36, cx2 + 36, cy2 + 36), fill=col + (255,))

    # Soft outer shadow
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse((cx - r - 10, cy - r + 10, cx + r + 10, cy + r + 30), fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(40))
    img = img.convert("RGBA")
    img.alpha_composite(shadow, (0, 0))
    # Re-draw the glass on top
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, 22))
    od.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 255, 255, 80), width=4)
    img.alpha_composite(overlay, (0, 0))

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.convert("RGB").save(OUT, "PNG", optimize=True)
    print("Wrote", OUT)

if __name__ == "__main__":
    main()
