"""Generate placeholder avatar PNGs for the WeChat clone app.

Creates simple 240x240 PNGs with a solid colored background. These are
placeholders that the UI Track will replace with real headshots. The UI
also overlays a Text glyph (first character of the nickname) in Flutter,
so the color variety below mainly provides visual differentiation.

Usage:
    python tools/gen_avatars.py
"""
from __future__ import annotations

import struct
import zlib
from pathlib import Path

# 10 distinct colors (5 WeChat-themed + 5 complementary) for visual variety
PALETTE = [
    (0x07, 0xC1, 0x60),  # 微信绿
    (0x57, 0x6B, 0x95),  # 链接蓝
    (0xE6, 0x43, 0x40),  # 警示红
    (0xFA, 0x9D, 0x3B),  # 警告橙
    (0x95, 0xEC, 0x69),  # 浅绿
    (0x66, 0xCC, 0xFF),  # 天空蓝
    (0xB3, 0x7F, 0xE6),  # 紫罗兰
    (0xFF, 0xB7, 0x4D),  # 蜜橙
    (0x4D, 0xCD, 0xB6),  # 薄荷
    (0xE6, 0x73, 0x9C),  # 玫红
]


def write_png(path: Path, rgb: tuple[int, int, int], size: int = 240) -> None:
    """Write a solid-color PNG of given size using only stdlib."""
    r, g, b = rgb
    # Each row: filter byte 0, then 4 bytes per pixel (RGBA)
    row = bytes([0]) + bytes([r, g, b, 0xFF]) * size
    raw = row * size
    compressed = zlib.compress(raw, 9)

    def chunk(tag: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)  # 8-bit RGBA
    idat = compressed
    iend = b""

    path.write_bytes(sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", iend))


def main() -> None:
    out_dir = Path(__file__).resolve().parent.parent / "assets" / "images" / "avatars"
    out_dir.mkdir(parents=True, exist_ok=True)

    for i, rgb in enumerate(PALETTE, start=1):
        path = out_dir / f"avatar_{i}.png"
        write_png(path, rgb)
        print(f"wrote {path}  color=#{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}")


if __name__ == "__main__":
    main()
