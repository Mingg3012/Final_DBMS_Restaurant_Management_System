-- =========================================================
-- 05_functions.sql
-- User Defined Functions
-- =========================================================

USE restaurant_db;

DROP FUNCTION IF EXISTS fn_calculate_service_charge;
DROP FUNCTION IF EXISTS fn_calculate_discount;
DROP FUNCTION IF EXISTS fn_calculate_order_subtotal;

DELIMITER $$

-- =========================================================
-- 1. SERVICE CHARGE FUNCTION
-- Service charge = 5% of subtotal
-- =========================================================
CREATE FUNCTION fn_calculate_service_charge(
    p_subtotal DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN ROUND(p_subtotal * 0.05, 2);
END$$

-- =========================================================
-- 2. DISCOUNT FUNCTION
-- Rule:
-- If subtotal >= 1,000,000: 10% discount
-- If customer has >= 5 paid visits: additional 5%
-- =========================================================
CREATE FUNCTION fn_calculate_discount(
    p_customer_id INT,
    p_subtotal DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_visit_count INT DEFAULT 0;
    DECLARE v_discount_rate DECIMAL(5,2) DEFAULT 0.00;

    SELECT COUNT(*)
    INTO v_visit_count
    FROM Invoices
    WHERE CustomerID = p_customer_id
      AND PaymentStatus = 'paid';

    IF p_subtotal >= 1000000 THEN
        SET v_discount_rate = v_discount_rate + 0.10;
    END IF;

    IF v_visit_count >= 5 THEN
        SET v_discount_rate = v_discount_rate + 0.05;
    END IF;

    RETURN ROUND(p_subtotal * v_discount_rate, 2);
END$$

-- =========================================================
-- 3. ORDER SUBTOTAL FUNCTION
-- Calculate subtotal from OrderItems
-- =========================================================
CREATE FUNCTION fn_calculate_order_subtotal(
    p_order_id INT
)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_subtotal DECIMAL(10,2);

    SELECT IFNULL(SUM(LineTotal), 0)
    INTO v_subtotal
    FROM OrderItems
    WHERE OrderID = p_order_id;

    RETURN v_subtotal;
END$$

DELIMITER ;