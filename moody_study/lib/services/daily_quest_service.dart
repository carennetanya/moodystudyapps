import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/daily_quest_model.dart';

class DailyQuestService {
  static Future<DailyQuestModel> getDailyQuests() async {
    final res = await ApiClient.dio.get('/api/quest/daily');
    return DailyQuestModel.fromJson(res.data as Map<String, dynamic>);
  }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Autentikasi gagal. Silakan login ulang.');
    }

    throw Exception('Gagal memuat daily quest: ${response.statusCode}.');
  }

  /// Tandai quest REVIEW_STATS selesai.
  /// Panggil ini saat user membuka halaman statistik.
  static Future<DailyQuestModel> completeReviewStats() async {
    final uri = Uri.parse('$baseUrl/api/quest/complete-review');
    final response = await http.post(uri, headers: _authHeaders);

    if (response.statusCode == 200) {
      return DailyQuestModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Autentikasi gagal. Silakan login ulang.');
    }

    throw Exception('Gagal menyelesaikan quest review: ${response.statusCode}.');
  }
}