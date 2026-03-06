import pymysql
from pymysql.cursors import DictCursor
from .config import Config

def get_connection():
    """Tạo kết nối database gọn gàng."""
    return pymysql.connect(
        host=Config.DB_HOST,
        port=Config.DB_PORT,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        database=Config.DB_NAME,
        charset="utf8mb4",
        cursorclass=DictCursor,
        ssl={"ca": Config.DB_SSL_CA} if Config.DB_SSL_CA and Config.DB_SSL_VERIFY else None
    )

def get_cursor(connection=None):
    if connection:
        return connection.cursor()
    conn = get_connection()
    return conn, conn.cursor()
