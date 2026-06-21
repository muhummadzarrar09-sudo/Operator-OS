from __future__ import annotations

import math
import random
from pathlib import Path
from typing import Iterable, Sequence

from PIL import Image, ImageDraw, ImageFilter

OUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "compound"
SIZE = 512
SCALE = 4
CANVAS = SIZE * SCALE

STATS = {
    "forge": {
        "base": (47, 43, 42),
        "side": (32, 29, 29),
        "roof": (89, 51, 31),
        "accent": (255, 106, 32),
        "glow": (255, 116, 32),
    },
    "academy": {
        "base": (64, 87, 128),
        "side": (39, 54, 84),
        "roof": (123, 88, 61),
        "accent": (83, 176, 255),
        "glow": (83, 176, 255),
    },
    "leverage": {
        "base": (51, 101, 62),
        "side": (32, 66, 42),
        "roof": (76, 121, 66),
        "accent": (79, 220, 113),
        "glow": (79, 220, 113),
    },
    "presence": {
        "base": (91, 61, 126),
        "side": (56, 38, 82),
        "roof": (66, 48, 102),
        "accent": (185, 111, 255),
        "glow": (185, 111, 255),
    },
    "craft": {
        "base": (126, 55, 91),
        "side": (82, 36, 61),
        "roof": (101, 55, 77),
        "accent": (255, 83, 157),
        "glow": (255, 83, 157),
    },
    "vitality": {
        "base": (122, 58, 43),
        "side": (82, 38, 31),
        "roof": (151, 75, 46),
        "accent": (255, 86, 73),
        "glow": (255, 86, 73),
    },
    "capital": {
        "base": (123, 95, 42),
        "side": (88, 68, 32),
        "roof": (166, 122, 42),
        "accent": (255, 210, 87),
        "glow": (255, 210, 87),
    },
    "clarity": {
        "base": (58, 85, 113),
        "side": (35, 54, 78),
        "roof": (68, 82, 111),
        "accent": (86, 228, 255),
        "glow": (86, 228, 255),
    },
}

# Slightly tighter camera than the old generated art; every sprite keeps empty
# transparent margins but no baked checkerboard/placeholder pixels.
CX = 256
CY = 360
TX = 34
TY = 18


def rgba(color: Sequence[int], alpha: int = 255) -> tuple[int, int, int, int]:
    return int(color[0]), int(color[1]), int(color[2]), alpha


def mix(a: Sequence[int], b: Sequence[int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def lighten(color: Sequence[int], t: float) -> tuple[int, int, int]:
    return mix(color, (255, 255, 255), t)


def darken(color: Sequence[int], t: float) -> tuple[int, int, int]:
    return mix(color, (0, 0, 0), t)


def sc_point(p: tuple[float, float]) -> tuple[int, int]:
    return int(round(p[0] * SCALE)), int(round(p[1] * SCALE))


def sc_rect(rect: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
    return tuple(int(round(v * SCALE)) for v in rect)  # type: ignore[return-value]


def project(x: float, y: float, z: float = 0) -> tuple[float, float]:
    return CX + (x - y) * TX, CY + (x + y) * TY - z


class SpriteCanvas:
    def __init__(self):
        self.img = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.img, "RGBA")

    def polygon(self, points: Iterable[tuple[float, float]], fill, outline=None, width: int = 1):
        pts = [sc_point(p) for p in points]
        self.draw.polygon(pts, fill=fill)
        if outline is not None:
            self.draw.line(pts + [pts[0]], fill=outline, width=width * SCALE, joint="curve")

    def ellipse(self, rect, fill, outline=None, width: int = 1):
        self.draw.ellipse(sc_rect(rect), fill=fill, outline=outline, width=width * SCALE)

    def line(self, points, fill, width: int = 1):
        self.draw.line([sc_point(p) for p in points], fill=fill, width=width * SCALE)

    def box(self, x: float, y: float, w: float, d: float, z: float, h: float, color, edge_alpha: int = 44):
        top = [
            project(x, y, z + h),
            project(x + w, y, z + h),
            project(x + w, y + d, z + h),
            project(x, y + d, z + h),
        ]
        front = [
            project(x, y + d, z + h),
            project(x + w, y + d, z + h),
            project(x + w, y + d, z),
            project(x, y + d, z),
        ]
        right = [
            project(x + w, y, z + h),
            project(x + w, y + d, z + h),
            project(x + w, y + d, z),
            project(x + w, y, z),
        ]
        self.polygon(front, rgba(darken(color, 0.22)), rgba((0, 0, 0), edge_alpha))
        self.polygon(right, rgba(darken(color, 0.36)), rgba((0, 0, 0), edge_alpha))
        self.polygon(top, rgba(lighten(color, 0.12)), rgba((255, 255, 255), edge_alpha))

    def roof(self, x: float, y: float, w: float, d: float, z: float, h: float, color):
        p1 = project(x, y, z)
        p2 = project(x + w, y, z)
        p3 = project(x + w, y + d, z)
        p4 = project(x, y + d, z)
        r1 = project(x, y + d * 0.50, z + h)
        r2 = project(x + w, y + d * 0.50, z + h)
        self.polygon([p1, p2, r2, r1], rgba(lighten(color, 0.07)), rgba((0, 0, 0), 54))
        self.polygon([p4, p3, r2, r1], rgba(darken(color, 0.10)), rgba((0, 0, 0), 54))
        self.line([r1, r2], rgba(lighten(color, 0.28), 210), 2)

    def door(self, x1: float, x2: float, y: float, z1: float, z2: float, color, glow=None):
        pts = [project(x1, y, z2), project(x2, y, z2), project(x2, y, z1), project(x1, y, z1)]
        self.polygon(pts, rgba(color, 235), rgba((0, 0, 0), 80))
        if glow is not None:
            mid = project((x1 + x2) / 2, y + 0.02, (z1 + z2) / 2)
            self.ellipse((mid[0] - 16, mid[1] - 18, mid[0] + 16, mid[1] + 18), rgba(glow, 76))

    def window(self, x1: float, x2: float, y: float, z1: float, z2: float, color):
        pts = [project(x1, y, z2), project(x2, y, z2), project(x2, y, z1), project(x1, y, z1)]
        self.polygon(pts, rgba(color, 210), rgba((255, 255, 255), 70))

    def glow(self, center: tuple[float, float], radius: float, color, alpha: int = 90):
        layer = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer, "RGBA")
        x, y = sc_point(center)
        r = int(radius * SCALE)
        d.ellipse((x - r, y - r, x + r, y + r), fill=rgba(color, alpha))
        layer = layer.filter(ImageFilter.GaussianBlur(radius=int(radius * SCALE * 0.35)))
        self.img.alpha_composite(layer)
        self.draw = ImageDraw.Draw(self.img, "RGBA")

    def finish(self) -> Image.Image:
        out = self.img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
        return out


def draw_platform(c: SpriteCanvas, tier: int, cfg):
    radius = 2.55 + tier * 0.22
    z = 0
    h = 12 + tier * 2
    # soft shadow
    c.ellipse((116, 344, 396, 432), rgba((0, 0, 0), 58))
    c.box(-radius, -radius, radius * 2, radius * 2, z, h, (70, 92, 62))
    # pad / paving diamond on top
    topz = h + 1
    pad = [project(-radius * 0.72, 0, topz), project(0, -radius * 0.72, topz), project(radius * 0.72, 0, topz), project(0, radius * 0.72, topz)]
    c.polygon(pad, rgba(mix(cfg["accent"], (55, 64, 54), 0.72), 215), rgba(cfg["accent"], 82), 2)
    # tiny stones/flowers, deterministic but not debug-looking
    rng = random.Random(1000 + tier)
    for _ in range(8 + tier * 2):
        lx = rng.uniform(-radius * 0.9, radius * 0.9)
        ly = rng.uniform(-radius * 0.9, radius * 0.9)
        if abs(lx) + abs(ly) > radius * 1.45:
            continue
        sx, sy = project(lx, ly, h + 3)
        col = lighten((70, 92, 62), rng.uniform(0.05, 0.28))
        c.ellipse((sx - 3, sy - 2, sx + 3, sy + 2), rgba(col, 140))


def draw_main_hall(c: SpriteCanvas, tier: int, cfg, stat: str):
    z = 14 + tier * 2
    w = 2.10 + tier * 0.40
    d = 1.90 + tier * 0.32
    h = 42 + tier * 20
    x = -w / 2
    y = -d / 2

    if tier >= 4:
        # side wings sell the tier-4 footprint.
        c.box(x - 1.15, y + 0.25, 1.1, d * 0.78, z, h * 0.62, cfg["side"])
        c.box(x + w + 0.05, y + 0.25, 1.1, d * 0.78, z, h * 0.62, cfg["side"])
    elif tier >= 3:
        c.box(x + w + 0.05, y + 0.25, 0.9, d * 0.72, z, h * 0.62, cfg["side"])

    c.box(x, y, w, d, z, h, cfg["base"])
    c.roof(x - 0.18, y - 0.18, w + 0.36, d + 0.36, z + h, 22 + tier * 4, cfg["roof"])

    door_color = darken(cfg["base"], 0.54)
    c.door(-0.38, 0.38, y + d + 0.01, z + 1, z + min(30, h * 0.62), door_color, cfg["glow"])
    if tier >= 2:
        c.window(x + 0.32, x + 0.62, y + d + 0.02, z + h * 0.42, z + h * 0.62, cfg["accent"])
        c.window(x + w - 0.62, x + w - 0.32, y + d + 0.02, z + h * 0.42, z + h * 0.62, cfg["accent"])


def draw_chimney(c: SpriteCanvas, x, y, z, cfg, height=42):
    c.box(x, y, 0.36, 0.36, z, height, darken(cfg["base"], 0.18))
    top = project(x + 0.18, y + 0.18, z + height + 2)
    c.glow(top, 12, cfg["glow"], 62)
    c.ellipse((top[0] - 5, top[1] - 8, top[0] + 5, top[1] + 5), rgba(cfg["glow"], 220))


def draw_tower(c: SpriteCanvas, x, y, z, cfg, height=70):
    c.box(x, y, 0.78, 0.78, z, height, darken(cfg["base"], 0.05))
    c.roof(x - 0.10, y - 0.10, 0.98, 0.98, z + height, 14, cfg["roof"])
    c.window(x + 0.22, x + 0.52, y + 0.79, z + height * 0.48, z + height * 0.70, cfg["accent"])


def draw_stat_details(c: SpriteCanvas, stat: str, tier: int, cfg):
    z = 20 + tier * 2
    if stat == "forge":
        draw_chimney(c, -1.25, -1.15, z + 35, cfg, 28 + tier * 7)
        if tier >= 3:
            draw_chimney(c, 0.95, -1.05, z + 38, cfg, 34 + tier * 7)
        c.glow(project(0, 1.08, z + 22), 28 + tier * 4, cfg["glow"], 75)
    elif stat == "academy":
        # book stack / lecture plinth
        c.box(-2.55, 0.80, 0.65, 0.45, 16, 16, (112, 82, 55))
        c.box(-2.55, 0.80, 0.65, 0.45, 32, 8, cfg["accent"])
        if tier >= 3:
            draw_tower(c, 1.05, -1.45, z + 15, cfg, 44 + tier * 10)
    elif stat == "leverage":
        c.box(-2.55, 0.95, 0.75, 0.55, 16, 18, (113, 78, 41))
        c.box(1.75, 0.95, 0.75, 0.55, 16, 18, (113, 78, 41))
        # market canopy
        c.roof(-2.75, 0.55, 1.2, 0.9, 39, 8, cfg["accent"])
        if tier >= 3:
            c.roof(1.55, 0.55, 1.2, 0.9, 39, 8, cfg["accent"])
    elif stat == "presence":
        if tier >= 2:
            draw_tower(c, -1.95, -1.30, z, cfg, 46 + tier * 10)
            draw_tower(c, 1.22, -1.15, z, cfg, 46 + tier * 10)
        # banner on front, stat-colored but as production art, not debug marker.
        pole_a = project(0.95, 1.42, z + 4)
        pole_b = project(0.95, 1.42, z + 64)
        c.line([pole_a, pole_b], rgba((35, 27, 20), 220), 3)
        flag = [pole_b, (pole_b[0] + 35, pole_b[1] + 9), (pole_b[0] + 24, pole_b[1] + 26), (pole_b[0], pole_b[1] + 18)]
        c.polygon(flag, rgba(cfg["accent"], 210), rgba((255, 255, 255), 48))
    elif stat == "craft":
        # glowing worktable/anvil
        c.box(-2.45, 0.95, 0.70, 0.55, 16, 18, (89, 75, 72))
        c.glow(project(-2.12, 1.22, 44), 18, cfg["glow"], 55)
        if tier >= 3:
            c.ellipse((326, 225, 356, 255), rgba(cfg["accent"], 68), rgba(cfg["accent"], 180), 2)
            c.ellipse((333, 232, 349, 248), rgba((0, 0, 0), 35))
    elif stat == "vitality":
        # training dummy + recovery pool
        c.box(-2.55, 0.30, 0.28, 0.28, 16, 42, (116, 72, 35))
        head = project(-2.41, 0.44, 64)
        c.ellipse((head[0] - 9, head[1] - 11, head[0] + 9, head[1] + 7), rgba((196, 142, 81), 255))
        pool = project(1.75, 0.96, 22)
        c.ellipse((pool[0] - 35, pool[1] - 16, pool[0] + 35, pool[1] + 18), rgba((104, 224, 211), 125), rgba(cfg["accent"], 160), 2)
    elif stat == "capital":
        # treasury coin stacks/chests
        for i, dx in enumerate([-2.35, 1.95]):
            base = project(dx, 1.08, 26)
            for j in range(3 + tier):
                c.ellipse((base[0] - 12, base[1] - 6 - j * 5, base[0] + 12, base[1] + 4 - j * 5), rgba(cfg["accent"], 210), rgba((80, 55, 20), 95), 1)
    elif stat == "clarity":
        # crystal + observatory/telescope silhouette
        crystal_base = project(-1.95, 0.85, 22)
        c.glow(crystal_base, 36, cfg["glow"], 62)
        crystal = [
            (crystal_base[0], crystal_base[1] - 54),
            (crystal_base[0] + 20, crystal_base[1] - 14),
            (crystal_base[0] + 8, crystal_base[1] + 18),
            (crystal_base[0] - 16, crystal_base[1] + 20),
            (crystal_base[0] - 24, crystal_base[1] - 15),
        ]
        c.polygon(crystal, rgba(cfg["accent"], 185), rgba((255, 255, 255), 130), 2)
        if tier >= 3:
            dome = project(1.35, -1.05, 88 + tier * 10)
            c.ellipse((dome[0] - 42, dome[1] - 30, dome[0] + 42, dome[1] + 36), rgba(lighten(cfg["base"], 0.12), 235), rgba(cfg["accent"], 120), 2)
            c.line([(dome[0] + 12, dome[1] - 18), (dome[0] + 58, dome[1] - 58)], rgba(lighten(cfg["accent"], 0.28), 230), 6)


def draw_sprite(stat: str, tier: int) -> Image.Image:
    cfg = STATS[stat]
    c = SpriteCanvas()
    draw_platform(c, tier, cfg)
    draw_main_hall(c, tier, cfg, stat)
    draw_stat_details(c, stat, tier, cfg)

    # legendary outline/glow for higher tiers
    if tier >= 4:
        c.glow((256, 255), 98, cfg["glow"], 28)
    elif tier >= 3:
        c.glow((256, 265), 72, cfg["glow"], 18)

    return c.finish()


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for stat in STATS:
        for tier in range(1, 5):
            img = draw_sprite(stat, tier)
            out = OUT_DIR / f"{stat}_t{tier}.png"
            img.save(out)
            print(out.relative_to(OUT_DIR.parent.parent))


if __name__ == "__main__":
    main()
