from datetime import datetime, date, time

from fastapi import APIRouter, Depends, HTTPException, Query
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
    transaction_type: str | None = Query(None, description="Filter by transaction type: income or expense"),
    category: str | None = Query(None, description="Filter by category"),
    sub_category: str | None = Query(None, description="Filter by sub-category"),
    search: str | None = Query(None, description="Search title, description, category, or sub-category"),
    start_date: date | None = Query(None, description="Filter transactions on or after this date (YYYY-MM-DD)"),
    end_date: date | None = Query(None, description="Filter transactions on or before this date (YYYY-MM-DD)"),
    page: int = Query(1, description="Page number for pagination", ge=1),
    limit: int = Query(10, description="Number of items per page", ge=1),
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

    if sub_category is not None:
        query = query.filter(Transaction.sub_category == sub_category)

    if search is not None:
        search_pattern = f"%{search}%"
        query = query.filter(
            or_(
                Transaction.title.ilike(search_pattern),
                Transaction.description.ilike(search_pattern),
                Transaction.category.ilike(search_pattern),
                Transaction.sub_category.ilike(search_pattern),
            )
        )

    if start_date is not None:
        query = query.filter(Transaction.transaction_date >= datetime.combine(start_date, time.min))

    if end_date is not None:
        query = query.filter(Transaction.transaction_date <= datetime.combine(end_date, time.max))

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


@router.get("/categories")
def get_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    categories = (
        db.query(Transaction.category)
        .filter(Transaction.user_id == current_user.id)
        .distinct()
        .order_by(Transaction.category)
        .all()
    )
    return [category for (category,) in categories if category is not None]


@router.get("/subcategories")
def get_subcategories(
    category: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    subcategories = (
        db.query(Transaction.sub_category)
        .filter(Transaction.user_id == current_user.id)
        .filter(Transaction.category == category)
        .distinct()
        .order_by(Transaction.sub_category)
        .all()
    )
    return [sub for (sub,) in subcategories if sub is not None]


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
