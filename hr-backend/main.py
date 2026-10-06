from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import models
from database import engine
from routers import employee
from routers import employee, auth

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="HR System API")
app.include_router(employee.router)
app.include_router(auth.router)
# Allow Flutter to connect (CORS)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allows all origins during development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include the employee API routes
app.include_router(employee.router)

@app.get("/")
def read_root():
    return {"message": "HR Backend is running perfectly!"}