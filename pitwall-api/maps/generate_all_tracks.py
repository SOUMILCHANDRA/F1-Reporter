import os
import sys

# Add current directory to path so it can find create_map_poster
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

SCRIPT = "py create_map_poster.py"
THEME = "noir"
DIST = 2500  # PRO TWEAK: tighter track focus

tracks = [
    ("Bahrain GP", "Bahrain", 26.0325, 50.5106),
    ("Saudi Arabian GP", "Saudi Arabia", 21.6319, 39.1044),
    ("Australian GP", "Australia", -37.8497, 144.968),
    ("Japanese GP", "Japan", 34.8431, 136.541),
    ("Chinese GP", "China", 31.3389, 121.22),
    ("Miami GP", "USA", 25.9581, -80.2389),
    ("Emilia Romagna GP", "Italy", 44.3439, 11.7167),
    ("Monaco GP", "Monaco", 43.7347, 7.4206),
    ("Canadian GP", "Canada", 45.5006, -73.5228),
    ("Spanish GP", "Spain", 41.57, 2.2611),
    ("Austrian GP", "Austria", 47.2197, 14.7647),
    ("British GP", "UK", 52.0786, -1.0169),
    ("Hungarian GP", "Hungary", 47.5789, 19.2486),
    ("Belgian GP", "Belgium", 50.4372, 5.9714),
    ("Dutch GP", "Netherlands", 52.3888, 4.5409),
    ("Italian GP", "Italy", 45.6156, 9.2811),
    ("Singapore GP", "Singapore", 1.2914, 103.864),
    ("US GP", "USA", 30.1328, -97.6411),
    ("Mexico GP", "Mexico", 19.4042, -99.0907),
    ("Brazilian GP", "Brazil", -23.7036, -46.6997),
    ("Las Vegas GP", "USA", 36.1147, -115.1728),
    ("Qatar GP", "Qatar", 25.49, 51.4542),
    ("Abu Dhabi GP", "UAE", 24.4672, 54.6031),
]

def generate():
    for name, country, lat, lon in tracks:
        # Create a clean slug for the filename
        city_slug = name.lower().replace(" ", "_")
        cmd = f'{SCRIPT} --city "{name}" --country "{country}" --latitude {lat} --longitude {lon} --distance {DIST} --theme {THEME} --font-family "Titillium Web"'
        print(f"Generating: {name} ({lat}, {lon})")
        os.system(cmd)

if __name__ == "__main__":
    generate()
