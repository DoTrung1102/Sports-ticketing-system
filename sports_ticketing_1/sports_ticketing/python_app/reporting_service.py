"""
Dữ liệu bán vé lấy từ bảng Seats (Status='Sold')
"""
from database import Database


class ReportingService:

    # ------------------------------------------------------------------
    # DOANH THU
    # ------------------------------------------------------------------
    @staticmethod
    def revenue_by_event():
        return Database.fetch_all(
            "SELECT * FROM v_revenue_by_event ORDER BY TotalRevenue DESC"
        )

    @staticmethod
    def revenue_by_ticket_type():
        return Database.fetch_all("SELECT * FROM v_revenue_by_ticket_type")

    @staticmethod
    def revenue_summary(from_date: str, to_date: str):
        result = Database.call_proc("sp_revenue_summary", [from_date, to_date])
        return result["results"][0] if result["results"] else []

    @staticmethod
    def total_revenue():
        return Database.fetch_one("""
            SELECT COUNT(*)    AS TotalSales,
                   SUM(Amount) AS TotalRevenue,
                   AVG(Amount) AS AvgTicketPrice
              FROM Seats WHERE Status='Sold'
        """)

    # ------------------------------------------------------------------
    # GHẾ & SỨC CHỨA
    # ------------------------------------------------------------------
    @staticmethod
    def seat_availability(event_id: int = None):
        if event_id:
            return Database.fetch_all(
                "SELECT * FROM v_seat_availability WHERE EventID = %s",
                (event_id,)
            )
        return Database.fetch_all("SELECT * FROM v_seat_availability")

    @staticmethod
    def sold_out_events():
        return Database.fetch_all(
            "SELECT * FROM v_sold_out_events ORDER BY EventDate"
        )

    # ------------------------------------------------------------------
    # POPULARITY
    # ------------------------------------------------------------------
    @staticmethod
    def event_popularity(top_n: int = 10):
        return Database.fetch_all(
            "SELECT * FROM v_event_popularity "
            "ORDER BY PopularityRank LIMIT %s",
            (top_n,)
        )

    # ------------------------------------------------------------------
    # PHÒNG VÉ
    # ------------------------------------------------------------------
    @staticmethod
    def box_office_performance():
        return Database.fetch_all(
            "SELECT * FROM v_box_office_performance ORDER BY TotalRevenue DESC"
        )

    # ------------------------------------------------------------------
    # DASHBOARD
    # ------------------------------------------------------------------
    @staticmethod
    def dashboard():
        return Database.fetch_one("""
            SELECT
                (SELECT COUNT(*) FROM Events
                  WHERE EventDate >= NOW() AND Status='Scheduled') AS UpcomingEvents,
                (SELECT COUNT(*) FROM Customers)                   AS TotalCustomers,
                (SELECT COUNT(*) FROM Seats WHERE Status='Sold')   AS TicketsSold,
                (SELECT COALESCE(SUM(Amount),0)
                   FROM Seats WHERE Status='Sold')                 AS TotalRevenue,
                (SELECT COUNT(*) FROM Seats
                  WHERE Status='Sold'
                    AND DATE(SaleDate) = CURDATE())                AS TodaySales,
                (SELECT COALESCE(SUM(Amount),0) FROM Seats
                  WHERE Status='Sold'
                    AND DATE(SaleDate) = CURDATE())                AS TodayRevenue
        """)

    # ------------------------------------------------------------------
    # TOP KHÁCH HÀNG
    # ------------------------------------------------------------------
    @staticmethod
    def top_customers(top_n: int = 10):
        return Database.fetch_all("""
            SELECT c.CustomerID, c.CustomerName, c.PhoneNumber,
                   COUNT(s.SeatID)                AS TotalPurchases,
                   COALESCE(SUM(s.Amount),0)      AS TotalSpent,
                   fn_customer_tier(c.CustomerID) AS Tier
              FROM Customers c
              LEFT JOIN Seats s ON c.CustomerID = s.CustomerID
                               AND s.Status='Sold'
             GROUP BY c.CustomerID, c.CustomerName, c.PhoneNumber
             ORDER BY TotalSpent DESC
             LIMIT %s
        """, (top_n,))
