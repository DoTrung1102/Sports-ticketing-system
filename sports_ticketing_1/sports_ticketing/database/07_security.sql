-- =====================================================================
-- File: 07_security.sql
-- Purpose: User roles, phân quyền, mã hóa, backup
-- =====================================================================
USE sports_ticketing;

-- ---------------------------------------------------------------------
-- A. ROLES
-- ---------------------------------------------------------------------
DROP ROLE IF EXISTS 'role_admin', 'role_manager', 'role_cashier', 'role_readonly';

-- 1) ADMIN
CREATE ROLE 'role_admin';
GRANT ALL PRIVILEGES ON sports_ticketing.* TO 'role_admin';

-- 2) MANAGER - đọc all, sửa events/tickets/seats
CREATE ROLE 'role_manager';
GRANT SELECT, INSERT, UPDATE ON sports_ticketing.Events     TO 'role_manager';
GRANT SELECT, INSERT, UPDATE ON sports_ticketing.Tickets    TO 'role_manager';
GRANT SELECT, INSERT, UPDATE ON sports_ticketing.Seats      TO 'role_manager';
GRANT SELECT, INSERT, UPDATE ON sports_ticketing.BoxOffices TO 'role_manager';
GRANT SELECT ON sports_ticketing.Customers  TO 'role_manager';
GRANT SELECT ON sports_ticketing.v_revenue_by_event       TO 'role_manager';
GRANT SELECT ON sports_ticketing.v_seat_availability      TO 'role_manager';
GRANT SELECT ON sports_ticketing.v_sold_out_events        TO 'role_manager';
GRANT SELECT ON sports_ticketing.v_box_office_performance TO 'role_manager';
GRANT SELECT ON sports_ticketing.v_event_popularity       TO 'role_manager';
GRANT SELECT ON sports_ticketing.v_revenue_by_ticket_type TO 'role_manager';
GRANT EXECUTE ON PROCEDURE sports_ticketing.sp_revenue_summary TO 'role_manager';

-- 3) CASHIER - bán / hủy vé
CREATE ROLE 'role_cashier';
GRANT SELECT ON sports_ticketing.Events     TO 'role_cashier';
GRANT SELECT ON sports_ticketing.Tickets    TO 'role_cashier';
GRANT SELECT ON sports_ticketing.BoxOffices TO 'role_cashier';
GRANT SELECT, INSERT, UPDATE ON sports_ticketing.Customers TO 'role_cashier';
GRANT SELECT, UPDATE ON sports_ticketing.Seats             TO 'role_cashier';
GRANT EXECUTE ON PROCEDURE sports_ticketing.sp_book_ticket     TO 'role_cashier';
GRANT EXECUTE ON PROCEDURE sports_ticketing.sp_cancel_ticket   TO 'role_cashier';
GRANT EXECUTE ON PROCEDURE sports_ticketing.sp_search_events   TO 'role_cashier';
GRANT EXECUTE ON PROCEDURE sports_ticketing.sp_available_seats TO 'role_cashier';

-- 4) READONLY
CREATE ROLE 'role_readonly';
GRANT SELECT ON sports_ticketing.* TO 'role_readonly';

-- ---------------------------------------------------------------------
-- B. USERS
-- ---------------------------------------------------------------------
DROP USER IF EXISTS 'admin_user'@'localhost',
                   'manager_user'@'localhost',
                   'cashier_user'@'localhost',
                   'readonly_user'@'localhost';

CREATE USER 'admin_user'@'localhost'    IDENTIFIED BY 'Admin@2026!';
CREATE USER 'manager_user'@'localhost'  IDENTIFIED BY 'Manager@2026!';
CREATE USER 'cashier_user'@'localhost'  IDENTIFIED BY 'Cashier@2026!';
CREATE USER 'readonly_user'@'localhost' IDENTIFIED BY 'Readonly@2026!';

GRANT 'role_admin'    TO 'admin_user'@'localhost';
GRANT 'role_manager'  TO 'manager_user'@'localhost';
GRANT 'role_cashier'  TO 'cashier_user'@'localhost';
GRANT 'role_readonly' TO 'readonly_user'@'localhost';

SET DEFAULT ROLE 'role_admin'    TO 'admin_user'@'localhost';
SET DEFAULT ROLE 'role_manager'  TO 'manager_user'@'localhost';
SET DEFAULT ROLE 'role_cashier'  TO 'cashier_user'@'localhost';
SET DEFAULT ROLE 'role_readonly' TO 'readonly_user'@'localhost';

FLUSH PRIVILEGES;

-- ---------------------------------------------------------------------
-- C. MÃ HÓA DỮ LIỆU NHẠY CẢM (dùng AES_ENCRYPT khi cần)
-- ---------------------------------------------------------------------
-- Ví dụ tạo cột mã hóa cho số CCCD nếu cần (không sửa schema chính):
--   ALTER TABLE Customers ADD COLUMN IDNumberEnc VARBINARY(255);
--   UPDATE Customers SET IDNumberEnc =
--       AES_ENCRYPT('012345678901', UNHEX(SHA2('SECRET_KEY_2026',512)))
--    WHERE CustomerID=1;
--   SELECT CAST(AES_DECRYPT(IDNumberEnc,
--                           UNHEX(SHA2('SECRET_KEY_2026',512))) AS CHAR) AS ID
--     FROM Customers WHERE CustomerID=1;

-- ---------------------------------------------------------------------
-- D. BACKUP & RECOVERY (lệnh shell)
-- ---------------------------------------------------------------------
/*
  -- Backup hàng ngày:
  mysqldump -u admin_user -p --single-transaction \
    --routines --triggers --events \
    sports_ticketing > backup_$(date +%Y%m%d).sql

  -- Restore:
  mysql -u admin_user -p sports_ticketing < backup_20260101.sql

  -- Bật binary log để point-in-time recovery (my.cnf):
  [mysqld]
  log_bin   = /var/log/mysql/mysql-bin.log
  server_id = 1
*/
