# Pitwall 🏁

High‑fidelity Formula 1 intelligence dashboard with real‑time telemetry, tyre‑strategy analysis, and immersive visualisation.

[Quick Links: [Introduction](#introduction) · [Tech Stack](#tech-stack) · [Prerequisites / Requirements](#prerequisites--requirements) · [Installation](#installation) · [Configuration](#configuration) · [Usage](#usage) · [Project Structure](#project-structure) · [Features](#features) · [Development](#development) · [Contributing](#contributing) · [License](#license) · [FAQ](#faq)]

## Introduction

F1‑Reporter (branded as **Pitwall**) delivers a “Bloomberg‑Terminal‑style” experience for motorsport enthusiasts. It combines a Flutter front‑end with a FastAPI back‑end to provide:

* Live race telemetry and lap‑time charts  
* Detailed tyre‑strategy visualisations  
* Up‑to‑date standings and points progression  
* A news feed filtered by driver, team, and technical topics  
* Countdown timers for race weekends and sprint events  

The solution is designed for both mobile and desktop platforms, offering a premium noir‑inspired UI.

## Tech Stack

- **Frontend**: Flutter (Dart) with Riverpod state management  
- **Charts**: `fl_chart`  
- **Typography**: Orbitron, Rajdhani, JetBrains Mono  
- **Backend**: FastAPI (Python)  
- **Data Sources**: `fastf1` for official timing/telemetry, NewsAPI for editorial content  
- **Deployment**: Render.com (Web Service)  
- **Build Tools**: CMake (native plugins), Xcode (iOS), Android SDK (Android)  

## Prerequisites / Requirements

- **Flutter SDK** (≥ 3.0) – includes Dart  
- **Android Studio** or **Xcode** for platform‑specific builds  
- **Python** (≥ 3.9) and **pip**  
- **Git**  
- **Render.com** account (optional, for cloud deployment)  
- **NewsAPI.org** API key for news integration  

## Installation

### Backend (Pitwall API)

```bash
# Clone the repository
git clone https://github.com/SOUMILCHANDRA/F1-Reporter.git
cd F1-Reporter/pitwall-api

# Create a virtual environment
python -m venv venv
source venv/bin/activate   # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Frontend (Flutter app)

```bash
cd ../   # Return to repository root
flutter pub get
```

## Configuration

### Backend environment variables

Create a `.env` file in `pitwall-api/` with the following keys:

```dotenv
NEWS_API_KEY=your_newsapi_key_here
```

The FastAPI service reads these variables at startup.

### Render.com deployment (optional)

1. Add a **Web Service** and connect the repository.  
2. Set **Runtime** to `Python`.  
3. Use the following build and start commands:

```bash
# Build Command
pip install -r requirements.txt

# Start Command
uvicorn main:app --host 0.0.0.0 --port $PORT
```

4. Define the `NEWS_API_KEY` secret in the Render dashboard.

## Usage

### Run the API locally

```bash
uvicorn main:app --reload
```

The API will be available at `http://127.0.0.1:8000`.

### Launch the Flutter app

```bash
flutter run
```

*For iOS:* open `ios/Runner.xcworkspace` in Xcode and run on a simulator or device.  
*For Android:* ensure an emulator or device is connected, then run the command above.

## Project Structure

```
F1-Reporter/
├─ lib/                     # Flutter source code
├─ ios/                     # iOS project (Xcode)
├─ android/                 # Android project
├─ pitwall-api/             # FastAPI backend
│  ├─ main.py
│  ├─ requirements.txt
│  └─ .env (generated)
├─ render.yaml              # Render deployment blueprint
├─ README.md
└─ .github/                 # CI workflows
```

## Features

- **News Feed** – Real‑time editorial content with driver/team filters.  
- **Race Hub** – Interactive telemetry charts for lap‑time comparison.  
- **Tyre Strategy** – Stint timelines with compound tracking and precision.  
- **Standings** – Colour‑coded rankings with points progression graphs.  
- **Calendar** – Countdown timers for race weekends and sprint events.  
- **Responsive Design** – Adaptive layouts for mobile, tablet, and desktop.  
- **Cross‑Platform Builds** – Stable native compilation for Windows and Android.  

## Development

### Hot‑reload (Flutter)

```bash
flutter run
# Press "r" in the terminal to hot‑reload after code changes
```

### Backend testing

```bash
# Example: test health endpoint
curl http://127.0.0.1:8000/health
```

### Code style

- Flutter: follow the `flutter_lints` package (see `analysis_options.yaml`).  
- Python: adhere to PEP 8; lint with `flake8` or `ruff` if desired.

## Contributing

1. Fork the repository and create a feature branch.  
2. Ensure the code builds for both the Flutter app and FastAPI service.  
3. Write clear commit messages and update documentation as needed.  
4. Open a Pull Request describing the changes.

Please respect the existing code style and run the relevant linters before submitting.

## License

The project is licensed under the terms described in the `LICENSE` file located at the repository root.

##
