-- V17__Create_user_items_table.sql
-- Tabel untuk menyimpan item shop yang sudah dibeli user.
-- itemId merujuk ke katalog item di Flutter (e.g. "h_pink", "theme_night").

CREATE TABLE IF NOT EXISTS user_items (
    id           SERIAL PRIMARY KEY,
    user_id      INTEGER      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_id      VARCHAR(50)  NOT NULL,
    price_paid   INTEGER      NOT NULL DEFAULT 0,
    purchased_at TIMESTAMP    NOT NULL DEFAULT NOW(),

    -- Satu user hanya boleh punya satu item yang sama
    CONSTRAINT uq_user_item UNIQUE (user_id, item_id)
);

CREATE INDEX IF NOT EXISTS idx_user_items_user_id ON user_items(user_id);