"""Генерация иконки приложения «Рэндзю для Дианы» 1024×1024.
Пять чёрных камней по диагонали + победная жёлтая линия на фиолетовом фоне."""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 1024
Y = np.arange(S).reshape(1, S)
X = np.arange(S).reshape(S, 1)

# Фон: фиолетовый радиальный градиент
cx0, cy0 = S * 0.35, S * 0.30
d = np.hypot(X - cx0, Y - cy0) / math.hypot(S, S)
t = np.clip(d, 0, 1)
r = (0x82 + (0x60 - 0x82) * t).astype(np.uint8)
g = (0x66 + (0x47 - 0x66) * t).astype(np.uint8)
b = (0xD5 + (0xAF - 0xD5) * t).astype(np.uint8)
img = np.stack([r, g, b, np.full_like(r, 255)], axis=-1).astype(np.uint8)
img = Image.fromarray(img, "RGBA")

# Жёлтое свечение сверху-справа
glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(glow).ellipse([S - 360, -120, S + 120, 360], fill=(255, 214, 109, 90))
img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(60)))


def stone(cx, cy, rad, dark):
    global img
    sz = int(rad * 2.4)
    yy, xx = np.mgrid[0:sz, 0:sz]
    bx, by = sz / 2, sz / 2
    dd = np.hypot(xx - bx, yy - by) / rad
    tt = np.clip((dd - 0.3) / 0.8, 0, 1)  # сместим центр блика
    if dark:
        r1 = (0x6A + (0x2A - 0x6A) * tt).astype(np.uint8)
        g1 = (0x66 + (0x27 - 0x66) * tt).astype(np.uint8)
        b1 = (0x77 + (0x33 - 0x77) * tt).astype(np.uint8)
        edge = (0x1E, 0x1B, 0x26)
    else:
        r1 = (0xFF + (0xCE - 0xFF) * tt).astype(np.uint8)
        g1 = (0xFF + (0xB9 - 0xFF) * tt).astype(np.uint8)
        b1 = (0xFF + (0x98 - 0xFF) * tt).astype(np.uint8)
        edge = (0xCE, 0xB9, 0x98)
    body = np.stack([r1, g1, b1, np.full_like(r1, 255)], axis=-1).astype(np.uint8)
    mask = (np.hypot(xx - bx, yy - by) <= rad).astype(np.uint8) * 255
    body_img = Image.fromarray(body, "RGBA")
    mask_img = Image.fromarray(mask, "L")
    # тень
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse(
        [cx - rad + 6, cy - rad + 12, cx + rad + 6, cy + rad + 12], fill=(0, 0, 0, 90))
    img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(8)))
    img.paste(body_img, (int(cx - bx), int(cy - by)), mask_img)
    d = ImageDraw.Draw(img)
    d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], outline=edge, width=6)
    d.ellipse([cx - rad * 0.45, cy - rad * 0.45, cx - rad * 0.05, cy - rad * 0.05],
              fill=(255, 255, 255, 150))


pts = [(260, 720), (380, 600), (500, 480), (620, 360), (740, 240)]
for (x, y) in pts:
    stone(x, y, 92, dark=True)

# Победная жёлтая линия
line = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(line).line([(260, 720), (740, 240)], fill=(255, 214, 109, 210), width=34)
img = Image.alpha_composite(img, line.filter(ImageFilter.GaussianBlur(2)))
d = ImageDraw.Draw(img)
for (x, y) in pts:
    d.ellipse([x - 100, y - 100, x + 100, y + 100], outline=(255, 214, 109, 255), width=6)

stone(740, 240, 70, dark=False)

img.convert("RGB").save("/home/z/my-project/assets/images/app_icon.png", "PNG")
print("saved app_icon.png", img.size)
