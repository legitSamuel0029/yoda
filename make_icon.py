#!/usr/bin/env python3
"""Generates a simple yoda icon PNG."""
import struct, zlib, math, sys

def make_png(size, pixels_rgba):
    raw = b''
    for y in range(size):
        raw += b'\x00'
        for x in range(size):
            raw += bytes(pixels_rgba[y * size + x])

    def chunk(tag, data):
        crc = zlib.crc32(tag + data) & 0xffffffff
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', crc)

    ihdr = struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0)
    return (b'\x89PNG\r\n\x1a\n'
            + chunk(b'IHDR', ihdr)
            + chunk(b'IDAT', zlib.compress(raw, 9))
            + chunk(b'IEND', b''))

def make_icon(out_path, size=1024):
    cx = cy = size / 2
    radius = size * 0.42        # rounded rect radius for corner calc
    corner_r = size * 0.22      # corner rounding

    bg   = (14,  14,  14)       # #0e0e0e  dark background
    acc  = (163, 230,  53)      # #a3e635  lime accent
    dark = (10,  10,  10)       # slightly darker edge

    pixels = []
    for y in range(size):
        for x in range(size):
            nx = x - cx
            ny = y - cy
            # rounded rect signed distance
            qx = abs(nx) - (size * 0.42 - corner_r)
            qy = abs(ny) - (size * 0.42 - corner_r)
            dist = math.sqrt(max(qx,0)**2 + max(qy,0)**2) - corner_r
            if dist > 1:
                pixels.append((0, 0, 0, 0))   # transparent outside
                continue
            alpha = max(0, min(255, int((1 - dist) * 255)))

            # Draw two horizontal lines suggesting a task list
            rel_y = (y - cy) / size          # -0.5 to 0.5
            rel_x = (x - cx) / size

            # tick box outlines at two "rows"
            in_accent = False
            for row_y in [-0.10, 0.10]:
                # small square left side
                box_x0, box_x1 = -0.30, -0.18
                box_y0, box_y1 = row_y - 0.065, row_y + 0.065
                in_box = box_x0 < rel_x < box_x1 and box_y0 < rel_y < box_y1
                box_border = (abs(rel_x - box_x0) < 0.012 or abs(rel_x - box_x1) < 0.012 or
                              abs(rel_y - box_y0) < 0.012 or abs(rel_y - box_y1) < 0.012)
                # line to the right
                in_line = -0.10 < rel_x < 0.30 and abs(rel_y - row_y) < 0.022
                if in_box and box_border:
                    in_accent = True
                if in_line:
                    in_accent = True

            if in_accent:
                pixels.append((acc[0], acc[1], acc[2], alpha))
            else:
                pixels.append((bg[0], bg[1], bg[2], alpha))

    png_data = make_png(size, pixels)
    with open(out_path, 'wb') as f:
        f.write(png_data)

if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else '/tmp/yoda_icon.png'
    make_icon(out, 1024)
    print(f"Icon written to {out}")
