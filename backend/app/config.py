import os
from pathlib import Path

from dotenv import load_dotenv

# Load .env từ thư mục backend (parent của app)
_env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(_env_path)


class Config:
    """Cấu hình ứng dụng từ biến môi trường."""

    # Database (Aiven – trùng với .env / thông tin server)
    DB_HOST = os.getenv("DB_HOST", "dacn3-db-dangcongnhat2004qb-39ad.k.aivencloud.com")
    DB_PORT = int(os.getenv("DB_PORT", "26028"))
    DB_USER = os.getenv("DB_USER", "avnadmin")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")  # luôn đặt trong .env, không để mặc định trong code
    DB_NAME = os.getenv("DB_NAME", "disaster_response")
    DB_SSL_CA = os.getenv("DB_SSL_CA", "ca.pem")  # hoặc "db/ca.pem" nếu đặt cert trong backend/db/
    DB_SSL_VERIFY = os.getenv("DB_SSL_VERIFY", "true").lower() in ("true", "1", "yes")

    # Flask
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-key")
    DEBUG = os.getenv("FLASK_ENV", "development") == "development"

    # JWT (token 12h)
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", SECRET_KEY)
    JWT_EXPIRY_HOURS = float(os.getenv("JWT_EXPIRY_HOURS", "12"))
