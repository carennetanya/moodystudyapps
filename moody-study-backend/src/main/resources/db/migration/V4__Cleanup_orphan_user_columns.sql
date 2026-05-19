-- V4__Cleanup_orphan_user_columns.sql
-- Remove orphan columns left by V1 original schema (password_hash, full_name).
-- password_hash was NOT NULL without default, blocking every INSERT.
ALTER TABLE users DROP COLUMN IF EXISTS password_hash;
ALTER TABLE users DROP COLUMN IF EXISTS full_name;

