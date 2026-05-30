-- V6__Create_generated_quizzes_table.sql
-- Create generated_quizzes table used by the generated quiz feature.

CREATE TABLE IF NOT EXISTS generated_quizzes (
    id SERIAL PRIMARY KEY,
    material_id INTEGER NOT NULL REFERENCES study_materials(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quiz_content TEXT,
    generated_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_generated_quizzes_user_id ON generated_quizzes(user_id);
CREATE INDEX IF NOT EXISTS idx_generated_quizzes_material_id ON generated_quizzes(material_id);
