import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from dotenv import load_dotenv

# ខ្មែរ: ទាញយកការកំណត់និងលេខសម្ងាត់ពីឯកសារ .env ដែលនៅខាងក្រៅ
load_dotenv()

# ខ្មែរ: ទាញយក URL ដោយសុវត្ថិភាព
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(SQLALCHEMY_DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()