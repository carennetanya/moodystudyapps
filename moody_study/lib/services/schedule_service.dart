import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'auth_service.dart';

class ScheduleService {
  static String get baseUrl => AuthService.baseUrl;

  static Future<List<ScheduleItem>> fetchSchedules() async {
    final token = AuthService.token;
    if (token == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('$baseUrl/api/schedule');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) {
        return body
            .whereType<Map<String, dynamic>>()
            .map(ScheduleItem.fromJson)
            .toList();
      }
      return [];
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Authentication failed. Please log in again.');
    }

    throw Exception('Failed to load schedules: ${response.statusCode}.');
  }

  static Future<ScheduleItem> createSchedule({
    required String subject,
    required String studyDate,
    required String startTime,
    required String endTime,
    String? location,
    String? mood,
  }) async {
    final token = AuthService.token;
    if (token == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('$baseUrl/api/schedule');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'subject': subject,
        'studyDate': studyDate,
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'mood': mood,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return ScheduleItem.fromJson(body);
      }
      throw Exception('Invalid response from schedule API.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Authentication failed. Please log in again.');
    }

    throw Exception('Failed to create schedule: ${response.statusCode}.');
  }

  static Future<List<ScheduleItem>> generateAutoSchedule({
    required List<String> subjects,
    required List<String> availableDays,
    required String startHour,
    required String endHour,
    required int durationMinutes,
    int daysAhead = 7,
  }) async {
    final token = AuthService.token;
    if (token == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('$baseUrl/api/schedule/auto');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'subjects': subjects,
        'availableDays': availableDays,
        'startHour': startHour,
        'endHour': endHour,
        'durationMinutes': durationMinutes,
        'daysAhead': daysAhead,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) {
        return body
            .whereType<Map<String, dynamic>>()
            .map(ScheduleItem.fromJson)
            .toList();
      }
      return [];
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Authentication failed. Please log in again.');
    }

    throw Exception('Failed to generate AI schedule: ${response.statusCode}.');
  }

  static Future<ScheduleItem> completeSchedule(int id) async {
    final token = AuthService.token;
    if (token == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('$baseUrl/api/schedule/$id/complete');
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return ScheduleItem.fromJson(body);
      }
      throw Exception('Invalid response from schedule API.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Authentication failed. Please log in again.');
    }

    throw Exception('Failed to complete schedule: ${response.statusCode}.');
  }

  static Future<void> deleteSchedule(int id) async {
    final token = AuthService.token;
    if (token == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('$baseUrl/api/schedule/$id');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Authentication failed. Please log in again.');
    }

    throw Exception('Failed to delete schedule: ${response.statusCode}.');
  }
  static Future<List<String>> parseSubjectsFromFile(
    String filePath,
    String fileName,
  ) async {
    final token = AuthService.token;
    if (token == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('$baseUrl/api/schedule/parse-file');
    final file = File(filePath);
    final ext = fileName.split('.').last.toLowerCase();

    // Determine MIME type
    MediaType mediaType;
    switch (ext) {
      case 'pdf':
        mediaType = MediaType('application', 'pdf');
        break;
      case 'docx':
        mediaType = MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
        break;
      case 'csv':
        mediaType = MediaType('text', 'csv');
        break;
      default:
        mediaType = MediaType('text', 'plain');
    }

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: fileName,
        contentType: mediaType,
      ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final rawList = body['subjects'];
      if (rawList is List) {
        return rawList.whereType<String>().toList();
      }
      return [];
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Authentication failed. Please log in again.');
    }

    final errBody = jsonDecode(response.body);
    throw Exception(errBody['error'] ?? 'Gagal memproses file: ${response.statusCode}');
  }
}

class ScheduleItem {
  final int id;
  final String subject;
  final String studyDate;
  final String startTime;
  final String endTime;
  final String? location;
  final String? mood;
  final bool isCompleted;

  ScheduleItem({
    required this.id,
    required this.subject,
    required this.studyDate,
    required this.startTime,
    required this.endTime,
    this.location,
    this.mood,
    required this.isCompleted,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] is int ? json['id'] as int : (json['id'] is num ? (json['id'] as num).toInt() : 0),
      subject: json['subject'] as String? ?? '',
      studyDate: json['studyDate'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      location: json['location'] as String?,
      mood: json['mood'] as String?,
      isCompleted: json['isCompleted'] == true,
    );
  }
}