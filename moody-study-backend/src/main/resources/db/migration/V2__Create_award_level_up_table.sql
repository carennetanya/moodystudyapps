-- V2__Create_award_level_up_table.sql
-- Add award_level_up table to support award level progression.

CREATE TABLE award_level_up (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    level INTEGER NOT NULL,
    summary_count_threshold INTEGER NOT NULL,
    xp_points INTEGER NOT NULL,
    awarded_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_award_level_up_user_id ON award_level_up(user_id);
CREATE INDEX idx_award_level_up_level ON award_level_up(level);
