import argparse
import asyncio
import json
import os
import pickle
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import cast

import matplotlib.colors as mcolors
import matplotlib.pyplot as plt
import numpy as np
import osmnx as ox
from geopandas import GeoDataFrame
from geopy.geocoders import Nominatim
from lat_lon_parser import parse
from matplotlib.font_manager import FontProperties
from networkx import MultiDiGraph
from shapely.geometry import Point
from tqdm import tqdm

from font_management import load_fonts


class CacheError(Exception):
    """Raised when a cache operation fails."""


CACHE_DIR_PATH = os.environ.get("CACHE_DIR", "cache")
CACHE_DIR = Path(CACHE_DIR_PATH)
CACHE_DIR.mkdir(exist_ok=True)

THEMES_DIR = "themes"
FONTS_DIR = "fonts"
POSTERS_DIR = "posters"

FILE_ENCODING = "utf-8"

# Delay font loading until themes and fonts directories are set up
FONTS = None


def _cache_path(key: str) -> str:
    """
    Generate a safe cache file path from a cache key.

    Args:
        key: Cache key identifier

    Returns:
        Path to cache file with .pkl extension
    """
    safe = key.replace(os.sep, "_")
    return os.path.join(CACHE_DIR, f"{safe}.pkl")


def cache_get(key: str):
    """
    Retrieve a cached object by key.

    Args:
        key: Cache key identifier

    Returns:
        Cached object if found, None otherwise

    Raises:
        CacheError: If cache read operation fails
    """
    try:
        path = _cache_path(key)
        if not os.path.exists(path):
            return None
        with open(path, "rb") as f:
            return pickle.load(f)
    except Exception as e:
        raise CacheError(f"Cache read failed: {e}") from e


def cache_set(key: str, value):
    """
    Store an object in the cache.

    Args:
        key: Cache key identifier
        value: Object to cache (must be picklable)

    Raises:
        CacheError: If cache write operation fails
    """
    try:
        if not os.path.exists(CACHE_DIR):
            os.makedirs(CACHE_DIR)
        path = _cache_path(key)
        with open(path, "wb") as f:
            pickle.dump(value, f, protocol=pickle.HIGHEST_PROTOCOL)
    except Exception as e:
        raise CacheError(f"Cache write failed: {e}") from e

def is_latin_script(text):
    """
    Check if text is primarily Latin script.
    Used to determine if letter-spacing should be applied to city names.

    :param text: Text to analyze
    :return: True if text is primarily Latin script, False otherwise
    """
    if not text:
        return True

    latin_count = 0
    total_alpha = 0

    for char in text:
        if char.isalpha():
            total_alpha += 1
            if ord(char) < 0x250:
                latin_count += 1

    if total_alpha == 0:
        return True

    return (latin_count / total_alpha) > 0.8


def generate_output_filename(city, theme_name, output_format):
    """
    Generate unique output filename with city, theme, and datetime.
    """
    if not os.path.exists(POSTERS_DIR):
        os.makedirs(POSTERS_DIR)

    # Use a simpler name for Pitwall integration: city_theme.ext
    city_slug = city.lower().replace(" ", "_")
    ext = output_format.lower()
    filename = f"{city_slug}_{theme_name}.{ext}"
    return os.path.join(POSTERS_DIR, filename)


def get_available_themes():
    """
    Scans the themes directory and returns a list of available theme names.
    """
    if not os.path.exists(THEMES_DIR):
        os.makedirs(THEMES_DIR)
        return []

    themes = []
    for file in sorted(os.listdir(THEMES_DIR)):
        if file.endswith(".json"):
            theme_name = file[:-5]  # Remove .json extension
            themes.append(theme_name)
    return themes


def load_theme(theme_name="terracotta"):
    """
    Load theme from JSON file in themes directory.
    """
    theme_file = os.path.join(THEMES_DIR, f"{theme_name}.json")

    if not os.path.exists(theme_file):
        print(f"⚠ Theme file '{theme_file}' not found. Using default terracotta theme.")
        return {
            "name": "Terracotta",
            "description": "Mediterranean warmth - burnt orange and clay tones on cream",
            "bg": "#F5EDE4",
            "text": "#8B4513",
            "gradient_color": "#F5EDE4",
            "water": "#A8C4C4",
            "parks": "#E8E0D0",
            "road_motorway": "#A0522D",
            "road_primary": "#B8653A",
            "road_secondary": "#C9846A",
            "road_tertiary": "#D9A08A",
            "road_residential": "#E5C4B0",
            "road_default": "#D9A08A",
        }

    with open(theme_file, "r", encoding=FILE_ENCODING) as f:
        theme = json.load(f)
        print(f"Loaded theme: {theme.get('name', theme_name)}")
    return theme

THEME = {}


def create_gradient_fade(ax, color, location="bottom", zorder=10):
    """
    Creates a fade effect at the top or bottom of the map.
    """
    vals = np.linspace(0, 1, 256).reshape(-1, 1)
    gradient = np.hstack((vals, vals))

    rgb = mcolors.to_rgb(color)
    my_colors = np.zeros((256, 4))
    my_colors[:, 0] = rgb[0]
    my_colors[:, 1] = rgb[1]
    my_colors[:, 2] = rgb[2]

    if location == "bottom":
        my_colors[:, 3] = np.linspace(1, 0, 256)
        extent_y_start = 0
        extent_y_end = 0.25
    else:
        my_colors[:, 3] = np.linspace(0, 1, 256)
        extent_y_start = 0.75
        extent_y_end = 1.0

    custom_cmap = mcolors.ListedColormap(my_colors)

    xlim = ax.get_xlim()
    ylim = ax.get_ylim()
    y_range = ylim[1] - ylim[0]

    y_bottom = ylim[0] + y_range * extent_y_start
    y_top = ylim[0] + y_range * extent_y_end

    ax.imshow(
        gradient,
        extent=[xlim[0], xlim[1], y_bottom, y_top],
        aspect="auto",
        cmap=custom_cmap,
        zorder=zorder,
        origin="lower",
    )


def get_edge_colors_by_type(g):
    edge_colors = []
    for _u, _v, data in g.edges(data=True):
        highway = data.get('highway', 'unclassified')
        if isinstance(highway, list):
            highway = highway[0] if highway else 'unclassified'

        # PRO TWEAK: Force white for primary circuit roads in noir theme
        if THEME.get('name') == 'Noir' and highway in ["motorway", "trunk", "primary"]:
             edge_colors.append("#FFFFFF")
             continue

        if highway in ["motorway", "motorway_link"]:
            color = THEME["road_motorway"]
        elif highway in ["trunk", "trunk_link", "primary", "primary_link"]:
            color = THEME["road_primary"]
        elif highway in ["secondary", "secondary_link"]:
            color = THEME["road_secondary"]
        elif highway in ["tertiary", "tertiary_link"]:
            color = THEME["road_tertiary"]
        elif highway in ["residential", "living_street", "unclassified"]:
            color = THEME["road_residential"]
        else:
            color = THEME.get('road_default', THEME.get('road_residential', '#000'))

        edge_colors.append(color)
    return edge_colors


def get_edge_widths_by_type(g):
    edge_widths = []
    for _u, _v, data in g.edges(data=True):
        highway = data.get('highway', 'unclassified')
        if isinstance(highway, list):
            highway = highway[0] if highway else 'unclassified'

        # PRO TWEAK: Highlight main roads (hack for circuits)
        if highway in ["motorway", "trunk", "primary"]:
            width = 1.5
        elif highway in ["secondary", "secondary_link"]:
            width = 1.0
        elif highway in ["tertiary", "tertiary_link"]:
            width = 0.8
        else:
            width = 0.6
        edge_widths.append(width)
    return edge_widths


def get_coordinates(city, country):
    coords_key = f"coords_{city.lower()}_{country.lower()}"
    cached = cache_get(coords_key)
    if cached:
        print(f"Using cached coordinates for {city}, {country}")
        return cached

    print("Looking up coordinates...")
    geolocator = Nominatim(user_agent="city_map_poster", timeout=10)
    time.sleep(1)

    try:
        location = geolocator.geocode(f"{city}, {country}")
        if location:
            cache_set(coords_key, (location.latitude, location.longitude))
            return (location.latitude, location.longitude)
    except Exception as e:
        print(f"Geocoding failed: {e}")

    raise ValueError(f"Could not find coordinates for {city}, {country}")


def get_crop_limits(g_proj, center_lat_lon, fig, dist):
    lat, lon = center_lat_lon
    center = ox.projection.project_geometry(
        Point(lon, lat),
        crs="EPSG:4326",
        to_crs=g_proj.graph["crs"]
    )[0]
    center_x, center_y = center.x, center.y

    fig_width, fig_height = fig.get_size_inches()
    aspect = fig_width / fig_height

    half_x = dist
    half_y = dist

    if aspect > 1:  # landscape
        half_y = half_x / aspect
    else:  # portrait
        half_x = half_y * aspect

    return (
        (center_x - half_x, center_x + half_x),
        (center_y - half_y, center_y + half_y),
    )


def fetch_graph(point, dist) -> MultiDiGraph | None:
    lat, lon = point
    graph_key = f"graph_{lat}_{lon}_{dist}"
    cached = cache_get(graph_key)
    if cached is not None:
        return cast(MultiDiGraph, cached)

    try:
        # PRO TWEAK: Force road-only rendering for cleaner circuit lines
        g = ox.graph_from_point(point, dist=dist, dist_type='bbox', network_type='drive', truncate_by_edge=True)
        cache_set(graph_key, g)
        return g
    except Exception as e:
        print(f"OSMnx error: {e}")
        return None


def fetch_features(point, dist, tags, name) -> GeoDataFrame | None:
    lat, lon = point
    tag_str = "_".join(tags.keys())
    features_key = f"{name}_{lat}_{lon}_{dist}_{tag_str}"
    cached = cache_get(features_key)
    if cached is not None:
        return cast(GeoDataFrame, cached)

    try:
        data = ox.features_from_point(point, tags=tags, dist=dist)
        cache_set(features_key, data)
        return data
    except Exception as e:
        return None


def create_poster(
    city,
    country,
    point,
    dist,
    output_file,
    output_format,
    width=12,
    height=16,
    country_label=None,
    display_city=None,
    display_country=None,
    fonts=None,
):
    display_city = display_city or city
    display_country = display_country or country_label or country

    print(f"\nGenerating map for {city}, {country}...")

    compensated_dist = dist * (max(height, width) / min(height, width)) / 4
    g = fetch_graph(point, compensated_dist)
    if g is None:
        raise RuntimeError("Failed to retrieve street network data.")

    water = fetch_features(point, compensated_dist, {"natural": ["water", "bay", "strait"], "waterway": "riverbank"}, "water")
    parks = fetch_features(point, compensated_dist, {"leisure": "park", "landuse": "grass"}, "parks")

    fig, ax = plt.subplots(figsize=(width, height), facecolor=THEME["bg"])
    ax.set_facecolor(THEME["bg"])
    ax.set_position((0.0, 0.0, 1.0, 1.0))

    g_proj = ox.project_graph(g)

    if water is not None and not water.empty:
        water_polys = water[water.geometry.type.isin(["Polygon", "MultiPolygon"])]
        if not water_polys.empty:
            water_polys = ox.projection.project_gdf(water_polys)
            water_polys.plot(ax=ax, facecolor=THEME['water'], edgecolor='none', zorder=0.5)

    if parks is not None and not parks.empty:
        parks_polys = parks[parks.geometry.type.isin(["Polygon", "MultiPolygon"])]
        if not parks_polys.empty:
            parks_polys = ox.projection.project_gdf(parks_polys)
            parks_polys.plot(ax=ax, facecolor=THEME['parks'], edgecolor='none', zorder=0.8)

    edge_colors = get_edge_colors_by_type(g_proj)
    edge_widths = get_edge_widths_by_type(g_proj)

    crop_xlim, crop_ylim = get_crop_limits(g_proj, point, fig, compensated_dist)
    ox.plot_graph(
        g_proj, ax=ax, bgcolor=THEME['bg'],
        node_size=0,
        edge_color=edge_colors,
        edge_linewidth=edge_widths,
        show=False,
        close=False,
    )
    ax.set_aspect("equal", adjustable="box")
    ax.set_xlim(crop_xlim)
    ax.set_ylim(crop_ylim)

    create_gradient_fade(ax, THEME.get('gradient_color', THEME['bg']), location='bottom', zorder=10)
    create_gradient_fade(ax, THEME.get('gradient_color', THEME['bg']), location='top', zorder=10)

    scale_factor = min(height, width) / 12.0
    active_fonts = fonts or load_fonts()
    
    if active_fonts:
        font_sub = FontProperties(fname=active_fonts["light"], size=22 * scale_factor)
        font_coords = FontProperties(fname=active_fonts["regular"], size=14 * scale_factor)
        font_main = FontProperties(fname=active_fonts["bold"], size=60 * scale_factor)
    else:
        font_sub = FontProperties(family="sans-serif", size=22 * scale_factor)
        font_coords = FontProperties(family="monospace", size=14 * scale_factor)
        font_main = FontProperties(family="sans-serif", weight="bold", size=60 * scale_factor)

    if is_latin_script(display_city):
        spaced_city = "  ".join(list(display_city.upper()))
    else:
        spaced_city = display_city

    ax.text(0.5, 0.14, spaced_city, transform=ax.transAxes, color=THEME["text"], ha="center", fontproperties=font_main, zorder=11)
    ax.text(0.5, 0.10, display_country.upper(), transform=ax.transAxes, color=THEME["text"], ha="center", fontproperties=font_sub, zorder=11)

    lat, lon = point
    coords_text = f"{abs(lat):.4f}° {'N' if lat >= 0 else 'S'} / {abs(lon):.4f}° {'E' if lon >= 0 else 'W'}"
    ax.text(0.5, 0.07, coords_text, transform=ax.transAxes, color=THEME["text"], alpha=0.7, ha="center", fontproperties=font_coords, zorder=11)

    ax.plot([0.4, 0.6], [0.125, 0.125], transform=ax.transAxes, color=THEME["text"], linewidth=1 * scale_factor, zorder=11)

    plt.savefig(output_file, format=output_format, facecolor=THEME["bg"], bbox_inches="tight", pad_inches=0.05, dpi=300)
    plt.close()
    print(f"Saved: {output_file}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--city", "-c", required=True)
    parser.add_argument("--country", "-C", required=True)
    parser.add_argument("--latitude", "-lat", type=float)
    parser.add_argument("--longitude", "-long", type=float)
    parser.add_argument("--theme", "-t", default="terracotta")
    parser.add_argument("--distance", "-d", type=int, default=18000)
    parser.add_argument("--format", "-f", default="png")
    parser.add_argument("--font-family", type=str)
    args = parser.parse_args()

    THEME = load_theme(args.theme)
    custom_fonts = load_fonts(args.font_family) if args.font_family else None
    coords = (args.latitude, args.longitude) if args.latitude and args.longitude else get_coordinates(args.city, args.country)
    output = generate_output_filename(args.city, args.theme, args.format)
    
    create_poster(args.city, args.country, coords, args.distance, output, args.format, fonts=custom_fonts)
