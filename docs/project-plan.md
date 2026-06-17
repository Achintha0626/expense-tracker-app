# Expense Tracker Application

## Project Overview

A personal expense tracking mobile application built using Flutter and FastAPI.

Users can:
- Register and login
- Track income and expenses
- View transaction history
- Monitor monthly spending
- View financial summaries and charts

---

## Technology Stack

### Frontend
- Flutter
- Dart

### Backend
- Python
- FastAPI

### Database
- PostgreSQL (Neon)

### Authentication
- JWT Authentication
- Password Hashing (bcrypt)

### Deployment
- Backend: Render
- Database: Neon
- Mobile: Android APK

---

## Database Schema

### users

| Column | Type |
|----------|----------|
| id | Integer |
| name | String |
| email | String |
| password | String |
| created_at | DateTime |

### categories

| Column | Type |
|----------|----------|
| id | Integer |
| name | String |
| type | String |

### transactions

| Column | Type |
|----------|----------|
| id | Integer |
| user_id | Integer |
| category_id | Integer |
| amount | Float |
| description | String |
| transaction_type | String |
| transaction_date | DateTime |
| created_at | DateTime |

---

## API Endpoints

### Authentication

POST /auth/register

POST /auth/login

### Transactions

POST /transactions

GET /transactions

PUT /transactions/{id}

DELETE /transactions/{id}

### Dashboard

GET /dashboard/summary

GET /dashboard/monthly

GET /dashboard/categories

---

## Current Progress

### Completed

- [x] Project setup
- [x] FastAPI setup
- [x] PostgreSQL connection
- [x] User model
- [x] User registration

### In Progress

- [ ] JWT Login
- [ ] Protected Routes

### Pending

- [ ] Categories
- [ ] Transactions
- [ ] Dashboard
- [ ] Flutter UI
- [ ] Deployment
