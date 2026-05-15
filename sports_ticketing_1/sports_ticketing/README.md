 PROJECT 16 — SPORTS TICKETING MANAGEMENT SYSTEM

> Final project, NEU-College of Technology
> **Tech stack:** MySQL 8.0+, Python 3.10+
---

## 📐 MÔ HÌNH 5 BẢNG

| # | Bảng | Vai trò |
|---|---|---|
| 1 | **Events** | Sự kiện (EventID, EventName, EventDate, Venue, Sport, Status) |
| 2 | **Tickets** | Loại vé + giá theo sự kiện (TicketID, EventID, TicketType, Price, Quantity, SoldQuantity) |
| 3 | **Customers** | Khách hàng (CustomerID, CustomerName, PhoneNumber, Address) |
| 4 | **BoxOffices** | Phòng vé (BoxOfficeID, OfficeName, Address) |
| 5 | **Seats** | **Vừa là ghế, vừa là bản ghi bán vé** — khi ghế được bán, các cột Customer/BoxOffice/SaleDate/PaymentMethod/Amount được điền |

### Tại sao Seats kiêm vai trò bán vé?

Đề bài yêu cầu đúng 5 bảng, nhưng vẫn cần lưu thông tin "ai đã mua ghế nào, ở phòng vé nào, lúc nào, bao nhiêu tiền". Giải pháp: **mở rộng cột trong Seats** để mỗi dòng ghế cũng là một bản ghi giao dịch khi `Status='Sold'`.

```
Seats:
  Cột định danh:  SeatID, EventID, SeatNumber, SeatType
  Cột trạng thái: Status (Available/Sold/Cancelled)
  Cột bán vé:     CustomerID, BoxOfficeID, SaleDate,
                  PaymentMethod, Amount    (NULL khi chưa bán)
```

**Đánh đổi:**
- Đúng 5 bảng
- Đơn giản, dễ truy vấn
- Không lưu lịch sử nếu ghế bị hủy rồi bán lại

---

#Cấu trúc thư mục

```
sports_ticketing/
├── README.md
├── database/
│   ├── 01_schema.sql               ← 5 bảng + 10 indexes
│   ├── 02_sample_data.sql          ← Dữ liệu mẫu
│   ├── 03_views.sql                ← 7 views báo cáo
│   ├── 04_procedures.sql           ← 5 stored procedures
│   ├── 05_functions.sql            ← 5 user-defined functions
│   ├── 06_triggers.sql             ← 5 triggers
│   ├── 07_security.sql             ← Roles, users, mã hóa, backup
│
├── python_app/
│   ├── requirements.txt
│   ├── .env.example
│   ├── config.py
│   ├── database.py
│   ├── booking_service.py
│   ├── reporting_service.py
│   ├── ui.py
│   ├── data_generator.py
│   └── main.py
└── docs/
    ├── installation.md
    └── user_guide.md
```

---

##CÀI ĐẶT NHANH

### 1. Tạo database

```bash
cd database/
cat 01_schema.sql 02_sample_data.sql 03_views.sql 04_procedures.sql \
    05_functions.sql 06_triggers.sql 07_security.sql | mysql -u root -p
```

### 2. Cài Python

```bash
cd ../python_app/
python -m venv venv
source venv/bin/activate            # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env                # sửa password MySQL
```

### 3. (Tùy chọn) sinh dữ liệu lớn

```bash
python data_generator.py
# → 50 events, 500 KH, 3000 seats, ~60% được bán
```

### 4. Chạy ứng dụng

```bash
python main.py
```

---

#CHỨC NĂNG

| Menu | Mô tả |
|---|---|
| **1. Quản lý sự kiện** | Liệt kê, tìm kiếm, xem chi tiết |
| **2. Đặt vé mới** | Quy trình 7 bước với transaction |
| **3. Hủy vé** | Chuyển `Status='Cancelled'` (trigger tự giảm SoldQuantity) |
| **4. Quản lý khách hàng** | Tra cứu, lịch sử mua, phân hạng VIP/Gold/Silver |
| **5. Báo cáo** | Dashboard, doanh thu, sold-out, top events... |

---

#ĐỐI TƯỢNG DATABASE

### Indexes (10)
- `idx_seats_event_status` — quan trọng nhất, truy vấn ghế còn trống
- `idx_seats_saledate`, `idx_seats_customer`, `idx_seats_office_date` — báo cáo doanh thu
- `idx_events_date`, `idx_events_sport_status`, `idx_tickets_event`, `idx_customers_phone`, `idx_customers_name`, `idx_seats_type`

### Views (7)
| View | Dùng cho |
|---|---|
| `v_revenue_by_event` | Doanh thu theo sự kiện |
| `v_seat_availability` | % lấp đầy ghế |
| `v_sold_out_events` | Sự kiện sold-out |
| `v_customer_purchase_history` | Lịch sử mua của KH |
| `v_box_office_performance` | Hiệu suất phòng vé |
| `v_event_popularity` | Top sự kiện ưa chuộng |
| `v_revenue_by_ticket_type` | Doanh thu theo loại vé |

### Stored Procedures (5)
| SP | Mô tả |
|---|---|
| `sp_book_ticket` | UPDATE Seats với transaction + FOR UPDATE lock |
| `sp_cancel_ticket` | Hủy vé (Status='Cancelled') |
| `sp_revenue_summary` | Doanh thu theo khoảng ngày |
| `sp_search_events` | Tìm kiếm sự kiện đa tiêu chí |
| `sp_available_seats` | Liệt kê ghế trống |

### Functions (5)
- `fn_event_revenue(event_id)` — Tổng doanh thu sự kiện
- `fn_event_tickets_sold(event_id)` — Số vé đã bán
- `fn_event_occupancy(event_id)` — % lấp đầy
- `fn_customer_total_spent(customer_id)` — Tổng chi tiêu KH
- `fn_customer_tier(customer_id)` — Hạng VIP/Gold/Silver/Normal

### Triggers (5)
- `trg_before_seat_insert` — validate SeatType có giá trong Tickets
- `trg_before_seat_update` — chặn bán khi sự kiện đã hủy/diễn ra/hết vé
- `trg_after_seat_update` — đồng bộ `Tickets.SoldQuantity` (+1 bán, -1 hủy)
- `trg_before_seat_delete` — cấm xóa ghế đã bán
- `trg_after_event_update` — hủy sự kiện → tự động hủy tất cả vé đã bán

---

#BẢO MẬT

**4 roles:**
- `role_admin` — toàn quyền
- `role_manager` — đọc all + sửa events/tickets/seats + xem báo cáo
- `role_cashier` — chỉ thao tác bán/hủy vé qua procedure
- `role_readonly` — chỉ đọc (cho BI)

**Mã hóa:** dùng `AES_ENCRYPT` cho dữ liệu nhạy cảm khi cần.

**Backup:** `mysqldump --single-transaction --routines --triggers` hàng ngày + binary log.

---

#TEST NHANH

```sql
USE sports_ticketing;

-- KPIs nhanh
SELECT * FROM v_revenue_by_event ORDER BY TotalRevenue DESC LIMIT 5;
SELECT * FROM v_event_popularity LIMIT 5;

-- Function
SELECT EventID, EventName,
       fn_event_revenue(EventID)  AS Revenue,
       fn_event_occupancy(EventID) AS Occupancy
  FROM Events;

-- Đặt vé qua procedure
CALL sp_book_ticket(1, 1, 1, 'Cash', @st, @msg);
SELECT @st, @msg;

-- Kiểm tra trigger đã cập nhật
SELECT SeatID, Status, CustomerID, Amount FROM Seats WHERE SeatID=1;
SELECT TicketType, SoldQuantity FROM Tickets WHERE EventID=1;

-- Hủy vé
CALL sp_cancel_ticket(1, @st, @msg);
SELECT @st, @msg;
SELECT SeatID, Status FROM Seats WHERE SeatID=1;  -- → 'Cancelled'
```

---

---

#PHÁT TRIỂN TIẾP

- Tích hợp mã QR cho vé điện tử (`qrcode` library)
- Tích hợp VNPay/Momo thanh toán online
- Web UI Flask/FastAPI
- Mobile app Flutter
- Email/SMS notification

---

## 📚 TÀI LIỆU

- [MySQL 8.0 Reference Manual](https://dev.mysql.com/doc/refman/8.0/en/)
- [mysql-connector-python](https://dev.mysql.com/doc/connector-python/en/)
- [Faker](https://faker.readthedocs.io/)
- [tabulate](https://github.com/astanin/python-tabulate)
