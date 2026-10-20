# Location: app/core/security.py
import bcrypt

# ខ្មែរ: អនុគមន៍សម្រាប់បំប្លែងលេខសម្ងាត់ទៅជាកូដសម្ងាត់ (Hash)
def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

# ខ្មែរ: អនុគមន៍សម្រាប់ផ្ទៀងផ្ទាត់លេខសម្ងាត់ពេល Login
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))


# Password strength constants
MIN_PASSWORD_LENGTH = 8
STRONG_PASSWORD_LENGTH = 12

def check_password_strength(password: str) -> str:
    """Returns 'weak', 'medium', or 'strong' based on password complexity."""
    if len(password) < MIN_PASSWORD_LENGTH:
        return 'weak'
    has_upper = any(c.isupper() for c in password)
    has_digit = any(c.isdigit() for c in password)
    has_special = any(c in '!@#$%^&*()_+-=[]{}|;:,.<>?' for c in password)
    score = sum([has_upper, has_digit, has_special])
    if len(password) >= STRONG_PASSWORD_LENGTH and score >= 2:
        return 'strong'
    return 'medium' if score >= 1 else 'weak'