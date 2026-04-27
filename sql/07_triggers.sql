-- =========================================================
-- 07_triggers.sql
-- Triggers for Automation
-- =========================================================

USE restaurant_db;

DROP TRIGGER IF EXISTS trg_before_order_item_insert;
DROP TRIGGER IF EXISTS trg_after_reservation_update;
DROP TRIGGER IF EXISTS trg_after_invoice_paid_update;

DELIMITER $$

-- =========================================================
-- 1. BEFORE INSERT ORDER ITEM
-- Check dish availability and auto-fill unit price.
-- =========================================================
CREATE TRIGGER trg_before_order_item_insert
BEFORE INSERT ON OrderItems
FOR EACH ROW
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_availability VARCHAR(50);

    SELECT Price, Availability
    INTO v_price, v_availability
    FROM MenuItems
    WHERE DishID = NEW.DishID;

    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Dish does not exist.';
    END IF;

    IF v_availability <> 'available' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot add unavailable dish to order.';
    END IF;

    IF NEW.UnitPrice IS NULL THEN
        SET NEW.UnitPrice = v_price;
    END IF;
END$$

-- =========================================================
-- 2. AFTER RESERVATION UPDATE
-- If reservation is confirmed, table becomes reserved.
-- =========================================================
CREATE TRIGGER trg_after_reservation_update
AFTER UPDATE ON Reservations
FOR EACH ROW
BEGIN
    DECLARE v_old_status VARCHAR(50);

    IF OLD.Status <> 'confirmed' AND NEW.Status = 'confirmed' THEN

        SELECT Status
        INTO v_old_status
        FROM RestaurantTables
        WHERE TableID = NEW.TableID;

        UPDATE RestaurantTables
        SET Status = 'reserved'
        WHERE TableID = NEW.TableID;

        INSERT INTO TableStatusLog
        (TableID, OldStatus, NewStatus, Reason)
        VALUES
        (NEW.TableID, v_old_status, 'reserved', 'Reservation confirmed');

        INSERT INTO AuditLog
        (ActionType, TableName, RecordID, Description)
        VALUES
        ('UPDATE', 'Reservations', NEW.ReservationID, 'Reservation confirmed');
    END IF;
END$$

-- =========================================================
-- 3. AFTER INVOICE PAID UPDATE
-- If invoice is paid, table becomes available.
-- =========================================================
CREATE TRIGGER trg_after_invoice_paid_update
AFTER UPDATE ON Invoices
FOR EACH ROW
BEGIN
    DECLARE v_old_status VARCHAR(50);

    IF OLD.PaymentStatus <> 'paid' AND NEW.PaymentStatus = 'paid' THEN

        SELECT Status
        INTO v_old_status
        FROM RestaurantTables
        WHERE TableID = NEW.TableID;

        UPDATE RestaurantTables
        SET Status = 'available'
        WHERE TableID = NEW.TableID;

        INSERT INTO TableStatusLog
        (TableID, OldStatus, NewStatus, Reason)
        VALUES
        (NEW.TableID, v_old_status, 'available', 'Invoice paid');

        INSERT INTO AuditLog
        (ActionType, TableName, RecordID, Description)
        VALUES
        ('UPDATE', 'Invoices', NEW.InvoiceID, 'Invoice paid');
    END IF;
END$$

DELIMITER ;