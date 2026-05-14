"""
ui.py - Console menu (mô hình 5 bảng)
"""
from datetime import datetime
from tabulate import tabulate

from booking_service import (
    EventService, CustomerService, BookingService, BoxOfficeService
)
from reporting_service import ReportingService
from config import APP_NAME, APP_VERSION


def fmt_currency(amount):
    if amount is None:
        return "0 VND"
    return f"{float(amount):,.0f} VND"


def header(title):
    print("\n" + "═" * 70)
    print(f"  {title}")
    print("═" * 70)


def pause():
    input("\n[Nhấn Enter để tiếp tục] ")


def show_table(rows, headers="keys", title=None):
    if title:
        print(f"\n► {title}")
    if not rows:
        print("(Không có dữ liệu)")
        return
    print(tabulate(rows, headers=headers, tablefmt="rounded_outline",
                   floatfmt=",.0f", showindex=False))


# =====================================================================
# MENU CON: SỰ KIỆN
# =====================================================================
def menu_events():
    while True:
        header("📅 QUẢN LÝ SỰ KIỆN")
        print("1. Liệt kê sự kiện sắp diễn ra")
        print("2. Tìm kiếm sự kiện")
        print("3. Xem chi tiết sự kiện")
        print("0. Quay lại")
        choice = input("\nChọn: ").strip()

        if choice == "1":
            rows = EventService.list_upcoming(20)
            show_table(rows, title="Sự kiện sắp diễn ra")
            pause()
        elif choice == "2":
            kw    = input("Từ khóa (tên/sân): ").strip()
            sport = input("Môn (bỏ trống nếu tất cả): ").strip()
            rows = EventService.search_events(kw, sport)
            show_table(rows, title=f"Kết quả tìm '{kw}'")
            pause()
        elif choice == "3":
            try:
                eid = int(input("Nhập EventID: "))
                e = EventService.get_event_detail(eid)
                if not e:
                    print("Không tìm thấy")
                else:
                    show_table([e], title=f"Sự kiện #{eid}")
                    tickets = BookingService.get_ticket_types(eid)
                    show_table(tickets, title="Loại vé")
            except ValueError:
                print("EventID không hợp lệ")
            pause()
        elif choice == "0":
            break


# =====================================================================
# MENU CON: ĐẶT VÉ
# =====================================================================
def menu_booking():
    header("🎫 ĐẶT VÉ MỚI")

    # 1. Khách hàng
    phone = input("SĐT khách hàng: ").strip()
    cus = CustomerService.find_by_phone(phone)
    if cus:
        print(f"✓ Khách quen: {cus['CustomerName']} (ID={cus['CustomerID']})")
        customer_id = cus["CustomerID"]
    else:
        print("Khách mới - nhập thông tin:")
        name    = input("  Họ tên: ").strip()
        address = input("  Địa chỉ (Enter bỏ qua): ").strip() or None
        try:
            customer_id = CustomerService.create(name, phone, address)
            print(f"✓ Đã tạo khách hàng ID={customer_id}")
        except Exception as e:
            print(f"✗ Lỗi tạo khách hàng: {e}")
            return

    # 2. Sự kiện
    upcoming = EventService.list_upcoming(20)
    show_table(upcoming, title="Sự kiện đang mở bán")
    try:
        event_id = int(input("\nChọn EventID: "))
    except ValueError:
        print("EventID không hợp lệ"); return

    # 3. Loại vé (để xem giá - chọn ghế là chọn loại)
    tickets = BookingService.get_ticket_types(event_id)
    show_table(tickets, title="Loại vé khả dụng")
    seat_type = input("\nLoại ghế muốn xem (VIP/Standard/Economy/Student): ").strip()

    # 4. Ghế còn trống
    seats = BookingService.get_available_seats(event_id, seat_type)
    if not seats:
        print(f"✗ Không còn ghế loại {seat_type}"); return
    show_table(seats[:30], title=f"Ghế trống loại {seat_type}")
    try:
        seat_id = int(input("Chọn SeatID: "))
    except ValueError:
        print("SeatID không hợp lệ"); return

    # 5. Phòng vé
    offices = BoxOfficeService.list_all()
    show_table(offices, title="Phòng vé")
    try:
        office_id = int(input("Chọn BoxOfficeID: "))
    except ValueError:
        print("BoxOfficeID không hợp lệ"); return

    # 6. Thanh toán
    print("\nPhương thức: 1.Cash  2.Card  3.EWallet  4.BankTransfer")
    pmap = {"1": "Cash", "2": "Card", "3": "EWallet", "4": "BankTransfer"}
    payment = pmap.get(input("Chọn (1-4): ").strip(), "Cash")

    # 7. Xác nhận
    if input("\nXác nhận đặt vé? (y/n): ").lower() != "y":
        print("Đã hủy"); return

    res = BookingService.book(customer_id, seat_id, office_id, payment)
    if res["ok"]:
        print(f"\n✓ {res['message']}")
        sale = BookingService.get_sale_detail(res["sale_id"])
        if sale:
            show_table([sale], title="Hóa đơn")
    else:
        print(f"\n✗ {res['message']}")


# =====================================================================
# MENU CON: HỦY VÉ
# =====================================================================
def menu_cancel():
    header("❌ HỦY VÉ")
    try:
        seat_id = int(input("Nhập SeatID cần hủy: "))
    except ValueError:
        print("SeatID không hợp lệ"); return

    sale = BookingService.get_sale_detail(seat_id)
    if not sale:
        print("Không tìm thấy"); return
    show_table([sale], title="Giao dịch")

    if input("\nXác nhận hủy? (y/n): ").lower() != "y":
        return

    res = BookingService.cancel(seat_id)
    print(f"\n{'✓' if res['ok'] else '✗'} {res['message']}")


# =====================================================================
# MENU CON: KHÁCH HÀNG
# =====================================================================
def menu_customer():
    while True:
        header("👤 QUẢN LÝ KHÁCH HÀNG")
        print("1. Tra cứu khách hàng theo SĐT")
        print("2. Lịch sử mua vé của khách")
        print("3. Phân hạng khách hàng")
        print("0. Quay lại")
        c = input("\nChọn: ").strip()
        if c == "1":
            phone = input("SĐT: ").strip()
            cus = CustomerService.find_by_phone(phone)
            if cus:
                show_table([cus], title="Khách hàng")
            else:
                print("Không tìm thấy")
            pause()
        elif c == "2":
            try:
                cid = int(input("CustomerID: "))
                rows = CustomerService.purchase_history(cid)
                show_table(rows, title=f"Lịch sử mua vé KH#{cid}")
            except ValueError:
                print("ID không hợp lệ")
            pause()
        elif c == "3":
            try:
                cid = int(input("CustomerID: "))
                info = CustomerService.get_tier_info(cid)
                show_table([info], title="Phân hạng")
            except ValueError:
                print("ID không hợp lệ")
            pause()
        elif c == "0":
            break


# =====================================================================
# MENU CON: BÁO CÁO
# =====================================================================
def menu_reports():
    while True:
        header("📊 BÁO CÁO & THỐNG KÊ")
        print("1. Dashboard tổng quan")
        print("2. Doanh thu theo sự kiện")
        print("3. Doanh thu theo loại vé")
        print("4. Doanh thu theo khoảng ngày")
        print("5. Tình trạng ghế (toàn hệ thống)")
        print("6. Sự kiện đã sold-out")
        print("7. Top sự kiện được ưa chuộng")
        print("8. Hiệu suất phòng vé")
        print("9. Top khách hàng VIP")
        print("0. Quay lại")
        c = input("\nChọn: ").strip()

        if c == "1":
            d = ReportingService.dashboard()
            print(f"""
╭────────────────────────────────────────────────╮
│  📅 Sự kiện sắp tới:    {d['UpcomingEvents']:>6}              │
│  👥 Tổng khách hàng:    {d['TotalCustomers']:>6}              │
│  🎫 Tổng vé đã bán:     {d['TicketsSold']:>6}              │
│  💰 Tổng doanh thu:     {fmt_currency(d['TotalRevenue']):>20}  │
│  🕒 Vé bán hôm nay:     {d['TodaySales']:>6}              │
│  💵 Doanh thu hôm nay:  {fmt_currency(d['TodayRevenue']):>20}  │
╰────────────────────────────────────────────────╯""")
            pause()
        elif c == "2":
            show_table(ReportingService.revenue_by_event(),
                       title="Doanh thu theo sự kiện")
            pause()
        elif c == "3":
            show_table(ReportingService.revenue_by_ticket_type(),
                       title="Doanh thu theo loại vé")
            pause()
        elif c == "4":
            f = input("Từ ngày (YYYY-MM-DD): ").strip()
            t = input("Đến ngày (YYYY-MM-DD): ").strip()
            show_table(ReportingService.revenue_summary(f, t),
                       title=f"Doanh thu {f} → {t}")
            pause()
        elif c == "5":
            show_table(ReportingService.seat_availability(),
                       title="Tình trạng ghế")
            pause()
        elif c == "6":
            show_table(ReportingService.sold_out_events(),
                       title="Sự kiện sold-out")
            pause()
        elif c == "7":
            show_table(ReportingService.event_popularity(10),
                       title="Top 10 sự kiện ưa chuộng")
            pause()
        elif c == "8":
            show_table(ReportingService.box_office_performance(),
                       title="Hiệu suất phòng vé")
            pause()
        elif c == "9":
            show_table(ReportingService.top_customers(10),
                       title="Top 10 khách hàng VIP")
            pause()
        elif c == "0":
            break


# =====================================================================
# MAIN MENU
# =====================================================================
def main_menu():
    while True:
        print(f"\n{'═'*70}")
        print(f"  🏟️   {APP_NAME}  (v{APP_VERSION})")
        print(f"  {datetime.now().strftime('%A, %d/%m/%Y %H:%M:%S')}")
        print(f"{'═'*70}")
        print("  1. Quản lý sự kiện")
        print("  2. Đặt vé mới")
        print("  3. Hủy vé")
        print("  4. Quản lý khách hàng")
        print("  5. Báo cáo & thống kê")
        print("  0. Thoát")
        c = input("\n  Chọn: ").strip()
        if   c == "1": menu_events()
        elif c == "2": menu_booking()
        elif c == "3": menu_cancel(); pause()
        elif c == "4": menu_customer()
        elif c == "5": menu_reports()
        elif c == "0":
            print("Tạm biệt! 👋")
            break
        else:
            print("Lựa chọn không hợp lệ")
