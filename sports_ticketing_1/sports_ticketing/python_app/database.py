"""
database.py - Quản lý kết nối MySQL
Hỗ trợ context manager và connection pooling
"""
import mysql.connector
from mysql.connector import pooling, Error
from contextlib import contextmanager
import logging
from config import DB_CONFIG, POOL_SIZE

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger(__name__)


class Database:
    """Singleton quản lý connection pool tới MySQL."""

    _pool = None

    @classmethod
    def init_pool(cls):
        if cls._pool is None:
            try:
                cls._pool = pooling.MySQLConnectionPool(
                    pool_name="sports_pool",
                    pool_size=POOL_SIZE,
                    pool_reset_session=True,
                    **DB_CONFIG,
                )
                logger.info(f"MySQL pool initialized (size={POOL_SIZE})")
            except Error as e:
                logger.error(f"Không khởi tạo được pool: {e}")
                raise

    @classmethod
    @contextmanager
    def get_connection(cls):
        """Sử dụng:  with Database.get_connection() as conn:"""
        if cls._pool is None:
            cls.init_pool()
        conn = cls._pool.get_connection()
        try:
            yield conn
        finally:
            conn.close()  # trả về pool

    @classmethod
    @contextmanager
    def get_cursor(cls, dictionary=True, commit=False):
        """Sử dụng:  with Database.get_cursor() as cur:"""
        with cls.get_connection() as conn:
            cur = conn.cursor(dictionary=dictionary)
            try:
                yield cur
                if commit:
                    conn.commit()
            except Error as e:
                conn.rollback()
                logger.error(f"DB error - rolled back: {e}")
                raise
            finally:
                cur.close()

    # ------------------------------------------------------------------
    # Helper functions
    # ------------------------------------------------------------------
    @classmethod
    def execute(cls, query, params=None, commit=False):
        with cls.get_cursor(commit=commit) as cur:
            cur.execute(query, params or ())
            return cur.lastrowid

    @classmethod
    def fetch_one(cls, query, params=None):
        with cls.get_cursor() as cur:
            cur.execute(query, params or ())
            return cur.fetchone()

    @classmethod
    def fetch_all(cls, query, params=None):
        with cls.get_cursor() as cur:
            cur.execute(query, params or ())
            return cur.fetchall()

    @classmethod
    def call_proc(cls, proc_name, params=None):
        """Gọi stored procedure - trả về OUT params + result sets."""
        with cls.get_connection() as conn:
            cur = conn.cursor(dictionary=True)
            try:
                out_args = cur.callproc(proc_name, params or [])
                # Lấy tất cả result set (nếu có)
                results = []
                for result in cur.stored_results():
                    results.append(result.fetchall())
                conn.commit()
                return {"out": out_args, "results": results}
            except Error as e:
                conn.rollback()
                logger.error(f"Lỗi gọi {proc_name}: {e}")
                raise
            finally:
                cur.close()


# ----------------------------------------------------------------------
# Test kết nối khi chạy file trực tiếp
# ----------------------------------------------------------------------
if __name__ == "__main__":
    try:
        Database.init_pool()
        row = Database.fetch_one("SELECT VERSION() AS version, NOW() AS now")
        print(f"✓ Đã kết nối MySQL {row['version']} - {row['now']}")

        tables = Database.fetch_all("SHOW TABLES")
        print(f"✓ Số bảng trong DB: {len(tables)}")
        for t in tables:
            print(f"  - {list(t.values())[0]}")
    except Exception as e:
        print(f"✗ Lỗi: {e}")
