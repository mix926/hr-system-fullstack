# Location: app/core/security.py
import bcrypt

# ខ្មែរ: អនុគមន៍សម្រាប់បំប្លែងលេខសម្ងាត់ទៅជាកូដសម្ងាត់ (Hash)
def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

# ខ្មែរ: អនុគមន៍សម្រាប់ផ្ទៀងផ្ទាត់លេខសម្ងាត់ពេល Login
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))