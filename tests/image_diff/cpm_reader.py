#!/usr/bin/env python3
"""
CPM Image Format Reader for ChrysaLisp

CPM is ChrysaLisp's native compressed pixmap format.
Header structure (28 bytes, little-endian):
  - ident: 4 bytes ('.CPM' or '.FLM')
  - bytes: 4 bytes (total size, 0 if unknown)
  - version: 4 bytes
  - type: 4 bytes (pixel format: 1,8,12,15,16,24,32)
  - width: 4 bytes
  - height: 4 bytes
  - trans: 4 bytes (transparent color)

Data is RLE encoded with bit-packed pixels.
"""

import struct
from pathlib import Path
from typing import Optional, Tuple
import numpy as np

class CPMReader:
    """Read ChrysaLisp CPM image files."""

    HEADER_SIZE = 28
    IDENT_CPM = b'.CPM'
    IDENT_FLM = b'.FLM'
    # Reversed for little-endian
    IDENT_CPM_LE = b'MPC.'
    IDENT_FLM_LE = b'MLF.'

    def __init__(self, filepath: str):
        self.filepath = Path(filepath)
        self.width = 0
        self.height = 0
        self.pixel_type = 0
        self.trans = 0
        self.data = None

    def read(self) -> np.ndarray:
        """Read CPM file and return RGBA numpy array."""
        with open(self.filepath, 'rb') as f:
            # Read header
            header = f.read(self.HEADER_SIZE)
            if len(header) < self.HEADER_SIZE:
                raise ValueError(f"Invalid CPM file: header too short")

            ident, total_bytes, version, ptype, w, h, trans = struct.unpack(
                '<4sIIIIII', header)

            if ident not in (self.IDENT_CPM_LE, self.IDENT_FLM_LE):
                raise ValueError(f"Invalid CPM ident: {ident}")

            self.width = w
            self.height = h
            self.pixel_type = ptype
            self.trans = trans

            # Read compressed data
            compressed = f.read()

        # Decompress
        return self._decompress(compressed)

    def _decompress(self, data: bytes) -> np.ndarray:
        """Decompress RLE data to RGBA array."""
        # Output buffer
        pixels = np.zeros((self.height, self.width, 4), dtype=np.uint8)
        flat = pixels.reshape(-1, 4)
        pixel_idx = 0
        total_pixels = self.width * self.height

        # Bit reader state
        bit_pool = 0
        bit_pool_size = 0
        byte_idx = 0

        # Bits per pixel based on type
        bits = self.pixel_type
        if bits in (12, 15):
            bits = 16

        def read_bits(n: int) -> int:
            nonlocal bit_pool, bit_pool_size, byte_idx
            while bit_pool_size < n:
                if byte_idx >= len(data):
                    return -1
                bit_pool |= data[byte_idx] << bit_pool_size
                byte_idx += 1
                bit_pool_size += 8
            result = bit_pool & ((1 << n) - 1)
            bit_pool >>= n
            bit_pool_size -= n
            return result

        def to_argb32(col: int) -> Tuple[int, int, int, int]:
            """Convert pixel value to RGBA based on pixel type."""
            if self.pixel_type == 32:
                a = (col >> 24) & 0xFF
                r = (col >> 16) & 0xFF
                g = (col >> 8) & 0xFF
                b = col & 0xFF
            elif self.pixel_type == 24:
                a = 255
                r = (col >> 16) & 0xFF
                g = (col >> 8) & 0xFF
                b = col & 0xFF
            elif self.pixel_type == 16:
                a = 255
                r = ((col >> 11) & 0x1F) << 3
                g = ((col >> 5) & 0x3F) << 2
                b = (col & 0x1F) << 3
            elif self.pixel_type == 15:
                a = 255 if (col & 0x8000) else 0
                r = ((col >> 10) & 0x1F) << 3
                g = ((col >> 5) & 0x1F) << 3
                b = (col & 0x1F) << 3
            elif self.pixel_type == 12:
                a = ((col >> 12) & 0xF) << 4
                r = ((col >> 8) & 0xF) << 4
                g = ((col >> 4) & 0xF) << 4
                b = (col & 0xF) << 4
            elif self.pixel_type == 8:
                a = 255
                r = g = b = col
            elif self.pixel_type == 1:
                a = 255
                r = g = b = 255 if col else 0
            else:
                a = r = g = b = 0
            return (r, g, b, a)

        while pixel_idx < total_pixels:
            token = read_bits(8)
            if token < 0:
                break

            if token >= 128:
                # Run of same pixel
                length = token - 127
                col = read_bits(bits)
                if col < 0:
                    break
                rgba = to_argb32(col)
                if col != self.trans:
                    for _ in range(length):
                        if pixel_idx < total_pixels:
                            flat[pixel_idx] = rgba
                            pixel_idx += 1
                else:
                    pixel_idx += length
            else:
                # Block of different pixels
                length = token + 1
                for _ in range(length):
                    col = read_bits(bits)
                    if col < 0:
                        break
                    if pixel_idx < total_pixels:
                        rgba = to_argb32(col)
                        if col != self.trans:
                            flat[pixel_idx] = rgba
                        pixel_idx += 1

        return pixels


def cpm_to_png(cpm_path: str, png_path: str) -> bool:
    """Convert CPM file to PNG."""
    try:
        from PIL import Image
        reader = CPMReader(cpm_path)
        pixels = reader.read()
        img = Image.fromarray(pixels, 'RGBA')
        img.save(png_path)
        return True
    except Exception as e:
        print(f"Error converting {cpm_path}: {e}")
        return False


if __name__ == '__main__':
    import sys
    if len(sys.argv) < 3:
        print("Usage: cpm_reader.py <input.cpm> <output.png>")
        sys.exit(1)
    if cpm_to_png(sys.argv[1], sys.argv[2]):
        print(f"Converted {sys.argv[1]} -> {sys.argv[2]}")
    else:
        sys.exit(1)
