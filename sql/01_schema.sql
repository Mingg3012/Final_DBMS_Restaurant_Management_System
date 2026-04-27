-- =========================================================
-- 01_schema.sql
-- Restaurant Management System Database Schema
-- =========================================================

DROP DATABASE IF EXISTS restaurant_db;
CREATE DATABASE restaurant_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE restaurant_db;

-- =========================================================
-- 1. CUSTOMERS
-- =========================================================
CREATE TABLE Customers (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    PhoneNumber VARCHAR(20) NOT NULL UNIQUE,
    Email VARCHAR(100) UNIQUE,
    Address VARCHAR(255),
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 2. RESTAURANT TABLES
-- =========================================================
CREATE TABLE RestaurantTables (
    TableID INT AUTO_INCREMENT PRIMARY KEY,
    TableNumber VARCHAR(20) NOT NULL UNIQUE,
    Capacity INT NOT NULL,
    Status ENUM('available', 'reserved', 'occupied', 'maintenance')
        DEFAULT 'available',
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_table_capacity
        CHECK (Capacity > 0)
);

-- =========================================================
-- 3. MENU CATEGORIES
-- =========================================================
CREATE TABLE MenuCategories (
    CategoryID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL UNIQUE,
    Description VARCHAR(255)
);

-- =========================================================
-- 4. MENU ITEMS
-- =========================================================
CREATE TABLE MenuItems (
    DishID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryID INT,
    DishName VARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Availability ENUM('available', 'unavailable')
        DEFAULT 'available',
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_menu_price
        CHECK (Price > 0),

    CONSTRAINT fk_menu_category
        FOREIGN KEY (CategoryID)
        REFERENCES MenuCategories(CategoryID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- =========================================================
-- 5. STAFF
-- =========================================================
CREATE TABLE Staff (
    StaffID INT AUTO_INCREMENT PRIMARY KEY,
    StaffName VARCHAR(100) NOT NULL,
    Role ENUM('admin', 'cashier', 'waiter') NOT NULL,
    PhoneNumber VARCHAR(20),
    Username VARCHAR(50) NOT NULL UNIQUE,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 6. RESERVATIONS
-- =========================================================
CREATE TABLE Reservations (
    ReservationID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    TableID INT NOT NULL,
    ReservationDateTime DATETIME NOT NULL,
    GuestCount INT NOT NULL,
    Status ENUM('pending', 'confirmed', 'cancelled', 'completed')
        DEFAULT 'pending',
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_guest_count
        CHECK (GuestCount > 0),

    CONSTRAINT fk_reservation_customer
        FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_reservation_table
        FOREIGN KEY (TableID)
        REFERENCES RestaurantTables(TableID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =========================================================
-- 7. ORDERS
-- =========================================================
CREATE TABLE Orders (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT,
    TableID INT NOT NULL,
    StaffID INT,
    OrderDateTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    OrderStatus ENUM('open', 'served', 'cancelled', 'closed')
        DEFAULT 'open',

    CONSTRAINT fk_order_customer
        FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT fk_order_table
        FOREIGN KEY (TableID)
        REFERENCES RestaurantTables(TableID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_order_staff
        FOREIGN KEY (StaffID)
        REFERENCES Staff(StaffID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- =========================================================
-- 8. ORDER ITEMS
-- =========================================================
CREATE TABLE OrderItems (
    OrderItemID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    DishID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2),
    LineTotal DECIMAL(10,2)
        GENERATED ALWAYS AS (Quantity * UnitPrice) STORED,
    Notes VARCHAR(255),

    CONSTRAINT chk_order_quantity
        CHECK (Quantity > 0),

    CONSTRAINT chk_unit_price
        CHECK (UnitPrice >= 0),

    CONSTRAINT fk_orderitem_order
        FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_orderitem_dish
        FOREIGN KEY (DishID)
        REFERENCES MenuItems(DishID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =========================================================
-- 9. INVOICES
-- =========================================================
CREATE TABLE Invoices (
    InvoiceID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL UNIQUE,
    CustomerID INT,
    TableID INT NOT NULL,
    SubTotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    ServiceCharge DECIMAL(10,2) NOT NULL DEFAULT 0,
    DiscountAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    TotalAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    PaymentStatus ENUM('unpaid', 'paid', 'cancelled')
        DEFAULT 'unpaid',
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    PaymentDate DATETIME NULL,

    CONSTRAINT chk_invoice_subtotal
        CHECK (SubTotal >= 0),

    CONSTRAINT chk_invoice_total
        CHECK (TotalAmount >= 0),

    CONSTRAINT fk_invoice_order
        FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_invoice_customer
        FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT fk_invoice_table
        FOREIGN KEY (TableID)
        REFERENCES RestaurantTables(TableID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =========================================================
-- 10. PAYMENTS
-- =========================================================
CREATE TABLE Payments (
    PaymentID INT AUTO_INCREMENT PRIMARY KEY,
    InvoiceID INT NOT NULL,
    PaymentMethod ENUM('cash', 'card', 'bank_transfer', 'e_wallet')
        NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentDate DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_payment_amount
        CHECK (Amount > 0),

    CONSTRAINT fk_payment_invoice
        FOREIGN KEY (InvoiceID)
        REFERENCES Invoices(InvoiceID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =========================================================
-- 11. TABLE STATUS LOG
-- =========================================================
CREATE TABLE TableStatusLog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    TableID INT NOT NULL,
    OldStatus VARCHAR(50),
    NewStatus VARCHAR(50),
    ChangedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    Reason VARCHAR(255),

    CONSTRAINT fk_log_table
        FOREIGN KEY (TableID)
        REFERENCES RestaurantTables(TableID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =========================================================
-- 12. AUDIT LOG
-- =========================================================
CREATE TABLE AuditLog (
    AuditID INT AUTO_INCREMENT PRIMARY KEY,
    ActionType VARCHAR(50) NOT NULL,
    TableName VARCHAR(100) NOT NULL,
    RecordID INT,
    Description VARCHAR(255),
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);