-- V15__Drop_unused_tables.sql
-- Menghapus tabel-tabel yang tidak dipakai di codebase.
--
-- Alasan:
--   - streams          : endpoint /api/streams tidak terdaftar di SecurityConfig.
--   - mood_scales      : endpoint /api/mood-scale tidak terdaftar di SecurityConfig.
--   - mood_object_logs : endpoint /api/mood-logs tidak terdaftar di SecurityConfig,
--                        kolom mood_scale_id selalu NULL.
--   - moods            : sisa V1, tidak ada entity/repository/service yang pakai.
--   - goals            : sisa V1, tidak ada entity/repository/service yang pakai.

-- ----------------------------------------------------------------
-- 1. Drop tabel mood_object_logs dulu (ada FK ke mood_scales)
-- ----------------------------------------------------------------
ALTER TABLE mood_object_logs DROP CONSTRAINT IF EXISTS FK_mood_object_logs_scale;
ALTER TABLE mood_object_logs DROP CONSTRAINT IF EXISTS FK_mood_object_logs_user;
DROP INDEX  IF EXISTS idx_mood_object_logs_user_id;
DROP TABLE  IF EXISTS mood_object_logs;

-- ----------------------------------------------------------------
-- 2. Drop tabel mood_scales
-- ----------------------------------------------------------------
ALTER TABLE mood_scales DROP CONSTRAINT IF EXISTS FK_mood_scales_user;
DROP INDEX  IF EXISTS idx_mood_scales_user_id;
DROP TABLE  IF EXISTS mood_scales;

-- ----------------------------------------------------------------
-- 3. Drop tabel streams
-- ----------------------------------------------------------------
ALTER TABLE streams DROP CONSTRAINT IF EXISTS FK_streams_user;
ALTER TABLE streams DROP CONSTRAINT IF EXISTS FK_streams_session;
DROP INDEX  IF EXISTS idx_streams_user_id;
DROP TABLE  IF EXISTS streams;

-- ----------------------------------------------------------------
-- 4. Drop tabel moods (sisa V1)
-- ----------------------------------------------------------------
DROP INDEX IF EXISTS idx_moods_user_id;
DROP INDEX IF EXISTS idx_moods_created_at;
DROP TABLE IF EXISTS moods;

-- ----------------------------------------------------------------
-- 5. Drop tabel goals (sisa V1)
-- ----------------------------------------------------------------
DROP INDEX IF EXISTS idx_goals_user_id;
DROP INDEX IF EXISTS idx_goals_status;
DROP TABLE IF EXISTS goals;