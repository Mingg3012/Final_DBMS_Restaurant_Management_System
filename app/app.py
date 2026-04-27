from flask import Flask, render_template, request, redirect, url_for, flash, session
from werkzeug.security import generate_password_hash, check_password_hash
from mysql.connector import Error
from db import get_connection

app = Flask(__name__)
app.secret_key = "restaurant-management-secret-key"
ROLE_CONFIG = {
    "admin": {
        "label": "Admin",
        "description": "Full system access",
        "pages": [
            "dashboard",
            "customers",
            "tables",
            "menu",
            "staff",
            "reservations",
            "orders",
            "invoices",
            "reports",
            "logs"
        ],
        "actions": [
            "add_customer",
            "update_table",
            "add_menu_item",
            "update_menu_item",
            "add_staff",
            "add_reservation",
            "confirm_reservation",
            "create_order",
            "add_order_item",
            "generate_invoice",
            "pay_invoice",
            "update_order_status"
        ]
    },

    "cashier": {
        "label": "Cashier",
        "description": "Billing and customer service access",
        "pages": [
            "dashboard",
            "customers",
            "tables",
            "menu",
            "orders",
            "invoices",
            "reports"
        ],
        "actions": [
            "add_customer",
            "generate_invoice",
            "pay_invoice"
        ]
    },

    "waiter": {
        "label": "Waiter",
        "description": "Table, reservation, and order access",
        "pages": [
            "dashboard",
            "tables",
            "menu",
            "reservations",
            "orders"
        ],
        "actions": [
            "add_reservation",
            "create_order",
            "add_order_item",
            "update_order_status"
        ]
    }
}

USER_ACCOUNTS = {
    "admin": {
        "display_name": "Restaurant Manager",
        "role": "admin",
        "password_hash": generate_password_hash("admin123")
    },
    "cashier": {
        "display_name": "Cashier Staff",
        "role": "cashier",
        "password_hash": generate_password_hash("cashier123")
    },
    "waiter": {
        "display_name": "Waiter Staff",
        "role": "waiter",
        "password_hash": generate_password_hash("waiter123")
    }
}

@app.before_request
def require_login():
    allowed_routes = ["login", "static"]

    if request.endpoint in allowed_routes:
        return

    if "username" not in session:
        return redirect(url_for("login"))


@app.route("/login", methods=["GET", "POST"])
def login():
    if "username" in session:
        return redirect(url_for("index"))

    if request.method == "POST":
        username = request.form["username"].strip()
        password = request.form["password"]

        user = USER_ACCOUNTS.get(username)

        if user and check_password_hash(user["password_hash"], password):
            session["username"] = username
            session["display_name"] = user["display_name"]
            session["current_role"] = user["role"]

            flash(f"Welcome, {user['display_name']}.", "success")
            return redirect(url_for("index"))

        flash("Invalid username or password.", "danger")

    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    flash("You have been logged out.", "success")
    return redirect(url_for("login"))


def get_current_role():
    return session.get("current_role", "admin")


def can_access_page(page_name):
    role = get_current_role()
    return page_name in ROLE_CONFIG[role]["pages"]


def can_do_action(action_name):
    role = get_current_role()
    return action_name in ROLE_CONFIG[role]["actions"]


@app.context_processor
def inject_role():
    role = get_current_role()

    return {
        "current_role": role,
        "current_role_info": ROLE_CONFIG[role],
        "current_user": session.get("display_name", "Guest"),
        "roles": ROLE_CONFIG,
        "can_access_page": can_access_page,
        "can_do_action": can_do_action
    }


def require_page(page_name):
    if not can_access_page(page_name):
        flash("Access denied. Your current role does not have permission to access this page.", "danger")
        return False
    return True


def require_action(action_name):
    if not can_do_action(action_name):
        flash("Access denied. Your current role does not have permission to perform this action.", "danger")
        return False
    return True


@app.route("/")
def index():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT COUNT(*) AS total_customers FROM Customers")
    total_customers = cursor.fetchone()["total_customers"]

    cursor.execute("SELECT COUNT(*) AS total_tables FROM RestaurantTables")
    total_tables = cursor.fetchone()["total_tables"]

    cursor.execute("SELECT COUNT(*) AS total_menu_items FROM MenuItems")
    total_menu_items = cursor.fetchone()["total_menu_items"]

    cursor.execute("""
        SELECT IFNULL(SUM(TotalAmount), 0) AS total_revenue
        FROM Invoices
        WHERE PaymentStatus = 'paid'
    """)
    total_revenue = cursor.fetchone()["total_revenue"]

    cursor.execute("""
        SELECT COUNT(*) AS available_tables
        FROM RestaurantTables
        WHERE Status = 'available'
    """)
    available_tables = cursor.fetchone()["available_tables"]

    cursor.execute("""
        SELECT COUNT(*) AS reserved_tables
        FROM RestaurantTables
        WHERE Status = 'reserved'
    """)
    reserved_tables = cursor.fetchone()["reserved_tables"]

    cursor.execute("""
        SELECT COUNT(*) AS occupied_tables
        FROM RestaurantTables
        WHERE Status = 'occupied'
    """)
    occupied_tables = cursor.fetchone()["occupied_tables"]

    cursor.execute("""
    SELECT COUNT(*) AS maintenance_tables
    FROM RestaurantTables
    WHERE Status = 'maintenance'
    """)
    maintenance_tables = cursor.fetchone()["maintenance_tables"]

    cursor.execute("""
        SELECT COUNT(*) AS pending_reservations
        FROM Reservations
        WHERE Status = 'pending'
    """)
    pending_reservations = cursor.fetchone()["pending_reservations"]

    cursor.execute("""
        SELECT COUNT(*) AS today_reservations
        FROM Reservations
        WHERE DATE(ReservationDateTime) = CURDATE()
    """)
    today_reservations = cursor.fetchone()["today_reservations"]

    cursor.execute("""
        SELECT COUNT(*) AS unpaid_invoices
        FROM Invoices
        WHERE PaymentStatus = 'unpaid'
    """)
    unpaid_invoices = cursor.fetchone()["unpaid_invoices"]

    cursor.execute("""
        SELECT IFNULL(SUM(TotalAmount), 0) AS today_revenue
        FROM Invoices
        WHERE PaymentStatus = 'paid'
          AND DATE(PaymentDate) = CURDATE()
    """)
    today_revenue = cursor.fetchone()["today_revenue"]

    cursor.execute("""
        SELECT 
            r.ReservationID,
            c.CustomerName,
            t.TableNumber,
            r.ReservationDateTime,
            r.GuestCount,
            r.Status
        FROM Reservations r
        JOIN Customers c ON r.CustomerID = c.CustomerID
        JOIN RestaurantTables t ON r.TableID = t.TableID
        ORDER BY r.ReservationDateTime DESC
        LIMIT 6
    """)
    recent_reservations = cursor.fetchall()

    cursor.execute("""
        SELECT DishName, TotalQuantitySold, TotalSales
        FROM v_top_selling_dishes
        LIMIT 5
    """)
    top_dishes = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "index.html",
        total_customers=total_customers,
        total_tables=total_tables,
        total_menu_items=total_menu_items,
        total_revenue=total_revenue,
        available_tables=available_tables,
        reserved_tables=reserved_tables,
        occupied_tables=occupied_tables,
        maintenance_tables=maintenance_tables,
        pending_reservations=pending_reservations,
        today_reservations=today_reservations,
        unpaid_invoices=unpaid_invoices,
        today_revenue=today_revenue,
        recent_reservations=recent_reservations,
        top_dishes=top_dishes
    )


@app.route("/customers")
def customers():
    if not require_page("customers"):
        return redirect(url_for("index"))
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT CustomerID, CustomerName, PhoneNumber, Email, Address, CreatedAt
        FROM Customers
        ORDER BY CustomerID DESC
    """)
    customers = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template("customers.html", customers=customers)


@app.route("/customers/add", methods=["POST"])
def add_customer():
    if not require_action("add_customer"):
        return redirect(url_for("customers"))
    name = request.form["customer_name"]
    phone = request.form["phone_number"]
    email = request.form["email"]
    address = request.form["address"]

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO Customers (CustomerName, PhoneNumber, Email, Address)
            VALUES (%s, %s, %s, %s)
        """, (name, phone, email, address))

        conn.commit()
        flash("Customer added successfully.", "success")

    except Error as e:
        flash(f"Error: {e}", "danger")

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("customers"))


@app.route("/menu")
def menu():
    if not require_page("menu"):
        return redirect(url_for("index"))

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT 
            m.DishID,
            m.DishName,
            c.CategoryName,
            m.CategoryID,
            m.Price,
            m.Availability
        FROM MenuItems m
        LEFT JOIN MenuCategories c ON m.CategoryID = c.CategoryID
        ORDER BY m.DishID DESC
    """)
    menu_items = cursor.fetchall()

    cursor.execute("""
        SELECT CategoryID, CategoryName
        FROM MenuCategories
        ORDER BY CategoryName
    """)
    categories = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "menu.html",
        menu_items=menu_items,
        categories=categories
    )

@app.route("/menu/add", methods=["POST"])
def add_menu_item():
    if not require_action("add_menu_item"):
        return redirect(url_for("menu"))

    category_id = request.form["category_id"]
    dish_name = request.form["dish_name"]
    price = request.form["price"]
    availability = request.form["availability"]

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO MenuItems (CategoryID, DishName, Price, Availability)
            VALUES (%s, %s, %s, %s)
        """, (category_id, dish_name, price, availability))

        conn.commit()
        flash("Menu item added successfully.", "success")

    except Exception as e:
        flash(f"Error: {e}", "danger")

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("menu"))

@app.route("/menu/update-availability", methods=["POST"])
def update_menu_availability():
    if not require_action("update_menu_item"):
        return redirect(url_for("menu"))

    dish_id = request.form["dish_id"]
    availability = request.form["availability"]

    if availability not in ["available", "unavailable"]:
        flash("Invalid availability value.", "danger")
        return redirect(url_for("menu"))

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            UPDATE MenuItems
            SET Availability = %s
            WHERE DishID = %s
        """, (availability, dish_id))

        conn.commit()
        flash("Menu item availability updated successfully.", "success")

    except Exception as e:
        flash(f"Error: {e}", "danger")

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("menu"))


@app.route("/reservations")
def reservations():
    if not require_page("reservations"):
        return redirect(url_for("index"))
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT 
            r.ReservationID,
            c.CustomerName,
            t.TableNumber,
            r.ReservationDateTime,
            r.GuestCount,
            r.Status
        FROM Reservations r
        JOIN Customers c ON r.CustomerID = c.CustomerID
        JOIN RestaurantTables t ON r.TableID = t.TableID
        ORDER BY r.ReservationDateTime DESC
    """)
    reservations = cursor.fetchall()

    cursor.execute("""
        SELECT CustomerID, CustomerName
        FROM Customers
        ORDER BY CustomerName
    """)
    customers = cursor.fetchall()

    cursor.execute("""
        SELECT TableID, TableNumber, Capacity, Status
        FROM RestaurantTables
        WHERE Status IN ('available', 'reserved')
        ORDER BY TableNumber
    """)
    tables = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "reservations.html",
        reservations=reservations,
        customers=customers,
        tables=tables
    )


@app.route("/reservations/add", methods=["POST"])
def add_reservation():
    if not require_action("add_reservation"):
        return redirect(url_for("reservations"))
    customer_id = request.form["customer_id"]
    table_id = request.form["table_id"]
    reservation_datetime = request.form["reservation_datetime"]
    guest_count = request.form["guest_count"]

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.callproc(
            "sp_create_reservation",
            [customer_id, table_id, reservation_datetime, guest_count]
        )

        conn.commit()
        flash("Reservation created successfully.", "success")

    except Error as e:
        flash(f"Error: {e}", "danger")

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("reservations"))


@app.route("/reservations/confirm/<int:reservation_id>", methods=["POST"])
def confirm_reservation(reservation_id):
    if not require_action("confirm_reservation"):
        return redirect(url_for("reservations"))
    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.callproc("sp_confirm_reservation", [reservation_id])

        conn.commit()
        flash("Reservation confirmed successfully.", "success")

    except Error as e:
        flash(f"Error: {e}", "danger")

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("reservations"))


@app.route("/reports")
def reports():
    if not require_page("reports"):
        return redirect(url_for("index"))
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT * FROM v_top_selling_dishes")
    top_dishes = cursor.fetchall()

    cursor.execute("SELECT * FROM v_daily_revenue")
    daily_revenue = cursor.fetchall()

    cursor.execute("SELECT * FROM v_customer_visit_summary")
    customer_visits = cursor.fetchall()

    cursor.execute("SELECT * FROM v_table_usage_statistics")
    table_usage = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "reports.html",
        top_dishes=top_dishes,
        daily_revenue=daily_revenue,
        customer_visits=customer_visits,
        table_usage=table_usage
    )


@app.route("/tables")
def tables():
    if not require_page("tables"):
        return redirect(url_for("index"))

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT TableID, TableNumber, Capacity, Status, CreatedAt
        FROM RestaurantTables
        ORDER BY TableNumber
    """)
    tables = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template("tables.html", tables=tables)

@app.route("/tables/update-status", methods=["POST"])
def update_table_status():
    if not require_action("update_table"):
        return redirect(url_for("tables"))

    table_id = request.form["table_id"]
    new_status = request.form["status"]

    allowed_statuses = ["available", "reserved", "occupied", "maintenance"]

    if new_status not in allowed_statuses:
        flash("Invalid table status.", "danger")
        return redirect(url_for("tables"))

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            UPDATE RestaurantTables
            SET Status = %s
            WHERE TableID = %s
        """, (new_status, table_id))

        conn.commit()
        flash("Table status updated successfully.", "success")

    except Exception as e:
        flash(f"Error: {e}", "danger")

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("tables"))




@app.route("/staff")
def staff():
    if not require_page("staff"):
        return redirect(url_for("index"))

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT StaffID, StaffName, Role, PhoneNumber, Username, CreatedAt
        FROM Staff
        ORDER BY StaffID DESC
    """)
    staff_members = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template("staff.html", staff_members=staff_members)

@app.route("/staff/add", methods=["POST"])
def add_staff():
    if not require_action("add_staff"):
        return redirect(url_for("staff"))

    staff_name = request.form["staff_name"]
    role = request.form["role"]
    phone_number = request.form["phone_number"]
    username = request.form["username"]

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO Staff (StaffName, Role, PhoneNumber, Username)
            VALUES (%s, %s, %s, %s)
        """, (staff_name, role, phone_number, username))

        conn.commit()
        flash("Staff member added successfully.", "success")

    except Exception as e:
        flash(f"Error: {e}", "danger")

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("staff"))


@app.route("/orders")
def orders():
    if not require_page("orders"):
        return redirect(url_for("index"))

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT 
            o.OrderID,
            c.CustomerName,
            t.TableNumber,
            s.StaffName,
            o.OrderDateTime,
            o.OrderStatus AS Status
        FROM Orders o
        JOIN Customers c ON o.CustomerID = c.CustomerID
        JOIN RestaurantTables t ON o.TableID = t.TableID
        JOIN Staff s ON o.StaffID = s.StaffID
        ORDER BY o.OrderID DESC
    """)
    orders = cursor.fetchall()

    cursor.execute("""
        SELECT 
            o.OrderID,
            c.CustomerName,
            t.TableNumber,
            o.OrderStatus AS Status
        FROM Orders o
        JOIN Customers c ON o.CustomerID = c.CustomerID
        JOIN RestaurantTables t ON o.TableID = t.TableID
        WHERE o.OrderStatus = 'open'
        ORDER BY o.OrderID DESC
    """)
    open_orders = cursor.fetchall()

    cursor.execute("""
        SELECT 
            oi.OrderItemID,
            oi.OrderID,
            m.DishName,
            oi.Quantity,
            oi.UnitPrice,
            oi.LineTotal,
            oi.Notes
        FROM OrderItems oi
        JOIN MenuItems m ON oi.DishID = m.DishID
        ORDER BY oi.OrderItemID DESC
        LIMIT 50
    """)
    order_items = cursor.fetchall()

    cursor.execute("SELECT CustomerID, CustomerName FROM Customers ORDER BY CustomerName")
    customers = cursor.fetchall()

    cursor.execute("""
        SELECT TableID, TableNumber, Capacity, Status
        FROM RestaurantTables
        WHERE Status IN ('available', 'reserved', 'occupied')
        ORDER BY TableNumber
    """)
    tables = cursor.fetchall()

    cursor.execute("SELECT StaffID, StaffName, Role FROM Staff ORDER BY StaffName")
    staff_members = cursor.fetchall()

    cursor.execute("""
        SELECT DishID, DishName, Price
        FROM MenuItems
        WHERE Availability = 'available'
        ORDER BY DishName
    """)
    menu_items = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
    "orders.html",
    orders=orders,
    open_orders=open_orders,
    order_items=order_items,
    customers=customers,
    tables=tables,
    staff_members=staff_members,
    menu_items=menu_items
)

@app.route("/orders/create", methods=["POST"])
def create_order():
    if not require_action("create_order"):
        return redirect(url_for("orders"))

    customer_id = request.form["customer_id"]
    table_id = request.form["table_id"]
    staff_id = request.form["staff_id"]

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.callproc("sp_create_order", [customer_id, table_id, staff_id])

        conn.commit()
        flash("Order created successfully.", "success")

    except Exception as e:
        flash(f"Error: {e}", "danger")

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("orders"))

@app.route("/orders/add-item", methods=["POST"])
def add_order_item():
    if not require_action("add_order_item"):
        return redirect(url_for("orders"))

    order_id = request.form["order_id"]
    dish_id = request.form["dish_id"]
    quantity = request.form["quantity"]
    notes = request.form.get("notes") or None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT OrderStatus
            FROM Orders
            WHERE OrderID = %s
        """, (order_id,))
        order = cursor.fetchone()

        if not order:
            flash("Order not found.", "danger")
            return redirect(url_for("orders"))

        if order["OrderStatus"] != "open":
            flash("Cannot add items to an order that is not open.", "danger")
            return redirect(url_for("orders"))

        cursor = conn.cursor()
        cursor.callproc("sp_add_order_item", [order_id, dish_id, quantity, notes])

        conn.commit()
        flash("Order item added successfully.", "success")

    except Exception as e:
        flash(f"Error: {e}", "danger")

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("orders"))

@app.route("/orders/update-status", methods=["POST"])
def update_order_status():
    if not require_action("update_order_status"):
        return redirect(url_for("orders"))

    order_id = request.form["order_id"]
    new_status = request.form["order_status"]

    allowed_statuses = ["open", "served", "cancelled", "closed"]

    if new_status not in allowed_statuses:
        flash("Invalid order status.", "danger")
        return redirect(url_for("orders"))

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT OrderStatus
            FROM Orders
            WHERE OrderID = %s
        """, (order_id,))
        order = cursor.fetchone()

        if not order:
            flash("Order not found.", "danger")
            return redirect(url_for("orders"))

        current_status = order["OrderStatus"]

        if current_status in ["closed", "cancelled"]:
            flash("Closed or cancelled orders cannot be changed.", "danger")
            return redirect(url_for("orders"))

        cursor.execute("""
            UPDATE Orders
            SET OrderStatus = %s
            WHERE OrderID = %s
        """, (new_status, order_id))

        conn.commit()
        flash("Order status updated successfully.", "success")

    except Exception as e:
        flash(f"Error: {e}", "danger")

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("orders"))


@app.route("/invoices")
def invoices():
    if not require_page("invoices"):
        return redirect(url_for("index"))

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT 
            i.InvoiceID,
            i.OrderID,
            c.CustomerName,
            t.TableNumber,
            i.SubTotal,
            i.ServiceCharge,
            i.DiscountAmount,
            i.TotalAmount,
            i.PaymentStatus,
            i.PaymentDate
        FROM Invoices i
        JOIN Orders o ON i.OrderID = o.OrderID
        JOIN Customers c ON o.CustomerID = c.CustomerID
        JOIN RestaurantTables t ON o.TableID = t.TableID
        ORDER BY i.InvoiceID DESC
    """)
    invoices = cursor.fetchall()

    cursor.execute("""
        SELECT 
            o.OrderID,
            c.CustomerName,
            t.TableNumber,
            o.OrderStatus AS Status
        FROM Orders o
        JOIN Customers c ON o.CustomerID = c.CustomerID
        JOIN RestaurantTables t ON o.TableID = t.TableID
        WHERE o.OrderID NOT IN (
            SELECT OrderID FROM Invoices
        )
        AND o.OrderStatus = 'served'
        ORDER BY o.OrderID DESC
    """)
    uninvoiced_orders = cursor.fetchall()

    cursor.execute("""
        SELECT InvoiceID, TotalAmount
        FROM Invoices
        WHERE PaymentStatus = 'unpaid'
        ORDER BY InvoiceID DESC
    """)
    unpaid_invoices = cursor.fetchall()

    cursor.execute("""
        SELECT 
            p.PaymentID,
            p.InvoiceID,
            p.PaymentMethod,
            p.Amount,
            p.PaymentDate
        FROM Payments p
        ORDER BY p.PaymentID DESC
        LIMIT 50
    """)
    payments = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "invoices.html",
        invoices=invoices,
        uninvoiced_orders=uninvoiced_orders,
        unpaid_invoices=unpaid_invoices,
        payments=payments
    )

@app.route("/invoices/generate", methods=["POST"])
def generate_invoice():
    if not require_action("generate_invoice"):
        return redirect(url_for("invoices"))

    order_id = request.form["order_id"]

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT OrderStatus
            FROM Orders
            WHERE OrderID = %s
        """, (order_id,))
        order = cursor.fetchone()

        if not order:
            flash("Order not found.", "danger")
            return redirect(url_for("invoices"))

        if order["OrderStatus"] != "served":
            flash("Only served orders can be invoiced.", "danger")
            return redirect(url_for("invoices"))

        cursor = conn.cursor()
        cursor.callproc("sp_generate_invoice", [order_id])

        cursor.execute("""
            UPDATE Orders
            SET OrderStatus = 'closed'
            WHERE OrderID = %s
        """, (order_id,))

        conn.commit()
        flash("Invoice generated successfully. Order has been closed.", "success")

    except Exception as e:
        flash(f"Error: {e}", "danger")

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("invoices"))

@app.route("/invoices/pay", methods=["POST"])
def pay_invoice():
    if not require_action("pay_invoice"):
        return redirect(url_for("invoices"))

    invoice_id = request.form["invoice_id"]
    payment_method = request.form["payment_method"]
    amount = request.form["amount"]

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.callproc("sp_pay_invoice", [invoice_id, payment_method, amount])

        conn.commit()
        flash("Invoice paid successfully.", "success")

    except Exception as e:
        flash(f"Error: {e}", "danger")

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("invoices"))

@app.route("/logs")
def logs():
    if not require_page("logs"):
        return redirect(url_for("index"))

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT 
            l.LogID,
            t.TableNumber,
            l.OldStatus,
            l.NewStatus,
            l.Reason,
            l.ChangedAt
        FROM TableStatusLog l
        LEFT JOIN RestaurantTables t ON l.TableID = t.TableID
        ORDER BY l.ChangedAt DESC
        LIMIT 50
    """)
    table_logs = cursor.fetchall()

    cursor.execute("""
        SELECT 
            AuditID,
            ActionType,
            TableName,
            RecordID,
            Description,
            CreatedAt
        FROM AuditLog
        ORDER BY CreatedAt DESC
        LIMIT 50
    """)
    audit_logs = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "logs.html",
        table_logs=table_logs,
        audit_logs=audit_logs
    )



if __name__ == "__main__":
    app.run(debug=True)