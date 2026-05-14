"""
main.py - Điểm khởi chạy ứng dụng
Chạy: python main.py
"""
import sys
from database import Database
from ui import main_menu
from config import APP_NAME


def main():
    print(f"\n Đang khởi động {APP_NAME}...")
    try:
        Database.init_pool()
        row = Database.fetch_one("SELECT VERSION() AS v")
        print(f"✓ Kết nối MySQL {row['v']} thành công\n")
    except Exception as e:
        print(f"\n✗ Không kết nối được database: {e}")
        print("Kiểm tra config.py / biến môi trường DB_*")
        sys.exit(1)

    try:
        main_menu()
    except KeyboardInterrupt:
        print("\n\nĐã thoát bằng Ctrl+C")
    except Exception as e:
        print(f"\n✗ Lỗi không xử lý được: {e}")
        import traceback; traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
