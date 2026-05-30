-- V7__Create_streaks_table.sql
-- Create streaks table used by the streak tracking feature.

CREATE TABLE IF NOT EXISTS streaks (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    current_streak INTEGER NOT NULL,
    last_study_date DATE,
    life INTEGER NOT NULL DEFAULT 3,
    last_life_deducted_date DATE
);

CREATE INDEX IF NOT EXISTS idx_streaks_user_id ON streaks(user_id);
