from PIL import Image
import os

def process_icon(source_path):
    if not os.path.exists(source_path):
        print(f"Error: Source image not found at {source_path}")
        return

    try:
        img = Image.open(source_path)
    except Exception as e:
        print(f"Error opening image: {e}")
        return

    # Ensure image is square
    width, height = img.size
    size = min(width, height)
    
    # Center crop if not square
    if width != height:
        left = (width - size) / 2
        top = (height - size) / 2
        right = (width + size) / 2
        bottom = (height + size) / 2
        img = img.crop((left, top, right, bottom))
    
    # Resize to max needed size (1024x1024) first if larger, or just use as base
    # High quality resize
    if size > 1024:
        img = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    
    iconset_name = "TraeManager.iconset"
    if not os.path.exists(iconset_name):
        os.makedirs(iconset_name)
        
    sizes = [16, 32, 128, 256, 512]
    
    for s in sizes:
        # 1x
        resized = img.resize((s, s), Image.Resampling.LANCZOS)
        resized.save(f"{iconset_name}/icon_{s}x{s}.png")
        
        # 2x
        s2 = s * 2
        resized2 = img.resize((s2, s2), Image.Resampling.LANCZOS)
        resized2.save(f"{iconset_name}/icon_{s}x{s}@2x.png")
        
    print(f"Iconset generated at {iconset_name}")
    
    # Generate Windows .ico
    try:
        # Prepare sizes for ICO
        ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        img.save("TraeManager.ico", format='ICO', sizes=ico_sizes)
        print("Generated TraeManager.ico for Windows")
    except Exception as e:
        print(f"Error generating ICO: {e}")

if __name__ == "__main__":
    process_icon("TraeManagerSource.png")
