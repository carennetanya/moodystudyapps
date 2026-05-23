class DailyQuestModel {
  final String questDate;
  final int todayXp;  // XP yang sudah dikumpul dari quest completed hari ini
  final int maxXp;    // Total XP maksimal yang bisa didapat hari ini
  final List<QuestItem> quests;

  DailyQuestModel({
    required this.questDate,
    required this.todayXp,
    required this.maxXp,
    required this.quests,
  });

  factory DailyQuestModel.fromJson(Map<String, dynamic> json) {
    return DailyQuestModel(
      questDate: json['questDate'] as String? ?? '',
      todayXp: (json['todayXp'] as num?)?.toInt() ?? 0,
      maxXp: (json['maxXp'] as num?)?.toInt() ?? 0,
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
  final int xpReward;
  final bool completed;

  QuestItem({
    required this.id,
    required this.questKey,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.completed,
  });

  factory QuestItem.fromJson(Map<String, dynamic> json) {
    return QuestItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      questKey: json['questKey'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }
}