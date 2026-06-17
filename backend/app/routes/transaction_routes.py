from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import Transaction
from app.schemas import (
    TransactionCreate,
    TransactionListResponse,
    TransactionResponse,
    TransactionUpdate,
)
from app.models import User

router = APIRouter(
    prefix="/transactions",
    tags=["Transactions"]
)

VALID_TRANSACTION_TYPES = {"income", "expense"}


def _validate_transaction_type(transaction_type: str):
    if transaction_type not in VALID_TRANSACTION_TYPES:
        raise HTTPException(
            status_code=400,
            detail="transaction_type must be 'income' or 'expense'"
        )


def _get_transaction_for_user(db: Session, transaction_id: int, user_id: int):
    transaction = (
        db.query(Transaction)
        .filter(Transaction.id == transaction_id)
        .filter(Transaction.user_id == user_id)
        .first()
    )
    if not transaction:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found"
        )
    return transaction


@router.post("/", response_model=TransactionResponse)
def create_transaction(
    transaction: TransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    _validate_transaction_type(transaction.transaction_type)

    new_transaction = Transaction(
        user_id=current_user.id,
        title=transaction.title,
        amount=transaction.amount,
        transaction_type=transaction.transaction_type,
        category=transaction.category,
        sub_category=transaction.sub_category,
        description=transaction.description,
        transaction_date=transaction.transaction_date,
    )

    db.add(new_transaction)
    db.commit()
    db.refresh(new_transaction)

    return new_transaction


@router.get("/", response_model=TransactionListResponse)
def list_transactions(
    transaction_type: str | None = None,
    category: str | None = None,
    search: str | None = None,
    start_date: datetime | None = None,
    end_date: datetime | None = None,
    page: int = 1,
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if transaction_type is not None:
        _validate_transaction_type(transaction_type)

    if page < 1:
        page = 1
    if limit < 1:
        limit = 10

    query = db.query(Transaction).filter(Transaction.user_id == current_user.id)

    if transaction_type is not None:
        query = query.filter(Transaction.transaction_type == transaction_type)

    if category is not None:
        query = query.filter(Transaction.category == category)

    if search is not None:
        search_pattern = f"%{search}%"
        query = query.filter(
            or_(
                Transaction.title.ilike(search_pattern),
                Transaction.description.ilike(search_pattern),
            )
        )

    if start_date is not None:
        query = query.filter(Transaction.transaction_date >= start_date)

    if end_date is not None:
        query = query.filter(Transaction.transaction_date <= end_date)

    total = query.count()
    items = (
        query.order_by(Transaction.transaction_date.desc())
        .offset((page - 1) * limit)
        .limit(limit)
        .all()
    )

    return {
        "page": page,
        "limit": limit,
        "total": total,
        "items": items,
    }


@router.get("/{transaction_id}", response_model=TransactionResponse)
def get_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return _get_transaction_for_user(db, transaction_id, current_user.id)


@router.put("/{transaction_id}", response_model=TransactionResponse)
def update_transaction(
    transaction_id: int,
    transaction_update: TransactionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    transaction = _get_transaction_for_user(db, transaction_id, current_user.id)

    if transaction_update.transaction_type is not None:
        _validate_transaction_type(transaction_update.transaction_type)

    if transaction_update.title is not None:
        transaction.title = transaction_update.title
    if transaction_update.amount is not None:
        transaction.amount = transaction_update.amount
    if transaction_update.transaction_type is not None:
        transaction.transaction_type = transaction_update.transaction_type
    if transaction_update.category is not None:
        transaction.category = transaction_update.category
    if transaction_update.sub_category is not None:
        transaction.sub_category = transaction_update.sub_category
    if transaction_update.description is not None:
        transaction.description = transaction_update.description
    if transaction_update.transaction_date is not None:
        transaction.transaction_date = transaction_update.transaction_date

    db.commit()
    db.refresh(transaction)
    return transaction


@router.delete("/{transaction_id}")
def delete_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    transaction = _get_transaction_for_user(db, transaction_id, current_user.id)

    db.delete(transaction)
    db.commit()

    return {"detail": "Transaction deleted successfully"}
