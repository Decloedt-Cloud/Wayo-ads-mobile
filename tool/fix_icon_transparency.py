"""Remove outer white matte from app icon PNGs (corner flood-fill from edges)."""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

from PIL import Image


def remove_white_matte(path: Path, *, rgb_min: int = 238) -> None:
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    px = img.load()

    def is_whiteish(r: int, g: int, b: int) -> bool:
        return r >= rgb_min and g >= rgb_min and b >= rgb_min

    visited = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()

    for x in range(w):
        for y in (0, h - 1):
            if not visited[y][x]:
                r, g, b, _ = px[x, y]
                if is_whiteish(r, g, b):
                    visited[y][x] = True
                    q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if not visited[y][x]:
                r, g, b, _ = px[x, y]
                if is_whiteish(r, g, b):
                    visited[y][x] = True
                    q.append((x, y))

    while q:
        x, y = q.popleft()
        r, g, b, _ = px[x, y]
        px[x, y] = (r, g, b, 0)
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx]:
                r2, g2, b2, _ = px[nx, ny]
                if is_whiteish(r2, g2, b2):
                    visited[ny][nx] = True
                    q.append((nx, ny))

    img.save(path, format="PNG", optimize=True)
    print(f"OK: {path}")


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    for rel in (
        "assets/android-chrome-192x192.png",
        "assets/apple-touch-icon.png",
    ):
        p = root / rel
        if not p.is_file():
            print(f"Skip (missing): {p}", file=sys.stderr)
            continue
        remove_white_matte(p)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
