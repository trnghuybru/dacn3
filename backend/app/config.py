import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


class Config:
    DB_HOST = os.getenv("DB_HOST")
    DB_PORT = int(os.getenv("DB_PORT", 3306))
    DB_USER = os.getenv("DB_USER")
    DB_PASSWORD = os.getenv("DB_PASSWORD")
    DB_NAME = os.getenv("DB_NAME")
    
    # Xử lý đường dẫn SSL CA (đối chiếu từ BASE_DIR nếu là path tương đối)
    _ca_path = os.getenv("DB_SSL_CA")
    DB_SSL_CA = str(BASE_DIR / _ca_path) if _ca_path and not Path(_ca_path).is_absolute() else _ca_path
    DB_SSL_VERIFY = os.getenv("DB_SSL_VERIFY", "true").lower() in ("true", "1")

    # Flask & JWT
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret")
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", SECRET_KEY)
    JWT_EXPIRY_HOURS = float(os.getenv("JWT_EXPIRY_HOURS", 12))

print("DB_HOST:", Config.DB_HOST)
print("DB_USER:", Config.DB_USER)