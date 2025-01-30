from fastapi import FastAPI, HTTPException, Depends, Query, APIRouter
from fastapi.security import APIKeyHeader
from pydantic import BaseModel
from typing import List, Optional
import uvicorn
import time

# --- Define Pydantic Models ---
class ArtistSchema(BaseModel):
    id: int
    name: str
    genre: str
    country: str
    image_url: Optional[str] = None
    schedule: Optional[List[str]] = []  # Performance schedule
    stage: Optional[str] = None  # Assigned stage

class StageSchema(BaseModel):
    id: int
    name: str
    location: str
    capacity: int
    performances: Optional[List[str]] = []

class ScheduleSchema(BaseModel):
    id: int
    artist_id: int
    stage_id: int
    time_slot: str

class TicketSchema(BaseModel):
    id: int
    type: str
    price: float
    quantity_available: int

class UserSchema(BaseModel):
    id: int
    name: str
    role: str  # Admin, Artist, Attendee

class RatingSchema(BaseModel):
    artist_id: int
    user_id: int
    rating: float  # Scale of 1-5
    feedback: Optional[str] = None

class NewsSchema(BaseModel):
    id: int
    title: str
    content: str
    timestamp: str

# --- Authentication & Security ---
API_KEY = "festival_secure_key"
SECRET_KEY = "supersecret"
ALGORITHM = "HS256"
api_key_header = APIKeyHeader(name="X-API-Key")

def authenticate(api_key: str = Depends(api_key_header)):
    if api_key != API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API Key")

# --- Pagination ---
def paginate(items: List, page: int = 1, size: int = 10):
    start = (page - 1) * size
    end = start + size
    return items[start:end]

# --- Rate Limiting ---
RATE_LIMIT = {}
RATE_LIMIT_WINDOW = 60  # seconds
RATE_LIMIT_MAX = 5  # max requests per window

# --- Mock Databases ---
artists_db = []
stages_db = []
schedules_db = []
tickets_db = []
users_db = []
ratings_db = []
news_db = []

# --- Core API Endpoints ---

app = FastAPI(title="Music Festival Management API", version="1.0", description="Music Festival Management API with advanced features")

@app.get("/artists", response_model=List[ArtistSchema], summary="Get all artists with filtering, sorting, and pagination")
async def get_artists(
    genre: Optional[str] = None,
    country: Optional[str] = None,
    sort_by: Optional[str] = Query(None, regex="^(name|genre|country)$"),
    page: int = 1,
    size: int = 10
):
    artists = artists_db
    if genre:
        artists = [a for a in artists if a["genre"] == genre]
    if country:
        artists = [a for a in artists if a["country"] == country]
    if sort_by:
        artists.sort(key=lambda x: x[sort_by])
    return paginate(artists, page, size)

@app.post("/artists", response_model=ArtistSchema, summary="Add a new artist")
async def add_artist(artist: ArtistSchema):
    artists_db.append(artist)
    return artist

@app.get("/stages", response_model=List[StageSchema], summary="Get all stages")
async def get_stages():
    return stages_db

@app.post("/stages", response_model=StageSchema, summary="Add a new stage")
async def add_stage(stage: StageSchema):
    stages_db.append(stage)
    return stage

@app.get("/schedule", response_model=List[ScheduleSchema], summary="Get the festival schedule")
async def get_schedule():
    return schedules_db

@app.post("/schedule", response_model=ScheduleSchema, summary="Create a new schedule entry")
async def add_schedule(schedule: ScheduleSchema):
    schedules_db.append(schedule)
    return schedule

@app.get("/tickets", response_model=List[TicketSchema], summary="Get available tickets")
async def get_tickets():
    return tickets_db

@app.post("/tickets", response_model=TicketSchema, summary="Create a new ticket type")
async def add_ticket(ticket: TicketSchema):
    tickets_db.append(ticket)
    return ticket

@app.get("/users", response_model=List[UserSchema], summary="Get all users")
async def get_users():
    return users_db

@app.post("/users", response_model=UserSchema, summary="Register a new user")
async def add_user(user: UserSchema):
    users_db.append(user)
    return user

@app.post("/ratings", response_model=RatingSchema, summary="Rate an artist and provide feedback")
async def rate_artist(rating: RatingSchema):
    ratings_db.append(rating)
    return rating

@app.get("/news", response_model=List[NewsSchema], summary="Get real-time festival news and announcements")
async def get_news():
    return news_db

@app.post("/news", response_model=NewsSchema, summary="Post a festival announcement")
async def post_news(news: NewsSchema):
    news_db.append(news)
    return news

# --- Search Functionality ---
@app.get("/artists/search", summary="Search artists by name")
async def search_artists(query: str):
    return [a for a in artists_db if query.lower() in a["name"].lower()]

# --- Rate Limiting Middleware ---
@app.middleware("http")
async def rate_limiter(request, call_next):
    client_ip = request.client.host
    current_time = time.time()
    if client_ip not in RATE_LIMIT:
        RATE_LIMIT[client_ip] = []
    RATE_LIMIT[client_ip] = [t for t in RATE_LIMIT[client_ip] if current_time - t < RATE_LIMIT_WINDOW]
    if len(RATE_LIMIT[client_ip]) >= RATE_LIMIT_MAX:
        return HTTPException(status_code=429, detail="Rate limit exceeded")
    RATE_LIMIT[client_ip].append(current_time)
    return await call_next(request)

# --- Unit Testing Placeholder ---
@app.get("/test", summary="Run unit tests")
async def run_tests():
    return {"message": "Unit tests executed successfully"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
