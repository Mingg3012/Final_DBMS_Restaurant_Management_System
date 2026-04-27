-- =========================================================
-- 09_backup_recovery_notes.sql
-- Backup and Recovery Notes
-- =========================================================

-- Logical backup command:
-- Run this in terminal, not inside MySQL Workbench.

-- Backup database:
-- mysqldump -u root -p restaurant_db > restaurant_db_backup.sql

-- Restore database:
-- mysql -u root -p restaurant_db < restaurant_db_backup.sql

-- Backup with routines, triggers, and events:
-- mysqldump -u root -p --routines --triggers --events restaurant_db > restaurant_db_full_backup.sql

-- Recommended backup strategy:
-- 1. Daily backup during operation.
-- 2. Store backup files in a separate location.
-- 3. Test recovery regularly.
-- 4. Restrict backup file access because it may contain customer and payment data.