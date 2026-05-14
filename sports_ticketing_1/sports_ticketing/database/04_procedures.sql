-- =====================================================================
-- File: 04_procedures.sql
-- Purpose: Stored procedures
-- =====================================================================
USE sports_ticketing;

DELIMITER $$

-- ---------------------------------------------------------------------
-- SP 1: sp_book_ticket - Đặt vé (UPDATE bảng Seats)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_book_ticket$$
CREATE PROCEDURE sp_book_ticket (
    IN  p_customer_id    INT,
    IN  p_seat_id        INT,
    IN  p_box_office_id  INT,
    IN  p_payment_method VARCHAR(20),
    OUT p_status         VARCHAR(10),
    OUT p_message        VARCHAR(255)
)
BEGIN
    DECLARE v_seat_status  VARCHAR(20);
    DECLARE v_event_id     INT;
    DECLARE v_seat_type    VARCHAR(20);
    DECLARE v_price        DECIMAL(10,2);
    DECLARE v_event_status VARCHAR(20);
    DECLARE v_event_date   DATETIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status='ERROR'; SET p_message='Lỗi giao dịch - đã rollback';
    END;

    START TRANSACTION;

    -- 1. Khóa dòng ghế để chống race condition
    SELECT Status, EventID, SeatType
      INTO v_seat_status, v_event_id, v_seat_type
      FROM Seats WHERE SeatID = p_seat_id
      FOR UPDATE;

    IF v_seat_status IS NULL THEN
        SET p_status='ERROR'; SET p_message='Không tìm thấy ghế'; ROLLBACK;
    ELSEIF v_seat_status <> 'Available' THEN
        SET p_status='ERROR';
        SET p_message=CONCAT('Ghế không thể đặt - trạng thái: ', v_seat_status);
        ROLLBACK;
    ELSE
        -- 2. Kiểm tra sự kiện
        SELECT Status, EventDate INTO v_event_status, v_event_date
          FROM Events WHERE EventID = v_event_id;

        IF v_event_status = 'Cancelled' THEN
            SET p_status='ERROR'; SET p_message='Sự kiện đã hủy'; ROLLBACK;
        ELSEIF v_event_date < NOW() THEN
            SET p_status='ERROR'; SET p_message='Sự kiện đã diễn ra'; ROLLBACK;
        ELSE
            -- 3. Lấy giá từ Tickets (theo EventID + SeatType)
            SELECT Price INTO v_price
              FROM Tickets
             WHERE EventID = v_event_id AND TicketType = v_seat_type;

            IF v_price IS NULL THEN
                SET p_status='ERROR';
                SET p_message=CONCAT('Không có giá cho loại vé ', v_seat_type);
                ROLLBACK;
            ELSE
                -- 4. UPDATE Seats (trigger tự cập nhật Tickets.SoldQuantity)
                UPDATE Seats
                   SET CustomerID    = p_customer_id,
                       BoxOfficeID   = p_box_office_id,
                       SaleDate      = NOW(),
                       PaymentMethod = p_payment_method,
                       Amount        = v_price,
                       Status        = 'Sold'
                 WHERE SeatID = p_seat_id;

                SET p_status='OK';
                SET p_message=CONCAT('Đặt vé thành công - SeatID=', p_seat_id,
                                     ', Amount=', v_price);
                COMMIT;
            END IF;
        END IF;
    END IF;
END$$

-- ---------------------------------------------------------------------
-- SP 2: sp_cancel_ticket - Hủy vé
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_cancel_ticket$$
CREATE PROCEDURE sp_cancel_ticket (
    IN  p_seat_id INT,
    OUT p_status  VARCHAR(10),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_current_status VARCHAR(20);
    DECLARE v_event_date     DATETIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status='ERROR'; SET p_message='Lỗi hủy vé';
    END;

    START TRANSACTION;

    SELECT s.Status, e.EventDate
      INTO v_current_status, v_event_date
      FROM Seats s JOIN Events e ON s.EventID = e.EventID
     WHERE s.SeatID = p_seat_id
     FOR UPDATE;

    IF v_current_status IS NULL THEN
        SET p_status='ERROR'; SET p_message='Không tìm thấy ghế'; ROLLBACK;
    ELSEIF v_current_status <> 'Sold' THEN
        SET p_status='ERROR';
        SET p_message=CONCAT('Không thể hủy - trạng thái: ', v_current_status);
        ROLLBACK;
    ELSEIF v_event_date < NOW() THEN
        SET p_status='ERROR'; SET p_message='Sự kiện đã diễn ra'; ROLLBACK;
    ELSE
        -- Đổi trạng thái sang Cancelled (giữ lại CustomerID để biết ai từng đặt)
        -- Trigger sẽ giảm Tickets.SoldQuantity
        UPDATE Seats
           SET Status='Cancelled'
         WHERE SeatID = p_seat_id;

        SET p_status='OK'; SET p_message='Hủy vé thành công';
        COMMIT;
    END IF;
END$$

-- ---------------------------------------------------------------------
-- SP 3: sp_revenue_summary - Báo cáo doanh thu theo khoảng ngày
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_revenue_summary$$
CREATE PROCEDURE sp_revenue_summary (
    IN p_from_date DATE,
    IN p_to_date   DATE
)
BEGIN
    SELECT
        DATE(s.SaleDate)  AS SaleDay,
        e.Sport,
        COUNT(*)          AS TicketsSold,
        SUM(s.Amount)     AS DailyRevenue
    FROM Seats s
    JOIN Events e ON s.EventID = e.EventID
    WHERE s.Status='Sold'
      AND DATE(s.SaleDate) BETWEEN p_from_date AND p_to_date
    GROUP BY DATE(s.SaleDate), e.Sport
    ORDER BY SaleDay DESC, DailyRevenue DESC;
END$$

-- ---------------------------------------------------------------------
-- SP 4: sp_search_events - Tìm sự kiện
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_search_events$$
CREATE PROCEDURE sp_search_events (
    IN p_keyword  VARCHAR(100),
    IN p_sport    VARCHAR(50),
    IN p_from_date DATE,
    IN p_to_date   DATE
)
BEGIN
    SELECT
        e.EventID, e.EventName, e.Sport,
        e.EventDate, e.Venue, e.Status,
        (SELECT MIN(Price) FROM Tickets WHERE EventID=e.EventID) AS MinPrice,
        (SELECT MAX(Price) FROM Tickets WHERE EventID=e.EventID) AS MaxPrice
    FROM Events e
    WHERE (p_keyword IS NULL OR p_keyword='' OR
           e.EventName LIKE CONCAT('%', p_keyword, '%') OR
           e.Venue     LIKE CONCAT('%', p_keyword, '%'))
      AND (p_sport IS NULL OR p_sport='' OR e.Sport = p_sport)
      AND (p_from_date IS NULL OR DATE(e.EventDate) >= p_from_date)
      AND (p_to_date   IS NULL OR DATE(e.EventDate) <= p_to_date)
    ORDER BY e.EventDate ASC;
END$$

-- ---------------------------------------------------------------------
-- SP 5: sp_available_seats - Ghế còn trống của sự kiện
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_available_seats$$
CREATE PROCEDURE sp_available_seats (
    IN p_event_id  INT,
    IN p_seat_type VARCHAR(20)
)
BEGIN
    SELECT
        s.SeatID, s.SeatNumber, s.SeatType, s.Status,
        t.Price
    FROM Seats s
    JOIN Tickets t ON s.EventID = t.EventID AND s.SeatType = t.TicketType
    WHERE s.EventID = p_event_id
      AND s.Status  = 'Available'
      AND (p_seat_type IS NULL OR p_seat_type='' OR s.SeatType = p_seat_type)
    ORDER BY s.SeatNumber;
END$$

DELIMITER ;
