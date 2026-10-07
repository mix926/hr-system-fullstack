# Location: app/seed.py

# ខ្មែរ: ទាញយកពីទីតាំងថ្មីនៅក្នុង Clean Architecture
from app.core.database import SessionLocal
from app.repositories import crud
from app.schemas import schemas
from app.models.models import RoleEnum

def create_super_admin():
    db = SessionLocal()
    try:
        admin_email = "admin@company.com"
        
        # ១. ពិនិត្យមើលថាតើមាន admin នៅក្នុង Database រួចហើយឬនៅ
        existing_admin = crud.get_employee_by_email(db, email=admin_email)
        if existing_admin:
            print(f"⚠️ Admin account ({admin_email}) already exists!")
            return

        # ២. រៀបចំទិន្នន័យសម្រាប់គណនី admin ដោយប្រើ Enum ផ្ទាល់
        admin_data = schemas.EmployeeCreate(
            first_name="Super",
            last_name="Admin",
            email=admin_email,
            password="adminpassword123", # ខ្មែរ: កុំភ្លេចប្តូរវាទៅជាលេខសម្ងាត់ដែលមានសុវត្ថិភាព
            position="System Administrator",
            
            # ខ្មែរ: ប្រើប្រាស់ RoleEnum.ADMIN ជំនួសអោយ String "admin" ធម្មតា
            role=RoleEnum.ADMIN 
        )
        
        # ៣. រក្សាទុកក្នុង Database
        crud.create_employee(db=db, employee=admin_data)
        print(f"✅ Success! Super Admin created with email: {admin_email}")
        
    except Exception as e:
        print(f"❌ Error creating admin: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    print("Starting database seeding process...")
    create_super_admin()