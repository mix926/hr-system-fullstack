from database import SessionLocal
import crud
import schemas

def create_super_admin():
    db = SessionLocal()
    try:
        admin_email = "admin@company.com"
        
        # 1. Check if admin is already in the database
        # ១. ពិនិត្យមើលថាតើមាន admin នៅក្នុង Database រួចហើយឬនៅ
        existing_admin = crud.get_employee_by_email(db, email=admin_email)
        if existing_admin:
            print(f"⚠️  Admin account ({admin_email}) already exists!")
            return

        # 2. Prepare the admin data
        # ២. រៀបចំទិន្នន័យសម្រាប់គណនី admin
        admin_data = schemas.EmployeeCreate(
            first_name="Super",
            last_name="Admin",
            email=admin_email,
            password="adminpassword123", # Change this to a secure password / ប្តូរវាទៅជាលេខសម្ងាត់ដែលមានសុវត្ថិភាព
            position="System Administrator"
        )
        
        # 3. Force the role to be 'admin'
      
        admin_data.role = "admin"
        
        # 4. Save directly to the database
        
        crud.create_employee(db=db, employee=admin_data)
        print(f"✅ Success! Super Admin created with email: {admin_email}")
        
    except Exception as e:
        print(f"❌ Error creating admin: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    print("Starting database seeding process...")
    create_super_admin()