import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter

os.makedirs('assets/hub', exist_ok=True)
W, H = 1440, 3120

# 1. hub_back.webp: Sky, haze, distant atmosphere, near-black
back = Image.new('RGB', (W, H), (10, 12, 13)) # #0A0C0D
draw_back = ImageDraw.Draw(back)

for y in range(H):
    progress = y / H
    r = int(6 + (17 - 6) * progress)
    g = int(8 + (20 - 8) * progress)
    b = int(9 + (23 - 9) * progress)
    
    if 0.5 < progress < 0.9:
        haze = math.sin((progress - 0.5) / 0.4 * math.pi) * 22
        r += int(haze * 1.1)
        g += int(haze * 0.9)
        b += int(haze * 0.7)
    draw_back.line([(0, y), (W, y)], fill=(min(255, r), min(255, g), min(255, b)))

back.save('assets/hub/hub_back.webp', 'WEBP', quality=90)
print('Generated assets/hub/hub_back.webp')

# 2. hub_mid.webp: Warriors / subject art on pure black background (#000000)
mid = Image.new('RGB', (W, H), (0, 0, 0))
draw_mid = ImageDraw.Draw(mid)

cream = (243, 234, 217) # #F3EAD9
ember = (255, 106, 31)   # #FF6A1F
ember_glow = (180, 70, 15)

for i in range(12):
    y_start = 2200 + i * 70
    points = [
        (40 + i * 15, y_start),
        (220 + i * 20, y_start - 120),
        (380 + i * 15, y_start + 40),
        (460, y_start - 30)
    ]
    color = ember if i % 4 == 0 else (cream[0]//2, cream[1]//2, cream[2]//2)
    draw_mid.line(points, fill=color, width=3)

for i in range(12):
    y_start = 2200 + i * 70
    points = [
        (W - (40 + i * 15), y_start),
        (W - (220 + i * 20), y_start - 120),
        (W - (380 + i * 15), y_start + 40),
        (W - 460, y_start - 30)
    ]
    color = ember if i % 4 == 0 else (cream[0]//2, cream[1]//2, cream[2]//2)
    draw_mid.line(points, fill=color, width=3)

cx = W // 2
for r_val in range(150, 450, 60):
    bbox = [cx - r_val, 2800 - r_val, cx + r_val, 2800 + r_val]
    draw_mid.arc(bbox, 190, 350, fill=ember_glow, width=2)

draw_mid.line([(cx, 2350), (cx, 2900)], fill=ember, width=4)
for dy in range(2400, 2850, 50):
    draw_mid.polygon([(cx, dy - 20), (cx - 40, dy + 20), (cx + 40, dy + 20)], outline=cream, width=2)

mid_blur = mid.filter(ImageFilter.GaussianBlur(radius=0.8))
mid_blur.save('assets/hub/hub_mid.webp', 'WEBP', quality=90)
print('Generated assets/hub/hub_mid.webp')

# 3. hub_front.webp: floating dust, embers, light particles on pure black (#000000)
front = Image.new('RGB', (W, H), (0, 0, 0))
draw_front = ImageDraw.Draw(front)

random.seed(42)

for _ in range(180):
    px = random.randint(30, W - 30)
    py = random.randint(100, H - 100)
    radius = random.choice([2, 3, 4, 6, 8])
    is_ember = random.random() < 0.65
    c = ember if is_ember else cream
    alpha = random.uniform(0.4, 0.95)
    f_color = (int(c[0] * alpha), int(c[1] * alpha), int(c[2] * alpha))
    
    draw_front.ellipse([px - radius, py - radius, px + radius, py + radius], fill=f_color)
    if radius >= 4:
        draw_front.ellipse([px - radius * 2, py - radius * 2, px + radius * 2, py + radius * 2], outline=(int(c[0]*0.3), int(c[1]*0.3), int(c[2]*0.3)), width=1)

front_glow = front.filter(ImageFilter.GaussianBlur(radius=1.2))
front_combined = Image.blend(front, front_glow, 0.4)
front_combined.save('assets/hub/hub_front.webp', 'WEBP', quality=90)
print('Generated assets/hub/hub_front.webp')
