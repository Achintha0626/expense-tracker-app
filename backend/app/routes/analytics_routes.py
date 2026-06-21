from datetime import date, datetime, time

from fastapi import APIRouter, Depends, Query
from sqlalchemy import case, func
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import Transaction, User
from app.schemas import CategoryBreakdownItem, MonthlySummaryItem

router = APIRouter(
    prefix="/analytics",
    tags=["Analytics"]
)


def _apply_date_filters(query, start_date: date | None, end_date: date | None, user_id: int):
    query = query.filter(Transaction.user_id == user_id)

    if start_date is not None:
        query = query.filter(Transaction.transaction_date >= datetime.combine(start_date, time.min))
    if end_date is not None:
        query = query.filter(Transaction.transaction_date <= datetime.combine(end_date, time.max))

    return query


@router.get("/category-breakdown", response_model=list[CategoryBreakdownItem])
def category_breakdown(
    start_date: date | None = Query(None, description="Filter transactions on or after this date (YYYY-MM-DD)"),
    end_date: date | None = Query(None, description="Filter transactions on or before this date (YYYY-MM-DD)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(
        Transaction.category.label("category"),
        func.coalesce(func.sum(Transaction.amount), 0.0).label("amount"),
    )
    query = _apply_date_filters(query, start_date, end_date, current_user.id)
    query = query.filter(Transaction.transaction_type == "expense")
    results = query.group_by(Transaction.category).order_by(func.sum(Transaction.amount).desc()).all()

    return [
        {
            "category": row.category,
            "amount": float(row.amount),
        }
        for row in results
    ]


@router.get("/monthly-summary", response_model=list[MonthlySummaryItem])
def monthly_summary(
    start_date: date | None = Query(None, description="Filter transactions on or after this date (YYYY-MM-DD)"),
    end_date: date | None = Query(None, description="Filter transactions on or before this date (YYYY-MM-DD)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    month_label = func.to_char(Transaction.transaction_date, "YYYY-MM").label("month")
    income_amount = func.coalesce(
        func.sum(
            case(
                (Transaction.transaction_type == "income", Transaction.amount),
                else_=0.0,
            )
        ),
        0.0,
    ).label("income")
    expense_amount = func.coalesce(
        func.sum(
            case(
                (Transaction.transaction_type == "expense", Transaction.amount),
                else_=0.0,
            )
        ),
        0.0,
    ).label("expense")

    query = db.query(month_label, income_amount, expense_amount)
    query = _apply_date_filters(query, start_date, end_date, current_user.id)
    results = query.group_by(month_label).order_by(month_label).all()

    return [
        {
            "month": row.month,
            "income": float(row.income),
            "expense": float(row.expense),
        }
        for row in results
    ]
