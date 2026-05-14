-- =====================================================================
-- File: 05_functions.sql
-- Purpose: User Defined Functions
-- =====================================================================
USE sports_ticketing;

DELIMITER $$

-- ---------------------------------------------------------------------
-- FN 1: Tổng doanh thu của 1 sự kiện
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_event_revenue$$
CREATE FUNCTION fn_event_revenue (p_event_id INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(15,2);
    SELECT COALESCE(SUM(Amount), 0) INTO v_total
      FROM Seats
     WHERE EventID = p_event_id AND Status = 'Sold';
    RETURN v_total;
END$$

-- ---------------------------------------------------------------------
-- FN 2: Tổng số vé đã bán của 1 sự kiện
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_event_tickets_sold$$
CREATE FUNCTION fn_event_tickets_sold (p_event_id INT)
RETURNS INT
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
      FROM Seats
     WHERE EventID = p_event_id AND Status = 'Sold';
    RETURN v_count;
END$$

-- ---------------------------------------------------------------------
-- FN 3: % lấp đầy ghế của 1 sự kiện
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_event_occupancy$$
CREATE FUNCTION fn_event_occupancy (p_event_id INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total INT;
    DECLARE v_sold  INT;
    SELECT COUNT(*), SUM(CASE WHEN Status='Sold' THEN 1 ELSE 0 END)
      INTO v_total, v_sold
      FROM Seats WHERE EventID = p_event_id;
    IF v_total IS NULL OR v_total = 0 THEN RETURN 0; END IF;
    RETURN ROUND(v_sold * 100.0 / v_total, 2);
END$$

-- ---------------------------------------------------------------------
-- FN 4: Tổng tiền 1 khách hàng đã chi
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_customer_total_spent$$
CREATE FUNCTION fn_customer_total_spent (p_customer_id INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(15,2);
    SELECT COALESCE(SUM(Amount), 0) INTO v_total
      FROM Seats
     WHERE CustomerID = p_customer_id AND Status = 'Sold';
    RETURN v_total;
END$$

-- ---------------------------------------------------------------------
-- FN 5: Phân hạng khách hàng
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_customer_tier$$
CREATE FUNCTION fn_customer_tier (p_customer_id INT)
RETURNS VARCHAR(20)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_spent DECIMAL(15,2);
    SET v_spent = fn_customer_total_spent(p_customer_id);
    RETURN CASE
        WHEN v_spent >= 10000000 THEN 'VIP'
        WHEN v_spent >=  5000000 THEN 'Gold'
        WHEN v_spent >=  1000000 THEN 'Silver'
        ELSE 'Normal'
    END;
END$$

DELIMITER ;
