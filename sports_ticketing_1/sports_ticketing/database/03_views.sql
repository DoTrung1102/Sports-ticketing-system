-- =====================================================================
-- File: 03_views.sql
-- Purpose: Views báo cáo (dùng bảng Seats làm nguồn dữ liệu bán vé)
-- =====================================================================
USE sports_ticketing;

-- ---------------------------------------------------------------------
-- VIEW 1: Doanh thu theo sự kiện
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_revenue_by_event;
CREATE VIEW v_revenue_by_event AS
SELECT
    e.EventID,
    e.EventName,
    e.Sport,
    e.EventDate,
    e.Venue,
    COUNT(CASE WHEN s.Status='Sold'      THEN 1 END) AS TicketsSold,
    COUNT(CASE WHEN s.Status='Cancelled' THEN 1 END) AS CancelledCount,
    COALESCE(SUM(CASE WHEN s.Status='Sold' THEN s.Amount END), 0) AS TotalRevenue
FROM Events e
LEFT JOIN Seats s ON e.EventID = s.EventID
GROUP BY e.EventID, e.EventName, e.Sport, e.EventDate, e.Venue;

-- ---------------------------------------------------------------------
-- VIEW 2: Tình trạng ghế theo loại
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_seat_availability;
CREATE VIEW v_seat_availability AS
SELECT
    e.EventID,
    e.EventName,
    e.EventDate,
    s.SeatType,
    COUNT(*)                                              AS TotalSeats,
    SUM(CASE WHEN s.Status='Available' THEN 1 ELSE 0 END) AS AvailableSeats,
    SUM(CASE WHEN s.Status='Sold'      THEN 1 ELSE 0 END) AS SoldSeats,
    SUM(CASE WHEN s.Status='Cancelled' THEN 1 ELSE 0 END) AS CancelledSeats,
    ROUND(SUM(CASE WHEN s.Status='Sold' THEN 1 ELSE 0 END)*100.0/COUNT(*), 2)
                                                          AS OccupancyPercent
FROM Events e
JOIN Seats s ON e.EventID = s.EventID
GROUP BY e.EventID, e.EventName, e.EventDate, s.SeatType;

-- ---------------------------------------------------------------------
-- VIEW 3: Sự kiện đã bán hết vé (theo Tickets.SoldQuantity)
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_sold_out_events;
CREATE VIEW v_sold_out_events AS
SELECT
    e.EventID, e.EventName, e.Sport, e.EventDate, e.Venue,
    SUM(t.Quantity)     AS TotalCapacity,
    SUM(t.SoldQuantity) AS TotalSold
FROM Events e
JOIN Tickets t ON e.EventID = t.EventID
GROUP BY e.EventID, e.EventName, e.Sport, e.EventDate, e.Venue
HAVING SUM(t.Quantity) > 0 AND SUM(t.SoldQuantity) = SUM(t.Quantity);

-- ---------------------------------------------------------------------
-- VIEW 4: Lịch sử mua vé của khách hàng
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_customer_purchase_history;
CREATE VIEW v_customer_purchase_history AS
SELECT
    c.CustomerID,
    c.CustomerName,
    c.PhoneNumber,
    s.SeatID,
    e.EventName,
    e.EventDate,
    s.SeatType,
    s.SeatNumber,
    bo.OfficeName       AS PurchasedAt,
    s.SaleDate,
    s.PaymentMethod,
    s.Amount,
    s.Status
FROM Customers c
JOIN Seats     s ON c.CustomerID  = s.CustomerID
JOIN Events    e ON s.EventID     = e.EventID
LEFT JOIN BoxOffices bo ON s.BoxOfficeID = bo.BoxOfficeID;

-- ---------------------------------------------------------------------
-- VIEW 5: Hiệu suất phòng vé
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_box_office_performance;
CREATE VIEW v_box_office_performance AS
SELECT
    bo.BoxOfficeID,
    bo.OfficeName,
    bo.Address,
    COUNT(s.SeatID)                                          AS TotalTransactions,
    COALESCE(SUM(CASE WHEN s.Status='Sold' THEN s.Amount END), 0) AS TotalRevenue,
    COUNT(DISTINCT s.CustomerID)                             AS UniqueCustomers,
    MIN(s.SaleDate)                                          AS FirstSale,
    MAX(s.SaleDate)                                          AS LastSale
FROM BoxOffices bo
LEFT JOIN Seats s ON bo.BoxOfficeID = s.BoxOfficeID AND s.Status='Sold'
GROUP BY bo.BoxOfficeID, bo.OfficeName, bo.Address;

-- ---------------------------------------------------------------------
-- VIEW 6: Top sự kiện được ưa chuộng
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_event_popularity;
CREATE VIEW v_event_popularity AS
SELECT
    e.EventID,
    e.EventName,
    e.Sport,
    e.EventDate,
    COUNT(CASE WHEN s.Status='Sold' THEN 1 END)                       AS TicketsSold,
    COALESCE(SUM(CASE WHEN s.Status='Sold' THEN s.Amount END), 0)     AS Revenue,
    RANK() OVER (ORDER BY COUNT(CASE WHEN s.Status='Sold' THEN 1 END) DESC) AS PopularityRank
FROM Events e
LEFT JOIN Seats s ON e.EventID = s.EventID
GROUP BY e.EventID, e.EventName, e.Sport, e.EventDate;

-- ---------------------------------------------------------------------
-- VIEW 7: Doanh thu theo loại vé
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_revenue_by_ticket_type;
CREATE VIEW v_revenue_by_ticket_type AS
SELECT
    s.SeatType                AS TicketType,
    COUNT(*)                  AS TicketsSold,
    AVG(s.Amount)             AS AvgPrice,
    SUM(s.Amount)             AS TotalRevenue
FROM Seats s
WHERE s.Status='Sold'
GROUP BY s.SeatType;
