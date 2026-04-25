# WikiSwipe

A Tinder-like MVP app for discovering Wikipedia knowledge through swipeable cards. Built with FastAPI (Python) on the backend and SwiftUI (iOS) on the frontend.

## Project Structure
- `backend/`: FastAPI app, Supabase Postgres schema, OpenAI API script for summeries, Wikipedia API logic.
- `ios-app/WikiSwipe`: Native iOS implementation in SwiftUI.
- `docs/`: Documentation folder.

## Prerequisites
- Python 3.9+
- iOS 15.0+ Simulator or real device with Xcode
- PostgreSQL database
- OpenAI API Key

## Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Build virtual env and install requirements:
   ```bash
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```
3. Initialize Database:
   Execute `schema.sql` into your Postgres database.
4. Setup Environment:
   Copy `.env.example` to `.env` and fill in your details:
   ```
   DATABASE_URL=postgresql://your_user:your_password@localhost:5432/your_db
   OPENAI_API_KEY=sk-your-openai-key
   ```
5. Run the API:
   ```bash
   uvicorn main:app --reload
   ```
   Available at `http://localhost:8000`. 
   
*Note: Ensure to call the `POST /refresh` endpoint through Swagger (`http://localhost:8000/docs`) with `user_id` to start loading the Wikipedia articles per topic into the database.*

## iOS Setup (SwiftUI)

1. Open Xcode and Create a new iOS App called `WikiSwipe`.
2. Delete the default generated `ContentView.swift` and `WikiSwipeApp.swift`.
3. Drag and drop all `.swift` files from `ios-app/WikiSwipe/` into your Xcode project.
4. In `APIClient.swift`, verify `baseURL` points to your backend instance (`http://localhost:8000` is default). 
*(Note: To connect to localhost from an iOS physical device you must use your local IP instead like `http://192.168.1.X:8000` or use Ngrok)*
5. Press `Cmd + R` to build and run the app.

## Architectural Notes
- **Attribution**: Every card handles attribution using UI links directly leading back to the original Wikipedia url.
- **Recommendations**: In `main.py`, the rating calculation increases/decreases `UserTopicPreference` which then affects which domains are prioritized during the `/refresh` phase.
- **Images**: Lead images are loaded securely via Apple's standard `AsyncImage` component in `CardView.swift` preventing unnecessary freezing and caching seamlessly.
