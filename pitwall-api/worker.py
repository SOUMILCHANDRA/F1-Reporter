import os
import logging
import fastf1
import pandas as pd
import json
import time
from datetime import datetime, timezone
from supabase import create_client, Client
from dotenv import load_dotenv

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    logger.error("Supabase credentials not found in environment variables.")
    exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

CACHE_DIR = "/app/cache" if os.path.exists("/app") else "./cache"
if not os.path.exists(CACHE_DIR):
    os.makedirs(CACHE_DIR)
fastf1.Cache.enable_cache(CACHE_DIR)

def to_ms(td):
    if pd.isna(td):
        return None
    try:
        return td.total_seconds() * 1000
    except:
        return None

def sync_schedule(year: int, skip_existing=True):
    if skip_existing:
        # Check if year is already synced
        res = supabase.table("races").select("id").eq("year", year).limit(1).execute()
        if res.data:
            logger.info(f"Schedule for {year} already exists. Skipping.")
            return

    logger.info(f"Syncing schedule for {year}...")
    try:
        schedule = fastf1.get_event_schedule(year, include_testing=False)
        data = []
        for _, row in schedule.iterrows():
            data.append({
                "year": year,
                "round_number": int(row["RoundNumber"]),
                "event_name": row["EventName"],
                "country": row["Country"],
                "location": row["Location"],
                "circuit_name": row.get("OfficialEventName", row["EventName"]),
                "date_fp1": row["Session1Date"].isoformat() if pd.notna(row.get("Session1Date")) else None,
                "date_fp2": row["Session2Date"].isoformat() if pd.notna(row.get("Session2Date")) else None,
                "date_fp3": row["Session3Date"].isoformat() if pd.notna(row.get("Session3Date")) else None,
                "date_qualifying": row["Session4Date"].isoformat() if pd.notna(row.get("Session4Date")) else None,
                "date_sprint": row["Session5Date"].isoformat() if pd.notna(row.get("Session5Date")) else None,
                "date_race": row["Session5Date"].isoformat() if pd.notna(row.get("Session5Date")) else None,
                "event_format": row.get("EventFormat"),
                "gmt_offset": str(row.get("GmtOffset", ""))
            })
        if data:
            supabase.table("races").upsert(data, on_conflict="year,round_number").execute()
            logger.info(f"Synced {len(data)} races for {year}.")
    except Exception as e:
        logger.error(f"Schedule sync failed for {year}: {e}")

def sync_standings(year: int, skip_existing=True):
    if skip_existing:
        res = supabase.table("driver_standings").select("id").eq("year", year).limit(1).execute()
        if res.data:
            logger.info(f"Standings for {year} already exist. Skipping.")
            return

    logger.info(f"Syncing standings for {year}...")
    try:
        import fastf1.ergast as ergast
        e = ergast.Ergast()
        
        # Drivers
        d_standings = e.get_driver_standings(season=year)
        d_data = []
        if d_standings.content:
            df = d_standings.content[0]
            for _, s in df.iterrows():
                try:
                    pos = s.get('position', 0)
                    pts = s.get('points', 0.0)
                    wins = s.get('wins', 0)
                    
                    d_data.append({
                        "year": year,
                        "position": int(pos) if pd.notna(pos) else 0,
                        "driver_code": str(s.get('driverCode', s.get('driverId', 'UNK'))),
                        "full_name": f"{s.get('givenName', '')} {s.get('familyName', '')}",
                        "team": str(s['constructorNames'][0]) if s.get('constructorNames') and len(s['constructorNames']) > 0 else "Unknown",
                        "nationality": str(s.get('driverNationality', s.get('nationality', 'Unknown'))),
                        "points": float(pts) if pd.notna(pts) else 0.0,
                        "wins": int(wins) if pd.notna(wins) else 0,
                        "podiums": 0
                    })
                except:
                    continue
        if d_data:
            supabase.table("driver_standings").upsert(d_data, on_conflict="year,driver_code").execute()
        
        # Constructors
        c_standings = e.get_constructor_standings(season=year)
        c_data = []
        if c_standings.content:
            df = c_standings.content[0]
            for _, s in df.iterrows():
                try:
                    pos = s.get('position', 0)
                    pts = s.get('points', 0.0)
                    wins = s.get('wins', 0)
                    
                    c_data.append({
                        "year": year,
                        "position": int(pos) if pd.notna(pos) else 0,
                        "team_name": str(s.get('constructorName', s.get('constructorId', 'Unknown'))),
                        "nationality": str(s.get('constructorNationality', s.get('nationality', 'Unknown'))),
                        "points": float(pts) if pd.notna(pts) else 0.0,
                        "wins": int(wins) if pd.notna(wins) else 0
                    })
                except:
                    continue
        if c_data:
            supabase.table("constructor_standings").upsert(c_data, on_conflict="year,team_name").execute()
            
        logger.info(f"Synced standings for {year}.")
    except Exception as e:
        logger.error(f"Standings sync failed for {year}: {e}")

def sync_race_results(year: int, round_num: int, skip_existing=True):
    if skip_existing:
        res = supabase.table("session_results").select("id").eq("year", year).eq("round_number", round_num).eq("session_type", "Race").limit(1).execute()
        if res.data:
            return

    logger.info(f"Syncing race results for {year} Round {round_num}...")
    try:
        s = fastf1.get_session(year, round_num, 'Race')
        s.load(laps=False, telemetry=False, weather=False, messages=False)
        data = []
        for _, row in s.results.iterrows():
            data.append({
                "year": year,
                "round_number": round_num,
                "session_type": "Race",
                "position": int(row["Position"]) if pd.notna(row.get("Position")) else None,
                "driver_code": row.get("Abbreviation", row.get("DriverId", "UNK")),
                "full_name": row.get("FullName", row.get("DriverId", "Unknown")),
                "team": row.get("TeamName", "Unknown"),
                "team_color": f"#{row['TeamColor']}" if pd.notna(row.get('TeamColor')) else "#FFFFFF",
                "grid_position": int(row["GridPosition"]) if pd.notna(row.get("GridPosition")) else None,
                "status": row.get("Status", "Finished"),
                "points": float(row["Points"]) if pd.notna(row.get("Points")) else 0.0,
                "fastest_lap_time": to_ms(row.get("FastestLapTime")),
                "finishing_time": to_ms(row.get("Time")),
                "gap_to_leader": to_ms(row.get("Time"))
            })
        if data:
            supabase.table("session_results").upsert(data, on_conflict="year,round_number,session_type,driver_code").execute()
    except Exception as e:
        logger.error(f"Race results sync failed for {year} Round {round_num}: {e}")

def sync_detailed_data(year: int, round_num: int, skip_existing=True):
    if skip_existing:
        # Only skip if we already have telemetry (the last step of detailed sync)
        res = supabase.table("telemetry").select("id").eq("year", year).eq("round_number", round_num).limit(1).execute()
        if res.data:
            return

    logger.info(f"Syncing detailed data for {year} Round {round_num}...")
    try:
        s = fastf1.get_session(year, round_num, 'Race')
        s.load() # Loads laps, telemetry, weather, messages
        session_start = s.date
        
        # 1. Laps
        laps_data = []
        for _, row in s.laps.iterrows():
            laps_data.append({
                "year": year,
                "round_number": round_num,
                "session_type": "Race",
                "driver_code": row.get("Driver", "UNK"),
                "lap_number": int(row["LapNumber"]) if pd.notna(row.get("LapNumber")) else 0,
                "lap_time_ms": to_ms(row.get("LapTime")),
                "sector1_ms": to_ms(row.get("Sector1Time")),
                "sector2_ms": to_ms(row.get("Sector2Time")),
                "sector3_ms": to_ms(row.get("Sector3Time")),
                "compound": row.get("Compound", "UNKNOWN"),
                "tyre_life": int(row["TyreLife"]) if pd.notna(row.get("TyreLife")) else 0,
                "stint": int(row["Stint"]) if pd.notna(row.get("Stint")) else 1,
                "is_personal_best": bool(row.get("IsPersonalBest", False)),
                "pit_in_time": to_ms(row.get("PitInTime")),
                "pit_out_time": to_ms(row.get("PitOutTime")),
                "track_status": str(row.get("TrackStatus", ""))
            })
        if laps_data:
            for i in range(0, len(laps_data), 500):
                supabase.table("laps").upsert(laps_data[i:i+500], on_conflict="year,round_number,session_type,driver_code,lap_number").execute()
        
        # 2. Weather
        weather_data = []
        for _, row in s.weather_data.iterrows():
            t = row.get("Time")
            if isinstance(t, pd.Timedelta):
                abs_time = (session_start + t).isoformat()
            else:
                abs_time = t.isoformat() if hasattr(t, "isoformat") else str(t)
            weather_data.append({
                "year": year,
                "round_number": round_num,
                "session_type": "Race",
                "time": abs_time,
                "air_temp": float(row.get("AirTemp", 0)),
                "track_temp": float(row.get("TrackTemp", 0)),
                "humidity": float(row.get("Humidity", 0)),
                "pressure": float(row.get("Pressure", 0)),
                "wind_speed": float(row.get("WindSpeed", 0)),
                "wind_direction": int(row.get("WindDirection", 0)),
                "rainfall": bool(row.get("Rainfall", False))
            })
        if weather_data:
            supabase.table("weather").upsert(weather_data, on_conflict="year,round_number,session_type,time").execute()
            
        # 3. Race Control
        rc_data = []
        for _, row in s.race_control_messages.iterrows():
            t = row.get("Time")
            if isinstance(t, pd.Timedelta):
                abs_time = (session_start + t).isoformat()
            else:
                abs_time = t.isoformat() if hasattr(t, "isoformat") else str(t)
            rc_data.append({
                "year": year,
                "round_number": round_num,
                "session_type": "Race",
                "time": abs_time,
                "lap_number": int(row["Lap"]) if pd.notna(row.get("Lap")) else None,
                "category": row.get("Category", ""),
                "message": row.get("Message", ""),
                "flag": row.get("Flag", ""),
                "scope": row.get("Scope", ""),
                "driver_code": row.get("Driver")
            })
        if rc_data:
            supabase.table("race_control").upsert(rc_data, on_conflict="year,round_number,session_type,time,message").execute()

        # 4. Telemetry (Sampled for all drivers)
        for driver in s.drivers:
            try:
                driver_laps = s.laps.pick_driver(driver)
                if driver_laps.empty: continue
                tel = driver_laps.get_telemetry()
                if tel.empty: continue
                sampled = tel.iloc[::5]
                tel_json = {
                    "speed": sampled["Speed"].tolist(),
                    "rpm": sampled["RPM"].tolist(),
                    "gear": sampled["nGear"].tolist(),
                    "throttle": sampled["Throttle"].tolist(),
                    "brake": sampled["Brake"].tolist()
                }
                supabase.table("telemetry").upsert({
                    "year": year,
                    "round_number": round_num,
                    "session_type": "Race",
                    "driver_code": driver,
                    "telemetry_data": tel_json
                }, on_conflict="year,round_number,session_type,driver_code").execute()
            except Exception as e:
                logger.warning(f"Telemetry failed for {driver}: {e}")
                continue

        logger.info(f"Synced detailed data for {year} Round {round_num}.")
    except Exception as e:
        logger.error(f"Detailed sync failed for {year} Round {round_num}: {e}")

def run_sync(start_year=2024, end_year=2026):
    for current_year in range(start_year, end_year + 1):
        logger.info(f"--- Syncing Season {current_year} ---")
        sync_schedule(current_year)
        sync_standings(current_year)
        
        # Sync results and detailed data for all completed races
        res = supabase.table("races").select("round_number,date_race").eq("year", current_year).execute()
        for race in res.data:
            if not race.get("date_race"):
                continue
            try:
                race_date = datetime.fromisoformat(race["date_race"].replace('Z', '+00:00'))
                if race_date.tzinfo is None:
                    race_date = race_date.replace(tzinfo=timezone.utc)
                    
                now_utc = datetime.now(timezone.utc)
                if race_date < now_utc:
                    sync_race_results(current_year, race["round_number"])
                    sync_detailed_data(current_year, race["round_number"])
            except Exception as e:
                logger.error(f"Failed to process {current_year} Round {race['round_number']}: {e}")
        
        # Pause slightly between seasons to be polite to the API
        time.sleep(2)

if __name__ == "__main__":
    import sys
    start = int(sys.argv[1]) if len(sys.argv) > 1 else 2024
    end = int(sys.argv[2]) if len(sys.argv) > 2 else 2026
    run_sync(start, end)
