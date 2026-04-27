-- =========================================================
-- 03_indexes.sql
-- Indexes for Query Optimization
-- =========================================================

USE restaurant_db;

-- Search customer by phone number
CREATE INDEX idx_customer_phone
ON Customers(PhoneNumber);

-- Search dish by dish name
CREATE INDEX idx_menu_dish_name
ON MenuItems(DishName);

-- Search menu items by category
CREATE INDEX idx_menu_category
ON MenuItems(CategoryID);

-- Search reservations by date/time
CREATE INDEX idx_reservation_datetime
ON Reservations(ReservationDateTime);

-- Search reservations by customer
CREATE INDEX idx_reservation_customer
ON Reservations(CustomerID);

-- Search reservations by table
CREATE INDEX idx_reservation_table
ON Reservations(TableID);

-- Search orders by table
CREATE INDEX idx_order_table
ON Orders(TableID);

-- Search orders by date
CREATE INDEX idx_order_datetime
ON Orders(OrderDateTime);

-- Search order items by dish
CREATE INDEX idx_orderitem_dish
ON OrderItems(DishID);

-- Search invoices by payment date
CREATE INDEX idx_invoice_payment_date
ON Invoices(PaymentDate);

-- Search invoices by payment status
CREATE INDEX idx_invoice_payment_status
ON Invoices(PaymentStatus);