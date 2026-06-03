/**
 * ============================================================
 * Moody Study Backend — Error Rate Under Load (v1)
 * ============================================================
 * Metric  : Error rate under load
 * Tool    : k6
 * Target  : < 1% error rate at 50 concurrent users
 * Scenario: 50 VU, full user journey, 5 menit
 *
 * Journey per iterasi (login sekali per VU, lalu loop):
 *   1. POST /api/auth/login         → setup token
 *   2. GET  /api/schedule           → fetch list
 *   3. POST /api/schedule           → create resource
 *   4. GET  /api/user/xp            → end session
 *
 * Error yang dihitung:
 *   - HTTP status non-2xx (network errors, server crash, 4xx/5xx)
 *   - http_req_failed (k6 built-in: timeout + connection refused + 5xx)
 *
 * Perbedaan dari p95-latency-user-journey.js:
 *   - Threshold utama adalah http_req_failed{journey:main} < 0.01
 *   - Check lebih ketat: setiap step di-assert secara terpisah
 *   - Output melaporkan breakdown error per fase secara eksplisit
 *   - Tidak menggunakan threshold latency agar focus ke reliability
 * ============================================================
 */

import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8081';

// ── Custom metrics untuk error breakdown per fase ─────────────
const loginErrorRate    = new Rate('error_rate_login');
const fetchErrorRate    = new Rate('error_rate_fetch_list');
const createErrorRate   = new Rate('error_rate_create');
const endSessionErrorRate = new Rate('error_rate_end_session');

export const options = {
  scenarios: {
    error_rate_journey: {
      executor: 'constant-vus',
      vus: 50,
      duration: '5m',
      gracefulStop: '15s',
    },
  },

  thresholds: {
    // Threshold utama — WAJIB PASS
    'http_req_failed':              ['rate<0.01'],  // < 1% seluruh request

    // Threshold per fase — validasi breakdown
    'error_rate_login':             ['rate<0.01'],
    'error_rate_fetch_list':        ['rate<0.01'],
    'error_rate_create':            ['rate<0.01'],
    'error_rate_end_session':       ['rate<0.01'],

    // Checks pass rate — semua response harus valid
    'checks':                       ['rate>0.99'],
  },

  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

// ── Per-VU state ───────────────────────────────────────────────
let vuToken = null;

/**
 * Login sekali per VU. Register jika akun belum ada.
 * Email berbasis __VU agar setiap VU punya data sendiri
 * (konsisten dengan desain p95-latency-user-journey.js v3).
 */
function ensureReady() {
  if (vuToken !== null) return;

  const vuId     = __VU;
  const email    = `k6-vu${vuId}@moodystudy.test`;
  const password = 'MoodyBench2024!';
  const username = `k6vu${vuId}benchmark`;
  const headers  = { 'Content-Type': 'application/json', Accept: 'application/json' };

  // Register — abaikan 400 jika user sudah ada dari run sebelumnya
  http.post(
    `${BASE_URL}/api/auth/register`,
    JSON.stringify({ username, name: `Benchmark VU ${vuId}`, email, password }),
    { headers, tags: { phase: 'setup' } }
  );

  // Login
  const loginRes = http.post(
    `${BASE_URL}/api/auth/login`,
    JSON.stringify({ email, password }),
    { headers, tags: { phase: 'login' } }
  );

  const loginOk = check(loginRes, {
    '[login] status 200': (r) => r.status === 200,
    '[login] token ada':  (r) => {
      try { return !!r.json('token'); } catch (_) { return false; }
    },
  });

  // Catat ke custom metric
  loginErrorRate.add(!loginOk);

  try { vuToken = loginRes.json('token'); } catch (_) { vuToken = null; }
}

// ── Default: journey per iterasi ───────────────────────────────
export default function () {
  ensureReady();
  if (!vuToken) return;

  const authHeaders = {
    'Content-Type': 'application/json',
    Accept: 'application/json',
    Authorization: `Bearer ${vuToken}`,
  };

  // ── STEP 1: Fetch List ─────────────────────────────────────
  group('step_1_fetch_list', () => {
    const res = http.get(`${BASE_URL}/api/schedule`, {
      headers: authHeaders,
      tags: { phase: 'fetch_list' },
    });

    const ok = check(res, {
      '[fetch_list] status 200':    (r) => r.status === 200,
      '[fetch_list] body is array': (r) => {
        try { return Array.isArray(r.json()); } catch (_) { return false; }
      },
    });

    fetchErrorRate.add(!ok);
  });

  sleep(0.3);

  // ── STEP 2: Create Resource ────────────────────────────────
  group('step_2_create_resource', () => {
    const today    = new Date();
    const dateStr  = today.toISOString().split('T')[0];
    const offset   = today.getTime() % 60;
    const startHour = String(8 + (offset % 4)).padStart(2, '0');
    const endHour   = String(9 + (offset % 4)).padStart(2, '0');

    const res = http.post(
      `${BASE_URL}/api/schedule`,
      JSON.stringify({
        subject:   `ErrRateTest VU${__VU}-${__ITER}`,
        studyDate: dateStr,
        startTime: `${startHour}:00`,
        endTime:   `${endHour}:00`,
        location:  'Benchmark Lab',
        mood:      'HAPPY',
      }),
      { headers: authHeaders, tags: { phase: 'create_resource' } }
    );

    const ok = check(res, {
      '[create] status 200': (r) => r.status === 200,
      '[create] id ada':     (r) => {
        try { return !!r.json('id'); } catch (_) { return false; }
      },
    });

    createErrorRate.add(!ok);
  });

  sleep(0.3);

  // ── STEP 3: End Session ────────────────────────────────────
  group('step_3_end_session', () => {
    const res = http.get(`${BASE_URL}/api/user/xp`, {
      headers: authHeaders,
      tags: { phase: 'end_session' },
    });

    const ok = check(res, {
      '[end_session] status 200':  (r) => r.status === 200,
      '[end_session] totalXp ada': (r) => {
        try { return r.json('totalXp') !== undefined; } catch (_) { return false; }
      },
    });

    endSessionErrorRate.add(!ok);
  });

  sleep(0.5);
}

// ── Handle Summary ─────────────────────────────────────────────
function mv(data, name, field) {
  return data.metrics?.[name]?.values?.[field] ?? 0;
}

export function handleSummary(data) {
  const errRateAll    = mv(data, 'http_req_failed', 'rate');
  const errLogin      = mv(data, 'error_rate_login', 'rate');
  const errFetch      = mv(data, 'error_rate_fetch_list', 'rate');
  const errCreate     = mv(data, 'error_rate_create', 'rate');
  const errEndSession = mv(data, 'error_rate_end_session', 'rate');
  const chkRate       = mv(data, 'checks', 'rate');
  const totalReqs     = mv(data, 'http_reqs', 'count');
  const rps           = mv(data, 'http_reqs', 'rate');
  const passed        = errRateAll < 0.01;

  const P = (v) => v < 0.01 ? 'PASS ✓' : 'FAIL ✗';

  const report = [
    'Moody Study Backend — Error Rate Under Load (v1)',
    '==================================================',
    `Tool              : k6`,
    `Scenario          : 50 virtual users, constant load, 5 minutes`,
    `User accounts     : 50 akun terpisah (1 per VU)`,
    `Journey per iter  : login → fetch list → create resource → end session`,
    `Base URL          : ${__ENV.BASE_URL || 'http://localhost:8081'}`,
    '',
    '── Error Rate per Fase ────────────────────────────────',
    `  Login           : ${(errLogin * 100).toFixed(2)}%   ${P(errLogin)}`,
    `  Fetch List      : ${(errFetch * 100).toFixed(2)}%   ${P(errFetch)}`,
    `  Create Resource : ${(errCreate * 100).toFixed(2)}%   ${P(errCreate)}`,
    `  End Session     : ${(errEndSession * 100).toFixed(2)}%   ${P(errEndSession)}`,
    '',
    '── Overall ────────────────────────────────────────────',
    `  Total requests  : ${totalReqs}`,
    `  Throughput      : ${rps.toFixed(2)} req/s`,
    `  Error rate      : ${(errRateAll * 100).toFixed(2)}%   ${P(errRateAll)} (threshold: < 1%)`,
    `  Check pass rate : ${(chkRate * 100).toFixed(2)}%`,
    '',
    '── Final Result ───────────────────────────────────────',
    `  Error < 1%      : ${P(errRateAll)}`,
    `  OVERALL         : ${passed ? 'PASS ✓' : 'FAIL ✗'}`,
    '',
  ].join('\n');

  return {
    stdout: report,
    'error-rate-summary.json': JSON.stringify(data, null, 2),
    'error-rate-summary.txt': report,
  };
}