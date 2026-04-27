-- =========================================================
-- 04_views.sql
-- Views for Reporting and Querying
-- =========================================================

USE restaurant_db;

-- =========================================================
-- 1. AVAILABLE TABLES
-- =========================================================
CREATE OR REPLACE VIEW v_available_tables AS
SELECT
    TableID,
    TableNumber,
    Capacity,
    Status
FROM RestaurantTables
WHERE Status = 'available';

-- =========================================================
-- 2. DAILY RESERVATIONS
-- =========================================================
CREATE OR REPLACE VIEW v_daily_reservations AS
SELECT
    DATE(r.ReservationDateTime) AS ReservationDate,
    r.ReservationID,
    c.CustomerName,
    c.PhoneNumber,
    t.TableNumber,
    r.GuestCount,
    r.Status
FROM Reservations r
JOIN Customers c
    ON r.CustomerID = c.CustomerID
JOIN RestaurantTables t
    ON r.TableID = t.TableID
ORDER BY r.ReservationDateTime;

-- =========================================================
-- 3. TOP SELLING DISHES
-- =========================================================
CREATE OR REPLACE VIEW v_top_selling_dishes AS
SELECT
    m.DishID,
    m.DishName,
    SUM(oi.Quantity) AS TotalQuantitySold,
    SUM(oi.LineTotal) AS TotalSales
FROM OrderItems oi
JOIN MenuItems m
    ON oi.DishID = m.DishID
JOIN Orders o
    ON oi.OrderID = o.OrderID
WHERE o.OrderStatus IN ('served', 'closed')
GROUP BY
    m.DishID,
    m.DishName
ORDER BY TotalQuantitySold DESC;

-- =========================================================
-- 4. DAILY REVENUE
-- =========================================================
CREATE OR REPLACE VIEW v_daily_revenue AS
SELECT
    DATE(PaymentDate) AS RevenueDate,
    COUNT(InvoiceID) AS NumberOfInvoices,
    SUM(SubTotal) AS TotalSubTotal,
    SUM(ServiceCharge) AS TotalServiceCharge,
    SUM(DiscountAmount) AS TotalDiscount,
    SUM(TotalAmount) AS TotalRevenue
FROM Invoices
WHERE PaymentStatus = 'paid'
GROUP BY DATE(PaymentDate)
ORDER BY RevenueDate;

-- =========================================================
-- 5. CUSTOMER VISIT SUMMARY
-- =========================================================
CREATE OR REPLACE VIEW v_customer_visit_summary AS
SELECT
    c.CustomerID,
    c.CustomerName,
    c.PhoneNumber,
    COUNT(DISTINCT o.OrderID) AS TotalVisits,
    IFNULL(SUM(i.TotalAmount), 0) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o
    ON c.CustomerID = o.CustomerID
LEFT JOIN Invoices i
    ON o.OrderID = i.OrderID
    AND i.PaymentStatus = 'paid'
GROUP BY
    c.CustomerID,
    c.CustomerName,
    c.PhoneNumber
ORDER BY TotalSpent DESC;

-- =========================================================
-- 6. TABLE USAGE STATISTICS
-- =========================================================
CREATE OR REPLACE VIEW v_table_usage_statistics AS
SELECT
    t.TableID,
    t.TableNumber,
    t.Capacity,
    COUNT(o.OrderID) AS TotalOrders,
    IFNULL(SUM(i.TotalAmount), 0) AS TotalRevenue
FROM RestaurantTables t
LEFT JOIN Orders o
    ON t.TableID = o.TableID
LEFT JOIN Invoices i
    ON o.OrderID = i.OrderID
    AND i.PaymentStatus = 'paid'
GROUP BY
    t.TableID,
    t.TableNumber,
    t.Capacity
ORDER BY TotalRevenue DESC;