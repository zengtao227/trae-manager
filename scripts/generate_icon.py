from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import math

def create_icon(size=1024):
    # Colors
    bg_color = (30, 30, 35)       # Dark gray/black
    accent_color = (0, 122, 255)  # Apple Blue
    text_color = (255, 255, 255)
    
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # macOS Squircle shape (approximate)
    rect_size = size
    radius = size * 0.2237 # macOS icon curvature
    
    # Draw background squircle
    draw.rounded_rectangle(
        [(0, 0), (size, size)], 
        radius=radius, 
        fill=bg_color
    )
    
    # Draw subtle gradient/shine (optional, keep simple for now)
    
    # Draw "T" text
    # Try to load a system font
    font_size = int(size * 0.6)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", font_size)
    except:
        try:
             font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size, index=1)
        except:
             font = ImageFont.load_default()

    # Center text "T"
    text = "T"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    
    text_x = (size - text_w) / 2
    text_y = (size - text_h) / 2 - (size * 0.05) # Slightly move up
    
    draw.text((text_x, text_y), text, font=font, fill=text_color)
    
    # Draw "Switch" indicator (Cycle symbol) - Simplified as a circle/arc
    # Bottom right corner
    indicator_size = int(size * 0.35)
    indicator_x = size - indicator_size - (size * 0.1)
    indicator_y = size - indicator_size - (size * 0.1)
    
    # Draw circle background for indicator
    draw.ellipse(
        [(indicator_x, indicator_y), (indicator_x + indicator_size, indicator_y + indicator_size)],
        fill=accent_color
    )
    
    # Draw "Arrows" or symbol inside indicator
    inner_margin = indicator_size * 0.25
    inner_rect = [
        (indicator_x + inner_margin, indicator_y + inner_margin), 
        (indicator_x + indicator_size - inner_margin, indicator_y + indicator_size - inner_margin)
    ]
    
    # Simply draw two dots or simplified "user" icon representation
    # Drawing a simple user icon silhouette
    cx = indicator_x + indicator_size / 2
    cy = indicator_y + indicator_size / 2
    
    # Head
    head_r = indicator_size * 0.15
    draw.ellipse([(cx - head_r, cy - head_r*1.5), (cx + head_r, cy + head_r*0.5)], fill='white')
    
    # Body
    body_w = indicator_size * 0.4
    body_h = indicator_size * 0.25
    draw.pieslice(
        [(cx - body_w/2, cy + head_r*0.8), (cx + body_w/2, cy + head_r*0.8 + body_h*2)],
        180, 0, fill='white'
    )
    
    return img

if __name__ == "__main__":
    # Create the icon
    icon = create_icon(1024)
    
    # Save as PNG
    icon_path = "TraeManager.png"
    icon.save(icon_path)
    print(f"Icon created: {icon_path}")
    
    # Create iconset folder structure
    iconset_name = "TraeManager.iconset"
    if not os.path.exists(iconset_name):
        os.makedirs(iconset_name)
    
    # Generate sizes required for .iconset
    sizes = [16, 32, 128, 256, 512]
    for s in sizes:
        # 1x
        resized = icon.resize((s, s), Image.Resampling.LANCZOS)
        resized.save(f"{iconset_name}/icon_{s}x{s}.png")
        
        # 2x (Retina)
        s2 = s * 2
        if s2 <= 1024:
            resized2 = icon.resize((s2, s2), Image.Resampling.LANCZOS)
            resized2.save(f"{iconset_name}/icon_{s}x{s}@2x.png")

    print(f"Iconset prepared: {iconset_name}")
    print("Run 'iconutil -c icns TraeManager.iconset' to generate .icns")
