-- =========================================================
-- 08_roles_security.sql
-- Roles and Privileges
-- =========================================================

USE restaurant_db;

-- =========================================================
-- CREATE ROLES
-- =========================================================
CREATE ROLE IF NOT EXISTS restaurant_admin;
CREATE ROLE IF NOT EXISTS restaurant_cashier;
CREATE ROLE IF NOT EXISTS restaurant_waiter;

-- =========================================================
-- ADMIN ROLE
-- Full access
-- =========================================================
GRANT ALL PRIVILEGES
ON restaurant_db.*
TO restaurant_admin;

-- =========================================================
-- CASHIER ROLE
-- Cashier can view customers, tables, menu, orders, invoices.
-- Cashier can create payments and execute invoice procedures.
-- =========================================================
GRANT SELECT
ON restaurant_db.Customers
TO restaurant_cashier;

GRANT SELECT
ON restaurant_db.RestaurantTables
TO restaurant_cashier;

GRANT SELECT
ON restaurant_db.MenuItems
TO restaurant_cashier;

GRANT SELECT
ON restaurant_db.Orders
TO restaurant_cashier;

GRANT SELECT
ON restaurant_db.OrderItems
TO restaurant_cashier;

GRANT SELECT, INSERT, UPDATE
ON restaurant_db.Invoices
TO restaurant_cashier;

GRANT SELECT, INSERT
ON restaurant_db.Payments
TO restaurant_cashier;

GRANT EXECUTE
ON PROCEDURE restaurant_db.sp_generate_invoice
TO restaurant_cashier;

GRANT EXECUTE
ON PROCEDURE restaurant_db.sp_pay_invoice
TO restaurant_cashier;

-- =========================================================
-- WAITER ROLE
-- Waiter can view tables/menu and manage orders.
-- =========================================================
GRANT SELECT
ON restaurant_db.RestaurantTables
TO restaurant_waiter;

GRANT SELECT
ON restaurant_db.MenuItems
TO restaurant_waiter;

GRANT SELECT, INSERT, UPDATE
ON restaurant_db.Orders
TO restaurant_waiter;

GRANT SELECT, INSERT, UPDATE
ON restaurant_db.OrderItems
TO restaurant_waiter;

GRANT EXECUTE
ON PROCEDURE restaurant_db.sp_create_order
TO restaurant_waiter;

GRANT EXECUTE
ON PROCEDURE restaurant_db.sp_add_order_item
TO restaurant_waiter;

-- =========================================================
-- CREATE USERS
-- Change passwords if needed.
-- =========================================================
CREATE USER IF NOT EXISTS 'admin_user'@'localhost'
IDENTIFIED BY 'Admin@123';

CREATE USER IF NOT EXISTS 'cashier_user'@'localhost'
IDENTIFIED BY 'Cashier@123';

CREATE USER IF NOT EXISTS 'waiter_user'@'localhost'
IDENTIFIED BY 'Waiter@123';

-- =========================================================
-- ASSIGN ROLES
-- =========================================================
GRANT restaurant_admin TO 'admin_user'@'localhost';
GRANT restaurant_cashier TO 'cashier_user'@'localhost';
GRANT restaurant_waiter TO 'waiter_user'@'localhost';

SET DEFAULT ROLE restaurant_admin TO 'admin_user'@'localhost';
SET DEFAULT ROLE restaurant_cashier TO 'cashier_user'@'localhost';
SET DEFAULT ROLE restaurant_waiter TO 'waiter_user'@'localhost';

FLUSH PRIVILEGES;