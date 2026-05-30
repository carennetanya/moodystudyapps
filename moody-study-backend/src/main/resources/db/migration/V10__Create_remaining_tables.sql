-- V10__Create_remaining_tables.sql
-- Create remaining application tables that are not yet managed by Flyway.

CREATE TABLE IF NOT EXISTS daily_quests (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    quest_date DATE NOT NULL,
    quest_key VARCHAR(40) NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    xp_reward INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS mood_scales (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    mood_date TIMESTAMP NOT NULL,
    mood_type VARCHAR(255) NOT NULL,
    mood_value INTEGER NOT NULL,
    mood_feel VARCHAR(255) NOT NULL,
    mood_intensity INTEGER,
    mood_note VARCHAR(255),
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mood_object_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    mood_scale_id BIGINT,
    subject VARCHAR(255),
    mood_feel VARCHAR(255) NOT NULL,
    mood_intensity INTEGER NOT NULL,
    mood_date TIMESTAMP NOT NULL,
    notes VARCHAR(255),
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS schedules (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    subject VARCHAR(255) NOT NULL,
    study_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    location VARCHAR(255),
    mood VARCHAR(255),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    schedule_id BIGINT NOT NULL,
    message VARCHAR(255) NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS saved_files (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    file_name VARCHAR(255),
    file_type VARCHAR(255),
    content TEXT,
    saved_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS streams (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    stream_id VARCHAR(255) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    study_session_id BIGINT,
    status VARCHAR(255) NOT NULL DEFAULT 'active',
    stream_url VARCHAR(255),
    duration_seconds BIGINT
);

CREATE TABLE IF NOT EXISTS subject_plans (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    subject VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(255) NOT NULL DEFAULT 'active',
    target_hours INTEGER,
    completed_hours INTEGER,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    nickname VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    current_password VARCHAR(255),
    new_password VARCHAR(255),
    confirm_password VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS user_xp (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    total_xp INTEGER NOT NULL DEFAULT 0
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'UK_daily_quests_user_date_key'
    ) THEN
        ALTER TABLE daily_quests
            ADD CONSTRAINT UK_daily_quests_user_date_key UNIQUE (user_id, quest_date, quest_key);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_daily_quests_user'
    ) THEN
        ALTER TABLE daily_quests
            ADD CONSTRAINT FK_daily_quests_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_mood_scales_user'
    ) THEN
        ALTER TABLE mood_scales
            ADD CONSTRAINT FK_mood_scales_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_mood_object_logs_user'
    ) THEN
        ALTER TABLE mood_object_logs
            ADD CONSTRAINT FK_mood_object_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_mood_object_logs_scale'
    ) THEN
        ALTER TABLE mood_object_logs
            ADD CONSTRAINT FK_mood_object_logs_scale FOREIGN KEY (mood_scale_id) REFERENCES mood_scales(id);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_schedules_user'
    ) THEN
        ALTER TABLE schedules
            ADD CONSTRAINT FK_schedules_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_notifications_user'
    ) THEN
        ALTER TABLE notifications
            ADD CONSTRAINT FK_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_notifications_schedule'
    ) THEN
        ALTER TABLE notifications
            ADD CONSTRAINT FK_notifications_schedule FOREIGN KEY (schedule_id) REFERENCES schedules(id) ON DELETE CASCADE;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_saved_files_user'
    ) THEN
        ALTER TABLE saved_files
            ADD CONSTRAINT FK_saved_files_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_streams_user'
    ) THEN
        ALTER TABLE streams
            ADD CONSTRAINT FK_streams_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_streams_session'
    ) THEN
        ALTER TABLE streams
            ADD CONSTRAINT FK_streams_session FOREIGN KEY (study_session_id) REFERENCES study_sessions(id);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_subject_plans_user'
    ) THEN
        ALTER TABLE subject_plans
            ADD CONSTRAINT FK_subject_plans_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'UK_user_profiles_user'
    ) THEN
        ALTER TABLE user_profiles
            ADD CONSTRAINT UK_user_profiles_user UNIQUE (user_id);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_user_profiles_user'
    ) THEN
        ALTER TABLE user_profiles
            ADD CONSTRAINT FK_user_profiles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'UK_user_xp_user'
    ) THEN
        ALTER TABLE user_xp
            ADD CONSTRAINT UK_user_xp_user UNIQUE (user_id);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'FK_user_xp_user'
    ) THEN
        ALTER TABLE user_xp
            ADD CONSTRAINT FK_user_xp_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_daily_quests_user_id ON daily_quests(user_id);
CREATE INDEX IF NOT EXISTS idx_mood_scales_user_id ON mood_scales(user_id);
CREATE INDEX IF NOT EXISTS idx_mood_object_logs_user_id ON mood_object_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_schedules_user_id ON schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_files_user_id ON saved_files(user_id);
CREATE INDEX IF NOT EXISTS idx_streams_user_id ON streams(user_id);
CREATE INDEX IF NOT EXISTS idx_subject_plans_user_id ON subject_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_xp_user_id ON user_xp(user_id);
