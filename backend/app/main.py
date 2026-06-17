from fastapi import FastAPI
import os

from app.database import engine, Base
from app import models

from fastapi.middleware.cors import CORSMiddleware
from app.routes.auth_routes import router as auth_router
from app.routes.dashboard_routes import router as dashboard_router
from app.routes.transaction_routes import router as transaction_router
from app.dependencies import get_current_user
from app.models import User
from fastapi import Depends

# Production-ready FastAPI application
app = FastAPI(
    title="Expense Tracker API",
    description="Backend API for personal expense tracker app",
    version="1.0.0"
)


Base.metadata.create_all(bind=engine)

# Temporary startup migration: add sub_category column if it does not exist.
with engine.connect() as connection:
    existing_columns = connection.execute(
        "SELECT column_name FROM information_schema.columns WHERE table_name = 'transactions'"
    ).fetchall()
    column_names = {row[0] for row in existing_columns}
    if 'sub_category' not in column_names:
        connection.execute(
            "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS sub_category VARCHAR"
        )

# Add CORS middleware to allow Flutter web and mobile clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(transaction_router)
app.include_router(dashboard_router)


@app.get("/")
def home():
    return {"message": "Expense Tracker API is running"}

@app.get("/me")
def get_me(
    current_user: User = Depends(get_current_user)
):
    return {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email
    }


# Health check endpoint for Render and load balancers
@app.get("/health")
def health():
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", 8000))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, log_level="info")