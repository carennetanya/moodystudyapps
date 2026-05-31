-- V12__Fix_avatar_url_column.sql
-- Expand avatar_url from VARCHAR(500) to TEXT
-- to support base64-encoded image strings

ALTER TABLE users ALTER COLUMN avatar_url TYPE TEXT;
