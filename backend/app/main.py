from fastapi import FastAPI

from app.database import engine, Base
from app import models

from app.routes.auth_routes import router as auth_router
from app.routes.dashboard_routes import router as dashboard_router
from app.routes.transaction_routes import router as transaction_router
from app.dependencies import get_current_user
from app.models import User
from fastapi import Depends
app = FastAPI(
    title="Expense Tracker API",
    description="Backend API for personal expense tracker app",
    version="1.0.0"
)

Base.metadata.create_all(bind=engine)

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