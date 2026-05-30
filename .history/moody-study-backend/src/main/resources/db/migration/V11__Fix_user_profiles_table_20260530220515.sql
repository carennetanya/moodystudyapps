-- V11__Fix_user_profiles_table.sql
-- Fix user_profiles table by removing unnecessary password columns and email
-- Keep only id, user_id, and nickname

-- Drop the old user_profiles table
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Create the corrected user_profiles table
CREATE TABLE user_profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    nickname VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add constraints
ALTER TABLE user_profiles
    ADD CONSTRAINT UK_user_profiles_user UNIQUE (user_id);

ALTER TABLE user_profiles
    ADD CONSTRAINT FK_user_profiles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Create index
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
