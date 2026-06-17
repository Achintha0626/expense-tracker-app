from fastapi import FastAPI

from app.database import engine, Base
from app import models

from app.routes.auth_routes import router as auth_router

app = FastAPI(
    title="Expense Tracker API",
    description="Backend API for personal expense tracker app",
    version="1.0.0"
)

Base.metadata.create_all(bind=engine)

app.include_router(auth_router)


@app.get("/")
def home():
    return {"message": "Expense Tracker API is running"}