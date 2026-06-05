import 'api_client.dart';
import '../models/daily_quest_model.dart';

class DailyQuestService {
  static Future<DailyQuestModel> getDailyQuests() async {
    final res = await ApiClient.dio.get('/api/quest/daily');
    return DailyQuestModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<DailyQuestModel> completeReviewStats() async {
    final res = await ApiClient.dio.post('/api/quest/complete-review');
    return DailyQuestModel.fromJson(res.data as Map<String, dynamic>);
  }
}
