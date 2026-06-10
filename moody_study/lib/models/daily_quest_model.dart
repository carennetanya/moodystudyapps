class DailyQuestModel {
  final String questDate;
  final int todayCoins;  // Coin yang sudah dikumpul dari quest completed hari ini
  final int maxCoins;    // Total Coin maksimal yang bisa didapat hari ini
  final List<QuestItem> quests;

  DailyQuestModel({
    required this.questDate,
    required this.todayCoins,
    required this.maxCoins,
    required this.quests,
  });

  factory DailyQuestModel.fromJson(Map<String, dynamic> json) {
    return DailyQuestModel(
      questDate: json['questDate'] as String? ?? '',
      todayCoins: (json['todayCoins'] as num?)?.toInt() ?? 0,
      maxCoins: (json['maxCoins'] as num?)?.toInt() ?? 0,
      quests: (json['quests'] as List<dynamic>? ?? [])
          .map((e) => QuestItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuestItem {
  final int id;
  final String questKey;
  final String title;
  final String description;
  final int coinReward;
  final bool completed;

  QuestItem({
    required this.id,
    required this.questKey,
    required this.title,
    required this.description,
    required this.coinReward,
    required this.completed,
  });

  factory QuestItem.fromJson(Map<String, dynamic> json) {
    return QuestItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      questKey: json['questKey'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coinReward: (json['coinReward'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }
}