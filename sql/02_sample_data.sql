-- =========================================================
-- 02_sample_data.sql
-- Sample Data for Restaurant Management System
-- =========================================================

USE restaurant_db;

START TRANSACTION;

-- =========================================================
-- CUSTOMERS
-- =========================================================
INSERT INTO Customers (CustomerName, PhoneNumber, Email, Address) VALUES
('Nguyen Van An', '0901000001', 'an.nguyen@example.com', 'Hanoi'),
('Tran Thi Bich', '0901000002', 'bich.tran@example.com', 'Hanoi'),
('Le Minh Chau', '0901000003', 'chau.le@example.com', 'Hai Phong'),
('Pham Quoc Duy', '0901000004', 'duy.pham@example.com', 'Nam Dinh'),
('Hoang Gia Han', '0901000005', 'han.hoang@example.com', 'Hanoi'),
('Do Thanh Long', '0901000006', 'long.do@example.com', 'Bac Ninh'),
('Vu Ngoc Mai', '0901000007', 'mai.vu@example.com', 'Hanoi'),
('Bui Duc Minh', '0901000008', 'minh.bui@example.com', 'Thai Binh'),
('Dang Thu Trang', '0901000009', 'trang.dang@example.com', 'Hanoi'),
('Phan Anh Tuan', '0901000010', 'tuan.phan@example.com', 'Hung Yen');

-- =========================================================
-- RESTAURANT TABLES
-- =========================================================
INSERT INTO RestaurantTables (TableNumber, Capacity, Status) VALUES
('T01', 2, 'available'),
('T02', 2, 'available'),
('T03', 4, 'available'),
('T04', 4, 'available'),
('T05', 4, 'reserved'),
('T06', 6, 'available'),
('T07', 6, 'occupied'),
('T08', 8, 'available'),
('T09', 8, 'maintenance'),
('T10', 10, 'available');

-- =========================================================
-- MENU CATEGORIES
-- =========================================================
INSERT INTO MenuCategories (CategoryName, Description) VALUES
('Appetizer', 'Starter dishes'),
('Main Course', 'Main dishes'),
('Dessert', 'Sweet dishes'),
('Beverage', 'Drinks'),
('Combo', 'Set meals and combos');

-- =========================================================
-- MENU ITEMS
-- =========================================================
INSERT INTO MenuItems (CategoryID, DishName, Price, Availability) VALUES
(1, 'Spring Rolls', 45000, 'available'),
(1, 'Fried Dumplings', 55000, 'available'),
(2, 'Beef Pho', 65000, 'available'),
(2, 'Chicken Rice', 70000, 'available'),
(2, 'Grilled Pork Rice', 75000, 'available'),
(2, 'Seafood Hotpot', 250000, 'available'),
(2, 'Beef Steak', 180000, 'available'),
(3, 'Caramel Flan', 30000, 'available'),
(3, 'Mango Pudding', 35000, 'available'),
(4, 'Iced Tea', 10000, 'available'),
(4, 'Orange Juice', 40000, 'available'),
(4, 'Coffee', 35000, 'available'),
(5, 'Family Combo A', 420000, 'available'),
(5, 'Couple Combo', 220000, 'available'),
(2, 'Salmon Salad', 120000, 'unavailable');

-- =========================================================
-- STAFF
-- =========================================================
INSERT INTO Staff (StaffName, Role, PhoneNumber, Username) VALUES
('Admin User', 'admin', '0911000001', 'admin01'),
('Cashier One', 'cashier', '0911000002', 'cashier01'),
('Cashier Two', 'cashier', '0911000003', 'cashier02'),
('Waiter One', 'waiter', '0911000004', 'waiter01'),
('Waiter Two', 'waiter', '0911000005', 'waiter02');

-- =========================================================
-- RESERVATIONS
-- =========================================================
INSERT INTO Reservations
(CustomerID, TableID, ReservationDateTime, GuestCount, Status)
VALUES
(1, 1, '2026-04-28 18:00:00', 2, 'confirmed'),
(2, 3, '2026-04-28 19:00:00', 4, 'confirmed'),
(3, 4, '2026-04-29 18:30:00', 3, 'pending'),
(4, 6, '2026-04-29 20:00:00', 5, 'confirmed'),
(5, 8, '2026-04-30 18:00:00', 7, 'pending'),
(6, 2, '2026-04-30 19:30:00', 2, 'cancelled'),
(7, 5, '2026-05-01 18:00:00', 4, 'confirmed'),
(8, 10, '2026-05-01 20:00:00', 9, 'pending');

-- =========================================================
-- ORDERS
-- =========================================================
INSERT INTO Orders
(CustomerID, TableID, StaffID, OrderDateTime, OrderStatus)
VALUES
(1, 1, 4, '2026-04-25 18:10:00', 'closed'),
(2, 3, 4, '2026-04-25 19:15:00', 'closed'),
(3, 4, 5, '2026-04-26 18:30:00', 'closed'),
(4, 6, 5, '2026-04-26 20:00:00', 'closed'),
(5, 8, 4, '2026-04-27 18:00:00', 'open'),
(6, 2, 5, '2026-04-27 19:00:00', 'served'),
(7, 7, 4, '2026-04-27 20:00:00', 'open'),
(8, 10, 5, '2026-04-27 20:30:00', 'open');

-- =========================================================
-- ORDER ITEMS
-- UnitPrice is inserted directly here.
-- Later, trigger can auto-fill it.
-- =========================================================
INSERT INTO OrderItems (OrderID, DishID, Quantity, UnitPrice, Notes) VALUES
(1, 3, 2, 65000, 'Less onion'),
(1, 10, 2, 10000, NULL),
(2, 6, 1, 250000, 'Extra vegetables'),
(2, 11, 4, 40000, NULL),
(3, 4, 3, 70000, NULL),
(3, 8, 3, 30000, NULL),
(4, 13, 1, 420000, NULL),
(4, 12, 2, 35000, NULL),
(5, 7, 2, 180000, 'Medium rare'),
(5, 11, 2, 40000, NULL),
(6, 14, 1, 220000, NULL),
(7, 5, 4, 75000, NULL),
(7, 10, 4, 10000, NULL),
(8, 6, 2, 250000, NULL),
(8, 9, 4, 35000, NULL);

-- =========================================================
-- INVOICES
-- =========================================================
INSERT INTO Invoices
(OrderID, CustomerID, TableID, SubTotal, ServiceCharge, DiscountAmount, TotalAmount, PaymentStatus, CreatedAt, PaymentDate)
VALUES
(1, 1, 1, 150000, 7500, 0, 157500, 'paid', '2026-04-25 19:00:00', '2026-04-25 19:05:00'),
(2, 2, 3, 410000, 20500, 0, 430500, 'paid', '2026-04-25 20:10:00', '2026-04-25 20:15:00'),
(3, 3, 4, 300000, 15000, 0, 315000, 'paid', '2026-04-26 19:30:00', '2026-04-26 19:35:00'),
(4, 4, 6, 490000, 24500, 0, 514500, 'paid', '2026-04-26 21:00:00', '2026-04-26 21:05:00'),
(5, 5, 8, 440000, 22000, 0, 462000, 'unpaid', '2026-04-27 19:00:00', NULL);

-- =========================================================
-- PAYMENTS
-- =========================================================
INSERT INTO Payments (InvoiceID, PaymentMethod, Amount, PaymentDate) VALUES
(1, 'cash', 157500, '2026-04-25 19:05:00'),
(2, 'card', 430500, '2026-04-25 20:15:00'),
(3, 'e_wallet', 315000, '2026-04-26 19:35:00'),
(4, 'bank_transfer', 514500, '2026-04-26 21:05:00');

COMMIT;