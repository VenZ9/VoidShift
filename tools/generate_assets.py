#!/usr/bin/env python3
"""
VOIDSHIFT - Original Pixel Art & Texture Generator
Creates high-contrast sci-fi pixel art sprites, tiles, UI icons, and the official VOIDSHIFT logo.
"""

import os
from PIL import Image, ImageDraw, ImageFont

def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

# Color Palette (Dark Sci-Fi Void Station)
PALETTE = {
    "void_black": (10, 12, 18, 255),
    "space_dark": (18, 24, 38, 255),
    "hull_dark": (30, 39, 58, 255),
    "hull_mid": (48, 62, 92, 255),
    "hull_light": (82, 102, 145, 255),
    "hull_highlight": (135, 160, 205, 255),
    "cyan_core": (0, 240, 255, 255),
    "cyan_dim": (0, 140, 160, 255),
    "cyan_glow": (100, 248, 255, 180),
    "amber_warn": (255, 170, 0, 255),
    "amber_dim": (180, 110, 0, 255),
    "crimson_alert": (255, 45, 85, 255),
    "crimson_dim": (160, 20, 50, 255),
    "plasma_magenta": (220, 0, 255, 255),
    "white": (255, 255, 255, 255),
    "clear": (0, 0, 0, 0),
}

def create_logo(output_path):
    # 480x110 Pixel Art Logo
    w, h = 480, 110
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Outer Tech Frame / Backing Plate
    draw.rectangle([10, 10, w - 10, h - 10], fill=(12, 16, 26, 235), outline=(48, 62, 92, 255), width=2)
    # Beveled corners
    draw.line([(10, 25), (25, 10)], fill=(0, 240, 255, 255), width=2)
    draw.line([(w - 25, 10), (w - 10, 25)], fill=(0, 240, 255, 255), width=2)
    draw.line([(10, h - 25), (25, h - 10)], fill=(0, 240, 255, 255), width=2)
    draw.line([(w - 25, h - 10), (w - 10, h - 25)], fill=(0, 240, 255, 255), width=2)
    
    # Grid lines in background
    for x in range(30, w - 30, 24):
        draw.line([(x, 15), (x, h - 15)], fill=(20, 30, 48, 120), width=1)
    for y in range(20, h - 20, 18):
        draw.line([(20, y), (w - 20, y)], fill=(20, 30, 48, 120), width=1)

    # Pixel font simulation for "VOIDSHIFT"
    # 9 characters: V O I D S H I F T
    # 5x7 block font scaled by 5 (each pixel is 5x5)
    chars = {
        'V': ["1...1", "1...1", "1...1", "1...1", "1...1", ".1.1.", "..1.."],
        'O': [".111.", "1...1", "1...1", "1...1", "1...1", "1...1", ".111."],
        'I': ["11111", "..1..", "..1..", "..1..", "..1..", "..1..", "11111"],
        'D': ["111..", "1..1.", "1...1", "1...1", "1...1", "1..1.", "111.."],
        'S': [".1111", "1....", "1....", ".111.", "....1", "....1", "1111."],
        'H': ["1...1", "1...1", "1...1", "11111", "1...1", "1...1", "1...1"],
        'F': ["11111", "1....", "1....", "1111.", "1....", "1....", "1...."],
        'T': ["11111", "..1..", "..1..", "..1..", "..1..", "..1..", "..1.."],
    }
    word = "VOIDSHIFT"
    
    # Scale factor 6, spacing 10
    scale = 6
    char_w = 5 * scale
    char_h = 7 * scale
    spacing = 10
    total_text_w = len(word) * char_w + (len(word) - 1) * spacing
    start_x = (w - total_text_w) // 2
    start_y = 26
    
    for c_idx, char in enumerate(word):
        grid = chars[char]
        cx = start_x + c_idx * (char_w + spacing)
        for r_idx, row in enumerate(grid):
            for col_idx, pixel in enumerate(row):
                if pixel == '1':
                    px = cx + col_idx * scale
                    py = start_y + r_idx * scale
                    # Chromatic aberration shadow
                    draw.rectangle([px + 2, py + 2, px + scale + 1, py + scale + 1], fill=(220, 0, 100, 160))
                    # Cyan core
                    draw.rectangle([px, py, px + scale - 1, py + scale - 1], fill=(0, 240, 255, 255))
                    # Inner white highlight
                    if col_idx in (1, 2) and r_idx in (1, 2, 3):
                        draw.rectangle([px + 1, py + 1, px + scale - 2, py + scale - 2], fill=(220, 255, 255, 255))

    # Subtitle: "GRAVITATIONAL ROGUELITE"
    sub_y = h - 24
    draw.rectangle([start_x, sub_y - 2, start_x + total_text_w, sub_y + 10], fill=(25, 34, 52, 200))
    # Draw chevron accents on sides of subtitle
    draw.polygon([(start_x - 14, sub_y + 4), (start_x - 6, sub_y), (start_x - 6, sub_y + 8)], fill=(0, 240, 255, 255))
    draw.polygon([(start_x + total_text_w + 14, sub_y + 4), (start_x + total_text_w + 6, sub_y), (start_x + total_text_w + 6, sub_y + 8)], fill=(0, 240, 255, 255))
    
    # Gravity Shift Symbol Chevrons at bottom center
    mid_x = w // 2
    for offset, color in [(-12, (255, 170, 0, 255)), (0, (0, 240, 255, 255)), (12, (255, 45, 85, 255))]:
        draw.polygon([(mid_x + offset - 4, sub_y + 1), (mid_x + offset, sub_y - 3), (mid_x + offset + 4, sub_y + 1)], fill=color)

    ensure_dir(output_path)
    img.save(output_path, "PNG")
    print(f"Generated Logo: {output_path}")

def create_player(output_path):
    # 32x32 Player Omni-Grav RIG suit (Top-down)
    w, h = 32, 32
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Outer dark shadow / border
    draw.ellipse([6, 5, 25, 26], fill=(12, 16, 26, 255))
    # Armor Shoulders / Torso
    draw.rectangle([8, 10, 23, 23], fill=PALETTE["hull_light"])
    draw.rectangle([9, 11, 22, 22], fill=PALETTE["hull_mid"])
    # Left shoulder pad
    draw.rectangle([6, 11, 8, 20], fill=PALETTE["hull_highlight"])
    # Right shoulder pad
    draw.rectangle([23, 11, 25, 20], fill=PALETTE["hull_highlight"])
    # Helmet / Visor (Facing UP by default)
    draw.ellipse([11, 6, 20, 15], fill=PALETTE["hull_dark"])
    draw.rectangle([12, 8, 19, 11], fill=PALETTE["cyan_core"])
    draw.point((14, 9), fill=PALETTE["white"])
    # Omni-Grav Core on back (Cyan glowing circular emitter)
    draw.ellipse([13, 14, 18, 19], fill=PALETTE["cyan_dim"])
    draw.ellipse([14, 15, 17, 18], fill=PALETTE["cyan_core"])
    draw.point((15, 16), fill=PALETTE["white"])
    # Magnetic boots / thruster nozzles (facing DOWN)
    draw.rectangle([9, 24, 13, 27], fill=PALETTE["hull_dark"])
    draw.rectangle([18, 24, 22, 27], fill=PALETTE["hull_dark"])
    draw.line([(10, 27), (12, 27)], fill=PALETTE["amber_warn"])
    draw.line([(19, 27), (21, 27)], fill=PALETTE["amber_warn"])
    # Directional forward aiming indicator dot
    draw.rectangle([15, 2, 16, 4], fill=PALETTE["cyan_core"])
    
    ensure_dir(output_path)
    img.save(output_path, "PNG")
    print(f"Generated Player: {output_path}")

def create_sentry_drone(output_path):
    # 32x32 Sentry Drone
    w, h = 32, 32
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Shadow/Border
    draw.ellipse([5, 5, 26, 26], fill=(12, 16, 24, 255))
    # Main octagonal chassis
    draw.polygon([(10, 6), (21, 6), (26, 11), (26, 20), (21, 25), (10, 25), (5, 20), (5, 11)], fill=PALETTE["hull_mid"])
    draw.polygon([(11, 8), (20, 8), (24, 12), (24, 19), (20, 23), (11, 23), (7, 19), (7, 12)], fill=PALETTE["hull_dark"])
    # Central Menacing Sensor Eye (Crimson red)
    draw.ellipse([12, 11, 19, 18], fill=PALETTE["crimson_dim"])
    draw.ellipse([13, 12, 18, 17], fill=PALETTE["crimson_alert"])
    draw.rectangle([15, 14, 16, 15], fill=PALETTE["white"])
    # Twin weapon blaster prongs
    draw.rectangle([7, 2, 9, 7], fill=PALETTE["hull_highlight"])
    draw.rectangle([22, 2, 24, 7], fill=PALETTE["hull_highlight"])
    draw.point((8, 2), fill=PALETTE["crimson_alert"])
    draw.point((23, 2), fill=PALETTE["crimson_alert"])
    # Lateral Thruster vents
    draw.line([(3, 14), (5, 14)], fill=PALETTE["amber_warn"], width=2)
    draw.line([(26, 14), (28, 14)], fill=PALETTE["amber_warn"], width=2)
    
    ensure_dir(output_path)
    img.save(output_path, "PNG")
    print(f"Generated Enemy Sentry: {output_path}")

def create_tiles(tiles_dir):
    # 1. station_floor.png (32x32)
    floor = Image.new("RGBA", (32, 32), (18, 24, 38, 255))
    d_f = ImageDraw.Draw(floor)
    d_f.rectangle([0, 0, 31, 31], outline=(30, 39, 58, 255), width=1)
    d_f.line([(0, 0), (31, 0)], fill=(40, 52, 78, 255))
    d_f.line([(0, 0), (0, 31)], fill=(40, 52, 78, 255))
    # Rivet corners
    for rx, ry in [(3, 3), (28, 3), (3, 28), (28, 28)]:
        d_f.point((rx, ry), fill=(60, 78, 110, 255))
    # Subtle panel seam cross
    d_f.line([(15, 1), (15, 30)], fill=(24, 32, 50, 255))
    d_f.line([(1, 15), (30, 15)], fill=(24, 32, 50, 255))
    floor.save(os.path.join(tiles_dir, "station_floor.png"))

    # 2. station_wall.png (32x32)
    wall = Image.new("RGBA", (32, 32), (32, 42, 64, 255))
    d_w = ImageDraw.Draw(wall)
    d_w.rectangle([0, 0, 31, 31], fill=(42, 54, 82, 255), outline=(14, 18, 28, 255), width=2)
    # Beveled high-tech bulkhead panel
    d_w.rectangle([4, 4, 27, 27], fill=(52, 68, 102, 255), outline=(70, 92, 138, 255), width=1)
    d_w.line([(4, 4), (27, 4)], fill=(120, 150, 200, 255)) # Top highlight
    d_w.line([(4, 4), (4, 27)], fill=(90, 115, 160, 255))  # Left highlight
    d_w.line([(27, 4), (27, 27)], fill=(25, 32, 50, 255))  # Right shadow
    d_w.line([(4, 27), (27, 27)], fill=(25, 32, 50, 255))  # Bottom shadow
    # Center hazard stripe slot
    d_w.rectangle([10, 12, 21, 19], fill=(22, 28, 44, 255))
    d_w.line([(12, 15), (19, 15)], fill=(0, 240, 255, 255))
    wall.save(os.path.join(tiles_dir, "station_wall.png"))

    # 3. station_hazard.png (32x32)
    hazard = Image.new("RGBA", (32, 32), (22, 28, 42, 255))
    d_h = ImageDraw.Draw(hazard)
    # Diagonal yellow/black hazard stripes
    stripe_w = 6
    for i in range(-32, 64, stripe_w * 2):
        d_h.polygon([(i, 0), (i + stripe_w, 0), (i + stripe_w + 32, 32), (i + 32, 32)], fill=(230, 160, 10, 255))
    # Border
    d_h.rectangle([0, 0, 31, 31], outline=(40, 50, 70, 255), width=1)
    hazard.save(os.path.join(tiles_dir, "station_hazard.png"))

    # 4. grav_rail.png (32x32)
    rail = Image.new("RGBA", (32, 32), (18, 24, 38, 255))
    d_r = ImageDraw.Draw(rail)
    # Magnetic guide rail channel
    d_r.rectangle([10, 0, 21, 31], fill=(28, 38, 56, 255), outline=(48, 64, 96, 255))
    d_r.rectangle([14, 0, 17, 31], fill=(0, 240, 255, 255))
    d_r.line([(15, 0), (16, 31)], fill=(200, 255, 255, 255))
    rail.save(os.path.join(tiles_dir, "grav_rail.png"))

    # 5. airlock_door.png (32x32)
    door = Image.new("RGBA", (32, 32), (28, 36, 54, 255))
    d_d = ImageDraw.Draw(door)
    d_d.rectangle([0, 0, 31, 31], fill=(36, 46, 70, 255), outline=(15, 20, 32, 255), width=2)
    d_d.line([(15, 0), (15, 31)], fill=(15, 20, 32, 255), width=2) # Center seam
    # Access indicator light
    d_d.rectangle([12, 13, 19, 18], fill=(0, 240, 255, 255))
    d_d.point((15, 15), fill=PALETTE["white"])
    door.save(os.path.join(tiles_dir, "airlock_door.png"))
    print(f"Generated Tiles in {tiles_dir}")

def create_props(props_dir):
    # 1. grav_crate.png (32x32)
    crate = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d_c = ImageDraw.Draw(crate)
    d_c.rectangle([2, 2, 29, 29], fill=(65, 80, 115, 255), outline=(20, 26, 40, 255), width=2)
    d_c.rectangle([5, 5, 26, 26], fill=(50, 62, 90, 255))
    # Reinforced corner braces
    for bx, by in [(2, 2), (25, 2), (2, 25), (25, 25)]:
        d_c.rectangle([bx, by, bx + 4, by + 4], fill=(130, 155, 200, 255))
    # Central Gravity Chevrons
    d_c.polygon([(16, 8), (22, 15), (19, 15), (19, 22), (13, 22), (13, 15), (10, 15)], fill=(0, 240, 255, 255))
    d_c.point((16, 11), fill=(255, 255, 255, 255))
    crate.save(os.path.join(props_dir, "grav_crate.png"))

    # 2. energy_cell.png (16x16)
    cell = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d_e = ImageDraw.Draw(cell)
    d_e.rectangle([4, 2, 11, 13], fill=(20, 28, 44, 255), outline=(40, 56, 86, 255))
    d_e.rectangle([5, 4, 10, 11], fill=(0, 240, 255, 255))
    d_e.rectangle([6, 5, 9, 8], fill=(220, 255, 255, 255))
    # Terminal cap
    d_e.rectangle([6, 1, 9, 2], fill=(255, 170, 0, 255))
    cell.save(os.path.join(props_dir, "energy_cell.png"))

    # 3. scrap_metal.png (16x16)
    scrap = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d_s = ImageDraw.Draw(scrap)
    d_s.polygon([(8, 1), (14, 5), (14, 11), (8, 15), (2, 11), (2, 5)], fill=(180, 140, 70, 255), outline=(90, 65, 30, 255))
    d_s.ellipse([6, 6, 10, 10], fill=(50, 40, 25, 255))
    scrap.save(os.path.join(props_dir, "scrap_metal.png"))
    print(f"Generated Props in {props_dir}")

def create_combat(sprites_dir):
    # 1. projectile_player.png (16x16)
    p_p = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d_p = ImageDraw.Draw(p_p)
    d_p.ellipse([4, 2, 11, 13], fill=(0, 240, 255, 140))
    d_p.ellipse([5, 3, 10, 12], fill=(0, 240, 255, 255))
    d_p.ellipse([6, 5, 9, 10], fill=(255, 255, 255, 255))
    p_p.save(os.path.join(sprites_dir, "projectile_player.png"))

    # 2. projectile_enemy.png (16x16)
    p_e = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d_e = ImageDraw.Draw(p_e)
    d_e.ellipse([4, 2, 11, 13], fill=(255, 45, 85, 140))
    d_e.ellipse([5, 3, 10, 12], fill=(255, 45, 85, 255))
    d_e.ellipse([6, 5, 9, 10], fill=(255, 220, 230, 255))
    p_e.save(os.path.join(sprites_dir, "projectile_enemy.png"))
    print(f"Generated Projectiles in {sprites_dir}")

def create_ui(ui_dir):
    # 1. joystick_base.png (128x128)
    jb = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d_jb = ImageDraw.Draw(jb)
    d_jb.ellipse([4, 4, 123, 123], fill=(16, 24, 40, 100), outline=(0, 240, 255, 180), width=2)
    d_jb.ellipse([24, 24, 103, 103], outline=(48, 70, 100, 120), width=1)
    # Crosshair ticks
    d_jb.line([(64, 8), (64, 20)], fill=(0, 240, 255, 200), width=2)
    d_jb.line([(64, 108), (64, 120)], fill=(0, 240, 255, 200), width=2)
    d_jb.line([(8, 64), (20, 64)], fill=(0, 240, 255, 200), width=2)
    d_jb.line([(108, 64), (120, 64)], fill=(0, 240, 255, 200), width=2)
    jb.save(os.path.join(ui_dir, "joystick_base.png"))

    # 2. joystick_tip.png (56x56)
    jt = Image.new("RGBA", (56, 56), (0, 0, 0, 0))
    d_jt = ImageDraw.Draw(jt)
    d_jt.ellipse([2, 2, 53, 53], fill=(24, 38, 64, 210), outline=(0, 240, 255, 240), width=2)
    d_jt.ellipse([16, 16, 39, 39], fill=(0, 240, 255, 180))
    d_jt.ellipse([22, 22, 33, 33], fill=(255, 255, 255, 255))
    jt.save(os.path.join(ui_dir, "joystick_tip.png"))

    # 3. btn_shift_cw.png (64x64) - Clockwise Shift ↷
    bcw = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d_cw = ImageDraw.Draw(bcw)
    d_cw.rectangle([4, 4, 59, 59], fill=(20, 30, 50, 190), outline=(0, 240, 255, 220), width=2)
    # Arc and arrow head
    d_cw.arc([16, 16, 48, 48], start=210, end=380, fill=(0, 240, 255, 255), width=4)
    d_cw.polygon([(46, 30), (52, 22), (40, 24)], fill=(0, 240, 255, 255))
    # "CW" label
    d_cw.point((32, 32), fill=PALETTE["white"])
    bcw.save(os.path.join(ui_dir, "btn_shift_cw.png"))

    # 4. btn_shift_ccw.png (64x64) - Counter-Clockwise Shift ↶
    bccw = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d_ccw = ImageDraw.Draw(bccw)
    d_ccw.rectangle([4, 4, 59, 59], fill=(20, 30, 50, 190), outline=(0, 240, 255, 220), width=2)
    # Arc and arrow head
    d_ccw.arc([16, 16, 48, 48], start=160, end=330, fill=(0, 240, 255, 255), width=4)
    d_ccw.polygon([(18, 30), (12, 22), (24, 24)], fill=(0, 240, 255, 255))
    d_ccw.point((32, 32), fill=PALETTE["white"])
    bccw.save(os.path.join(ui_dir, "btn_shift_ccw.png"))

    # 5. btn_fire.png (64x64)
    bf = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d_f = ImageDraw.Draw(bf)
    d_f.rectangle([4, 4, 59, 59], fill=(30, 20, 36, 190), outline=(255, 45, 85, 220), width=2)
    d_f.ellipse([20, 20, 43, 43], outline=(255, 45, 85, 255), width=2)
    d_f.ellipse([27, 27, 36, 36], fill=(255, 45, 85, 255))
    d_f.line([(32, 14), (32, 49)], fill=(255, 255, 255, 200), width=2)
    d_f.line([(14, 32), (49, 32)], fill=(255, 255, 255, 200), width=2)
    bf.save(os.path.join(ui_dir, "btn_fire.png"))

    # 6. btn_dash.png (64x64)
    bd = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d_d = ImageDraw.Draw(bd)
    d_d.rectangle([4, 4, 59, 59], fill=(20, 32, 44, 190), outline=(255, 170, 0, 220), width=2)
    # Double chevron right
    d_d.polygon([(18, 20), (28, 32), (18, 44), (24, 44), (34, 32), (24, 20)], fill=(255, 170, 0, 255))
    d_d.polygon([(30, 20), (40, 32), (30, 44), (36, 44), (46, 32), (36, 20)], fill=(255, 220, 100, 255))
    bd.save(os.path.join(ui_dir, "btn_dash.png"))

    # 7. btn_pause.png (48x48)
    bp = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    d_p = ImageDraw.Draw(bp)
    d_p.rectangle([2, 2, 45, 45], fill=(20, 26, 40, 180), outline=(100, 130, 170, 200), width=2)
    d_p.rectangle([14, 12, 19, 35], fill=PALETTE["white"])
    d_p.rectangle([28, 12, 33, 35], fill=PALETTE["white"])
    bp.save(os.path.join(ui_dir, "btn_pause.png"))

    # 8. grav_compass.png (64x64) - HUD Gravity Vector Indicator
    gc = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d_gc = ImageDraw.Draw(gc)
    d_gc.ellipse([4, 4, 59, 59], fill=(14, 18, 28, 220), outline=(0, 240, 255, 200), width=2)
    # 4 Cardinal tick marks
    d_gc.line([(32, 6), (32, 12)], fill=(120, 150, 190, 255), width=2)
    d_gc.line([(32, 51), (32, 57)], fill=(0, 240, 255, 255), width=2) # Down is default
    d_gc.line([(6, 32), (12, 32)], fill=(120, 150, 190, 255), width=2)
    d_gc.line([(51, 32), (57, 32)], fill=(120, 150, 190, 255), width=2)
    # Arrow needle pointing Down (default gravity)
    d_gc.polygon([(32, 48), (24, 24), (32, 30), (40, 24)], fill=(0, 240, 255, 255))
    d_gc.ellipse([29, 29, 34, 34], fill=PALETTE["white"])
    gc.save(os.path.join(ui_dir, "grav_compass.png"))
    print(f"Generated UI Icons in {ui_dir}")

if __name__ == "__main__":
    base_assets = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "sprites"))
    create_logo(os.path.join(base_assets, "logo", "voidshift_logo.png"))
    create_player(os.path.join(base_assets, "player", "player_rig.png"))
    create_sentry_drone(os.path.join(base_assets, "enemies", "sentry_drone.png"))
    create_tiles(os.path.join(base_assets, "tiles"))
    create_props(os.path.join(base_assets, "props"))
    create_combat(base_assets)
    create_ui(os.path.join(base_assets, "ui"))
    print("All VOIDSHIFT visual assets generated successfully!")
