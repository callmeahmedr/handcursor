#!/usr/bin/env python3
"""Builds assets/AppIcon.icns: the lavender hand on a soft gradient tile. Needs Pillow and macOS iconutil."""
import os
import shutil
import subprocess
import tempfile

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIZE = 1024


def tile():
    top, bottom = (196, 181, 253), (129, 140, 248)
    base = Image.new("RGBA", (SIZE, SIZE))
    px = base.load()
    for y in range(SIZE):
        t = y / (SIZE - 1)
        row = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        for x in range(SIZE):
            px[x, y] = row
    inset = 100  # macOS icon grid leaves a margin around the tile
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).rounded_rectangle((inset, inset, SIZE - inset, SIZE - inset), radius=185, fill=255)
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
    return out, inset


def main():
    icon, inset = tile()
    hand = Image.open(os.path.join(ROOT, "assets", "hand_lavender.png")).convert("RGBA")
    hand = hand.crop((300, 90, 720, 686))
    target_h = int((SIZE - 2 * inset) * 0.78)
    hand = hand.resize((int(hand.width * target_h / hand.height), target_h), Image.LANCZOS)
    x, y = (SIZE - hand.width) // 2, inset + int((SIZE - 2 * inset) * 0.11)
    shadow = Image.new("RGBA", icon.size, (0, 0, 0, 0))
    shadow.paste((40, 30, 110, 120), (x + 6, y + 18), hand.getchannel("A"))
    icon = Image.alpha_composite(icon, shadow.filter(ImageFilter.GaussianBlur(22)))
    icon.alpha_composite(hand, (x, y))

    with tempfile.TemporaryDirectory() as tmp:
        iconset = os.path.join(tmp, "AppIcon.iconset")
        os.makedirs(iconset)
        for size in (16, 32, 128, 256, 512):
            icon.resize((size, size), Image.LANCZOS).save(os.path.join(iconset, f"icon_{size}x{size}.png"))
            icon.resize((size * 2, size * 2), Image.LANCZOS).save(os.path.join(iconset, f"icon_{size}x{size}@2x.png"))
        subprocess.run(["iconutil", "-c", "icns", iconset, "-o", os.path.join(ROOT, "assets", "AppIcon.icns")], check=True)
    icon.resize((512, 512), Image.LANCZOS).save(os.path.join(ROOT, "assets", "icon-preview.png"))
    print("wrote assets/AppIcon.icns")


if __name__ == "__main__":
    main()
