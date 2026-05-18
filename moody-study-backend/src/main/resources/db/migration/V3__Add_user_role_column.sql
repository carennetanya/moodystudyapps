-- V3__Add_user_role_column.sql
-- Add role column to the users table if it does not exist.

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'ROLE_USER' NOT NULL;
