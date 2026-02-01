"""
Xác thực: hash mật khẩu (Werkzeug), JWT token 12h.
"""
import time
from datetime import datetime, timedelta, timezone

import jwt
from flask import request
from werkzeug.security import check_password_hash, generate_password_hash

from .config import Config


# --- Mật khẩu ---
def hash_password(password: str) -> str:
    return generate_password_hash(password, method="pbkdf2:sha256")


def verify_password(password: str, password_hash: str) -> bool:
    return bool(password_hash and check_password_hash(password_hash, password))


# --- JWT ---
def create_token(user_id: int, phone: str) -> str:
    now = datetime.now(timezone.utc)
    expire = now + timedelta(hours=Config.JWT_EXPIRY_HOURS)
    payload = {
        "sub": user_id,
        "phone": phone,
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
    }
    return jwt.encode(
        payload,
        Config.JWT_SECRET_KEY,
        algorithm="HS256",
    )


def decode_token(token: str) -> dict | None:
    try:
        return jwt.decode(
            token,
            Config.JWT_SECRET_KEY,
            algorithms=["HS256"],
        )
    except jwt.InvalidTokenError:
        return None


def get_token_from_request() -> str | None:
    auth = request.headers.get("Authorization")
    if auth and auth.startswith("Bearer "):
        return auth[7:].strip()
    return None


def get_current_user_id() -> int | None:
    token = get_token_from_request()
    if not token:
        return None
    payload = decode_token(token)
    if not payload or "sub" not in payload:
        return None
    return int(payload["sub"])
