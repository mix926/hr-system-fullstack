# HR System Backend

Enterprise-grade REST API built with FastAPI and SQLAlchemy.

## Tech Stack
- **FastAPI** — Modern Python web framework
- **SQLAlchemy** — ORM for database operations
- **JWT** — Secure authentication
- **bcrypt** — Password hashing
- **Pydantic v2** — Data validation

## Features
- Employee management (CRUD)
- Department management
- Leave request system with approval workflow
- Attendance tracking (check-in/check-out)
- Performance review system
- Role-based access control (ADMIN, MANAGER, STAFF)

## Setup
```bash
cd hr-backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## API Docs
Once running, visit: http://127.0.0.1:8000/docs

## Environment Variables
Create a `.env` file:
```
DATABASE_URL=sqlite:///./hr.db
```
