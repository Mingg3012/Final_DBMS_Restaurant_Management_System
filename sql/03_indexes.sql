-- =========================================================
-- 03_indexes.sql
-- Indexes for Query Optimization
-- =========================================================

USE restaurant_db;

CREATE INDEX idx_customer_phone
ON Customers(PhoneNumber);

CREATE INDEX idx_invoice_payment_status
ON Invoices(PaymentStatus);