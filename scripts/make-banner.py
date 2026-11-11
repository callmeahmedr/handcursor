#!/usr/bin/env python3
"""Builds .github/banner.png, the README demo image. Needs Pillow."""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H, S = 1600, 800, 1


def font(size, bold=False):
    for path in ("/System/Library/Fonts/HelveticaNeue.ttc", "/System/Library/Fonts/Helvetica.ttc"):
        try:
            return ImageFont.truetype(path, size, index=1 if bold else 0)
        except Exception:
            pass
    return ImageFont.load_default()


def gradient(size, top, bottom):
    w, h = size
    im = Image.new("RGB", size)
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / (h - 1)
        d.line((0, y, w, y), fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    return im.convert("RGBA")


def hand_with_tip_at(name, target, angle, height):
    img = Image.open(os.path.join(ROOT, "assets", f"hand_{name}.png")).convert("RGBA")
    tip = (475, 125)  # fingertip in the 1024x1536 source art
    canvas = Image.new("RGBA", (3200, 3200), (0, 0, 0, 0))
    canvas.paste(img, (1600 - tip[0], 1600 - tip[1]))
    canvas = canvas.rotate(angle, center=(1600, 1600), resample=Image.BICUBIC)
    scale = height / 1536
    canvas = canvas.resize((int(3200 * scale), int(3200 * scale)), Image.LANCZOS)
    return canvas, (int(1600 * scale), int(1600 * scale))


def main():
    im = gradient((W, H), (233, 228, 255), (186, 196, 250))
    d = ImageDraw.Draw(im)

    # Mock app window
    win = (130, 150, 930, 640)
    shadow = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((win[0], win[1] + 24, win[2], win[3] + 24), 26, fill=(40, 30, 110, 110))
    im = Image.alpha_composite(im, shadow.filter(ImageFilter.GaussianBlur(30)))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle(win, 26, fill=(255, 255, 255, 255))
    d.rounded_rectangle((win[0], win[1], win[2], win[1] + 64), 26, fill=(244, 243, 250, 255))
    d.rectangle((win[0], win[1] + 40, win[2], win[1] + 64), fill=(244, 243, 250, 255))
    for i, c in enumerate(((255, 95, 87), (254, 188, 46), (40, 200, 64))):
        d.ellipse((win[0] + 28 + i * 34, win[1] + 22, win[0] + 48 + i * 34, win[1] + 42), fill=c)
    d.text((win[0] + 60, win[1] + 120), "Click anything.", font=font(44, True), fill=(40, 36, 80))
    d.text((win[0] + 60, win[1] + 184), "The hand is your cursor now.", font=font(30), fill=(110, 106, 150))
    btn = (win[0] + 60, win[1] + 280, win[0] + 340, win[1] + 352)
    d.rounded_rectangle(btn, 18, fill=(124, 108, 240, 255))
    d.text(((btn[0] + btn[2]) / 2, (btn[1] + btn[3]) / 2), "Click me", font=font(30, True), fill="white", anchor="mm")
    for i, w in enumerate((380, 300, 340)):
        d.rounded_rectangle((win[0] + 60, win[1] + 395 + i * 28, win[0] + 60 + w, win[1] + 407 + i * 28), 6, fill=(232, 230, 244, 255))

    # Click ripple + the hand, tip on the button
    target = (btn[0] + 235, btn[1] + 46)
    ripple = Image.new("RGBA", im.size, (0, 0, 0, 0))
    rd = ImageDraw.Draw(ripple)
    for r, a in ((46, 90), (30, 140)):
        rd.ellipse((target[0] - r, target[1] - r, target[0] + r, target[1] + r), outline=(255, 255, 255, a), width=5)
    im = Image.alpha_composite(im, ripple)
    hand, (tx, ty) = hand_with_tip_at("lavender", target, -24, 1050)
    hs = Image.new("RGBA", im.size, (0, 0, 0, 0))
    hs.paste((30, 20, 90, 120), (target[0] - tx + 16, target[1] - ty + 26), hand.getchannel("A").resize(hand.size))
    im = Image.alpha_composite(im, hs.filter(ImageFilter.GaussianBlur(14)))
    im.alpha_composite(hand, (target[0] - tx, target[1] - ty))
    d = ImageDraw.Draw(im)

    # Title block
    d.text((1010, 190), "HandCursor", font=font(92, True), fill=(40, 36, 80))
    d.text((1012, 300), "A toy hand for your Mac cursor.", font=font(34), fill=(90, 86, 140))
    d.text((1012, 352), "Real clicks. No permissions.", font=font(34), fill=(90, 86, 140))
    chips = ["Open source", "Menu bar app", "36 hands"]
    x = 1012
    for c in chips:
        w = d.textlength(c, font=font(21, True)) + 36
        d.rounded_rectangle((x, 430, x + w, 480), 25, fill=(255, 255, 255, 220))
        d.text((x + w / 2, 455), c, font=font(21, True), fill=(110, 94, 220), anchor="mm")
        x += w + 10

    # A few of the other hands
    for i, name in enumerate(("coral", "plush", "robot", "glove", "pink")):
        t = Image.open(os.path.join(ROOT, "assets", f"hand_{name}.png")).convert("RGBA").crop((300, 90, 720, 690))
        t = t.resize((int(t.width * 150 / t.height), 150), Image.LANCZOS)
        im.alpha_composite(t, (1012 + i * 108, 540))
    d = ImageDraw.Draw(im)
    d.text((1012, 720), "Rebuilt for fun on top of TinyHand by @nilbuild", font=font(22), fill=(100, 96, 150))
    d.text((1012, 752), "github.com/callmeahmedr/handcursor", font=font(22), fill=(100, 96, 150))
    im.convert("RGB").save(os.path.join(ROOT, ".github", "banner.png"), optimize=True)
    print("wrote .github/banner.png")


if __name__ == "__main__":
    main()
