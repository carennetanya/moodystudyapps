-- V6__Add_saved_to_generated_quizzes.sql
-- Tambah kolom saved ke tabel generated_quizzes
-- Default false = belum disimpan ke tab Kuis

ALTER TABLE generated_quizzes
    ADD COLUMN saved BOOLEAN NOT NULL DEFAULT FALSE;