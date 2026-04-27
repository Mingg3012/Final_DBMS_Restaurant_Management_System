-- =========================================================
-- 06_procedures.sql
-- Stored Procedures for Restaurant Operations
-- =========================================================

USE restaurant_db;

DROP PROCEDURE IF EXISTS sp_create_reservation;
DROP PROCEDURE IF EXISTS sp_confirm_reservation;
DROP PROCEDURE IF EXISTS sp_create_order;
DROP PROCEDURE IF EXISTS sp_add_order_item;
DROP PROCEDURE IF EXISTS sp_generate_invoice;
DROP PROCEDURE IF EXISTS sp_pay_invoice;

DELIMITER $$

-- =========================================================
-- 1. CREATE RESERVATION
-- Check:
-- - Table exists
-- - Table capacity is enough
-- - Table is not reserved in the same time window
-- =========================================================
CREATE PROCEDURE sp_create_reservation(
    IN p_customer_id INT,
    IN p_table_id INT,
    IN p_reservation_datetime DATETIME,
    IN p_guest_count INT
)
BEGIN
    DECLARE v_capacity INT;
    DECLARE v_conflict_count INT;

    SELECT Capacity
    INTO v_capacity
    FROM RestaurantTables
    WHERE TableID = p_table_id;

    IF v_capacity IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Table does not exist.';
    END IF;

    IF p_guest_count > v_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Guest count exceeds table capacity.';
    END IF;

    SELECT COUNT(*)
    INTO v_conflict_count
    FROM Reservations
    WHERE TableID = p_table_id
      AND Status IN ('pending', 'confirmed')
      AND ReservationDateTime BETWEEN
          DATE_SUB(p_reservation_datetime, INTERVAL 2 HOUR)
          AND DATE_ADD(p_reservation_datetime, INTERVAL 2 HOUR);

    IF v_conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This table already has a reservation near this time.';
    END IF;

    INSERT INTO Reservations
    (CustomerID, TableID, ReservationDateTime, GuestCount, Status)
    VALUES
    (p_customer_id, p_table_id, p_reservation_datetime, p_guest_count, 'pending');

    SELECT LAST_INSERT_ID() AS NewReservationID;
END$$

-- =========================================================
-- 2. CONFIRM RESERVATION
-- The trigger will update table status after confirmation.
-- =========================================================
CREATE PROCEDURE sp_confirm_reservation(
    IN p_reservation_id INT
)
BEGIN
    UPDATE Reservations
    SET Status = 'confirmed'
    WHERE ReservationID = p_reservation_id;

    SELECT 'Reservation confirmed successfully.' AS Message;
END$$

-- =========================================================
-- 3. CREATE ORDER
-- Create a new order for a table.
-- =========================================================
CREATE PROCEDURE sp_create_order(
    IN p_customer_id INT,
    IN p_table_id INT,
    IN p_staff_id INT
)
BEGIN
    DECLARE v_table_status VARCHAR(50);

    SELECT Status
    INTO v_table_status
    FROM RestaurantTables
    WHERE TableID = p_table_id;

    IF v_table_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Table does not exist.';
    END IF;

    IF v_table_status = 'maintenance' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This table is under maintenance.';
    END IF;

    INSERT INTO Orders
    (CustomerID, TableID, StaffID, OrderStatus)
    VALUES
    (p_customer_id, p_table_id, p_staff_id, 'open');

    UPDATE RestaurantTables
    SET Status = 'occupied'
    WHERE TableID = p_table_id;

    SELECT LAST_INSERT_ID() AS NewOrderID;
END$$

-- =========================================================
-- 4. ADD ORDER ITEM
-- Add dish to order.
-- The trigger can auto-check availability and price.
-- =========================================================
CREATE PROCEDURE sp_add_order_item(
    IN p_order_id INT,
    IN p_dish_id INT,
    IN p_quantity INT,
    IN p_notes VARCHAR(255)
)
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_availability VARCHAR(50);

    SELECT Price, Availability
    INTO v_price, v_availability
    FROM MenuItems
    WHERE DishID = p_dish_id;

    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Dish does not exist.';
    END IF;

    IF v_availability <> 'available' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This dish is currently unavailable.';
    END IF;

    INSERT INTO OrderItems
    (OrderID, DishID, Quantity, UnitPrice, Notes)
    VALUES
    (p_order_id, p_dish_id, p_quantity, v_price, p_notes);

    SELECT 'Order item added successfully.' AS Message;
END$$

-- =========================================================
-- 5. GENERATE INVOICE
-- Calculate subtotal, service charge, discount, total.
-- =========================================================
CREATE PROCEDURE sp_generate_invoice(
    IN p_order_id INT
)
BEGIN
    DECLARE v_customer_id INT;
    DECLARE v_table_id INT;
    DECLARE v_existing_invoice_count INT DEFAULT 0;

    DECLARE v_subtotal DECIMAL(10,2);
    DECLARE v_service_charge DECIMAL(10,2);
    DECLARE v_discount DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2);

    SELECT COUNT(*)
    INTO v_existing_invoice_count
    FROM Invoices
    WHERE OrderID = p_order_id;

    IF v_existing_invoice_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invoice already exists for this order.';
    END IF;

    SELECT CustomerID, TableID
    INTO v_customer_id, v_table_id
    FROM Orders
    WHERE OrderID = p_order_id;

    IF v_table_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order does not exist.';
    END IF;

    SET v_subtotal = fn_calculate_order_subtotal(p_order_id);
    SET v_service_charge = fn_calculate_service_charge(v_subtotal);
    SET v_discount = fn_calculate_discount(v_customer_id, v_subtotal);
    SET v_total = v_subtotal + v_service_charge - v_discount;

    INSERT INTO Invoices
    (
        OrderID,
        CustomerID,
        TableID,
        SubTotal,
        ServiceCharge,
        DiscountAmount,
        TotalAmount,
        PaymentStatus
    )
    VALUES
    (
        p_order_id,
        v_customer_id,
        v_table_id,
        v_subtotal,
        v_service_charge,
        v_discount,
        v_total,
        'unpaid'
    );

    UPDATE Orders
    SET OrderStatus = 'closed'
    WHERE OrderID = p_order_id;

    SELECT LAST_INSERT_ID() AS NewInvoiceID;
END$$

-- =========================================================
-- 6. PAY INVOICE
-- Add payment and update invoice status.
-- The trigger will update table status after invoice is paid.
-- =========================================================
CREATE PROCEDURE sp_pay_invoice(
    IN p_invoice_id INT,
    IN p_payment_method VARCHAR(50),
    IN p_amount DECIMAL(10,2)
)
BEGIN
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_status VARCHAR(50);

    SELECT TotalAmount, PaymentStatus
    INTO v_total, v_status
    FROM Invoices
    WHERE InvoiceID = p_invoice_id;

    IF v_total IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invoice does not exist.';
    END IF;

    IF v_status = 'paid' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invoice has already been paid.';
    END IF;

    IF p_amount < v_total THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment amount is less than invoice total.';
    END IF;

    INSERT INTO Payments
    (InvoiceID, PaymentMethod, Amount)
    VALUES
    (p_invoice_id, p_payment_method, p_amount);

    UPDATE Invoices
    SET PaymentStatus = 'paid',
        PaymentDate = CURRENT_TIMESTAMP
    WHERE InvoiceID = p_invoice_id;

    SELECT 'Invoice paid successfully.' AS Message;
END$$

DELIMITER ;