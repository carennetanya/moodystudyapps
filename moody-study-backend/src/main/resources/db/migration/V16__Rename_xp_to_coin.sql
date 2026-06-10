-- V16__Rename_xp_to_coin.sql
-- Mengganti sistem XP menjadi Coin di daily_quests dan award_level_up,
-- serta membuat tabel user_coins baru untuk menyimpan saldo coin tiap user.

-- ----------------------------------------------------------------
-- 1. Ganti kolom xp_reward → coin_reward di tabel daily_quests
-- ----------------------------------------------------------------
ALTER TABLE daily_quests
    RENAME COLUMN xp_reward TO coin_reward;

-- ----------------------------------------------------------------
-- 2. Ganti kolom xp_points → coin_points di tabel award_level_up
-- ----------------------------------------------------------------
ALTER TABLE award_level_up
    RENAME COLUMN xp_points TO coin_points;

-- ----------------------------------------------------------------
-- 3. Buat tabel user_coins
--    Menyimpan total coin yang dimiliki setiap user.
--    Coin didapat dari daily quest & level-up award,
--    dan bisa digunakan untuk membeli item di Shop.
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_coins (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    total_coins INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_user_coins_user_id ON user_coins(user_id);

-- ----------------------------------------------------------------
-- 4. (Opsional) Migrate saldo lama dari user_xp ke user_coins
--    Uncomment baris di bawah jika ada data existing di user_xp
--    yang ingin dipindah ke user_coins.
-- ----------------------------------------------------------------
-- INSERT INTO user_coins (user_id, total_coins)
-- SELECT user_id, total_xp FROM user_xp
-- ON CONFLICT (user_id) DO UPDATE SET total_coins = EXCLUDED.total_coins;