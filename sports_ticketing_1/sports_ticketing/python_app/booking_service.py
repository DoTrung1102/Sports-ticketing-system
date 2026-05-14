"""
booking_service.py - Logic nghiệp vụ (mô hình 5 bảng)
Trong mô hình này, bán vé = UPDATE 1 dòng trong bảng Seats
SeatID đóng vai trò "transaction ID"
"""
from database import Database
import logging

logger = logging.getLogger(__name__)


# =====================================================================
# EVENT SERVICE
# =====================================================================
class EventService:

    @staticmethod
    def search_events(keyword: str = "", sport: str = "",
                      from_date: str = None, to_date: str = None):
        result = Database.call_proc(
            "sp_search_events",
            [keyword or None, sport or None, from_date, to_date]
        )
        return result["results"][0] if result["results"] else []

    @staticmethod
    def get_event_detail(event_id: int):
        return Database.fetch_one(
            "SELECT * FROM Events WHERE EventID = %s", (event_id,)
        )

    @staticmethod
    def list_upcoming(limit: int = 20):
        return Database.fetch_all("""
            SELECT EventID, EventName, Sport, EventDate, Venue, Status
              FROM Events
             WHERE EventDate >= NOW() AND Status='Scheduled'
             ORDER BY EventDate ASC
             LIMIT %s
        """, (limit,))


# =====================================================================
# CUSTOMER SERVICE
# =====================================================================
class CustomerService:

    @staticmethod
    def find_by_phone(phone: str):
        return Database.fetch_one(
            "SELECT * FROM Customers WHERE PhoneNumber = %s", (phone,)
        )

    @staticmethod
    def create(name: str, phone: str, address: str = None) -> int:
        existing = CustomerService.find_by_phone(phone)
        if existing:
            return existing["CustomerID"]
        return Database.execute(
            """INSERT INTO Customers (CustomerName, PhoneNumber, Address)
               VALUES (%s, %s, %s)""",
            (name, phone, address),
            commit=True
        )

    @staticmethod
    def purchase_history(customer_id: int):
        return Database.fetch_all(
            "SELECT * FROM v_customer_purchase_history "
            "WHERE CustomerID = %s ORDER BY SaleDate DESC",
            (customer_id,)
        )

    @staticmethod
    def get_tier_info(customer_id: int):
        return Database.fetch_one("""
            SELECT CustomerID, CustomerName,
                   fn_customer_total_spent(%s) AS TotalSpent,
                   fn_customer_tier(%s)        AS Tier
              FROM Customers WHERE CustomerID = %s
        """, (customer_id, customer_id, customer_id))


# =====================================================================
# BOOKING SERVICE - thao tác trên bảng Seats
# =====================================================================
class BookingService:

    @staticmethod
    def get_available_seats(event_id: int, seat_type: str = ""):
        result = Database.call_proc(
            "sp_available_seats", [event_id, seat_type or None]
        )
        return result["results"][0] if result["results"] else []

    @staticmethod
    def get_ticket_types(event_id: int):
        return Database.fetch_all("""
            SELECT TicketID, TicketType, Price, Quantity, SoldQuantity,
                   (Quantity - SoldQuantity) AS Remaining
              FROM Tickets WHERE EventID = %s
        """, (event_id,))

    @staticmethod
    def book(customer_id: int, seat_id: int, box_office_id: int,
             payment_method: str = "Cash"):
        """Đặt vé qua sp_book_ticket. Trả về {ok, sale_id, message}."""
        result = Database.call_proc(
            "sp_book_ticket",
            [customer_id, seat_id, box_office_id, payment_method, "", ""]
        )
        out = result["out"]
        status, message = out[4], out[5]
        return {
            "ok": status == "OK",
            "sale_id": seat_id if status == "OK" else None,  # SeatID = SaleID
            "message": message,
        }

    @staticmethod
    def cancel(seat_id: int):
        result = Database.call_proc("sp_cancel_ticket", [seat_id, "", ""])
        out = result["out"]
        status, message = out[1], out[2]
        return {"ok": status == "OK", "message": message}

    @staticmethod
    def get_sale_detail(seat_id: int):
        return Database.fetch_one("""
            SELECT s.SeatID, c.CustomerName, c.PhoneNumber,
                   e.EventName, e.EventDate,
                   s.SeatType, s.SeatNumber,
                   bo.OfficeName, s.SaleDate, s.Amount,
                   s.PaymentMethod, s.Status
              FROM Seats s
              LEFT JOIN Customers   c  ON s.CustomerID  = c.CustomerID
              JOIN      Events      e  ON s.EventID     = e.EventID
              LEFT JOIN BoxOffices  bo ON s.BoxOfficeID = bo.BoxOfficeID
             WHERE s.SeatID = %s
        """, (seat_id,))


# =====================================================================
# BOX OFFICE SERVICE
# =====================================================================
class BoxOfficeService:

    @staticmethod
    def list_all():
        return Database.fetch_all(
            "SELECT * FROM BoxOffices ORDER BY OfficeName"
        )
