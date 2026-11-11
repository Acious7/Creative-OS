import os
import math
from PIL import Image, ImageDraw

def render_icon(size, is_foreground_only=False, is_monochrome=False, is_round=False):
    # Supersample at 4x for smooth anti-aliased geometry
    scale = 4
    w = size * scale
    h = size * scale
    
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background (if not transparent foreground layer)
    if not is_foreground_only:
        if is_round:
            draw.ellipse([0, 0, w - 1, h - 1], fill=(10, 12, 14, 255))
        else:
            # Rounded squircle for full app icon
            corner_r = int(w * 0.22)
            draw.rounded_rectangle([0, 0, w - 1, h - 1], radius=corner_r, fill=(10, 12, 14, 255))
            
    # Colors
    white_color = (255, 255, 255, 255)
    ember_color = (255, 255, 255, 255) if is_monochrome else (255, 106, 31, 255)
    ring_color = (255, 255, 255, 160) if is_monochrome else (46, 55, 64, 255)
    
    # Adaptive safe zone: foreground occupies center 66% (radius ~0.33)
    cx = w / 2.0
    cy = h / 2.0
    unit = w / 108.0  # normalize to 108dp Android grid
    
    # Outer Aperture Ring
    ring_r = 34.0 * unit
    ring_thickness = int(2.5 * unit)
    draw.ellipse(
        [cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r],
        outline=ring_color,
        width=max(1, ring_thickness)
    )
    
    # Geometric Monogram 'E'
    # Spine: x from (cx - 14*unit) to (cx - 9*unit), y from (cy - 22*unit) to (cy + 22*unit)
    spine_x1 = cx - 14.0 * unit
    spine_x2 = cx - 9.0 * unit
    spine_y1 = cy - 22.0 * unit
    spine_y2 = cy + 22.0 * unit
    draw.rounded_rectangle(
        [spine_x1, spine_y1, spine_x2, spine_y2],
        radius=int(2.5 * unit),
        fill=white_color
    )
    
    # Top Bar: from spine_x2 to cx + 14*unit, y from cy - 20*unit to cy - 12*unit
    top_poly = [
        (spine_x2, cy - 20.0 * unit),
        (cx + 14.0 * unit, cy - 20.0 * unit),
        (cx + 8.0 * unit, cy - 12.0 * unit),
        (spine_x2, cy - 12.0 * unit),
    ]
    draw.polygon(top_poly, fill=white_color)
    
    # Middle Bar (Ember Orange): from spine_x2 to cx + 10*unit, y from cy - 4.0*unit to cy + 4.0*unit
    mid_poly = [
        (spine_x2, cy - 4.0 * unit),
        (cx + 10.0 * unit, cy - 4.0 * unit),
        (cx + 4.0 * unit, cy + 4.0 * unit),
        (spine_x2, cy + 4.0 * unit),
    ]
    draw.polygon(mid_poly, fill=ember_color)
    
    # Bottom Bar: from spine_x2 to cx + 14*unit, y from cy + 12*unit to cy + 20*unit
    bot_poly = [
        (spine_x2, cy + 12.0 * unit),
        (cx + 14.0 * unit, cy + 12.0 * unit),
        (cx + 8.0 * unit, cy + 20.0 * unit),
        (spine_x2, cy + 20.0 * unit),
    ]
    draw.polygon(bot_poly, fill=white_color)
    
    # Core Aperture Lens Focal Dot
    dot_cx = cx + 17.0 * unit
    dot_cy = cy
    dot_r = 4.5 * unit
    draw.ellipse(
        [dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r],
        fill=ember_color
    )
    
    # Downsample using LANCZOS for high anti-aliasing quality
    return img.resize((size, size), Image.Resampling.LANCZOS)

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    assets_dir = os.path.join(root, "assets", "icon")
    res_dir = os.path.join(root, "android", "app", "src", "main", "res")
    os.makedirs(assets_dir, exist_ok=True)
    
    print("Generating Master Icons in assets/icon/...")
    master_1024 = render_icon(1024)
    master_1024.save(os.path.join(assets_dir, "app_icon.png"))
    
    master_fore = render_icon(432, is_foreground_only=True)
    master_fore.save(os.path.join(assets_dir, "ic_launcher_foreground.png"))
    
    master_mono = render_icon(432, is_foreground_only=True, is_monochrome=True)
    master_mono.save(os.path.join(assets_dir, "ic_launcher_monochrome.png"))
    
    # Android Mipmap Sizes: (legacy_size, adaptive_size)
    mipmaps = {
        "mipmap-mdpi": (48, 108),
        "mipmap-hdpi": (72, 162),
        "mipmap-xhdpi": (96, 216),
        "mipmap-xxhdpi": (144, 324),
        "mipmap-xxxhdpi": (192, 432),
    }
    
    for folder, (leg_s, adapt_s) in mipmaps.items():
        target_dir = os.path.join(res_dir, folder)
        os.makedirs(target_dir, exist_ok=True)
        
        # 1. Standard square launcher
        leg_icon = render_icon(leg_s)
        leg_icon.save(os.path.join(target_dir, "ic_launcher.png"))
        
        # 2. Round launcher
        round_icon = render_icon(leg_s, is_round=True)
        round_icon.save(os.path.join(target_dir, "ic_launcher_round.png"))
        
        # 3. Adaptive Foreground
        fore_icon = render_icon(adapt_s, is_foreground_only=True)
        fore_icon.save(os.path.join(target_dir, "ic_launcher_foreground.png"))
        
        # 4. Monochrome Layer (Android 13+ theming)
        mono_icon = render_icon(adapt_s, is_foreground_only=True, is_monochrome=True)
        mono_icon.save(os.path.join(target_dir, "ic_launcher_monochrome.png"))
        
        print(f"Generated {folder}: legacy={leg_s}x{leg_s}, adaptive={adapt_s}x{adapt_s}")

    print("App icon generation complete!")

if __name__ == "__main__":
    main()
