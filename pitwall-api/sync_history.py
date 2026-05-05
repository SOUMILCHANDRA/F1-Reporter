import subprocess
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Decades to sync
DECADES = [
    (1950, 1959),
    (1960, 1969),
    (1970, 1979),
    (1980, 1989),
    (1990, 1999),
    (2000, 2009),
    (2010, 2019),
    (2020, 2026)
]

PYTHON_EXE = "C:\\Users\\Admin\\AppData\\Local\\Programs\\Python\\Python313\\python.exe"

def sync_decades():
    for start, end in DECADES:
        logger.info(f"========== SYNCING DECADE: {start}s ({start}-{end}) ==========")
        try:
            # Run worker for this decade
            cmd = [PYTHON_EXE, "worker.py", str(start), str(end)]
            subprocess.run(cmd, check=True)
            
            logger.info(f"Finished syncing {start}-{end}. Waiting 1 minute to cool down API...")
            time.sleep(60) # Cooling down to avoid 429 errors
            
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to sync decade {start}-{end}: {e}")
            logger.info("Retrying in 5 minutes...")
            time.sleep(300)

if __name__ == "__main__":
    sync_decades()
