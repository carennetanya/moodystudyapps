class MaterialResponse {
  final int id;
  final String fileName;
  final String summary;
  final String uploadedAt;

  MaterialResponse({
    required this.id,
    required this.fileName,
    required this.summary,
    required this.uploadedAt,
  });

  factory MaterialResponse.fromJson(Map<String, dynamic> json) {
    return MaterialResponse(
      id: (json['id'] as num).toInt(),
      fileName: json['fileName'] as String,
      summary: json['summary'] as String,
      uploadedAt: json['uploadedAt'] as String,
    );
  }
}
