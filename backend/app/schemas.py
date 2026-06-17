from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    name: str
    email: str

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str


class TransactionCreate(BaseModel):
    title: str
    amount: float
    transaction_type: str
    category: str
    description: Optional[str] = None
    transaction_date: Optional[datetime] = None


class TransactionUpdate(BaseModel):
    title: Optional[str] = None
    amount: Optional[float] = None
    transaction_type: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    transaction_date: Optional[datetime] = None


class TransactionResponse(BaseModel):
    id: int
    user_id: int
    title: str
    amount: float
    transaction_type: str
    category: str
    description: Optional[str] = None
    transaction_date: datetime
    created_at: datetime

    class Config:
        from_attributes = True