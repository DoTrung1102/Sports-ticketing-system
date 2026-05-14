# Hướng dẫn sử dụng (mô hình 5 bảng)

## Khái niệm quan trọng

Trong mô hình này, **không có bảng `TicketSales` riêng**. Bảng `Seats` đảm nhiệm cả hai vai trò:

| Khi `Status='Available'` | Khi `Status='Sold'` | Khi `Status='Cancelled'` |
|---|---|---|
| Chỉ là catalog ghế | Là bản ghi giao dịch (đầy đủ thông tin khách + tiền + phòng vé) | Vé đã hủy, ghế giải phóng |

**Vì vậy `SeatID` chính là "ID giao dịch"** khi cần tra cứu, hủy vé, in hóa đơn.

---

## Menu chính

```
══════════════════════════════════════════════════════════════════════
  🏟️   Sports Ticketing Management System  (v1.0.0)
══════════════════════════════════════════════════════════════════════
  1. Quản lý sự kiện
  2. Đặt vé mới
  3. Hủy vé
  4. Quản lý khách hàng
  5. Báo cáo & thống kê
  0. Thoát
```

---

## 1. Quản lý sự kiện

### 1.1 Liệt kê sự kiện sắp diễn ra
Hiển thị tối đa 20 sự kiện có `Status='Scheduled'` và `EventDate >= NOW()`.

### 1.2 Tìm kiếm
Procedure `sp_search_events` cho phép lọc theo:
- Từ khóa (tên/sân)
- Môn thể thao
- Khoảng thời gian
Bỏ qua bằng cách nhấn Enter.

### 1.3 Chi tiết sự kiện
Hiển thị thông tin sự kiện + tất cả loại vé (Tickets) với số còn lại.

---

## 2. Đặt vé — Quy trình 7 bước

### Bước 1: Khách hàng
- Nhập SĐT → nếu có sẵn dùng luôn, không thì tạo mới (INSERT vào Customers)

### Bước 2: Chọn sự kiện
- Hệ thống liệt kê sự kiện mở bán → nhập `EventID`

### Bước 3: Chọn loại vé
- Hiển thị bảng `Tickets` của sự kiện → bạn xem giá để chọn loại ghế phù hợp

### Bước 4: Chọn ghế
- Procedure `sp_available_seats(EventID, SeatType)` trả về ghế trống đúng loại
- Nhập `SeatID`

### Bước 5: Phòng vé
- Liệt kê `BoxOffices` → nhập `BoxOfficeID`

### Bước 6: Phương thức thanh toán
- 1.Cash, 2.Card, 3.EWallet, 4.BankTransfer

### Bước 7: Xác nhận
- Gọi `sp_book_ticket` → UPDATE bảng Seats:
  - `CustomerID`, `BoxOfficeID`, `SaleDate`, `PaymentMethod`, `Amount` ← điền
  - `Status` ← `'Sold'`
- Trigger `trg_after_seat_update` tự tăng `Tickets.SoldQuantity`

### Các trường hợp lỗi tự động phát hiện

| Lỗi | Cơ chế phát hiện |
|---|---|
| Ghế đã bán | `sp_book_ticket` check `Status='Available'` |
| Sự kiện đã hủy | `trg_before_seat_update` SIGNAL SQLSTATE 45000 |
| Sự kiện đã diễn ra | `trg_before_seat_update` |
| Hết vé loại đó | `trg_before_seat_update` check `SoldQuantity < Quantity` |
| Loại vé không có giá | `sp_book_ticket` |

---

## 3. Hủy vé

- Nhập **SeatID** cần hủy (chính là "SaleID" trong mô hình này)
- Procedure `sp_cancel_ticket` chuyển `Status='Cancelled'`
- Trigger `trg_after_seat_update` giảm `Tickets.SoldQuantity`

**Không hủy được** khi:
- Ghế không ở trạng thái `Sold`
- Sự kiện đã diễn ra

**Lưu ý:** Sau khi hủy, ghế ở trạng thái `Cancelled`. Để bán lại, cần đổi về `Available` (admin can thiệp).

---

## 4. Khách hàng

### 4.1 Tra cứu theo SĐT
SELECT từ bảng `Customers`.

### 4.2 Lịch sử mua vé
View `v_customer_purchase_history` join Customers ← Seats ← Events ← BoxOffices.

### 4.3 Phân hạng
Function `fn_customer_tier`:

| Tier | Tổng chi tiêu |
|---|---|
| VIP | ≥ 10,000,000 VND |
| Gold | ≥ 5,000,000 VND |
| Silver | ≥ 1,000,000 VND |
| Normal | < 1,000,000 VND |

---

## 5. Báo cáo

| # | Báo cáo | Nguồn dữ liệu |
|---|---|---|
| 1 | Dashboard | Aggregate từ Seats `WHERE Status='Sold'` |
| 2 | Doanh thu theo sự kiện | `v_revenue_by_event` |
| 3 | Doanh thu theo loại vé | `v_revenue_by_ticket_type` |
| 4 | Doanh thu theo ngày | `sp_revenue_summary(from, to)` |
| 5 | Tình trạng ghế | `v_seat_availability` |
| 6 | Sự kiện sold-out | `v_sold_out_events` |
| 7 | Top sự kiện ưa chuộng | `v_event_popularity` |
| 8 | Hiệu suất phòng vé | `v_box_office_performance` |
| 9 | Top KH VIP | Aggregate Customers + Seats + `fn_customer_tier` |

---

## Truy vấn trực tiếp (cho admin)

```sql
-- Thêm sự kiện mới
INSERT INTO Events (EventName, EventDate, Venue, Sport)
VALUES ('Giao hữu VN-Nhật', '2026-11-15 19:00:00', 'SVĐ Mỹ Đình', 'Bóng đá');

-- Thêm loại vé
INSERT INTO Tickets (EventID, TicketType, Price, Quantity)
VALUES (LAST_INSERT_ID(), 'VIP', 2500000, 1000);

-- Hủy sự kiện → trigger tự hoàn vé tất cả KH
UPDATE Events SET Status='Cancelled' WHERE EventID = 5;

-- Sau đó kiểm tra
SELECT SeatID, CustomerID, Status FROM Seats
 WHERE EventID = 5 AND CustomerID IS NOT NULL;
-- Tất cả phải có Status='Cancelled'
```
