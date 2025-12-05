# app/utils.py
import os
from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timedelta
import uuid

# ================= Config =================
SECRET_KEY = os.environ.get("SECRET_KEY", "replace_this_secret_for_dev")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.environ.get("ACCESS_TOKEN_EXPIRE_MINUTES", 1440))

# ================= Password =================
# Chỉ dùng argon2
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

# ================= JWT =================
def create_access_token(subject: str, expires_minutes: int | None = None) -> dict:
    now = datetime.utcnow()
    expire = now + timedelta(minutes=(expires_minutes or ACCESS_TOKEN_EXPIRE_MINUTES))
    jti = str(uuid.uuid4())
    payload = {"sub": subject, "iat": now, "exp": expire, "jti": jti}
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return {"access_token": token, "jti": jti}
