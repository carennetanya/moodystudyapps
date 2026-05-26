class GeneratedQuizResponse {
  final int id;
  final int materialId;
  final String fileName;
  final String quizContent;
  final String generatedAt;
  final bool saved;

  GeneratedQuizResponse({
    required this.id,
    required this.materialId,
    required this.fileName,
    required this.quizContent,
    required this.generatedAt,
    this.saved = false,
  });

  factory GeneratedQuizResponse.fromJson(Map<String, dynamic> json) {
    return GeneratedQuizResponse(
      id: (json['id'] as num).toInt(),
      materialId: (json['materialId'] as num).toInt(),
      fileName: json['fileName'] as String,
      quizContent: json['quizContent'] as String,
      generatedAt: json['generatedAt'] as String,
      saved: json['saved'] as bool? ?? false,
    );
  }
}