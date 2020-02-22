import sys
from PIL import Image, ImageDraw, ImageFilter

tile_size = 64

def draw_tile(draw, tx, ty):
    draw.rectangle((tx * 64, ty * 64, tx * 64 + 64, ty * 64 + 64), "white")

def make_tile(mask):
    img = Image.new("RGB", (64*3, 64*3))
    draw = ImageDraw.Draw(img)
    draw_tile(draw, 1, 1)
    offsets = [(0, 0), (1, 0), (2, 0),
               (0, 1),         (2, 1),
               (0, 2), (1, 2), (2, 2)]
    c = 1
    for i in range(9):
        if mask & c > 0:
            draw_tile(draw, *offsets[i])
        c *= 2
    return img

def make_tile_full(mask):
    img = make_tile(mask)
    return img.filter(ImageFilter.GaussianBlur(16))

def generate_tilemap():
    tile_map = Image.new("RGB", (64*16, 64*16))
    for i in range(256):
        x = i % 16
        y = i // 16
        tile = make_tile_full(i)
        center = tile.crop((64, 64, 128, 128))
        tile_map.paste(center, (x*64, y*64))
    tile_map.show()
    tile_map.save("transitions.png")

if len(sys.argv) < 2:
    generate_tilemap()
else:
    make_tile_full(int(sys.argv[1])).show()

