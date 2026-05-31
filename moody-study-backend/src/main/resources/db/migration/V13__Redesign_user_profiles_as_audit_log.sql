-- Redesign user_profiles from a single-row-per-user profile table
-- into a multi-row audit/history log that records every profile change.
--
-- Each row = one change event: which field changed, old value, new value, when.
-- Tracks changes to: name, username, avatar_url, email, password, nickname.

-- Drop the existing table (V11 already dropped and recreated it, but it
-- still has the wrong single-row structure with UNIQUE constraint on user_id)
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Create audit log table
CREATE TABLE user_profiles (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT        NOT NULL,
    field_name  VARCHAR(50)   NOT NULL,
    old_value   TEXT,
    new_value   TEXT,
    changed_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT FK_user_profiles_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Index for fast lookup of all changes for a user
CREATE INDEX idx_user_profiles_user_id      ON user_profiles(user_id);

-- Index for fast lookup of latest value of a specific field
CREATE INDEX idx_user_profiles_user_field   ON user_profiles(user_id, field_name);
CREATE INDEX idx_user_profiles_changed_at   ON user_profiles(changed_at);