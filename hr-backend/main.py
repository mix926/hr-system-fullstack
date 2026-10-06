from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import models
from database import engine
from routers import employee, auth

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="HR System API")

# CORS must be added BEFORE routers / CORS ត្រូវបញ្ចូលមុនពេល routers
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins during development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers (each only once!) / បញ្ចូល router ម្តងប៉ុណ្ណោះ
app.include_router(auth.router)
app.include_router(employee.router)


@app.get("/")
def read_root():
    return {"message": "HR Backend is running perfectly!"}
