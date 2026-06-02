import http from 'k6/http';
import { check, fail } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8081';
const BENCHMARK_ENDPOINT = '/api/user/xp';
const PASSWORD = 'password123';

export const options = {
  scenarios: {
    user_xp_throughput: {
      executor: 'constant-vus',
      vus: 50,
      duration: '30s',
      gracefulStop: '5s',
    },
  },
  thresholds: {
    'http_reqs{endpoint:user_xp}': ['rate>=100'],
    'http_req_failed{endpoint:user_xp}': ['rate==0'],
    'checks{endpoint:user_xp}': ['rate==1'],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'max'],
};

export function setup() {
  const unique = `${Date.now()}-${Math.floor(Math.random() * 100000)}`;
  const email = `k6-${unique}@example.com`;
  const username = `k6user${unique}`.replace(/[^a-zA-Z0-9]/g, '');

  const registerPayload = JSON.stringify({
    username,
    name: 'K6 Benchmark User',
    email,
    password: PASSWORD,
  });

  const registerRes = http.post(`${BASE_URL}/api/auth/register`, registerPayload, {
    headers: { 'Content-Type': 'application/json' },
    tags: { endpoint: 'setup_auth' },
  });

  if (registerRes.status !== 200) {
    fail(`Setup gagal register user benchmark. Status=${registerRes.status}, body=${registerRes.body}`);
  }

  let token;
  try {
    token = registerRes.json('token');
  } catch (error) {
    fail(`Setup gagal membaca token register: ${error}`);
  }

  if (!token) {
    fail(`Setup gagal: response register tidak mengandung token. Body=${registerRes.body}`);
  }

  return { token };
}

export default function (data) {
  const res = http.get(`${BASE_URL}${BENCHMARK_ENDPOINT}`, {
    headers: {
      Authorization: `Bearer ${data.token}`,
      Accept: 'application/json',
    },
    tags: { endpoint: 'user_xp' },
  });

  check(
    res,
    {
      'GET /api/user/xp returns 200 OK': (r) => r.status === 200,
      'response contains totalXp': (r) => {
        try {
          return r.json('totalXp') !== undefined;
        } catch (_) {
          return false;
        }
      },
    },
    { endpoint: 'user_xp' }
  );
}

function metricValue(data, name, field, fallback = 0) {
  return data.metrics?.[name]?.values?.[field] ?? fallback;
}

export function handleSummary(data) {
  const requestsPerSecond = metricValue(data, 'http_reqs{endpoint:user_xp}', 'rate');
  const totalRequests = metricValue(data, 'http_reqs{endpoint:user_xp}', 'count');
  const errorRate = metricValue(data, 'http_req_failed{endpoint:user_xp}', 'rate');
  const checkRate = metricValue(data, 'checks{endpoint:user_xp}', 'rate');
  const passedThroughput = requestsPerSecond >= 100;
  const passedErrors = errorRate === 0 && checkRate === 1;
  const passed = passedThroughput && passedErrors;

  const report = [
    'Moody Study Backend API Throughput Benchmark',
    '=============================================',
    `Tool: k6`,
    `Scenario: 50 virtual users, constant load, 30 seconds`,
    `Endpoint: GET ${BENCHMARK_ENDPOINT}`,
    `Base URL: ${BASE_URL}`,
    `Total requests: ${totalRequests}`,
    `Throughput: ${requestsPerSecond.toFixed(2)} req/s`,
    `Error rate: ${(errorRate * 100).toFixed(2)}%`,
    `HTTP 200 check rate: ${(checkRate * 100).toFixed(2)}%`,
    `Pass threshold >=100 req/s: ${passedThroughput ? 'PASS' : 'FAIL'}`,
    `All requests successful: ${passedErrors ? 'PASS' : 'FAIL'}`,
    `Final result: ${passed ? 'PASS' : 'FAIL'}`,
    '',
  ].join('\n');

  return {
    stdout: report,
    'benchmark-summary-user-xp.json': JSON.stringify(data, null, 2),
    'benchmark-summary-user-xp.txt': report,
  };
}
