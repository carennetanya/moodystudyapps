-- V5__Add_session_id_to_study_materials.sql
-- Tambah kolom session_id ke tabel study_materials
-- Relasi optional ke study_sessions (NULL = upload di luar sesi)

ALTER TABLE study_materials
    ADD COLUMN session_id BIGINT,
    ADD CONSTRAINT fk_study_materials_session
        FOREIGN KEY (session_id)
        REFERENCES study_sessions(id)
        ON DELETE SET NULL;