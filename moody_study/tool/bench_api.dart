import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Simple API benchmark script. Run from repo root with:
//   dart run tool/bench_api.dart

const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://202.46.28.170:8081');
const _testEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: 'testuser@moody.dev');
const _testPassword = String.fromEnvironment('TEST_PASSWORD', defaultValue: 'TestPass123!');

Future<int> loginAndGetToken(http.Client client) async {
  final uri = Uri.parse('$_baseUrl/api/auth/login');
  final resp = await client.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': _testEmail, 'password': _testPassword}),
  );
  if (resp.statusCode == 200 || resp.statusCode == 201) {
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final token = body['token'] as String?;
    if (token != null) return token.hashCode; // not used, just confirm
  }
  throw Exception('Login failed: ${resp.statusCode} ${resp.body}');
}

Future<int> _timedRequest(http.Client client, String method, Uri uri, {Map<String, String>? headers, Object? body}) async {
  final t0 = DateTime.now().millisecondsSinceEpoch;
  http.Response resp;
  if (method == 'GET') {
    resp = await client.get(uri, headers: headers);
  } else if (method == 'POST') {
    resp = await client.post(uri, headers: headers, body: body);
  } else {
    resp = await client.get(uri, headers: headers);
  }
  final duration = DateTime.now().millisecondsSinceEpoch - t0;
  return duration;
}

Future<Map<String, dynamic>> measureEndpoint(http.Client client, String method, String path, {String? token, Object? body, int runs = 10}) async {
  final uri = Uri.parse('$_baseUrl$path');
  final durations = <int>[];
  final headers = <String, String>{'Content-Type': 'application/json'};
  if (token != null) headers['Authorization'] = 'Bearer $token';

  for (var i = 0; i < runs; i++) {
    try {
      final d = await _timedRequest(client, method, uri, headers: headers, body: body);
      durations.add(d);
    } catch (e) {
      durations.add(99999);
    }
    // small delay to avoid hammering
    await Future.delayed(Duration(milliseconds: 200));
  }

  durations.sort();
  final avg = durations.reduce((a, b) => a + b) / durations.length;
  int p95 = durations[(durations.length * 0.95).floor().clamp(0, durations.length - 1)];
  int p99 = durations[(durations.length * 0.99).floor().clamp(0, durations.length - 1)];
  final over = durations.where((d) => d > 1500).length;

  return {
    'path': path,
    'runs': runs,
    'avg_ms': avg,
    'p95_ms': p95,
    'p99_ms': p99,
    'over_1500': over,
    'raw': durations,
  };
}

Future<void> main() async {
  print('API benchmark starting. Base URL=$_baseUrl');
  final client = http.Client();
  try {
    // login first to get token (we will reuse token header if backend returns)
    String? token;
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/login');
      final resp = await client.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': _testEmail, 'password': _testPassword}));
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        token = body['token'] as String?;
        print('Login ok, token present: ${token != null}');
      } else {
        print('Login failed (${resp.statusCode}), continuing without token.');
      }
    } catch (e) {
      print('Login error: $e');
    }

    final endpoints = <Map<String, dynamic>>[
      {'method': 'POST', 'path': '/api/auth/login', 'body': jsonEncode({'email': _testEmail, 'password': _testPassword})},
      {'method': 'GET', 'path': '/api/profile/info'},
      {'method': 'POST', 'path': '/api/material/upload', 'body': jsonEncode({'fileName': 'bench.txt','originalText': 'Lorem ipsum'})},
      {'method': 'POST', 'path': '/api/quiz/generate', 'body': jsonEncode({'materialId': 1, 'quizType': 'multiple_choice', 'questionCount': 3})},
      {'method': 'GET', 'path': '/api/files'},
      {'method': 'GET', 'path': '/api/quest/daily'},
      {'method': 'POST', 'path': '/api/quest/complete-review'},
      {'method': 'GET', 'path': '/api/streak'},
    ];

    final results = <Map<String, dynamic>>[];
    for (final e in endpoints) {
      stdout.write('Measuring ${e['path']} ... ');
      final res = await measureEndpoint(client, e['method'] as String, e['path'] as String, token: token, body: e['body']);
      results.add(res);
      print('done');
    }

    print('\n=== Results ===');
    for (final r in results) {
      print('${r['path']} — runs=${r['runs']} avg=${r['avg_ms'].toStringAsFixed(1)}ms p95=${r['p95_ms']}ms p99=${r['p99_ms']}ms >1500=${r['over_1500']}');
    }
  } finally {
    client.close();
  }
}
