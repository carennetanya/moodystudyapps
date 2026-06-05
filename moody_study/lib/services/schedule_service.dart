import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'api_client.dart';

class ScheduleService {
  static Future<List<ScheduleItem>> fetchSchedules() async {
    final res = await ApiClient.dio.get('/api/schedule');
    final body = res.data;
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(ScheduleItem.fromJson)
          .toList();
    }
    return [];
  }

  static Future<ScheduleItem> createSchedule({
    required String subject,
    required String studyDate,
    required String startTime,
    required String endTime,
    String? location,
    String? mood,
  }) async {
    final res = await ApiClient.dio.post(
      '/api/schedule',
      data: {
        'subject': subject,
        'studyDate': studyDate,
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'mood': mood,
      },
    );
    final body = res.data;
    if (body is Map<String, dynamic>) {
      return ScheduleItem.fromJson(body);
    }
    throw Exception('Invalid response from schedule API.');
  }

  static Future<List<ScheduleItem>> generateAutoSchedule({
    required List<String> subjects,
    required List<String> availableDays,
    required String startHour,
    required String endHour,
    required int durationMinutes,
    int daysAhead = 7,
  }) async {
    final res = await ApiClient.dio.post(
      '/api/schedule/auto',
      data: {
        'subjects': subjects,
        'availableDays': availableDays,
        'startHour': startHour,
        'endHour': endHour,
        'durationMinutes': durationMinutes,
        'daysAhead': daysAhead,
      },
    );
    final body = res.data;
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(ScheduleItem.fromJson)
          .toList();
    }
    return [];
  }

  static Future<ScheduleItem> completeSchedule(int id) async {
    final res = await ApiClient.dio.patch('/api/schedule/$id/complete');
    final body = res.data;
    if (body is Map<String, dynamic>) {
      return ScheduleItem.fromJson(body);
    }
    throw Exception('Invalid response from schedule API.');
  }

  static Future<void> deleteSchedule(int id) async {
    await ApiClient.dio.delete('/api/schedule/$id');
  }

  static Future<List<String>> parseSubjectsFromFile(
    String filePath,
    String fileName,
  ) async {
    final ext = fileName.split('.').last.toLowerCase();
    final MediaType mediaType;
    switch (ext) {
      case 'pdf':
        mediaType = MediaType('application', 'pdf');
        break;
      case 'docx':
        mediaType = MediaType(
          'application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
        break;
      case 'csv':
        mediaType = MediaType('text', 'csv');
        break;
      default:
        mediaType = MediaType('text', 'plain');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: mediaType,
      ),
    });

    final res = await ApiClient.dio.post(
      '/api/schedule/parse-file',
      data: formData,
    );

    final body = res.data;
    final rawList = body is Map<String, dynamic> ? body['subjects'] : null;
    if (rawList is List) {
      return rawList.whereType<String>().toList();
    }
    return [];
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
      id: json['id'] is int
          ? json['id'] as int
          : (json['id'] is num ? (json['id'] as num).toInt() : 0),
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
