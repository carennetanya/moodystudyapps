# Backend API Throughput Benchmark

## Endpoint yang diuji

Endpoint utama benchmark:

```text
GET /api/user/xp
```

Alasan pemilihan:

- Endpoint ini valid di aplikasi Moody Study Backend.
- Endpoint dilindungi JWT, sehingga benchmark tetap melewati security filter Spring Boot.
- Endpoint ringan dan stabil karena hanya membaca total XP user.
- Endpoint tidak memanggil Gemini/API eksternal, sehingga hasil throughput merepresentasikan performa backend dan database, bukan latency layanan pihak ketiga.
- Response sukses normal adalah `200 OK` dengan body seperti:

```json
{
  "totalXp": 0
}
```

Script k6 melakukan `POST /api/auth/register` di tahap `setup()` untuk membuat user benchmark dan mengambil JWT. Setelah itu, 50 virtual users hanya menguji `GET /api/user/xp`.

## Menjalankan Spring Boot

Dari folder backend:

```bash
cd moody-study-backend
mvn spring-boot:run
```

Pastikan log Spring Boot menunjukkan aplikasi berjalan di port `8081`.

Tes cepat:

```bash
curl -i http://localhost:8081/api/auth/login
```

Jika backend belum berjalan, benchmark tidak valid karena request akan gagal dengan `connection refused`.

## Menjalankan k6

Dari folder backend:

```bash
k6 run performance/api-throughput-user-xp.js
```

Jika backend berjalan di host/port lain:

```bash
BASE_URL=http://localhost:8081 k6 run performance/api-throughput-user-xp.js
```

Konfigurasi benchmark:

- Tool: k6
- Virtual users: 50
- Durasi: 30 detik
- Endpoint throughput: `GET /api/user/xp`
- Validasi status: harus `200 OK`
- Pass threshold throughput: minimal `100 req/s`
- Error threshold: `0%` untuk endpoint benchmark

## Membaca hasil

k6 akan menampilkan ringkasan seperti:

```text
Throughput: 125.40 req/s
Error rate: 0.00%
HTTP 200 check rate: 100.00%
Pass threshold >=100 req/s: PASS
All requests successful: PASS
Final result: PASS
```

Script juga membuat file:

- `benchmark-summary-user-xp.txt`
- `benchmark-summary-user-xp.json`

Throughput diambil dari metric:

```text
http_reqs{endpoint:user_xp}.rate
```

Rumus manual:

```text
throughput = total request sukses / durasi pengujian
```

Contoh:

```text
3.750 request / 30 detik = 125 req/s
```

Error rate diambil dari metric:

```text
http_req_failed{endpoint:user_xp}.rate
```

Benchmark valid jika:

- Tidak ada response `401`, `403`, `404`, `500`, atau connection refused.
- `GET /api/user/xp returns 200 OK` bernilai 100%.
- `http_req_failed{endpoint:user_xp}` bernilai 0%.
- Throughput endpoint benchmark minimal 100 req/s.

## Bukti screenshot untuk laporan

Ambil screenshot yang menampilkan:

- Command yang dijalankan: `k6 run performance/api-throughput-user-xp.js`
- Konfigurasi VU dan durasi.
- Nilai `http_reqs` atau ringkasan `Throughput`.
- Nilai `http_req_failed`.
- Nilai checks/status `200 OK`.
- Status threshold `PASS`.

Di macOS:

```bash
Cmd + Shift + 4
```

Pilih area terminal yang memuat hasil k6. Simpan screenshot dan masukkan ke laporan.

## Format analisis laporan

```text
Pengujian throughput backend dilakukan menggunakan k6 terhadap endpoint GET /api/user/xp pada aplikasi Moody Study Backend. Endpoint ini dipilih karena merupakan endpoint API valid, membutuhkan autentikasi JWT, dan tidak bergantung pada layanan eksternal seperti Gemini sehingga hasil benchmark lebih merepresentasikan performa backend Spring Boot dan akses database.

Skenario pengujian menggunakan 50 virtual users secara konstan selama 30 detik. Sebelum pengujian utama dijalankan, script k6 membuat user benchmark melalui endpoint POST /api/auth/register dan menggunakan token JWT yang diperoleh untuk mengakses endpoint GET /api/user/xp. Setiap request divalidasi harus menghasilkan status HTTP 200 OK.

Berdasarkan hasil k6, total request yang diproses adalah [TOTAL_REQUEST] request selama 30 detik, sehingga throughput yang diperoleh adalah [REQ_PER_SECOND] request per second. Error rate pengujian adalah [ERROR_RATE]%, dan check status 200 OK sebesar [CHECK_RATE]%.

Dengan target minimal 100 request per second, hasil pengujian dinyatakan [MEMENUHI/TIDAK MEMENUHI] karena throughput yang diperoleh [LEBIH BESAR/LEBIH KECIL] dari 100 req/s. Benchmark dinyatakan [VALID/TIDAK VALID] karena seluruh request [BERHASIL/TIDAK BERHASIL] diproses tanpa error 401, 403, 404, 500, atau connection refused.
```

-- ============================================================
-- Moody Study Backend — DB Query Performance Check
-- ============================================================
-- Tool    : PostgreSQL EXPLAIN ANALYZE
-- Target  : No query > 200ms for standard operations
-- DB      : 202.46.28.160:2002 / uas_5803024002
--
-- CARA PAKAI:
--   Jalankan tiap blok satu per satu di psql atau DBeaver.
--   Ganti :user_id dengan ID user benchmark yang nyata
--   (lihat langkah 2 di panduan).
--
-- Standard operations yang diuji (sesuai ScheduleRepository,
-- UserXpRepository, UserRepository yang ada di program):
--   1. SELECT schedule by user (query paling sering dipanggil)
--   2. SELECT user_xp by user
--   3. SELECT user by email (login path)
--   4. INSERT schedule (create resource)
--   5. SELECT schedule by date range (NotificationSchedulerService)
-- ============================================================

-- ── LANGKAH 0: Aktifkan timing ──────────────────────────────
\timing on

-- ── LANGKAH 1: Cek index yang aktif di tabel schedules ──────
-- Memverifikasi bahwa V14__Add_missing_indexes.sql sudah terapply.
-- Kolom "indexname" harus ada: idx_schedules_user_date_time
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'schedules'
ORDER BY indexname;

-- ── LANGKAH 2: Cari user_id benchmark yang valid ────────────
-- Ganti output ini ke variabel :user_id di query bawah.
SELECT id, email
FROM users
WHERE email LIKE 'k6-vu%@moodystudy.test'
ORDER BY id
LIMIT 5;

-- ============================================================
-- QUERY 1: findByUserOrderByStudyDateAscStartTimeAsc
-- Dipanggil setiap GET /api/schedule
-- Repository: ScheduleRepository
-- ============================================================
-- Ganti 'GANTI_DENGAN_USER_ID' dengan angka dari LANGKAH 2
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT *
FROM schedules
WHERE user_id = GANTI_DENGAN_USER_ID
ORDER BY study_date ASC, start_time ASC;

-- Target: Execution Time < 200ms
-- Harus ada: "Index Scan using idx_schedules_user_date_time"
-- BUKAN: "Seq Scan on schedules"

-- ============================================================
-- QUERY 2: findByUser (UserXpRepository)
-- Dipanggil setiap GET /api/user/xp
-- Repository: UserXpRepository
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT *
FROM user_xp
WHERE user_id = GANTI_DENGAN_USER_ID;

-- Target: Execution Time < 200ms
-- Harus ada: "Index Scan using idx_user_xp_user_id"

-- ============================================================
-- QUERY 3: findByEmail (UserRepository)
-- Dipanggil setiap request (JWT filter lookup)
-- Repository: UserRepository
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT *
FROM users
WHERE email = 'k6-vu1@moodystudy.test';

-- Target: Execution Time < 200ms
-- Harus ada: "Index Scan using users_email_key" atau idx_users_email

-- ============================================================
-- QUERY 4: INSERT schedule (ScheduleRepository.save)
-- Dipanggil setiap POST /api/schedule
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
INSERT INTO schedules (user_id, subject, study_date, start_time, end_time, location, mood, is_completed)
VALUES (
    GANTI_DENGAN_USER_ID,
    'DB Performance Test',
    CURRENT_DATE,
    '10:00',
    '11:00',
    'Test Lab',
    'HAPPY',
    false
);

-- Target: Execution Time < 200ms
-- INSERT biasanya < 5ms jika tidak ada bloat atau lock contention

-- Cleanup baris test agar tidak kotor DB
DELETE FROM schedules
WHERE subject = 'DB Performance Test'
  AND user_id = GANTI_DENGAN_USER_ID;

-- ============================================================
-- QUERY 5: findByStudyDateAndStartTimeBetweenAndIsCompletedFalse
-- Dipanggil oleh NotificationSchedulerService
-- Repository: ScheduleRepository
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT *
FROM schedules
WHERE study_date = CURRENT_DATE
  AND start_time BETWEEN '08:00' AND '09:00'
  AND is_completed = false;

-- Target: Execution Time < 200ms
-- Harus ada: "Index Scan using idx_schedules_date_time_completed"

-- ============================================================
-- LANGKAH AKHIR: Cek slow query log via pg_stat_statements
-- (jika extension aktif di server kampus)
-- ============================================================
-- Cek apakah pg_stat_statements tersedia:
SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements';

-- Jika tersedia, lihat query terlambat dari DB ini:
SELECT
    LEFT(query, 80)          AS query_snippet,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS mean_ms,
    ROUND(max_exec_time::numeric, 2)  AS max_ms,
    ROUND(total_exec_time::numeric, 2) AS total_ms
FROM pg_stat_statements
WHERE query ILIKE '%schedules%'
   OR query ILIKE '%user_xp%'
   OR query ILIKE '%users%'
ORDER BY max_exec_time DESC
LIMIT 20;