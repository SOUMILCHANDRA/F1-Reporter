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
    # We now compute standings dynamically from session_results because Ergast is deprecated
    logger.info(f"Computing standings for {year} from session results...")
    try:
        res = supabase.table("session_results").select("driver_code, full_name, team, points, position, session_type").eq("year", year).execute()
        if not res.data:
            logger.info(f"No session results found to calculate standings for {year}.")
            return
            
        driver_stats = {}
        constructor_stats = {}
        
        for row in res.data:
            dc = row['driver_code']
            tm = row['team']
            pts = row.get('points', 0)
            pos = row.get('position')
            
            if dc not in driver_stats:
                driver_stats[dc] = {
                    "full_name": row['full_name'],
                    "team": tm,
                    "nationality": "Unknown",
                    "points": 0.0,
                    "wins": 0,
                    "podiums": 0
                }
            if tm not in constructor_stats:
                constructor_stats[tm] = {
                    "nationality": "Unknown",
                    "points": 0.0,
                    "wins": 0
                }
                
            driver_stats[dc]["points"] += pts
            # Only add to constructor points if the session awards points
            if row['session_type'] in ['Race', 'Sprint', 'S', 'R']:
                constructor_stats[tm]["points"] += pts
            
            if row['session_type'] in ['Race', 'R'] and pos == 1:
                driver_stats[dc]["wins"] += 1
                constructor_stats[tm]["wins"] += 1
                
            if row['session_type'] in ['Race', 'R'] and pos and pos <= 3:
                driver_stats[dc]["podiums"] += 1

        d_sorted = sorted(driver_stats.items(), key=lambda x: x[1]["points"], reverse=True)
        d_data = []
        for i, (dc, stats) in enumerate(d_sorted):
            d_data.append({
                "year": year,
                "position": i + 1,
                "driver_code": dc,
                "full_name": stats["full_name"],
                "team": stats["team"],
                "nationality": stats["nationality"],
                "points": stats["points"],
                "wins": stats["wins"],
                "podiums": stats["podiums"]
            })
            
        if d_data:
            supabase.table("driver_standings").upsert(d_data, on_conflict="year,driver_code").execute()

        c_sorted = sorted(constructor_stats.items(), key=lambda x: x[1]["points"], reverse=True)
        c_data = []
        for i, (tm, stats) in enumerate(c_sorted):
            c_data.append({
                "year": year,
                "position": i + 1,
                "team_name": tm,
                "nationality": stats["nationality"],
                "points": stats["points"],
                "wins": stats["wins"]
            })
            
        if c_data:
            supabase.table("constructor_standings").upsert(c_data, on_conflict="year,team_name").execute()

        logger.info(f"Synced computed standings for {year}.")
    except Exception as e:
        logger.error(f"Standings sync failed for {year}: {e}")

def sync_session_results(year: int, round_num: int, session_type: str, skip_existing=True):
    if skip_existing:
        res = supabase.table("session_results").select("id").eq("year", year).eq("round_number", round_num).eq("session_type", session_type).limit(1).execute()
        if res.data:
            return

    logger.info(f"Syncing results for {year} Round {round_num} {session_type}...")
    try:
        s = fastf1.get_session(year, round_num, session_type)
        s.load(laps=False, telemetry=False, weather=False, messages=False)
        if s.results.empty: return
        
        data = []
        for _, row in s.results.iterrows():
            data.append({
                "year": year,
                "round_number": round_num,
                "session_type": session_type,
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
        logger.error(f"Results sync failed for {year} Round {round_num} {session_type}: {e}")

def sync_detailed_data(year: int, round_num: int, session_type: str, skip_existing=True):
    if skip_existing:
        res = supabase.table("telemetry").select("id").eq("year", year).eq("round_number", round_num).eq("session_type", session_type).limit(1).execute()
        if res.data:
            return

    logger.info(f"Syncing detailed data for {year} Round {round_num} {session_type}...")
    try:
        s = fastf1.get_session(year, round_num, session_type)
        s.load() 
        session_start = s.date
        
        # 1. Laps
        laps_data = []
        for _, row in s.laps.iterrows():
            laps_data.append({
                "year": year,
                "round_number": round_num,
                "session_type": session_type,
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
                "session_type": session_type,
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
                "session_type": session_type,
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

        # 4. Track Status
        ts_data = []
        for _, row in s.track_status.iterrows():
            t = row.get("Time")
            if isinstance(t, pd.Timedelta):
                abs_time = (session_start + t).isoformat()
            else:
                abs_time = t.isoformat() if hasattr(t, "isoformat") else str(t)
            ts_data.append({
                "year": year,
                "round_number": round_num,
                "session_type": session_type,
                "time": abs_time,
                "status": str(row.get("Status", "")),
                "message": str(row.get("Message", ""))
            })
        if ts_data:
            supabase.table("track_status").upsert(ts_data, on_conflict="year,round_number,session_type,time").execute()

        # 5. Circuit Info
        try:
            ci = s.get_circuit_info()
            ci_data = {
                "year": year,
                "round_number": round_num,
                "corners": ci.corners.to_dict(orient="records") if not ci.corners.empty else [],
                "marshal_lights": ci.marshal_lights.to_dict(orient="records") if not ci.marshal_lights.empty else [],
                "marshal_sectors": ci.marshal_sectors.to_dict(orient="records") if not ci.marshal_sectors.empty else [],
                "rotation": float(ci.rotation)
            }
            supabase.table("circuit_info").upsert(ci_data, on_conflict="year,round_number").execute()
        except Exception as e:
            logger.warning(f"Circuit Info sync failed for {year} Round {round_num}: {e}")

        # 6. Telemetry and Position Data
        for driver in s.drivers:
            try:
                driver_laps = s.laps.pick_driver(driver)
                if driver_laps.empty: continue
                tel = driver_laps.get_telemetry()
                if tel.empty: continue
                
                # Downsample telemetry (10Hz to ~2Hz)
                sampled_tel = tel.iloc[::5]
                tel_json = {
                    "speed": sampled_tel["Speed"].tolist(),
                    "rpm": sampled_tel["RPM"].tolist(),
                    "gear": sampled_tel["nGear"].tolist(),
                    "throttle": sampled_tel["Throttle"].tolist(),
                    "brake": sampled_tel["Brake"].tolist()
                }
                supabase.table("telemetry").upsert({
                    "year": year,
                    "round_number": round_num,
                    "session_type": session_type,
                    "driver_code": driver,
                    "telemetry_data": tel_json
                }, on_conflict="year,round_number,session_type,driver_code").execute()

                # Downsample position data (10Hz to 1Hz to save space)
                sampled_pos = tel.iloc[::10]
                pos_json = {
                    "X": sampled_pos["X"].tolist(),
                    "Y": sampled_pos["Y"].tolist(),
                    "Z": sampled_pos["Z"].tolist(),
                    "Time": [to_ms(t) for t in sampled_pos["Time"]]
                }
                supabase.table("position_data").upsert({
                    "year": year,
                    "round_number": round_num,
                    "session_type": session_type,
                    "driver_code": driver,
                    "pos_data": pos_json
                }, on_conflict="year,round_number,session_type,driver_code").execute()
                
            except Exception as e:
                logger.warning(f"Telemetry/Pos data failed for {driver}: {e}")
                continue

        logger.info(f"Synced detailed data for {year} Round {round_num} {session_type}.")
    except Exception as e:
        logger.error(f"Detailed sync failed for {year} Round {round_num} {session_type}: {e}")

def run_sync(start_year=2024, end_year=2026):
    for current_year in range(start_year, end_year + 1):
        logger.info(f"--- Syncing Season {current_year} ---")
        sync_schedule(current_year)
        
        res = supabase.table("races").select("round_number,date_race,event_format").eq("year", current_year).execute()
        for race in res.data:
            if not race.get("date_race"):
                continue
            try:
                race_date = datetime.fromisoformat(race["date_race"].replace('Z', '+00:00'))
                if race_date.tzinfo is None:
                    race_date = race_date.replace(tzinfo=timezone.utc)
                    
                now_utc = datetime.now(timezone.utc)
                if race_date < now_utc:
                    event_format = race.get('event_format', 'conventional')
                    if event_format == 'sprint':
                        sessions = ['FP1', 'SQ', 'S', 'Q', 'R']
                    elif event_format == 'sprint_shootout':
                        sessions = ['FP1', 'Q', 'SQ', 'S', 'R'] 
                    else:
                        sessions = ['FP1', 'FP2', 'FP3', 'Q', 'R']
                    
                    for st in sessions:
                        try:
                            sync_session_results(current_year, race["round_number"], st)
                            sync_detailed_data(current_year, race["round_number"], st)
                        except Exception as e:
                            logger.error(f"Failed to process {st}: {e}")
            except Exception as e:
                logger.error(f"Failed to process {current_year} Round {race['round_number']}: {e}")
        
        # After all races in the year are processed, sync standings
        sync_standings(current_year, skip_existing=False)
        time.sleep(2)

if __name__ == "__main__":
    import sys
    start = int(sys.argv[1]) if len(sys.argv) > 1 else 2024
    end = int(sys.argv[2]) if len(sys.argv) > 2 else 2026
    run_sync(start, end)
