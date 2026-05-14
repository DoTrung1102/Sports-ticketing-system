"""
data_generator.py - Sinh dữ liệu mẫu lớn (mô hình 5 bảng)
Bán vé = UPDATE bảng Seats
"""
import random
from datetime import datetime, timedelta
from faker import Faker

from database import Database

fake = Faker("vi_VN")
random.seed(42)

# Cấu hình
N_EVENTS    = 50
N_CUSTOMERS = 500
N_OFFICES   = 10
SEATS_PER_EVENT = 60
SALES_RATIO  = 0.6     # bán ~60% số ghế

SPORTS = ["Bóng đá", "Bóng rổ", "Tennis", "Bóng chuyền",
          "Boxing", "Cầu lông", "Điền kinh", "Bơi lội"]
VENUES = ["SVĐ Hàng Đẫy", "SVĐ Mỹ Đình", "SVĐ Thống Nhất",
          "CIS Arena", "NTĐ Phú Thọ", "Bình Dương Tennis Center",
          "SVĐ Vinh", "Quân Khu 7", "Cần Thơ Sport Hall",
          "Bắc Ninh Stadium"]
TICKET_TYPES = ["VIP", "Standard", "Economy", "Student"]
PAYMENTS     = ["Cash", "Card", "EWallet", "BankTransfer"]


def truncate_all():
    print("• Truncating tables...")
    with Database.get_cursor(commit=True) as cur:
        cur.execute("SET FOREIGN_KEY_CHECKS=0")
        for t in ["Seats", "Tickets", "Customers", "BoxOffices", "Events"]:
            cur.execute(f"TRUNCATE TABLE {t}")
        cur.execute("SET FOREIGN_KEY_CHECKS=1")


def gen_events():
    print(f"• Sinh {N_EVENTS} sự kiện...")
    rows = []
    base = datetime.now().date()
    for i in range(N_EVENTS):
        sport = random.choice(SPORTS)
        offset = random.randint(-60, 180)
        hour = random.choice([15, 17, 19, 20])
        edate = datetime.combine(base + timedelta(days=offset),
                                 datetime.min.time()) + timedelta(hours=hour)
        status = ("Completed" if offset < 0 else
                  random.choices(["Scheduled", "Cancelled"], [0.95, 0.05])[0])
        rows.append((
            f"{sport} - Trận {i+1}",
            edate,
            random.choice(VENUES),
            sport,
            status,
        ))
    with Database.get_cursor(commit=True) as cur:
        cur.executemany("""
            INSERT INTO Events (EventName, EventDate, Venue, Sport, Status)
            VALUES (%s,%s,%s,%s,%s)
        """, rows)


def gen_customers():
    print(f"• Sinh {N_CUSTOMERS} khách hàng...")
    rows, used = [], set()
    while len(rows) < N_CUSTOMERS:
        phone = "09" + "".join(random.choices("0123456789", k=8))
        if phone in used: continue
        used.add(phone)
        rows.append((fake.name(), phone,
                     fake.address().replace("\n", ", ")))
    with Database.get_cursor(commit=True) as cur:
        cur.executemany("""
            INSERT INTO Customers (CustomerName, PhoneNumber, Address)
            VALUES (%s,%s,%s)
        """, rows)


def gen_box_offices():
    print(f"• Sinh {N_OFFICES} phòng vé...")
    rows = [(f"Phòng vé {fake.city()}",
             fake.address().replace("\n", ", "))
            for _ in range(N_OFFICES)]
    with Database.get_cursor(commit=True) as cur:
        cur.executemany(
            "INSERT INTO BoxOffices (OfficeName, Address) VALUES (%s,%s)", rows
        )


def gen_tickets():
    print("• Sinh loại vé cho mỗi sự kiện...")
    event_ids = [r["EventID"] for r in Database.fetch_all(
        "SELECT EventID FROM Events")]
    rows = []
    price_table = {
        "VIP":      (1000000, 5000000),
        "Standard": (300000, 1000000),
        "Economy":  (100000, 400000),
        "Student":  (50000, 200000),
    }
    qty_table = {"VIP":(100,500), "Standard":(2000,10000),
                 "Economy":(2000,15000), "Student":(500,2000)}
    for eid in event_ids:
        for tt in TICKET_TYPES:
            price = random.randint(*price_table[tt])
            qty   = random.randint(*qty_table[tt])
            rows.append((eid, tt, price, qty))
    with Database.get_cursor(commit=True) as cur:
        cur.executemany("""
            INSERT INTO Tickets (EventID, TicketType, Price, Quantity)
            VALUES (%s,%s,%s,%s)
        """, rows)


def gen_seats():
    print(f"• Sinh ghế ({SEATS_PER_EVENT}/sự kiện)...")
    event_ids = [r["EventID"] for r in Database.fetch_all(
        "SELECT EventID FROM Events")]
    rows = []
    for eid in event_ids:
        # 10 VIP + 25 Standard + 20 Economy + 5 Student
        configs = [("VIP", 10, "V"), ("Standard", 25, "A"),
                   ("Economy", 20, "C"), ("Student", 5, "S")]
        for stype, n, prefix in configs:
            for i in range(n):
                rows.append((eid, f"{prefix}{i+1:03d}", stype))
    with Database.get_cursor(commit=True) as cur:
        cur.executemany("""
            INSERT INTO Seats (EventID, SeatNumber, SeatType)
            VALUES (%s,%s,%s)
        """, rows)


def gen_sales():
    """Bán ghế = UPDATE Seats. Chỉ bán ghế của sự kiện còn Scheduled tương lai."""
    print(f"• Sinh giao dịch (~{int(SALES_RATIO*100)}% ghế khả dụng)...")

    candidates = Database.fetch_all("""
        SELECT s.SeatID, s.EventID, s.SeatType, t.Price
          FROM Seats s
          JOIN Tickets t ON s.EventID = t.EventID
                        AND s.SeatType = t.TicketType
          JOIN Events  e ON s.EventID = e.EventID
         WHERE s.Status='Available'
           AND e.Status='Scheduled'
           AND e.EventDate >= NOW()
    """)
    random.shuffle(candidates)
    target = int(len(candidates) * SALES_RATIO)
    customers = [r["CustomerID"] for r in Database.fetch_all(
        "SELECT CustomerID FROM Customers")]
    offices   = [r["BoxOfficeID"] for r in Database.fetch_all(
        "SELECT BoxOfficeID FROM BoxOffices")]

    success = fail = 0
    for c in candidates[:target]:
        try:
            with Database.get_cursor(commit=True) as cur:
                sale_date = datetime.now() - timedelta(
                    days=random.randint(0, 60),
                    hours=random.randint(0, 23)
                )
                cur.execute("""
                    UPDATE Seats
                       SET CustomerID    = %s,
                           BoxOfficeID   = %s,
                           SaleDate      = %s,
                           PaymentMethod = %s,
                           Amount        = %s,
                           Status        = 'Sold'
                     WHERE SeatID = %s
                """, (
                    random.choice(customers),
                    random.choice(offices),
                    sale_date,
                    random.choice(PAYMENTS),
                    c["Price"],
                    c["SeatID"],
                ))
            success += 1
        except Exception:
            fail += 1
    print(f"  ✓ Thành công: {success}, thất bại: {fail}")


def main():
    Database.init_pool()
    truncate_all()
    gen_events()
    gen_box_offices()
    gen_customers()
    gen_tickets()
    gen_seats()
    gen_sales()

    print("\n=== TỔNG KẾT ===")
    counts = Database.fetch_all("""
        SELECT 'Events'             AS T, COUNT(*) AS N FROM Events
        UNION ALL SELECT 'Customers',    COUNT(*) FROM Customers
        UNION ALL SELECT 'BoxOffices',   COUNT(*) FROM BoxOffices
        UNION ALL SELECT 'Tickets',      COUNT(*) FROM Tickets
        UNION ALL SELECT 'Seats (total)',COUNT(*) FROM Seats
        UNION ALL SELECT 'Seats (sold)', COUNT(*) FROM Seats WHERE Status='Sold'
    """)
    for r in counts:
        print(f"  {r['T']:<15}{r['N']:>6}")
    print("\n✓ Hoàn thành!")


if __name__ == "__main__":
    main()
