from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SHEET_DIR = ROOT / "generated_sheets"
OUT_DIR = ROOT / "assets" / "compound"
SIZE = 512

# Manual crops because image generation produced different sheet layouts per
# stat. Each crop contains exactly one intended tier source image.
CROPS: dict[str, list[tuple[int, int, int, int]]] = {
    # 1152 x 1728 sheets with useful images arranged in a poster layout.
    "forge": [
        (0, 0, 576, 430),
        (576, 0, 1152, 430),
        (576, 430, 1152, 900),
        (520, 850, 1152, 1728),
    ],
    "academy": [
        (0, 0, 576, 430),
        (576, 0, 1152, 430),
        (0, 760, 576, 1290),
        (576, 1240, 1152, 1728),
    ],
    # Mostly 1792 x 1008 sheets; use one row where duplicate rows exist.
    "leverage": [(0, 0, 448, 504), (448, 0, 896, 504), (896, 0, 1344, 504), (1344, 0, 1792, 504)],
    "presence": [(0, 0, 448, 1008), (448, 0, 896, 1008), (896, 0, 1344, 1008), (1344, 0, 1792, 1008)],
    "craft": [(0, 0, 448, 336), (448, 0, 896, 336), (896, 0, 1344, 336), (1344, 0, 1792, 336)],
    "vitality": [(0, 0, 448, 504), (448, 0, 896, 504), (896, 0, 1344, 504), (1344, 0, 1792, 504)],
    "capital": [(0, 0, 448, 1008), (448, 0, 896, 1008), (896, 0, 1344, 1008), (1344, 0, 1792, 1008)],
    "clarity": [(0, 0, 448, 1008), (448, 0, 896, 1008), (896, 0, 1344, 1008), (1344, 0, 1792, 1008)],
}

# Preserve the upgrade fantasy in the final 512 frame: lower tiers occupy less
# visual mass while tier 4 can fill most of the sprite box.
MAX_DIM_BY_TIER = {1: 310, 2: 365, 3: 425, 4: 472}


def is_background_candidate(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a < 20:
        return True
    # Generated sheets use white/off-white/very light gray backgrounds. Remove
    # only low-saturation pixels connected to the crop edge so light stone/gold
    # building details inside the object are preserved.
    return r > 185 and g > 185 and b > 185 and max(r, g, b) - min(r, g, b) < 52


def remove_connected_background(img: Image.Image) -> Image.Image:
    im = img.convert("RGBA")
    pix = im.load()
    w, h = im.size
    seen = set()
    q: deque[tuple[int, int]] = deque()

    for x in range(w):
        for y in (0, h - 1):
            if is_background_candidate(pix[x, y]):
                q.append((x, y))
                seen.add((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if (x, y) not in seen and is_background_candidate(pix[x, y]):
                q.append((x, y))
                seen.add((x, y))

    while q:
        x, y = q.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and is_background_candidate(pix[nx, ny]):
                seen.add((nx, ny))
                q.append((nx, ny))

    for x, y in seen:
        r, g, b, a = pix[x, y]
        pix[x, y] = (r, g, b, 0)

    return im


def keep_relevant_components(img: Image.Image) -> Image.Image:
    """Drop disconnected sheet leftovers while keeping the main building.

    The image model sometimes places small fragments from neighbouring tiers in
    a crop. After background removal, those fragments are usually disconnected
    alpha components. Keep the largest component and nearby components only.
    """
    im = img.convert("RGBA")
    pix = im.load()
    w, h = im.size
    seen: set[tuple[int, int]] = set()
    components: list[tuple[int, tuple[int, int, int, int], list[tuple[int, int]]]] = []

    for y in range(h):
        for x in range(w):
            if (x, y) in seen or pix[x, y][3] <= 12:
                continue
            q: deque[tuple[int, int]] = deque([(x, y)])
            seen.add((x, y))
            pts: list[tuple[int, int]] = []
            while q:
                cx, cy = q.popleft()
                pts.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and pix[nx, ny][3] > 12:
                        seen.add((nx, ny))
                        q.append((nx, ny))
            if len(pts) < 18:
                continue
            xs = [pt[0] for pt in pts]
            ys = [pt[1] for pt in pts]
            components.append((len(pts), (min(xs), min(ys), max(xs) + 1, max(ys) + 1), pts))

    if not components:
        return im

    largest = max(components, key=lambda item: item[0])
    # Keep only the dominant connected art component. This aggressively removes
    # neighbouring-tier fragments that the image model sometimes leaves inside a
    # crop. It also makes every final sprite read as one clean building at map
    # scale instead of a building plus random detached props.
    keep: set[tuple[int, int]] = set(largest[2])

    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out_pix = out.load()
    for x, y in keep:
        out_pix[x, y] = pix[x, y]
    return out


def trim_alpha(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()
    if bbox is None:
        raise ValueError("blank extracted sprite")
    return img.crop(bbox)


def center_in_frame(sprite: Image.Image, tier: int) -> Image.Image:
    max_dim = MAX_DIM_BY_TIER[tier]
    w, h = sprite.size
    scale = min(max_dim / max(w, h), 1.0)
    new_size = (max(1, round(w * scale)), max(1, round(h * scale)))
    sprite = sprite.resize(new_size, Image.Resampling.LANCZOS)

    frame = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    x = (SIZE - sprite.width) // 2
    # Anchor near bottom so all buildings sit consistently on the map.
    y = SIZE - sprite.height - 24
    frame.alpha_composite(sprite, (x, y))
    return frame


def extract_one(stat: str, tier: int, crop: tuple[int, int, int, int]) -> Image.Image:
    sheet = Image.open(SHEET_DIR / f"{stat}_tiers.png").convert("RGBA")
    cropped = sheet.crop(crop)
    cutout = remove_connected_background(cropped)
    cutout = keep_relevant_components(cutout)
    trimmed = trim_alpha(cutout)
    return center_in_frame(trimmed, tier)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for stat, crops in CROPS.items():
        for index, crop in enumerate(crops, start=1):
            sprite = extract_one(stat, index, crop)
            out = OUT_DIR / f"{stat}_t{index}.png"
            sprite.save(out)
            print(out.relative_to(ROOT))


if __name__ == "__main__":
    main()
