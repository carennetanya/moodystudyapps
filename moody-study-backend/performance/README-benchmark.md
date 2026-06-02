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
