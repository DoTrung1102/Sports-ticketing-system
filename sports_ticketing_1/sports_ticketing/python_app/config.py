"""
config.py - Cấu hình kết nối database
Đọc từ biến môi trường hoặc dùng giá trị mặc định
"""
import os
from dotenv import load_dotenv

load_dotenv()  # Đọc file .env nếu có

# ---------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------
DB_CONFIG = {
    "host":     "localhost",
    "port":     "3306",
    "user":      "root",
    "password": "2026SQLneu",
    "database":  "sports_ticketing",
    "charset":  "utf8mb4",
    "use_unicode": True,
    "autocommit": False,
}

# ---------------------------------------------------------------------
# Encryption - khóa cho AES_ENCRYPT/AES_DECRYPT
# ---------------------------------------------------------------------
ENCRYPTION_KEY = os.getenv("ENCRYPTION_KEY", "SECRET_KEY_2026_CHANGE_ME")

# ---------------------------------------------------------------------
# Pool size cho SQLAlchemy (nếu dùng)
# ---------------------------------------------------------------------
POOL_SIZE     = int(os.getenv("DB_POOL_SIZE", "5"))
POOL_TIMEOUT  = int(os.getenv("DB_POOL_TIMEOUT", "30"))

# ---------------------------------------------------------------------
# Ứng dụng
# ---------------------------------------------------------------------
APP_NAME    = "Sports Ticketing Management System"
APP_VERSION = "1.0.0"
DATE_FMT    = "%Y-%m-%d"
DATETIME_FMT = "%Y-%m-%d %H:%M:%S"
