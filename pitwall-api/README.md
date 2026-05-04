# Pitwall API 🏁

A high-performance FastAPI backend for the Pitwall F1 Intelligence app. Serves real-time and historical F1 data using FastF1 and NewsAPI.

## 🚀 Features
- **18+ Endpoints**: Comprehensive coverage of F1 data (Standings, Results, Telemetry, Strategy, Weather, etc.).
- **FastF1 Integration**: Direct access to official F1 timing and telemetry data.
- **News Integration**: Real-time F1 news via NewsAPI.org.
- **Optimized Telemetry**: Automatic downsampling of telemetry data to 400 points for mobile performance.
- **Persistent Caching**: Leverages FastF1's caching system for sub-second responses on repeat requests.
- **Production-Ready**: Configured for instant deployment on Railway.app.

## 🛠️ Deployment (Railway.app)
1. Fork/Clone this repository.
2. Create a new Project on Railway.
3. Add a **Nixpacks** build provider.
4. Set the following Environment Variables:
   - `NEWS_API_KEY`: Your API key from [newsapi.org](https://newsapi.org).
   - `PORT`: (Automatically set by Railway).
5. The `railway.toml` and `Procfile` will handle the rest.

## 📡 Key Endpoints
- `GET /health`: System health check.
- `GET /news`: Real-time F1 news.
- `GET /telemetry/{year}/{round}/{session}/{driver}`: Fastest lap telemetry.
- `GET /standings/drivers/{year}`: Driver championship standings.
- `GET /tyre_strategy/{year}/{round}`: Race tyre stint analysis.

## 📦 Local Setup
1. `pip install -r requirements.txt`
2. `cp .env.example .env` (Add your NewsAPI key)
3. `python main.py` or `uvicorn main:app --reload`

---
*Powered by FastF1 and FastAPI.*
