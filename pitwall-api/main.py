import os
import logging
from datetime import datetime, timedelta
from typing import List, Optional

import fastf1
import pandas as pd
import numpy as np
import requests
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()
NEWS_API_KEY = os.getenv("NEWS_API_KEY")

# FastF1 Setup
# Use /app/cache for Railway production, or ./cache for local
CACHE_DIR = "/app/cache" if os.path.exists("/app") else "./cache"
if not os.path.exists(CACHE_DIR):
    os.makedirs(CACHE_DIR)
fastf1.Cache.enable_cache(CACHE_DIR)

app = FastAPI(title="Pitwall F1 Intelligence API")

# CORS Setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Helper: Convert time to MS
def to_ms(td):
    if pd.isna(td):
        return None
    return td.total_seconds() * 1000

@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "cache_dir": CACHE_DIR
    }

@app.get("/news")
async def get_news(page: int = 1, pageSize: int = 20):
    if not NEWS_API_KEY:
        return {"error": "News API key not configured"}
    
    # Last 48 hours
    from_date = (datetime.now() - timedelta(hours=48)).strftime("%Y-%m-%dT%H:%M:%S")
    
    url = "https://newsapi.org/v2/everything"
    params = {
        "q": "Formula 1 OR F1 OR Grand Prix OR MotoGP",
        "language": "en",
        "sortBy": "publishedAt",
        "from": from_date,
        "page": page,
        "pageSize": pageSize,
        "apiKey": NEWS_API_KEY
    }
    
    try:
        response = requests.get(url, params=params)
        data = response.json()
        
        if data.get("status") != "ok":
            logger.error(f"NewsAPI Error: {data}")
            raise HTTPException(status_code=503, detail="News unavailable")
            
        articles = []
        for item in data.get("articles", []):
            articles.append({
                "title": item.get("title"),
                "source": item.get("source", {}).get("name"),
                "url": item.get("url"),
                "urlToImage": item.get("urlToImage"),
                "description": item.get("description"),
                "publishedAt": item.get("publishedAt"),
                "author": item.get("author")
            })
        return articles
    except Exception as e:
        logger.error(f"News fetch failed: {e}")
        raise HTTPException(status_code=503, detail="News unavailable")

@app.get("/schedule/{year}")
async def get_schedule(year: int):
    try:
        schedule = fastf1.get_event_schedule(year, include_testing=False)
        result = []
        for _, row in schedule.iterrows():
            result.append({
                "round_number": int(row["RoundNumber"]),
                "event_name": row["EventName"],
                "country": row["Country"],
                "location": row["Location"],
                "circuit_name": row["OfficialEventName"],
                "date_fp1": row["Session1Date"].isoformat() if pd.notna(row["Session1Date"]) else None,
                "date_fp2": row["Session2Date"].isoformat() if pd.notna(row["Session2Date"]) else None,
                "date_fp3": row["Session3Date"].isoformat() if pd.notna(row["Session3Date"]) else None,
                "date_qualifying": row["Session4Date"].isoformat() if pd.notna(row["Session4Date"]) else None,
                "date_sprint": row["Session5Date"].isoformat() if pd.notna(row["Session5Date"]) else None, # Simplified mapping
                "date_race": row["Session5Date"].isoformat() if pd.notna(row["Session5Date"]) else None,
                "event_format": row["EventFormat"],
                "gmt_offset": str(row["GmtOffset"])
            })
        return result
    except Exception as e:
        logger.error(f"Schedule load failed: {e}")
        raise HTTPException(status_code=404, detail="Schedule data unavailable")

@app.get("/next_race")
async def get_next_race():
    try:
        now = datetime.now()
        year = now.year
        schedule = fastf1.get_event_schedule(year, include_testing=False)
        
        # Filter for upcoming
        upcoming = schedule[schedule["Session5Date"].dt.tz_localize(None) > now]
        
        if upcoming.empty:
            # Check next year
            schedule = fastf1.get_event_schedule(year + 1, include_testing=False)
            upcoming = schedule[schedule["Session5Date"].dt.tz_localize(None) > now]
            
        if upcoming.empty:
            raise HTTPException(status_code=404, detail="No upcoming races found")
            
        next_event = upcoming.iloc[0]
        race_date = next_event["Session5Date"].dt.tz_localize(None)
        diff = race_date - now
        
        return {
            "round_number": int(next_event["RoundNumber"]),
            "event_name": next_event["EventName"],
            "country": next_event["Country"],
            "location": next_event["Location"],
            "date_race": race_date.isoformat(),
            "date_qualifying": next_event["Session4Date"].isoformat() if pd.notna(next_event["Session4Date"]) else None,
            "days_until": diff.days,
            "hours_until": diff.seconds // 3600,
            "circuit_name": next_event["OfficialEventName"]
        }
    except Exception as e:
        logger.error(f"Next race check failed: {e}")
        raise HTTPException(status_code=404, detail="Race data unavailable")

@app.get("/standings/drivers/{year}")
async def get_driver_standings(year: int):
    try:
        # FastF1 uses Jolpica internally for standings
        import fastf1.ergast as ergast
        e = ergast.Ergast()
        standings = e.get_driver_standings(season=year)
        
        result = []
        for s in standings.content[0]:
            result.append({
                "position": int(s['position']),
                "driver_code": s['driverCode'],
                "full_name": f"{s['givenName']} {s['familyName']}",
                "team": s['constructorNames'][0],
                "nationality": s['nationality'],
                "points": float(s['points']),
                "wins": int(s['wins']),
                "podiums": 0 # Not directly in Ergast summary, but could be computed
            })
        return result
    except Exception as e:
        logger.error(f"Driver standings failed: {e}")
        raise HTTPException(status_code=404, detail="Standings unavailable")

@app.get("/standings/constructors/{year}")
async def get_constructor_standings(year: int):
    try:
        import fastf1.ergast as ergast
        e = ergast.Ergast()
        standings = e.get_constructor_standings(season=year)
        
        result = []
        for s in standings.content[0]:
            result.append({
                "position": int(s['position']),
                "team_name": s['constructorName'],
                "nationality": s['nationality'],
                "points": float(s['points']),
                "wins": int(s['wins'])
            })
        return result
    except Exception as e:
        logger.error(f"Constructor standings failed: {e}")
        raise HTTPException(status_code=404, detail="Standings unavailable")

@app.get("/results/{year}/{round}/{session}")
async def get_results(year: int, round: int, session: str):
    try:
        s = fastf1.get_session(year, round, session)
        s.load(laps=False, telemetry=False, weather=False, messages=False)
        
        result = []
        for _, row in s.results.iterrows():
            result.append({
                "position": int(row["Position"]) if pd.notna(row["Position"]) else None,
                "driver_code": row["Abbreviation"],
                "full_name": row["FullName"],
                "team": row["TeamName"],
                "team_color": f"#{row['TeamColor']}" if pd.notna(row['TeamColor']) else "#FFFFFF",
                "grid_position": int(row["GridPosition"]) if pd.notna(row["GridPosition"]) else None,
                "status": row["Status"],
                "points": float(row["Points"]) if pd.notna(row["Points"]) else 0.0,
                "fastest_lap_time": to_ms(row["FastestLapTime"]),
                "finishing_time": to_ms(row["Time"]),
                "gap_to_leader": to_ms(row["Time"]) # This usually needs manual calc for gaps
            })
        return result
    except Exception as e:
        logger.error(f"Results load failed: {e}")
        raise HTTPException(status_code=404, detail="Session data not available yet")

@app.get("/laps/{year}/{round}/{session}")
async def get_laps(year: int, round: int, session: str):
    try:
        s = fastf1.get_session(year, round, session)
        s.load(laps=True, telemetry=False, weather=True, messages=False)
        
        result = []
        for driver in s.drivers:
            driver_laps = s.laps.pick_driver(driver)
            if driver_laps.empty: continue
            
            laps_data = []
            for _, lap in driver_laps.iterrows():
                laps_data.append({
                    "lap_number": int(lap["LapNumber"]),
                    "lap_time_ms": to_ms(lap["LapTime"]),
                    "sector1_ms": to_ms(lap["Sector1Time"]),
                    "sector2_ms": to_ms(lap["Sector2Time"]),
                    "sector3_ms": to_ms(lap["Sector3Time"]),
                    "compound": lap["Compound"],
                    "tyre_life": int(lap["TyreLife"]) if pd.notna(lap["TyreLife"]) else None,
                    "stint": int(lap["Stint"]) if pd.notna(lap["Stint"]) else None,
                    "is_personal_best": bool(lap["IsPersonalBest"]),
                    "pit_in_time": to_ms(lap["PitInTime"]),
                    "pit_out_time": to_ms(lap["PitOutTime"]),
                    "speed_i1": float(lap["SpeedI1"]) if pd.notna(lap["SpeedI1"]) else None,
                    "speed_i2": float(lap["SpeedI2"]) if pd.notna(lap["SpeedI2"]) else None,
                    "speed_fl": float(lap["SpeedFL"]) if pd.notna(lap["SpeedFL"]) else None,
                    "speed_st": float(lap["SpeedST"]) if pd.notna(lap["SpeedST"]) else None,
                    "track_status": lap["TrackStatus"]
                })
            
            result.append({
                "driver_code": driver_laps.iloc[0]["Driver"],
                "team_color": f"#{s.get_driver(driver)['TeamColor']}",
                "laps": laps_data
            })
        return result
    except Exception as e:
        logger.error(f"Laps load failed: {e}")
        raise HTTPException(status_code=404, detail="Session data not available yet")

@app.get("/telemetry/{year}/{round}/{session}/{driver}")
async def get_telemetry(year: int, round: int, session: str, driver: str):
    try:
        s = fastf1.get_session(year, round, session)
        s.load(laps=True, telemetry=True, weather=False, messages=False)
        
        fastest_lap = s.laps.pick_driver(driver).pick_fastest()
        tel = fastest_lap.get_telemetry()
        
        # Downsample to ~400 points
        step = max(1, len(tel) // 400)
        tel = tel.iloc[::step]
        
        data = []
        for _, row in tel.iterrows():
            data.append({
                "distance": float(row["Distance"]),
                "speed": float(row["Speed"]),
                "throttle": float(row["Throttle"]),
                "brake": bool(row["Brake"]),
                "gear": int(row["nGear"]),
                "rpm": int(row["RPM"]),
                "drs": int(row["DRS"]),
                "x": float(row["X"]),
                "y": float(row["Y"])
            })
            
        return {
            "driver_code": driver,
            "team_color": f"#{s.get_driver(driver)['TeamColor']}",
            "lap_time": to_ms(fastest_lap["LapTime"]),
            "compound": fastest_lap["Compound"],
            "telemetry": data
        }
    except Exception as e:
        logger.error(f"Telemetry failed: {e}")
        raise HTTPException(status_code=404, detail="Telemetry data unavailable")

@app.get("/telemetry_compare/{year}/{round}/{session}/{driver1}/{driver2}")
async def compare_telemetry(year: int, round: int, session: str, driver1: str, driver2: str):
    try:
        s = fastf1.get_session(year, round, session)
        s.load(laps=True, telemetry=True, weather=False, messages=False)
        
        laps = s.laps
        d1_lap = laps.pick_driver(driver1).pick_fastest()
        d2_lap = laps.pick_driver(driver2).pick_fastest()
        
        d1_tel = d1_lap.get_telemetry().add_distance()
        d2_tel = d2_lap.get_telemetry().add_distance()
        
        # Downsample
        step1 = max(1, len(d1_tel) // 400)
        d1_tel = d1_tel.iloc[::step1]
        step2 = max(1, len(d2_tel) // 400)
        d2_tel = d2_tel.iloc[::step2]
        
        def format_tel(tel):
            return [{
                "distance": float(r["Distance"]),
                "speed": float(r["Speed"]),
                "throttle": float(r["Throttle"]),
                "gear": int(r["nGear"]),
                "brake": bool(r["Brake"])
            } for _, r in tel.iterrows()]

        return {
            "driver1": {
                "code": driver1,
                "team_color": f"#{s.get_driver(driver1)['TeamColor']}",
                "lap_time": to_ms(d1_lap["LapTime"]),
                "data": format_tel(d1_tel)
            },
            "driver2": {
                "code": driver2,
                "team_color": f"#{s.get_driver(driver2)['TeamColor']}",
                "lap_time": to_ms(d2_lap["LapTime"]),
                "data": format_tel(d2_tel)
            }
        }
    except Exception as e:
        logger.error(f"Comparison failed: {e}")
        raise HTTPException(status_code=404, detail="Telemetry data unavailable")

@app.get("/tyre_strategy/{year}/{round}")
async def get_tyre_strategy(year: int, round: int):
    try:
        s = fastf1.get_session(year, round, 'R')
        s.load(laps=True, telemetry=False, weather=False, messages=False)
        
        laps = s.laps
        drivers = s.drivers
        result = []
        
        for driver in drivers:
            driver_laps = laps.pick_driver(driver)
            if driver_laps.empty: continue
            
            stints = []
            # FastF1 stint grouping
            stint_groups = driver_laps.groupby("Stint")
            for stint_num, stint_data in stint_groups:
                stints.append({
                    "compound": stint_data.iloc[0]["Compound"],
                    "start_lap": int(stint_data.iloc[0]["LapNumber"]),
                    "end_lap": int(stint_data.iloc[-1]["LapNumber"]),
                    "lap_count": len(stint_data),
                    "fresh_tyre": bool(stint_data.iloc[0]["FreshTyre"]) if pd.notna(stint_data.iloc[0]["FreshTyre"]) else None
                })
            
            result.append({
                "driver_code": driver_laps.iloc[0]["Driver"],
                "team_color": f"#{s.get_driver(driver)['TeamColor']}",
                "stints": stints,
                "position": int(s.get_driver(driver)["Position"]) if pd.notna(s.get_driver(driver)["Position"]) else 99
            })
            
        # Sort by finishing position
        result.sort(key=lambda x: x["position"])
        return result
    except Exception as e:
        logger.error(f"Strategy failed: {e}")
        raise HTTPException(status_code=404, detail="Strategy data unavailable")

@app.get("/positions/{year}/{round}")
async def get_positions(year: int, round: int):
    try:
        s = fastf1.get_session(year, round, 'R')
        s.load(laps=True, telemetry=False, weather=False, messages=False)
        
        laps = s.laps
        max_laps = int(laps["LapNumber"].max())
        result = []
        
        for lap_num in range(1, max_laps + 1):
            lap_positions = []
            lap_data = laps[laps["LapNumber"] == lap_num]
            
            for _, row in lap_data.iterrows():
                lap_positions.append({
                    "driver_code": row["Driver"],
                    "team_color": f"#{s.get_driver(row['Driver'])['TeamColor']}",
                    "position": int(row["Position"]) if pd.notna(row["Position"]) else None
                })
            
            result.append({
                "lap_number": lap_num,
                "positions": lap_positions
            })
            
        return result
    except Exception as e:
        logger.error(f"Positions failed: {e}")
        raise HTTPException(status_code=404, detail="Position data unavailable")

@app.get("/fastest_laps/{year}/{round}/{session}")
async def get_fastest_laps(year: int, round: int, session: str):
    try:
        s = fastf1.get_session(year, round, session)
        s.load(laps=True, telemetry=False, weather=False, messages=False)
        
        fastest = s.laps.groupby("Driver").pick_fastest()
        fastest = fastest.sort_values("LapTime")
        best_time = fastest.iloc[0]["LapTime"]
        
        result = []
        for i, (_, row) in enumerate(fastest.iterrows()):
            result.append({
                "rank": i + 1,
                "driver_code": row["Driver"],
                "full_name": s.get_driver(row["Driver"])["FullName"],
                "team": row["Team"],
                "team_color": f"#{s.get_driver(row['Driver'])['TeamColor']}",
                "lap_time_ms": to_ms(row["LapTime"]),
                "gap_to_fastest_ms": to_ms(row["LapTime"] - best_time),
                "compound": row["Compound"],
                "tyre_life": int(row["TyreLife"]) if pd.notna(row["TyreLife"]) else None,
                "speed_trap": float(row["SpeedST"]) if pd.notna(row["SpeedST"]) else None
            })
        return result
    except Exception as e:
        logger.error(f"Fastest laps failed: {e}")
        raise HTTPException(status_code=404, detail="Session data unavailable")

@app.get("/weather/{year}/{round}/{session}")
async def get_weather(year: int, round: int, session: str):
    try:
        s = fastf1.get_session(year, round, session)
        s.load(laps=False, telemetry=False, weather=True, messages=False)
        
        weather = s.weather_data
        result = []
        for _, row in weather.iterrows():
            result.append({
                "time": row["Time"].isoformat() if pd.notna(row["Time"]) else None,
                "air_temp": float(row["AirTemp"]),
                "track_temp": float(row["TrackTemp"]),
                "humidity": float(row["Humidity"]),
                "pressure": float(row["Pressure"]),
                "wind_speed": float(row["WindSpeed"]),
                "wind_direction": int(row["WindDirection"]),
                "rainfall": bool(row["Rainfall"])
            })
            
        summary = {
            "avg_air_temp": float(weather["AirTemp"].mean()),
            "avg_track_temp": float(weather["TrackTemp"].mean()),
            "max_wind_speed": float(weather["WindSpeed"].max()),
            "rainfall_occurred": bool(weather["Rainfall"].any()),
            "conditions": "Rain" if weather["Rainfall"].any() else "Dry"
        }
        
        return {"data": result, "summary": summary}
    except Exception as e:
        logger.error(f"Weather failed: {e}")
        raise HTTPException(status_code=404, detail="Weather data unavailable")

@app.get("/race_control/{year}/{round}/{session}")
async def get_race_control(year: int, round: int, session: str):
    try:
        s = fastf1.get_session(year, round, session)
        s.load(laps=False, telemetry=False, weather=False, messages=True)
        
        messages = s.race_control_messages
        result = []
        for _, row in messages.iterrows():
            result.append({
                "time": row["Time"].isoformat() if pd.notna(row["Time"]) else None,
                "lap_number": int(row["Lap"]) if pd.notna(row["Lap"]) else None,
                "category": row["Category"],
                "message": row["Message"],
                "flag": row["Flag"],
                "scope": row["Scope"],
                "driver_code": row["Driver"]
            })
        return result
    except Exception as e:
        logger.error(f"Race control failed: {e}")
        raise HTTPException(status_code=404, detail="Message data unavailable")

@app.get("/track_status/{year}/{round}/{session}")
async def get_track_status(year: int, round: int, session: str):
    try:
        s = fastf1.get_session(year, round, session)
        s.load(laps=False, telemetry=False, weather=False, messages=True)
        
        status = s.track_status
        mapping = {
            "1": "Green", "2": "Yellow", "4": "SC", "5": "Red", "6": "VSC", "7": "Chequered"
        }
        
        result = []
        for _, row in status.iterrows():
            result.append({
                "time": row["Time"].isoformat() if pd.notna(row["Time"]) else None,
                "status": row["Status"],
                "message": mapping.get(str(row["Status"]), "Unknown")
            })
        return result
    except Exception as e:
        logger.error(f"Track status failed: {e}")
        raise HTTPException(status_code=404, detail="Status data unavailable")

@app.get("/circuit/{year}/{round}")
async def get_circuit_info(year: int, round: int):
    try:
        s = fastf1.get_session(year, round, 'R')
        s.load(laps=False, telemetry=False, weather=False, messages=False)
        
        circuit = s.get_circuit_info()
        
        return {
            "corners": [{
                "number": str(c["Number"]),
                "letter": c["Letter"],
                "distance": float(c["Distance"]),
                "x": float(c["X"]),
                "y": float(c["Y"]),
                "angle": float(c["Angle"])
            } for _, c in circuit.corners.iterrows()],
            "marshal_lights": [{
                "distance": float(m["Distance"]),
                "x": float(m["X"]),
                "y": float(m["Y"])
            } for _, m in circuit.marshal_lights.iterrows()],
            "marshal_sectors": [{
                "distance": float(m["Distance"]),
                "x": float(m["X"]),
                "y": float(m["Y"])
            } for _, m in circuit.marshal_sectors.iterrows()],
            "rotation": float(circuit.rotation)
        }
    except Exception as e:
        logger.error(f"Circuit failed: {e}")
        raise HTTPException(status_code=404, detail="Circuit data unavailable")

@app.get("/driver_season/{year}/{driver_code}")
async def get_driver_season_stats(year: int, driver_code: str):
    try:
        schedule = fastf1.get_event_schedule(year, include_testing=False)
        races = []
        
        for _, race in schedule.iterrows():
            try:
                s = fastf1.get_session(year, int(race["RoundNumber"]), 'R')
                s.load(laps=False, telemetry=False, weather=False, messages=False)
                res = s.results.pick_driver(driver_code)
                if res.empty: continue
                
                row = res.iloc[0]
                races.append({
                    "round": int(race["RoundNumber"]),
                    "event_name": race["EventName"],
                    "position": int(row["Position"]) if pd.notna(row["Position"]) else None,
                    "grid": int(row["GridPosition"]),
                    "points": float(row["Points"]),
                    "status": row["Status"],
                    "fastest_lap": to_ms(row["FastestLapTime"])
                })
            except: continue
            
        if not races: return {"error": "No data found for driver"}
        
        valid_finishes = [r["position"] for r in races if r["position"] is not None]
        
        summary = {
            "total_points": sum(r["points"] for r in races),
            "wins": len([r for r in races if r["position"] == 1]),
            "podiums": len([r for r in races if r["position"] in [1,2,3]]),
            "dnfs": len([r for r in races if r["status"] not in ["Finished", "+1 Lap", "+2 Laps"]]),
            "avg_finish": sum(valid_finishes) / len(valid_finishes) if valid_finishes else None,
            "avg_grid": sum(r["grid"] for r in races) / len(races),
            "best_finish": min(valid_finishes) if valid_finishes else None,
            "poles": len([r for r in races if r["grid"] == 1])
        }
        
        return {"driver_code": driver_code, "races": races, "summary": summary}
    except Exception as e:
        logger.error(f"Season stats failed: {e}")
        raise HTTPException(status_code=404, detail="Season data unavailable")

@app.get("/h2h/{year}/{driver1}/{driver2}")
async def get_h2h(year: int, driver1: str, driver2: str):
    try:
        schedule = fastf1.get_event_schedule(year, include_testing=False)
        races = []
        d1_score = {"points": 0, "quali": 0, "race": 0}
        d2_score = {"points": 0, "quali": 0, "race": 0}
        
        for _, race in schedule.iterrows():
            try:
                rnd = int(race["RoundNumber"])
                s_r = fastf1.get_session(year, rnd, 'R')
                s_r.load(laps=False, telemetry=False, weather=False, messages=False)
                
                res1 = s_r.results.pick_driver(driver1)
                res2 = s_r.results.pick_driver(driver2)
                if res1.empty or res2.empty: continue
                
                r1, r2 = res1.iloc[0], res2.iloc[0]
                
                # Check race winner between them
                if pd.notna(r1["Position"]) and pd.notna(r2["Position"]):
                    if r1["Position"] < r2["Position"]: d1_score["race"] += 1
                    elif r2["Position"] < r1["Position"]: d2_score["race"] += 1
                
                # Check quali winner between them
                if r1["GridPosition"] < r2["GridPosition"]: d1_score["quali"] += 1
                elif r2["GridPosition"] < r1["GridPosition"]: d2_score["quali"] += 1
                
                d1_score["points"] += r1["Points"]
                d2_score["points"] += r2["Points"]
                
                races.append({
                    "round": rnd,
                    "event_name": race["EventName"],
                    "d1_quali_pos": int(r1["GridPosition"]),
                    "d2_quali_pos": int(r2["GridPosition"]),
                    "d1_race_pos": int(r1["Position"]) if pd.notna(r1["Position"]) else None,
                    "d2_race_pos": int(r2["Position"]) if pd.notna(r2["Position"]) else None
                })
            except: continue
            
        return {
            "driver1": {"code": driver1, "points": d1_score["points"], "quali_wins": d1_score["quali"], "race_wins": d1_score["race"]},
            "driver2": {"code": driver2, "points": d2_score["points"], "quali_wins": d2_score["quali"], "race_wins": d2_score["race"]},
            "races": races
        }
    except Exception as e:
        logger.error(f"H2H failed: {e}")
        raise HTTPException(status_code=404, detail="H2H data unavailable")

@app.get("/pitstops/{year}/{round}")
async def get_pitstops(year: int, round: int):
    try:
        s = fastf1.get_session(year, round, 'R')
        s.load(laps=True, telemetry=False, weather=False, messages=False)
        
        pit_laps = s.laps[s.laps["PitInTime"].notna() | s.laps["PitOutTime"].notna()]
        result = []
        
        for _, lap in pit_laps.iterrows():
            # Estimate duration if possible
            duration = to_ms(lap["PitInTime"]) # This is usually just the time of entry
            
            result.append({
                "driver_code": lap["Driver"],
                "team_color": f"#{s.get_driver(lap['Driver'])['TeamColor']}",
                "lap_number": int(lap["LapNumber"]),
                "pit_duration_ms": duration, 
                "compound_in": lap["Compound"],
                "compound_out": None, # FastF1 doesn't directly link next compound in the same row
                "position_at_pit": int(lap["Position"]) if pd.notna(lap["Position"]) else None
            })
            
        return result
    except Exception as e:
        logger.error(f"Pitstops failed: {e}")
        raise HTTPException(status_code=404, detail="Pitstop data unavailable")

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
