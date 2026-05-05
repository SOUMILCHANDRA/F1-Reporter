import os
import logging
from datetime import datetime, timedelta
from typing import List, Optional

import requests
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
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
        if not res.data:
            return {}
        return res.data[0]
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

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
