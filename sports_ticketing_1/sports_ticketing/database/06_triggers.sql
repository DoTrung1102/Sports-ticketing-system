-- =====================================================================
-- File: 06_triggers.sql
-- Purpose: Triggers tự động hóa nghiệp vụ
-- (Không có bảng audit log vì đề bài chỉ cho 5 bảng)
-- =====================================================================
USE sports_ticketing;

DELIMITER $$

-- ---------------------------------------------------------------------
-- TRG 1: BEFORE INSERT - Validate ghế khi tạo mới
-- (đảm bảo SeatType có giá trong bảng Tickets cho sự kiện đó)
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_before_seat_insert$$
CREATE TRIGGER trg_before_seat_insert
BEFORE INSERT ON Seats
FOR EACH ROW
BEGIN
    DECLARE v_exists INT;

    SELECT COUNT(*) INTO v_exists
      FROM Tickets
     WHERE EventID = NEW.EventID AND TicketType = NEW.SeatType;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT='Loại ghế chưa được định nghĩa trong Tickets cho sự kiện này';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- TRG 2: BEFORE UPDATE - Validate khi bán vé
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_before_seat_update$$
CREATE TRIGGER trg_before_seat_update
BEFORE UPDATE ON Seats
FOR EACH ROW
BEGIN
    DECLARE v_event_status VARCHAR(20);
    DECLARE v_event_date   DATETIME;
    DECLARE v_qty          INT;
    DECLARE v_sold         INT;

    -- Khi chuyển sang Sold mới cần validate
    IF OLD.Status <> 'Sold' AND NEW.Status = 'Sold' THEN
        SELECT Status, EventDate INTO v_event_status, v_event_date
          FROM Events WHERE EventID = NEW.EventID;

        IF v_event_status = 'Cancelled' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT='Sự kiện đã hủy - không bán được vé';
        END IF;

        IF v_event_date < NOW() THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT='Sự kiện đã diễn ra';
        END IF;

        SELECT Quantity, SoldQuantity INTO v_qty, v_sold
          FROM Tickets
         WHERE EventID = NEW.EventID AND TicketType = NEW.SeatType;

        IF v_sold >= v_qty THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT='Loại vé này đã bán hết';
        END IF;
    END IF;
END$$

-- ---------------------------------------------------------------------
-- TRG 3: AFTER UPDATE - Đồng bộ Tickets.SoldQuantity
-- Available → Sold: tăng SoldQuantity
-- Sold → Cancelled/Available: giảm SoldQuantity
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_after_seat_update$$
CREATE TRIGGER trg_after_seat_update
AFTER UPDATE ON Seats
FOR EACH ROW
BEGIN
    -- Bán vé
    IF OLD.Status <> 'Sold' AND NEW.Status = 'Sold' THEN
        UPDATE Tickets
           SET SoldQuantity = SoldQuantity + 1
         WHERE EventID = NEW.EventID AND TicketType = NEW.SeatType;
    END IF;

    -- Hủy vé
    IF OLD.Status = 'Sold' AND NEW.Status IN ('Cancelled','Available') THEN
        UPDATE Tickets
           SET SoldQuantity = GREATEST(SoldQuantity - 1, 0)
         WHERE EventID = NEW.EventID AND TicketType = NEW.SeatType;
    END IF;
END$$

-- ---------------------------------------------------------------------
-- TRG 4: BEFORE DELETE - Cấm xóa ghế đã bán
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_before_seat_delete$$
CREATE TRIGGER trg_before_seat_delete
BEFORE DELETE ON Seats
FOR EACH ROW
BEGIN
    IF OLD.Status = 'Sold' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT='Không xóa được ghế đã bán - hãy hủy trước';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- TRG 5: AFTER UPDATE Events - Khi sự kiện hủy → hủy tất cả vé đã bán
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_after_event_update$$
CREATE TRIGGER trg_after_event_update
AFTER UPDATE ON Events
FOR EACH ROW
BEGIN
    IF OLD.Status <> 'Cancelled' AND NEW.Status = 'Cancelled' THEN
        UPDATE Seats
           SET Status='Cancelled'
         WHERE EventID = NEW.EventID AND Status='Sold';
    END IF;
END$$

DELIMITER ;
