-- V14__Add_missing_indexes.sql
-- Menambahkan index yang hilang pada tabel schedules.
--
-- Root cause: V10__Create_remaining_tables.sql membuat tabel schedules
-- tanpa index apapun. Query ScheduleRepository.findByUserOrderByStudyDateAscStartTimeAsc
-- melakukan full table scan pada setiap GET /api/schedule.
-- Di bawah load 50 concurrent users selama 5 menit, tabel tumbuh ribuan
-- baris dan setiap scan menjadi semakin lambat (p95 mencapai 2469ms).
--
-- Fix: composite index (user_id, study_date, start_time) persis sesuai
-- kolom yang dipakai ORDER BY di repository, sehingga PostgreSQL tidak
-- perlu scan + sort ulang — hasilnya langsung dari index.

CREATE INDEX IF NOT EXISTS idx_schedules_user_id
    ON schedules(user_id);

CREATE INDEX IF NOT EXISTS idx_schedules_user_date_time
    ON schedules(user_id, study_date ASC, start_time ASC);

-- Index tambahan untuk NotificationSchedulerService:
-- findByStudyDateAndStartTimeBetweenAndIsCompletedFalse
CREATE INDEX IF NOT EXISTS idx_schedules_date_time_completed
    ON schedules(study_date, start_time, is_completed);