#!/usr/bin/env python3
"""Regenerates Resources/AppIcon.icns and Resources/AppIcon-1024.png.

Not part of the normal build — only needed if you want to tweak the icon
artwork. Requires Pillow: pip3 install Pillow

Usage: python3 Scripts/gen_icon.py
"""
import math
import struct
import tempfile
from pathlib import Path
from PIL import Image, ImageDraw

RESOURCES_DIR = Path(__file__).resolve().parent.parent / "Resources"

SS = 4  # supersample factor
SIZE = 1024
CANVAS = SIZE * SS


def lerp(a, b, t):
    return a + (b - a) * t


def make_master():
    # Diagonal gradient background (violet -> blue), inside a squircle mask.
    top_left = (124, 58, 237)     # #7C3AED
    bottom_right = (37, 99, 235)  # #2563EB
    small = 64
    small_img = Image.new("RGB", (small, small))
    sp = small_img.load()
    for y in range(small):
        for x in range(small):
            t = (x + y) / (2 * (small - 1))
            sp[x, y] = (
                int(lerp(top_left[0], bottom_right[0], t)),
                int(lerp(top_left[1], bottom_right[1], t)),
                int(lerp(top_left[2], bottom_right[2], t)),
            )
    grad = small_img.resize((CANVAS, CANVAS), Image.BICUBIC)

    # Squircle mask (superellipse), Apple-ish continuous curvature.
    mask = Image.new("L", (CANVAS, CANVAS), 0)
    mdraw = ImageDraw.Draw(mask)
    n = 5.0
    a = CANVAS / 2
    steps = 720
    pts = []
    for i in range(steps):
        theta = 2 * math.pi * i / steps
        ct, st = math.cos(theta), math.sin(theta)
        x = (abs(ct) ** (2 / n)) * a * (1 if ct >= 0 else -1)
        y = (abs(st) ** (2 / n)) * a * (1 if st >= 0 else -1)
        pts.append((a + x, a + y))
    mdraw.polygon(pts, fill=255)

    bg = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    bg.paste(grad, (0, 0))
    bg.putalpha(mask)

    # Subtle top-down sheen for depth.
    sheen = Image.new("L", (CANVAS, CANVAS), 0)
    sdraw = ImageDraw.Draw(sheen)
    sdraw.ellipse([CANVAS * 0.05, -CANVAS * 0.55, CANVAS * 0.95, CANVAS * 0.55], fill=40)
    sheen_rgba = Image.new("RGBA", (CANVAS, CANVAS), (255, 255, 255, 0))
    sheen_rgba.putalpha(sheen)
    bg = Image.alpha_composite(bg, Image.composite(sheen_rgba, Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0)), mask))

    draw = ImageDraw.Draw(bg)
    cx, cy = CANVAS / 2, CANVAS / 2
    R = CANVAS * 0.335
    stroke = CANVAS * 0.075
    ring_color = (255, 255, 255, 235)

    def point(angle_deg, radius):
        theta = math.radians(angle_deg)
        return (cx + radius * math.cos(theta), cy + radius * math.sin(theta))

    # Loop ring with a gap at the top (a "Loop Station" motif). Angle
    # convention here: 0=right/east, 90=bottom, 270=top.
    gap_half = 25  # degrees
    start_deg = 270 + gap_half
    end_deg = 270 - gap_half + 360

    # Build the ring as a precise annular-sector polygon (rather than
    # ImageDraw.arc's stroked-line approximation, which is imprecise at the
    # endpoints for a stroke this thick) so the tail dot and arrowhead below
    # — which use the same point()/angle math — land exactly flush with it.
    inner_R, outer_R = R - stroke / 2, R + stroke / 2
    ring_steps = 400
    angles = [start_deg + (end_deg - start_deg) * i / ring_steps for i in range(ring_steps + 1)]
    ring_poly = [point(a, outer_R) for a in angles] + [point(a, inner_R) for a in reversed(angles)]
    draw.polygon(ring_poly, fill=ring_color)

    # Round cap on the tail end only (the arrow forms the other end's cap).
    tail_x, tail_y = point(start_deg, R)
    r = stroke / 2
    draw.ellipse([tail_x - r, tail_y - r, tail_x + r, tail_y + r], fill=ring_color)

    # Arrowhead at the end of the arc, tangent to the circle, pointing
    # clockwise (continuing the loop). Flat base straddles the ring line,
    # tip points forward along the tangent direction.
    theta_end = math.radians(end_deg)
    ex, ey = point(end_deg, R)
    tangent = (-math.sin(theta_end), math.cos(theta_end))
    normal = (math.cos(theta_end), math.sin(theta_end))
    arrow_len = stroke * 3.1
    arrow_half_w = stroke * 0.95
    tip = (ex + tangent[0] * arrow_len, ey + tangent[1] * arrow_len)
    base_left = (ex + normal[0] * arrow_half_w, ey + normal[1] * arrow_half_w)
    base_right = (ex - normal[0] * arrow_half_w, ey - normal[1] * arrow_half_w)
    draw.polygon([tip, base_left, base_right], fill=ring_color)

    # Center play triangle.
    play_r = CANVAS * 0.185
    off = play_r * 0.12
    p1 = (cx - play_r * 0.62 + off, cy - play_r)
    p2 = (cx - play_r * 0.62 + off, cy + play_r)
    p3 = (cx + play_r * 1.05 + off, cy)
    draw.polygon([p1, p2, p3], fill=(255, 255, 255, 255))

    return bg.resize((SIZE, SIZE), Image.LANCZOS)


def build_icns(master, out_path):
    # Apple Icon Image format: 'icns' magic + total length, then a sequence
    # of [4-byte OSType][4-byte entry length][entry data] chunks. Modern
    # OSTypes below take raw PNG bytes directly as their payload.
    type_for_size_primary = {
        16: b"icp4", 32: b"icp5", 64: b"icp6", 128: b"ic07",
        256: b"ic08", 512: b"ic09", 1024: b"ic10",
    }
    type_for_size_retina = {
        32: b"ic11",   # 16@2x
        64: b"ic12",   # 32@2x
        256: b"ic13",  # 128@2x
        512: b"ic14",  # 256@2x
    }

    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        entries = []
        for s in (16, 32, 64, 128, 256, 512, 1024):
            png_path = tmp_dir / f"icon_{s}.png"
            master.resize((s, s), Image.LANCZOS).save(png_path)
            data = png_path.read_bytes()
            entries.append((type_for_size_primary[s], data))
            if s in type_for_size_retina:
                entries.append((type_for_size_retina[s], data))

    body = b"".join(otype + struct.pack(">I", 8 + len(data)) + data for otype, data in entries)
    out_path.write_bytes(b"icns" + struct.pack(">I", 8 + len(body)) + body)


if __name__ == "__main__":
    RESOURCES_DIR.mkdir(parents=True, exist_ok=True)
    master = make_master()
    master.save(RESOURCES_DIR / "AppIcon-1024.png")
    build_icns(master, RESOURCES_DIR / "AppIcon.icns")
    print(f"Wrote {RESOURCES_DIR / 'AppIcon.icns'} and AppIcon-1024.png")
