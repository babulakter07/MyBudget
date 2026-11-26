#!/usr/bin/env python3
"""Generates every MyBudget icon asset from one vector-like description.

    python tool/make_icon.py

Needs Pillow and a font with the taka sign (U+09F3). Set ICON_FONT to override
the default (Nirmala UI Bold, shipped with Windows).

All geometry is in the 108x108 dp adaptive-icon canvas. Important content stays
inside the central 66 dp circle, so no launcher mask can clip it.
"""

import os
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android" / "app" / "src" / "main" / "res"
FONT = os.environ.get("ICON_FONT", r"C:\Windows\Fonts\Nirmala.ttc")
FONT_INDEX = int(os.environ.get("ICON_FONT_INDEX", "1"))  # Bold face

DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

MASTER = 2160  # 20 px per dp; everything is downsampled from this
K = MASTER / 108

# Brand palette (matches the app's green seed colour).
BG_TOP = (30, 156, 118)
BG_BOTTOM = (7, 70, 66)
WALLET_TOP = (255, 255, 255)
WALLET_BOTTOM = (229, 242, 236)
CLASP = (14, 100, 80)
GOLD_TOP = (255, 214, 92)
GOLD_BOTTOM = (240, 166, 26)
GOLD_RING = (255, 232, 158)
GLYPH = (112, 70, 0)

# Geometry (dp).
COIN_CX, COIN_CY, COIN_R = 54.0, 44.0, 17.0
WALLET = (30.0, 53.5, 78.0, 80.5)
WALLET_RADIUS = 7.5
CLASP_BOX = (63.0, 61.0, 78.0, 73.0)
CLASP_RADIUS = 6.0
DOT = (69.5, 67.0, 2.4)


def px(*values):
    return [round(v * K) for v in values]


def gradient(top, bottom, y0=0.0, y1=108.0, diagonal=False):
    """Linear gradient across the canvas between rows y0 and y1."""
    n = 256
    small = Image.new("RGB", (n, n))
    pix = small.load()
    for y in range(n):
        for x in range(n):
            dp_y = y / (n - 1) * 108
            if diagonal:
                t = (x + y) / (2 * (n - 1))
            else:
                t = (dp_y - y0) / (y1 - y0)
            t = min(1.0, max(0.0, t))
            pix[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
    return small.resize((MASTER, MASTER), Image.BICUBIC).convert("RGBA")


def mask():
    return Image.new("L", (MASTER, MASTER), 0)


def rounded(box, radius):
    m = mask()
    ImageDraw.Draw(m).rounded_rectangle(px(*box), radius=round(radius * K), fill=255)
    return m


def circle(cx, cy, r):
    m = mask()
    ImageDraw.Draw(m).ellipse(px(cx - r, cy - r, cx + r, cy + r), fill=255)
    return m


def paint(canvas, shape, fill):
    layer = fill.copy() if isinstance(fill, Image.Image) else Image.new(
        "RGBA", (MASTER, MASTER), fill + (255,)
    )
    layer.putalpha(ImageChops.multiply(layer.getchannel("A"), shape))
    canvas.alpha_composite(layer)


def shadow(canvas, shape, dy, blur, opacity, clip=None):
    moved = mask()
    moved.paste(shape, (0, round(dy * K)))
    moved = moved.filter(ImageFilter.GaussianBlur(blur * K))
    moved = moved.point(lambda a: round(a * opacity))
    if clip is not None:
        moved = ImageChops.multiply(moved, clip)
    paint(canvas, moved, (0, 28, 22))


def taka_mask(cx, cy, height):
    """The taka sign, optically centred on (cx, cy) with the given ink height."""
    probe = ImageFont.truetype(FONT, 1000, index=FONT_INDEX)
    left, top, right, bottom = probe.getbbox("\u09f3")
    font = ImageFont.truetype(
        FONT, round(1000 * height * K / (bottom - top)), index=FONT_INDEX
    )
    left, top, right, bottom = font.getbbox("\u09f3")
    m = mask()
    ImageDraw.Draw(m).text(
        (cx * K - (left + right) / 2, cy * K - (top + bottom) / 2),
        "\u09f3",
        font=font,
        fill=255,
    )
    return m


def background():
    canvas = gradient(BG_TOP, BG_BOTTOM, diagonal=True)
    glow = circle(38, 28, 34).filter(ImageFilter.GaussianBlur(16 * K))
    paint(canvas, glow.point(lambda a: round(a * 0.16)), (190, 255, 224))
    return canvas


def foreground():
    canvas = Image.new("RGBA", (MASTER, MASTER), (0, 0, 0, 0))

    coin = circle(COIN_CX, COIN_CY, COIN_R)
    shadow(canvas, coin, 1.4, 1.6, 0.28)
    paint(canvas, coin, gradient(GOLD_TOP, GOLD_BOTTOM, 27, 61))
    ring = ImageChops.subtract(
        circle(COIN_CX, COIN_CY, COIN_R - 1.9), circle(COIN_CX, COIN_CY, COIN_R - 2.9)
    )
    paint(canvas, ring, GOLD_RING)
    paint(canvas, taka_mask(COIN_CX, 40.9, 17.0), GLYPH)

    wallet = rounded(WALLET, WALLET_RADIUS)
    # Upward shadow onto the coin, so the coin reads as sliding into the wallet.
    shadow(canvas, wallet, -1.1, 1.1, 0.30, clip=coin)
    shadow(canvas, wallet, 2.2, 2.4, 0.32)
    paint(canvas, wallet, gradient(WALLET_TOP, WALLET_BOTTOM, WALLET[1], WALLET[3]))

    clasp = mask()
    d = ImageDraw.Draw(clasp)
    d.rounded_rectangle(px(*CLASP_BOX), radius=round(CLASP_RADIUS * K), fill=255)
    d.rectangle(px(CLASP_BOX[2] - CLASP_RADIUS, CLASP_BOX[1], *CLASP_BOX[2:]), fill=255)
    paint(canvas, clasp, CLASP)
    paint(canvas, circle(*DOT), gradient(GOLD_TOP, GOLD_BOTTOM, 64.5, 69.5))
    return canvas


def silhouette():
    """Single-colour alpha mask for themed icons and the notification icon."""
    coin = circle(COIN_CX, COIN_CY, COIN_R)
    coin = ImageChops.subtract(coin, taka_mask(COIN_CX, 40.9, 18.0))
    # Gap between coin and wallet keeps the two shapes distinct.
    gap = rounded(
        (WALLET[0] - 2.4, WALLET[1] - 2.4, WALLET[2] + 2.4, WALLET[3]),
        WALLET_RADIUS + 2.4,
    )
    coin = ImageChops.subtract(coin, gap)
    wallet = ImageChops.subtract(rounded(WALLET, WALLET_RADIUS), circle(70.0, 67.0, 4.2))
    return ImageChops.lighter(coin, wallet)


def white(alpha):
    img = Image.new("RGBA", alpha.size, (255, 255, 255, 0))
    img.putalpha(alpha)
    return img


def crop_dp(img, size_dp):
    """Central size_dp x size_dp part of the 108 dp canvas."""
    inset = (108 - size_dp) / 2
    return img.crop(tuple(px(inset, inset, 108 - inset, 108 - inset)))


def resize(img, size):
    return img.resize((size, size), Image.LANCZOS)


def save(img, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)


def legacy_icon(full):
    """Pre-Android 8 icon: rounded square with a small transparent margin."""
    art = crop_dp(full, 76)
    size = 960
    body = resize(art, 880)
    m = Image.new("L", (880, 880), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, 879, 879), radius=190, fill=255)
    body.putalpha(m)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.alpha_composite(body, (40, 40))
    return out


def main():
    bg = background()
    fg = foreground()
    mono = white(silhouette())
    full = bg.copy()
    full.alpha_composite(fg)
    legacy = legacy_icon(full)
    # Status-bar icon: 24 dp with about 1 dp padding around the artwork.
    stat = crop_dp(mono, 58)

    for name, scale in DENSITIES.items():
        mipmap = RES / f"mipmap-{name}"
        layer = round(108 * scale)
        save(resize(bg, layer).convert("RGB"), mipmap / "ic_launcher_background.png")
        save(resize(fg, layer), mipmap / "ic_launcher_foreground.png")
        save(resize(mono, layer), mipmap / "ic_launcher_monochrome.png")
        save(resize(legacy, round(48 * scale)), mipmap / "ic_launcher.png")
        save(
            resize(stat, round(24 * scale)),
            RES / f"drawable-{name}" / "ic_stat_mybudget.png",
        )
        # Splash logo for Android 11 and older.
        save(resize(legacy, round(112 * scale)), RES / f"drawable-{name}" / "splash_logo.png")

    # Google Play: full-bleed square, no transparency (Play rounds the corners).
    save(resize(crop_dp(full, 76), 512).convert("RGB"), ROOT / "docs" / "playstore_icon_512.png")

    preview = os.environ.get("ICON_PREVIEW")
    if preview:
        sheet = Image.new("RGB", (1040, 420), (236, 238, 240))
        ImageDraw.Draw(sheet).rectangle((0, 300, 1040, 420), fill=(24, 26, 28))
        view = resize(crop_dp(full, 72), 256)
        shapes = [("circle", 128), ("squircle", 76), ("rounded", 36)]
        for i, (_, radius) in enumerate(shapes):
            m = Image.new("L", (1024, 1024), 0)
            ImageDraw.Draw(m).rounded_rectangle(
                (0, 0, 1023, 1023), radius=min(radius * 4, 511), fill=255
            )
            sheet.paste(view, (20 + i * 276, 22), resize(m, 256))
        small = resize(legacy, 48)
        sheet.paste(small, (880, 60), small)
        tiny = resize(legacy, 96)
        sheet.paste(tiny, (856, 150), tiny)
        for i, size in enumerate((96, 48, 24)):
            icon = resize(stat, size)
            sheet.paste(icon, (40 + i * 130, 312 + (96 - size) // 2), icon)
        themed = resize(crop_dp(mono, 72), 96)
        sheet.paste(themed, (460, 312), themed)
        sheet.save(preview)


if __name__ == "__main__":
    main()
