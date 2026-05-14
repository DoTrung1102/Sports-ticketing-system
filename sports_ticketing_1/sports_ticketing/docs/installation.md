# Hướng dẫn cài đặt chi tiết

## 1. Yêu cầu hệ thống

| Component | Phiên bản | Ghi chú |
|---|---|---|
| MySQL Server | 8.0+ | Roles cần MySQL 8.0+ |
| Python | 3.10+ | Khuyến nghị 3.11 |
| OS | Windows / Linux / macOS | |
| RAM | 4 GB+ | |
| Disk | 500 MB | Cho DB + dependencies |

## 2. Cài đặt MySQL Server

### Windows
1. Tải MySQL Installer: https://dev.mysql.com/downloads/installer/
2. Chọn "Server Only" hoặc "Developer Default"
3. Cấu hình:
   - Port: 3306
   - Authentication: "Use Strong Password Encryption"
   - Đặt password cho user `root`
4. Sau cài đặt, mở MySQL Workbench để test connection

### Ubuntu / Debian
```bash
sudo apt update
sudo apt install mysql-server
sudo systemctl start mysql
sudo mysql_secure_installation
```

### macOS
```bash
brew install mysql
brew services start mysql
mysql_secure_installation
```

## 3. Test MySQL hoạt động

```bash
mysql -u root -p
# Nhập password
mysql> SELECT VERSION();
# Kết quả mong đợi: 8.0.x hoặc cao hơn
```

## 4. Cài đặt database

```bash
cd database/

# Cách 1: chạy từng file
mysql -u root -p < 01_schema.sql
mysql -u root -p < 02_sample_data.sql
mysql -u root -p < 03_views.sql
mysql -u root -p < 04_procedures.sql
mysql -u root -p < 05_functions.sql
mysql -u root -p < 06_triggers.sql
mysql -u root -p < 07_security.sql

# Cách 2: chạy 1 lệnh
cat *.sql | mysql -u root -p
```

### Xác minh

```sql
USE sports_ticketing;
SHOW TABLES;
-- Kết quả: 7 bảng (6 main + SalesAuditLog)

SHOW PROCEDURE STATUS WHERE Db='sports_ticketing';
-- Kết quả: 5 procedures

SHOW FUNCTION STATUS WHERE Db='sports_ticketing';
-- Kết quả: 5 functions

SHOW TRIGGERS;
-- Kết quả: 5 triggers
```

## 5. Cài đặt môi trường Python

### Tạo virtual environment

```bash
cd python_app/

# Tạo venv
python -m venv venv

# Kích hoạt (Linux/macOS)
source venv/bin/activate

# Kích hoạt (Windows PowerShell)
venv\Scripts\Activate.ps1

# Kích hoạt (Windows CMD)
venv\Scripts\activate.bat
```

### Cài thư viện

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### Test kết nối

```bash
# Đảm bảo đã copy .env.example thành .env và sửa password
cp .env.example .env
nano .env       # hoặc notepad .env

# Chạy thử
python database.py
# Output mong đợi:
# ✓ Đã kết nối MySQL 8.0.x - 2026-...
# ✓ Số bảng trong DB: 7
```

## 6. Khởi chạy ứng dụng

```bash
python main.py
```

Menu chính sẽ hiện ra. Sử dụng các phím số để điều hướng.

## 7. (Tùy chọn) Sinh dữ liệu lớn

Mặc định file `02_sample_data.sql` chỉ chèn 10 dòng/bảng. Để sinh thêm dữ liệu lớn:

```bash
python data_generator.py
# Kết quả: ~50 events, 500 customers, 3000 seats, 600 sales
```

Có thể chỉnh số lượng trong file `data_generator.py`:
```python
N_EVENTS    = 50
N_CUSTOMERS = 500
SEATS_PER_EVENT = 60
SALES_TARGET    = 600
```

## 8. Khắc phục sự cố thường gặp

### Lỗi: "Access denied for user 'root'@'localhost'"
→ Kiểm tra password trong `.env`. Đảm bảo dùng đúng password của MySQL.

### Lỗi: "Can't connect to MySQL server"
→ Kiểm tra MySQL service đã chạy:
```bash
# Linux
sudo systemctl status mysql

# macOS
brew services list

# Windows
services.msc → tìm "MySQL80"
```

### Lỗi: "Unknown database 'sports_ticketing'"
→ Chạy lại `01_schema.sql` (file sẽ tự `DROP DATABASE IF EXISTS` rồi `CREATE`)

### Lỗi: "Trigger does not exist" khi gọi procedure
→ Chạy lại tất cả file SQL theo thứ tự 01 → 07

### Lỗi Python: "ModuleNotFoundError"
→ Quên activate venv. Chạy lại:
```bash
source venv/bin/activate
pip install -r requirements.txt
```

### Lỗi: "Encryption keys mismatch"
→ Đảm bảo `ENCRYPTION_KEY` trong `.env` không đổi giữa các lần encrypt/decrypt.

## 9. Backup & Restore

### Backup
```bash
mysqldump -u root -p \
    --single-transaction --routines --triggers --events \
    sports_ticketing > backup_$(date +%Y%m%d).sql
```

### Restore
```bash
mysql -u root -p sports_ticketing < backup_20260101.sql
```

### Tự động hóa (Linux cron)
```bash
crontab -e
# Thêm dòng:
0 2 * * * /usr/bin/mysqldump -u root -p'password' --single-transaction \
    sports_ticketing > /var/backups/sports_$(date +\%Y\%m\%d).sql
```
