from datetime import datetime
from io import BytesIO
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib import colors
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import User, Transaction

router = APIRouter(
    prefix="/reports",
    tags=["Reports"]
)


@router.get("/pdf")
def generate_pdf_report(
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate a PDF report of user's transactions.
    
    Query Parameters:
    - start_date: Optional start date in YYYY-MM-DD format
    - end_date: Optional end date in YYYY-MM-DD format
    """
    
    # Parse dates if provided
    start_dt = None
    end_dt = None
    
    if start_date:
        try:
            start_dt = datetime.strptime(start_date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid start_date format. Use YYYY-MM-DD")
    
    if end_date:
        try:
            end_dt = datetime.strptime(end_date, "%Y-%m-%d")
            # Set end_dt to end of day
            end_dt = end_dt.replace(hour=23, minute=59, second=59)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid end_date format. Use YYYY-MM-DD")
    
    # Query transactions for current user
    query = db.query(Transaction).filter(Transaction.user_id == current_user.id)
    
    if start_dt:
        query = query.filter(Transaction.transaction_date >= start_dt)
    if end_dt:
        query = query.filter(Transaction.transaction_date <= end_dt)
    
    transactions = query.order_by(Transaction.transaction_date.desc()).all()
    
    # Calculate summaries
    total_income = sum(t.amount for t in transactions if t.transaction_type.lower() == "income")
    total_expense = sum(t.amount for t in transactions if t.transaction_type.lower() == "expense")
    balance = total_income - total_expense
    transaction_count = len(transactions)
    
    # Separate income and expense transactions
    income_transactions = [t for t in transactions if t.transaction_type.lower() == "income"]
    expense_transactions = [t for t in transactions if t.transaction_type.lower() == "expense"]
    
    # Calculate category spending summary
    category_spending = {}
    for t in expense_transactions:
        if t.category not in category_spending:
            category_spending[t.category] = 0
        category_spending[t.category] += t.amount
    
    # Calculate sub-category spending summary
    subcategory_spending = {}
    for t in expense_transactions:
        if t.sub_category:
            key = (t.category, t.sub_category)
            if key not in subcategory_spending:
                subcategory_spending[key] = 0
            subcategory_spending[key] += t.amount
    
    # Create PDF
    pdf_buffer = BytesIO()
    doc = SimpleDocTemplate(pdf_buffer, pagesize=letter)
    story = []
    
    # Define styles
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=colors.HexColor('#1a1a1a'),
        spaceAfter=12,
        alignment=1  # Center alignment
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#333333'),
        spaceAfter=8,
        spaceBefore=12
    )
    
    normal_style = styles['Normal']
    
    # 1. Report Title
    story.append(Paragraph("Expense Tracker Report", title_style))
    story.append(Spacer(1, 0.2*inch))
    
    # 2. Date Range and User Info
    if start_dt and end_dt:
        date_range_text = f"Period: {start_dt.strftime('%B %d, %Y')} to {end_dt.strftime('%B %d, %Y')}"
    elif start_dt:
        date_range_text = f"From: {start_dt.strftime('%B %d, %Y')}"
    elif end_dt:
        date_range_text = f"Until: {end_dt.strftime('%B %d, %Y')}"
    else:
        date_range_text = "Full Period"
    
    story.append(Paragraph(f"<b>{date_range_text}</b>", normal_style))
    story.append(Paragraph(f"User: {current_user.name} ({current_user.email})", normal_style))
    story.append(Paragraph(f"Generated: {datetime.now().strftime('%B %d, %Y at %I:%M %p')}", normal_style))
    story.append(Spacer(1, 0.3*inch))
    
    # 3. Summary Section
    story.append(Paragraph("Financial Summary", heading_style))
    
    summary_data = [
        ["Metric", "Amount"],
        ["Total Income", f"Rs. {total_income:,.2f}"],
        ["Total Expense", f"Rs. {total_expense:,.2f}"],
        ["Balance", f"Rs. {balance:,.2f}"],
        ["Total Transactions", str(transaction_count)]
    ]
    
    summary_table = Table(summary_data, colWidths=[3*inch, 2*inch])
    summary_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#4CAF50')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 12),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
        ('GRID', (0, 0), (-1, -1), 1, colors.black),
        ('FONTSIZE', (0, 1), (-1, -1), 10),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f0f0f0')])
    ]))
    story.append(summary_table)
    story.append(Spacer(1, 0.3*inch))
    
    # 4. Income Section
    if income_transactions:
        story.append(Paragraph("Income Transactions", heading_style))
        
        income_data = [["Date", "Title", "Category", "Amount"]]
        for t in income_transactions:
            income_data.append([
                t.transaction_date.strftime('%m/%d/%Y'),
                t.title[:30],
                t.category,
                f"Rs. {t.amount:,.2f}"
            ])
        
        income_table = Table(income_data, colWidths=[1.2*inch, 2*inch, 1.5*inch, 1*inch])
        income_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2196F3')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('ALIGN', (3, 0), (3, -1), 'RIGHT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 10),
            ('GRID', (0, 0), (-1, -1), 1, colors.grey),
            ('FONTSIZE', (0, 1), (-1, -1), 9),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#e3f2fd')])
        ]))
        story.append(income_table)
        story.append(Spacer(1, 0.3*inch))
    
    # 5. Expense Section
    if expense_transactions:
        story.append(Paragraph("Expense Transactions", heading_style))
        
        expense_data = [["Date", "Title", "Category", "Amount"]]
        for t in expense_transactions:
            expense_data.append([
                t.transaction_date.strftime('%m/%d/%Y'),
                t.title[:30],
                t.category,
                f"Rs. {t.amount:,.2f}"
            ])
        
        expense_table = Table(expense_data, colWidths=[1.2*inch, 2*inch, 1.5*inch, 1*inch])
        expense_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#F44336')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('ALIGN', (3, 0), (3, -1), 'RIGHT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 10),
            ('GRID', (0, 0), (-1, -1), 1, colors.grey),
            ('FONTSIZE', (0, 1), (-1, -1), 9),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#ffebee')])
        ]))
        story.append(expense_table)
        story.append(Spacer(1, 0.3*inch))
    
    # Add page break before detailed summaries
    story.append(PageBreak())
    
    # 6. Category Spending Summary
    if category_spending:
        story.append(Paragraph("Category Spending Summary", heading_style))
        # For each category, show total then list sub-categories (expenses only)
        for category, amount in sorted(category_spending.items(), key=lambda x: x[1], reverse=True):
            story.append(Paragraph(category, ParagraphStyle('cat', parent=styles['Heading3'], spaceBefore=8)))
            story.append(Paragraph(f"Total: Rs. {amount:,.2f}", normal_style))

            # Find sub-categories for this category
            subs = [
                (sub, val)
                for (cat, sub), val in subcategory_spending.items()
                if cat == category
            ]

            if subs:
                # Build a simple two-column table for sub-categories
                sub_rows = [["Sub-Category", "Amount"]]
                for sub, val in sorted(subs, key=lambda x: x[1], reverse=True):
                    sub_rows.append([f"  - {sub}", f"Rs. {val:,.2f}"])

                sub_table = Table(sub_rows, colWidths=[3*inch, 2*inch])
                sub_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E0E0E0')),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.black),
                    ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                    ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 9),
                    ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
                    ('FONTSIZE', (0, 1), (-1, -1), 9),
                ]))
                story.append(sub_table)
            else:
                story.append(Paragraph("No sub-categories", normal_style))

            story.append(Spacer(1, 0.15*inch))
    
    # Removed separate Sub-Category Spending Summary per requirements.
    
    # 8. Full Transaction Table
    if transactions:
        story.append(PageBreak())
        story.append(Paragraph("All Transactions", heading_style))
        
        full_data = [["Date", "Title", "Type", "Category", "Sub-Category", "Amount", "Description"]]
        for t in transactions:
            full_data.append([
                t.transaction_date.strftime('%m/%d/%Y'),
                t.title[:25],
                t.transaction_type,
                t.category,
                t.sub_category or "-",
                f"Rs. {t.amount:,.2f}",
                (t.description or "-")[:20]
            ])
        
        full_table = Table(full_data, colWidths=[0.9*inch, 1.2*inch, 0.8*inch, 1*inch, 1*inch, 0.9*inch, 1.2*inch])
        full_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#607D8B')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('ALIGN', (5, 0), (5, -1), 'RIGHT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 9),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
            ('FONTSIZE', (0, 1), (-1, -1), 8),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')])
        ]))
        story.append(full_table)
    
    # Build PDF
    doc.build(story)
    pdf_buffer.seek(0)
    
    # Return PDF as downloadable file
    return StreamingResponse(
        iter([pdf_buffer.getvalue()]),
        media_type="application/pdf",
        headers={"Content-Disposition": "attachment; filename=expense_report.pdf"}
    )
