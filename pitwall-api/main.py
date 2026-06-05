import os
import logging
from datetime import datetime, timedelta
from typing import List, Optional

import requests
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from dotenv import load_dotenv
from supabase import create_client, Client

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()
NEWS_API_KEY = os.getenv("NEWS_API_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

app = FastAPI(title="Pitwall F1 Intelligence API")

# CORS Setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if SUPABASE_URL and SUPABASE_KEY:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
else:
    supabase = None
    logger.warning("Supabase credentials not found. DB endpoints will fail.")

@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "database": "supabase" if supabase else "disconnected"
    }

# Ensure map directories exist and mount static files
MAPS_DIR = os.path.join(os.path.dirname(__file__), "maps", "posters")
if not os.path.exists(MAPS_DIR):
    os.makedirs(MAPS_DIR, exist_ok=True)

app.mount("/static/maps", StaticFiles(directory=MAPS_DIR), name="maps")

@app.get("/map/{race_name}")
async def get_track_map(race_name: str):
    # Normalize race name to match generated filename
    # e.g. "Australian Grand Prix" -> "australian_gp_noir.png"
    name = race_name.lower().replace('grand prix', 'gp').replace(' ', '_')
    filename = f"{name}_noir.png"
    filepath = os.path.join(MAPS_DIR, filename)
    
    if os.path.exists(filepath):
        return {"url": f"/static/maps/{filename}"}
    else:
        # Try alternate if it was already gp
        if "_gp_" in filename:
            alt_name = filename.replace("_gp_", "_grand_prix_")
            alt_path = os.path.join(MAPS_DIR, alt_name)
            if os.path.exists(alt_path):
                return {"url": f"/static/maps/{alt_name}"}
                
        return {"error": "Map not found", "attempted": filename}


@app.get("/news")
async def get_news(page: int = 1, pageSize: int = 20):
    if not supabase:
        raise HTTPException(status_code=500, detail="Database not configured")
    try:
        offset = (page - 1) * pageSize
        res = supabase.table("f1_news").select("*").order("publishedAt", desc=True).range(offset, offset + pageSize - 1).execute()
        return res.data
    except Exception as e:
        logger.error(f"News fetch failed: {e}")
        raise HTTPException(status_code=503, detail="News unavailable")

@app.post("/trigger_news_update")
async def trigger_news_update():
    from rss_scraper import fetch_and_filter_news
    result = fetch_and_filter_news()
    if result and result.get("status") == "error":
        raise HTTPException(status_code=500, detail=result.get("detail"))
    return result

@app.get("/schedule/{year}")
async def get_schedule(year: int):
    if not supabase:
        raise HTTPException(status_code=500, detail="Database not configured")
    try:
        res = supabase.table("races").select("*").eq("year", year).order("round_number").execute()
        return res.data
    except Exception as e:
        logger.error(f"Schedule load failed: {e}")
        raise HTTPException(status_code=404, detail="Schedule data unavailable")

@app.get("/next_race")
async def get_next_race():
    if not supabase:
        raise HTTPException(status_code=500, detail="Database not configured")
    try:
        now = datetime.now()
        res = supabase.table("races").select("*").gt("date_race", now.isoformat()).order("date_race").limit(1).execute()
        
        if not res.data:
            raise HTTPException(status_code=404, detail="No upcoming races found")
            
        next_event = res.data[0]
        race_date = datetime.fromisoformat(next_event["date_race"].replace('Z', '+00:00')).replace(tzinfo=None)
        diff = race_date - now
        
        return {
            "round_number": next_event["round_number"],
            "event_name": next_event["event_name"],
            "country": next_event["country"],
            "location": next_event["location"],
            "date_race": next_event["date_race"],
            "date_qualifying": next_event.get("date_qualifying"),
            "days_until": diff.days,
            "hours_until": diff.seconds // 3600,
            "circuit_name": next_event["circuit_name"]
        }
    except Exception as e:
        logger.error(f"Next race check failed: {e}")
        raise HTTPException(status_code=404, detail="Race data unavailable")

@app.get("/standings/drivers/{year}")
async def get_driver_standings(year: int):
    if not supabase:
        raise HTTPException(status_code=500, detail="Database not configured")
    try:
        res = supabase.table("driver_standings").select("*").eq("year", year).order("position").execute()
        return res.data
    except Exception as e:
        logger.error(f"Driver standings failed: {e}")
        raise HTTPException(status_code=404, detail="Standings unavailable")

@app.get("/standings/constructors/{year}")
async def get_constructor_standings(year: int):
    if not supabase:
        raise HTTPException(status_code=500, detail="Database not configured")
    try:
        res = supabase.table("constructor_standings").select("*").eq("year", year).order("position").execute()
        return res.data
    except Exception as e:
        logger.error(f"Constructor standings failed: {e}")
        raise HTTPException(status_code=404, detail="Standings unavailable")

@app.get("/results/{year}/{round}/{session}")
async def get_results(year: int, round: int, session: str):
    if not supabase:
        raise HTTPException(status_code=500, detail="Database not configured")
    try:
        res = supabase.table("session_results").select("*").eq("year", year).eq("round_number", round).eq("session_type", session).order("position").execute()
        return res.data
    except Exception as e:
        logger.error(f"Results load failed: {e}")
        raise HTTPException(status_code=404, detail="Session data not available yet")

@app.get("/laps/{year}/{round}/{session}")
async def get_laps(year: int, round: int, session: str):
    if not supabase:
        raise HTTPException(status_code=500, detail="Database not configured")
    try:
        # Group laps by driver_code using postgres/supabase. For now just return raw if client can handle or reformat
        res = supabase.table("laps").select("*").eq("year", year).eq("round_number", round).eq("session_type", session).order("lap_number").execute()
        
        # Format similar to old endpoint
        drivers = {}
        for row in res.data:
            dc = row["driver_code"]
            if dc not in drivers:
                drivers[dc] = {
                    "driver_code": dc,
                    "team_color": row.get("team_color", "#FFF"),
                    "laps": []
                }
            drivers[dc]["laps"].append(row)
            
        return list(drivers.values())
    except Exception as e:
        logger.error(f"Laps load failed: {e}")
        raise HTTPException(status_code=404, detail="Session data not available yet")

@app.get("/telemetry/{year}/{round}/{session}/{driver}")
async def get_telemetry(year: int, round: int, session: str, driver: str):
    if not supabase:
        raise HTTPException(status_code=500, detail="Database not configured")
    try:
        res = supabase.table("telemetry").select("*").eq("year", year).eq("round_number", round).eq("session_type", session).eq("driver_code", driver).execute()
        if not res.data or "telemetry_data" not in res.data[0]:
            return {}
        return res.data[0]["telemetry_data"]
    except Exception as e:
        logger.error(f"Telemetry failed: {e}")
        raise HTTPException(status_code=404, detail="Telemetry data unavailable")

@app.get("/weather/{year}/{round}/{session}")
async def get_weather(year: int, round: int, session: str):
    if not supabase:
        raise HTTPException(status_code=500, detail="Database not configured")
    try:
        res = supabase.table("weather").select("*").eq("year", year).eq("round_number", round).eq("session_type", session).order("time").execute()
        return {"data": res.data, "summary": {}}
    except Exception as e:
        logger.error(f"Weather failed: {e}")
        raise HTTPException(status_code=404, detail="Weather data unavailable")

@app.get("/driver_season/{year}/{driver}")
async def get_driver_season(year: int, driver: str):
    if not supabase:
        raise HTTPException(status_code=500, detail="Database not configured")
    try:
        # Get total points, wins, podiums, and position history
        res = supabase.table("session_results").select("*").eq("year", year).eq("driver_code", driver).eq("session_type", "Race").execute()
        
        results = res.data
        if not results:
            return {"total_points": 0, "wins": 0, "podiums": 0, "avg_finish": 0, "evolution": []}
            
        total_points = sum(r.get("points", 0) for r in results)
        wins = sum(1 for r in results if r.get("position") == 1)
        podiums = sum(1 for r in results if r.get("position") and r.get("position") <= 3)
        positions = [r.get("position") for r in results if r.get("position")]
        avg_finish = round(sum(positions) / len(positions), 1) if positions else 0
        
        # Points evolution
        evolution = []
        running_total = 0
        for r in sorted(results, key=lambda x: x["round_number"]):
            running_total += r.get("points", 0)
            evolution.append(running_total)
            
        return {
            "total_points": total_points,
            "wins": wins,
            "podiums": podiums,
            "avg_finish": avg_finish,
            "evolution": evolution
        }
    except Exception as e:
        logger.error(f"Driver season stats failed: {e}")
        raise HTTPException(status_code=404, detail="Stats unavailable")

@app.get("/tyre_strategy/{year}/{round}")
async def get_tyre_strategy(year: int, round: int):
    if not supabase:
        raise HTTPException(status_code=500, detail="Database not configured")
    try:
        # In a real scenario, this would come from a dedicated 'stints' or 'laps' table summary
        # For now, let's group laps to show compound changes
        res = supabase.table("laps").select("driver_code,lap_number,compound,stint").eq("year", year).eq("round_number", round).eq("session_type", "Race").order("driver_code,lap_number").execute()
        
        drivers = {}
        for row in res.data:
            dc = row["driver_code"]
            if dc not in drivers:
                drivers[dc] = {"driver_code": dc, "stints": []}
            
            last_stint = drivers[dc]["stints"][-1] if drivers[dc]["stints"] else None
            if not last_stint or last_stint["compound"] != row["compound"]:
                drivers[dc]["stints"].append({
                    "compound": row["compound"],
                    "lap_count": 1
                })
            else:
                last_stint["lap_count"] += 1
                
        return list(drivers.values())
    except Exception as e:
        logger.error(f"Tyre strategy failed: {e}")
        return []

@app.get("/race_control/{year}/{round}")
async def get_race_control(year: int, round: int):
    if not supabase:
        raise HTTPException(status_code=500, detail="Database not configured")
    try:
        res = supabase.table("race_control").select("*").eq("year", year).eq("round_number", round).order("time").execute()
        return res.data
    except Exception as e:
        logger.error(f"Race control failed: {e}")
        return []

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
