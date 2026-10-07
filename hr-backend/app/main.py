# Location: app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# ខ្មែរ: ទាញយកពីទីតាំងថ្មីដោយប្រើ Absolute Imports (ចាប់ផ្តើមដោយពាក្យ app)
from app.models.models import Base
from app.core.database import engine
from app.api import employee, auth

# ខ្មែរ: បង្កើតតារាងក្នុង Database (នៅកម្រិតកំពូលគេប្រើ Alembic migrations, តែយើងប្រើវិធីនេះសិន)
Base.metadata.create_all(bind=engine)

# ខ្មែរ: កំណត់ឈ្មោះនិង Version របស់ API ឱ្យបានច្បាស់លាស់
app = FastAPI(
    title="Enterprise HR System API",
    version="1.0.0",
    description="Advanced Clean Architecture backend for Flutter HR App"
)

# ខ្មែរ: កំណត់ CORS Middleware
app.add_middleware(
    CORSMiddleware,
    # ខ្មែរ: ចំណាំ៖ ពេលដាក់ឱ្យប្រើប្រាស់ពិតប្រាកដ (Production) អ្នកត្រូវដូរ "*" ទៅជា Domain App របស់អ្នក
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ខ្មែរ: បញ្ចូល Routers ព្រមទាំងបន្ថែម Prefix /api/v1 និង Tags សម្រាប់រៀបចំឯកសារ Swagger UI
app.include_router(auth.router, prefix="/api/v1", tags=["Authentication"])
app.include_router(employee.router, prefix="/api/v1", tags=["Employees"])

# ខ្មែរ: Health Check Endpoint សម្រាប់អោយ Server (ដូចជា AWS/Docker) ឆែកមើលថា App នៅរស់ឬអត់
@app.get("/", tags=["Health Check"])
def read_root():
    return {
        "status": "success",
        "message": "HR Backend Version 1.0.0 is running perfectly!"
    }