-- =====================================================================
-- File: 02_sample_data.sql
-- Purpose: Dữ liệu mẫu cho 5 bảng
-- Lưu ý: Bán vé = UPDATE bảng Seats (set CustomerID, BoxOfficeID, ...)
-- =====================================================================
USE sports_ticketing;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE Seats;
TRUNCATE TABLE Tickets;
TRUNCATE TABLE Customers;
TRUNCATE TABLE BoxOffices;
TRUNCATE TABLE Events;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- EVENTS (10 sự kiện)
-- ---------------------------------------------------------------------
INSERT INTO Events (EventName, EventDate, Venue, Sport, Status) VALUES
('Hà Nội FC vs HAGL',                 '2026-06-15 19:00:00', 'SVĐ Hàng Đẫy',     'Bóng đá',   'Scheduled'),
('Thể Công Viettel vs Nam Định',      '2026-06-22 19:30:00', 'SVĐ Hàng Đẫy',     'Bóng đá',   'Scheduled'),
('Saigon Heat vs Nha Trang Dolphins', '2026-07-01 20:00:00', 'CIS Arena',         'Bóng rổ',   'Scheduled'),
('Việt Nam vs Thái Lan',              '2026-09-10 19:00:00', 'SVĐ Mỹ Đình',      'Bóng đá',   'Scheduled'),
('Lý Hoàng Nam vs Nishikori',         '2026-08-05 15:00:00', 'Bình Dương Tennis', 'Tennis',    'Scheduled'),
('Hà Nội Buffaloes vs Cantho Catfish','2026-06-18 20:00:00', 'Hà Nội Sport Hall', 'Bóng rổ',   'Scheduled'),
('SLNA vs Bình Định',                 '2026-05-30 18:00:00', 'SVĐ Vinh',         'Bóng đá',   'Completed'),
('VN Volleyball vs Indonesia',        '2026-07-15 19:00:00', 'NTĐ Phú Thọ',      'Bóng chuyền','Scheduled'),
('Boxing Night - Trương Đình Hoàng',  '2026-08-20 20:30:00', 'TT HL Quốc gia',   'Boxing',    'Scheduled'),
('Marathon Hà Nội 2026',              '2026-10-05 05:00:00', 'Hồ Hoàn Kiếm',     'Điền kinh', 'Scheduled');

-- ---------------------------------------------------------------------
-- BOX OFFICES
-- ---------------------------------------------------------------------
INSERT INTO BoxOffices (OfficeName, Address) VALUES
('Phòng vé Hàng Đẫy',    '9 Trịnh Hoài Đức, Đống Đa, Hà Nội'),
('Phòng vé Mỹ Đình',     'Đường Lê Đức Thọ, Nam Từ Liêm, Hà Nội'),
('Box Office CIS Arena', '171A Hoàng Hoa Thám, Bình Thạnh, TP.HCM'),
('Phòng vé Online',      'Website chính thức'),
('Đại lý Vincom Center', 'Vincom Bà Triệu, Hà Nội'),
('Phòng vé Sân Vinh',    'Đại lộ Lê Nin, Vinh, Nghệ An');

-- ---------------------------------------------------------------------
-- CUSTOMERS
-- ---------------------------------------------------------------------
INSERT INTO Customers (CustomerName, PhoneNumber, Address) VALUES
('Nguyễn Văn Hùng',  '0901234001', '12 Trần Phú, Ba Đình, HN'),
('Trần Thị Lan',     '0901234002', '45 Hai Bà Trưng, Hoàn Kiếm, HN'),
('Lê Minh Đức',      '0901234003', '88 Nguyễn Trãi, Thanh Xuân, HN'),
('Phạm Thu Hà',      '0901234004', '23 Lê Lợi, Q1, TP.HCM'),
('Hoàng Văn Sơn',    '0901234005', '156 Cầu Giấy, Cầu Giấy, HN'),
('Đỗ Thị Mai',       '0901234006', '7 Lý Thường Kiệt, Hoàn Kiếm, HN'),
('Vũ Đình Khoa',     '0901234007', '34 Tôn Đức Thắng, Đống Đa, HN'),
('Bùi Thị Hương',    '0901234008', '67 Phạm Ngọc Thạch, Đống Đa, HN'),
('Đặng Quang Linh',  '0901234009', '101 Kim Mã, Ba Đình, HN'),
('Phan Mỹ Linh',     '0901234010', '15 Bà Triệu, Hai Bà Trưng, HN');

-- ---------------------------------------------------------------------
-- TICKETS - loại vé cho mỗi sự kiện
-- ---------------------------------------------------------------------
INSERT INTO Tickets (EventID, TicketType, Price, Quantity) VALUES
-- Event 1
(1,'VIP',1500000.00,500),(1,'Standard',500000.00,8000),
(1,'Economy',200000.00,12000),(1,'Student',100000.00,1500),
-- Event 2
(2,'VIP',1200000.00,500),(2,'Standard',400000.00,10000),(2,'Economy',150000.00,11500),
-- Event 3
(3,'VIP',2000000.00,200),(3,'Standard',600000.00,3000),(3,'Economy',300000.00,1800),
-- Event 4
(4,'VIP',3000000.00,1000),(4,'Standard',1000000.00,20000),(4,'Economy',400000.00,19000),
-- Event 5
(5,'VIP',2500000.00,100),(5,'Standard',800000.00,2000),(5,'Economy',300000.00,900),
-- Event 6
(6,'VIP',1800000.00,200),(6,'Standard',500000.00,3000),(6,'Economy',250000.00,1800),
-- Event 7
(7,'VIP',1000000.00,400),(7,'Standard',300000.00,9000),(7,'Economy',120000.00,8600),
-- Event 8
(8,'VIP',1500000.00,200),(8,'Standard',500000.00,2500),(8,'Economy',200000.00,1300),
-- Event 9
(9,'VIP',5000000.00,100),(9,'Standard',1500000.00,1500),(9,'Economy',500000.00,900),
-- Event 10
(10,'Standard',500000.00,8000),(10,'Economy',200000.00,2000);

-- ---------------------------------------------------------------------
-- SEATS - ghế cho từng sự kiện (chưa bán)
-- ---------------------------------------------------------------------
-- Event 1: 5 VIP + 10 Standard + 10 Economy
INSERT INTO Seats (EventID, SeatNumber, SeatType) VALUES
(1,'V01','VIP'),(1,'V02','VIP'),(1,'V03','VIP'),(1,'V04','VIP'),(1,'V05','VIP'),
(1,'A01','Standard'),(1,'A02','Standard'),(1,'A03','Standard'),(1,'A04','Standard'),(1,'A05','Standard'),
(1,'B01','Standard'),(1,'B02','Standard'),(1,'B03','Standard'),(1,'B04','Standard'),(1,'B05','Standard'),
(1,'C01','Economy'),(1,'C02','Economy'),(1,'C03','Economy'),(1,'C04','Economy'),(1,'C05','Economy'),
(1,'D01','Economy'),(1,'D02','Economy'),(1,'D03','Economy'),(1,'D04','Economy'),(1,'D05','Economy');

-- Event 3 (Bóng rổ): 10 ghế
INSERT INTO Seats (EventID, SeatNumber, SeatType) VALUES
(3,'CT01','VIP'),(3,'CT02','VIP'),(3,'CT03','VIP'),
(3,'L01','Standard'),(3,'L02','Standard'),(3,'L03','Standard'),(3,'L04','Standard'),
(3,'U01','Economy'),(3,'U02','Economy'),(3,'U03','Economy');

-- Event 4 (VN vs Thái Lan): 10 ghế
INSERT INTO Seats (EventID, SeatNumber, SeatType) VALUES
(4,'V01','VIP'),(4,'V02','VIP'),
(4,'A01','Standard'),(4,'A02','Standard'),(4,'A03','Standard'),(4,'B01','Standard'),
(4,'C01','Economy'),(4,'C02','Economy'),(4,'D01','Economy'),(4,'D02','Economy');

-- ---------------------------------------------------------------------
-- BÁN VÉ - UPDATE Seats để gán khách hàng + thông tin giao dịch
-- Trigger sẽ tự động set Status='Sold' và tăng Tickets.SoldQuantity
-- ---------------------------------------------------------------------
-- KH1 mua ghế VIP V01 sự kiện 1 tại Hàng Đẫy
UPDATE Seats SET CustomerID=1, BoxOfficeID=1, SaleDate=NOW(),
                 PaymentMethod='Card', Amount=1500000, Status='Sold'
 WHERE EventID=1 AND SeatNumber='V01';

-- KH2 mua Standard A01 tại Hàng Đẫy
UPDATE Seats SET CustomerID=2, BoxOfficeID=1, SaleDate=NOW(),
                 PaymentMethod='Cash', Amount=500000, Status='Sold'
 WHERE EventID=1 AND SeatNumber='A01';

-- KH3 mua Economy C01 online
UPDATE Seats SET CustomerID=3, BoxOfficeID=4, SaleDate=NOW(),
                 PaymentMethod='EWallet', Amount=200000, Status='Sold'
 WHERE EventID=1 AND SeatNumber='C01';

-- KH4 mua VIP sự kiện 3 (Bóng rổ)
UPDATE Seats SET CustomerID=4, BoxOfficeID=3, SaleDate=NOW(),
                 PaymentMethod='Card', Amount=2000000, Status='Sold'
 WHERE EventID=3 AND SeatNumber='CT01';

-- KH5 mua VIP sự kiện 4
UPDATE Seats SET CustomerID=5, BoxOfficeID=2, SaleDate=NOW(),
                 PaymentMethod='Card', Amount=3000000, Status='Sold'
 WHERE EventID=4 AND SeatNumber='V01';

-- KH6 mua Standard sự kiện 4
UPDATE Seats SET CustomerID=6, BoxOfficeID=2, SaleDate=NOW(),
                 PaymentMethod='BankTransfer', Amount=1000000, Status='Sold'
 WHERE EventID=4 AND SeatNumber='A01';

-- KH7 mua Standard A02 sự kiện 1
UPDATE Seats SET CustomerID=7, BoxOfficeID=1, SaleDate=NOW(),
                 PaymentMethod='Cash', Amount=500000, Status='Sold'
 WHERE EventID=1 AND SeatNumber='A02';

-- KH8 mua VIP V02 sự kiện 1 (online)
UPDATE Seats SET CustomerID=8, BoxOfficeID=4, SaleDate=NOW(),
                 PaymentMethod='EWallet', Amount=1500000, Status='Sold'
 WHERE EventID=1 AND SeatNumber='V02';

-- KH9 mua Standard sự kiện 3
UPDATE Seats SET CustomerID=9, BoxOfficeID=3, SaleDate=NOW(),
                 PaymentMethod='Card', Amount=600000, Status='Sold'
 WHERE EventID=3 AND SeatNumber='L01';

-- KH10 mua Economy sự kiện 4
UPDATE Seats SET CustomerID=10, BoxOfficeID=4, SaleDate=NOW(),
                 PaymentMethod='EWallet', Amount=400000, Status='Sold'
 WHERE EventID=4 AND SeatNumber='C01';

-- ---------------------------------------------------------------------
-- Kiểm tra
-- ---------------------------------------------------------------------
SELECT 'Events'     AS T, COUNT(*) AS N FROM Events
UNION ALL SELECT 'Tickets',    COUNT(*) FROM Tickets
UNION ALL SELECT 'Customers',  COUNT(*) FROM Customers
UNION ALL SELECT 'BoxOffices', COUNT(*) FROM BoxOffices
UNION ALL SELECT 'Seats',      COUNT(*) FROM Seats
UNION ALL SELECT 'Seats Sold', COUNT(*) FROM Seats WHERE Status='Sold';
