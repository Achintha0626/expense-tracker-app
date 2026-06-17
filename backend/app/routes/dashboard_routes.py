from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import Transaction, User

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"]
)


@router.get("/summary")
def get_dashboard_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    total_income = db.query(
        func.coalesce(func.sum(Transaction.amount), 0.0)
    ).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "income"
    ).scalar()

    total_expense = db.query(
        func.coalesce(func.sum(Transaction.amount), 0.0)
    ).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "expense"
    ).scalar()

    return {
        "total_income": float(total_income),
        "total_expense": float(total_expense),
        "balance": float(total_income - total_expense),
        "transaction_count": db.query(Transaction)
            .filter(Transaction.user_id == current_user.id)
            .count()
    }


@router.get("/category-breakdown")
def get_category_breakdown(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    results = (
        db.query(
            Transaction.category,
            func.coalesce(func.sum(Transaction.amount), 0.0).label("total")
        )
        .filter(
            Transaction.user_id == current_user.id,
            Transaction.transaction_type == "expense"
        )
        .group_by(Transaction.category)
        .order_by(func.sum(Transaction.amount).desc())
        .all()
    )

    return [
        {"category": category, "total": float(total)}
        for category, total in results
    ]


@router.get("/recent-transactions")
def get_recent_transactions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    transactions = (
        db.query(Transaction)
        .filter(Transaction.user_id == current_user.id)
        .order_by(Transaction.transaction_date.desc())
        .limit(5)
        .all()
    )

    return transactions
