"""
Module kết nối database MySQL với SSL (Aiven).
Cấu hình đọc từ biến môi trường qua Config.
"""
import os
from pathlib import Path

import pymysql
from pymysql.cursors import DictCursor

from .config import Config


def _ssl_ca_path() -> str | None:
    """Đường dẫn tuyệt đối tới file CA (PEM). Path tương đối so với thư mục backend."""
    raw = getattr(Config, "DB_SSL_CA", None) or os.getenv("DB_SSL_CA")
    if not raw:
        return None
    base = Path(__file__).resolve().parent.parent
    path = (base / raw).resolve()
    return str(path) if path.exists() else None


def get_connection():
    """
    Tạo kết nối MySQL với SSL.
    Trả về connection (pymysql). Nhớ đóng connection khi dùng xong.
    """
    ssl_ca = _ssl_ca_path()
    ssl_verify = getattr(Config, "DB_SSL_VERIFY", True)

    connect_kwargs = {
        "host": Config.DB_HOST,
        "port": Config.DB_PORT,
        "user": Config.DB_USER,
        "password": Config.DB_PASSWORD,
        "database": Config.DB_NAME,
        "cursorclass": DictCursor,
        "charset": "utf8mb4",
    }

    if ssl_ca and ssl_verify:
        connect_kwargs["ssl"] = {"ca": ssl_ca}

    return pymysql.connect(**connect_kwargs)


def get_cursor(connection=None):
    """
    Trả về cursor. Nếu không truyền connection thì tạo mới (và caller cần đóng connection).
    """
    if connection is not None:
        return connection.cursor()
    conn = get_connection()
    return conn, conn.cursor()
