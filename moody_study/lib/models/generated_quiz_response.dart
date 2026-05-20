class GeneratedQuizResponse {
  final int id;
  final int materialId;
  final String fileName;
  final String quizContent;
  final String generatedAt;

  GeneratedQuizResponse({
    required this.id,
    required this.materialId,
    required this.fileName,
    required this.quizContent,
    required this.generatedAt,
  });

  factory GeneratedQuizResponse.fromJson(Map<String, dynamic> json) {
    return GeneratedQuizResponse(
      id: (json['id'] as num).toInt(),
      materialId: (json['materialId'] as num).toInt(),
      fileName: json['fileName'] as String,
      quizContent: json['quizContent'] as String,
      generatedAt: json['generatedAt'] as String,
    );
  }
}
