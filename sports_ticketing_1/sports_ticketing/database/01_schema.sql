-- =====================================================================
-- PROJECT 16: SPORTS TICKETING MANAGEMENT SYSTEM
-- File: 01_schema.sql
-- Mô hình: đúng 5 bảng theo đề bài
--   Events, Tickets, Customers, BoxOffices, Seats
-- Lưu ý: bảng Seats kiêm hai vai trò
--   (a) Catalog ghế của sự kiện
--   (b) Bản ghi bán vé (khi ghế được bán, các cột Customer/BoxOffice/SaleDate
--       /PaymentMethod/Amount được điền vào, Status='Sold')
-- =====================================================================

DROP DATABASE IF EXISTS sports_ticketing;
CREATE DATABASE sports_ticketing
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE sports_ticketing;

-- ---------------------------------------------------------------------
-- 1. EVENTS
-- ---------------------------------------------------------------------
CREATE TABLE Events (
    EventID     INT AUTO_INCREMENT PRIMARY KEY,
    EventName   VARCHAR(150) NOT NULL,
    EventDate   DATETIME     NOT NULL,                  -- ngày + giờ thi đấu
    Venue       VARCHAR(150) NOT NULL,
    Sport       VARCHAR(50)  NOT NULL DEFAULT 'Khác',   -- môn thể thao
    Status      ENUM('Scheduled','Completed','Cancelled')
                             NOT NULL DEFAULT 'Scheduled'
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. TICKETS - định nghĩa loại vé và giá cho mỗi sự kiện
-- ---------------------------------------------------------------------
CREATE TABLE Tickets (
    TicketID     INT AUTO_INCREMENT PRIMARY KEY,
    EventID      INT NOT NULL,
    TicketType   ENUM('VIP','Standard','Economy','Student') NOT NULL,
    Price        DECIMAL(10,2) NOT NULL,
    Quantity     INT NOT NULL DEFAULT 0,    -- tổng số vé loại này phát hành
    SoldQuantity INT NOT NULL DEFAULT 0,    -- số vé đã bán (trigger cập nhật)
    CONSTRAINT fk_ticket_event FOREIGN KEY (EventID)
        REFERENCES Events(EventID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_event_type UNIQUE (EventID, TicketType),
    CONSTRAINT chk_ticket_price CHECK (Price >= 0),
    CONSTRAINT chk_ticket_qty   CHECK (Quantity >= 0
                                        AND SoldQuantity >= 0
                                        AND SoldQuantity <= Quantity)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. CUSTOMERS
-- ---------------------------------------------------------------------
CREATE TABLE Customers (
    CustomerID   INT AUTO_INCREMENT PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    PhoneNumber  VARCHAR(15)  NOT NULL UNIQUE,
    Address      VARCHAR(255),
    CONSTRAINT chk_phone_len CHECK (CHAR_LENGTH(PhoneNumber) >= 9)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. BOX OFFICES
-- ---------------------------------------------------------------------
CREATE TABLE BoxOffices (
    BoxOfficeID INT AUTO_INCREMENT PRIMARY KEY,
    OfficeName  VARCHAR(100) NOT NULL,
    Address     VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. SEATS - catalog ghế + bản ghi bán vé
-- ---------------------------------------------------------------------
CREATE TABLE Seats (
    SeatID        INT AUTO_INCREMENT PRIMARY KEY,
    EventID       INT NOT NULL,
    SeatNumber    VARCHAR(10) NOT NULL,
    SeatType      ENUM('VIP','Standard','Economy','Student') NOT NULL,
    Status        ENUM('Available','Sold','Cancelled')
                  NOT NULL DEFAULT 'Available',

    -- Thông tin bán vé (NULL khi ghế chưa bán)
    CustomerID    INT NULL,
    BoxOfficeID   INT NULL,
    SaleDate      DATETIME NULL,
    PaymentMethod ENUM('Cash','Card','EWallet','BankTransfer') NULL,
    Amount        DECIMAL(10,2) NULL,

    CONSTRAINT fk_seat_event FOREIGN KEY (EventID)
        REFERENCES Events(EventID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_seat_customer FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID) ON UPDATE CASCADE,
    CONSTRAINT fk_seat_office FOREIGN KEY (BoxOfficeID)
        REFERENCES BoxOffices(BoxOfficeID) ON UPDATE CASCADE,
    CONSTRAINT uq_event_seatnum UNIQUE (EventID, SeatNumber),
    CONSTRAINT chk_seat_amount CHECK (Amount IS NULL OR Amount >= 0),
    CONSTRAINT chk_sold_complete CHECK (
        Status <> 'Sold' OR (
            CustomerID IS NOT NULL AND BoxOfficeID IS NOT NULL
            AND SaleDate IS NOT NULL AND PaymentMethod IS NOT NULL
            AND Amount IS NOT NULL
        )
    )
) ENGINE=InnoDB;

-- =====================================================================
-- INDEXES
-- =====================================================================
CREATE INDEX idx_events_date         ON Events(EventDate);
CREATE INDEX idx_events_sport_status ON Events(Sport, Status);
CREATE INDEX idx_tickets_event       ON Tickets(EventID);
CREATE INDEX idx_customers_phone     ON Customers(PhoneNumber);
CREATE INDEX idx_customers_name      ON Customers(CustomerName);
CREATE INDEX idx_seats_event_status  ON Seats(EventID, Status);
CREATE INDEX idx_seats_type          ON Seats(EventID, SeatType, Status);
CREATE INDEX idx_seats_saledate      ON Seats(SaleDate);
CREATE INDEX idx_seats_customer      ON Seats(CustomerID);
CREATE INDEX idx_seats_office_date   ON Seats(BoxOfficeID, SaleDate);

SHOW TABLES;
