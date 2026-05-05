import os
import re
from pathlib import Path
from typing import Optional
import requests

FONTS_DIR = "fonts"
FONTS_CACHE_DIR = Path(FONTS_DIR) / "cache"

def download_google_font(font_family: str, weights: list = None) -> Optional[dict]:
    if weights is None:
        weights = [300, 400, 700]
    FONTS_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    font_name_safe = font_family.replace(" ", "_").lower()
    font_files = {}

    try:
        weights_str = ";".join(map(str, weights))
        api_url = "https://fonts.googleapis.com/css2"
        params = {"family": f"{font_family}:wght@{weights_str}"}
        headers = {"User-Agent": "Mozilla/5.0"}
        response = requests.get(api_url, params=params, headers=headers, timeout=10)
        response.raise_for_status()
        css_content = response.text
        weight_url_map = {}
        font_face_blocks = re.split(r"@font-face\s*\{", css_content)

        for block in font_face_blocks[1:]:
            weight_match = re.search(r"font-weight:\s*(\d+)", block)
            if not weight_match: continue
            weight = int(weight_match.group(1))
            url_match = re.search(r"url\((https://[^)]+\.(woff2|ttf))\)", block)
            if url_match:
                weight_url_map[weight] = url_match.group(1)

        weight_map = {300: "light", 400: "regular", 700: "bold"}
        for weight in weights:
            weight_key = weight_map.get(weight, "regular")
            weight_url = weight_url_map.get(weight)
            if weight_url:
                file_ext = "woff2" if weight_url.endswith(".woff2") else "ttf"
                font_filename = f"{font_name_safe}_{weight_key}.{file_ext}"
                font_path = FONTS_CACHE_DIR / font_filename
                if not font_path.exists():
                    print(f"  Downloading {font_family} {weight_key}...")
                    font_response = requests.get(weight_url, timeout=10)
                    font_response.raise_for_status()
                    font_path.write_bytes(font_response.content)
                font_files[weight_key] = str(font_path)

        if "regular" not in font_files and font_files:
            font_files["regular"] = list(font_files.values())[0]
        if "bold" not in font_files and "regular" in font_files:
            font_files["bold"] = font_files["regular"]
        if "light" not in font_files and "regular" in font_files:
            font_files["light"] = font_files["regular"]
        return font_files if font_files else None
    except Exception as e:
        print(f"⚠ Error downloading font: {e}")
        return None

def load_fonts(font_family: Optional[str] = None) -> Optional[dict]:
    if font_family and font_family.lower() != "roboto":
        fonts = download_google_font(font_family)
        if fonts: return fonts
    
    fonts = {
        "bold": os.path.join(FONTS_DIR, "Roboto-Bold.ttf"),
        "regular": os.path.join(FONTS_DIR, "Roboto-Regular.ttf"),
        "light": os.path.join(FONTS_DIR, "Roboto-Light.ttf"),
    }
    
    for weight, path in fonts.items():
        if not os.path.exists(path):
            # Fallback to a system font if local files missing and not specified
            return None
    return fonts
