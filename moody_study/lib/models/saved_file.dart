class SavedFile {
  final int id;
  final String fileName;
  final String fileType;
  final String content;
  final String savedAt;

  SavedFile({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.content,
    required this.savedAt,
  });

  factory SavedFile.fromJson(Map<String, dynamic> json) {
    return SavedFile(
      id: json['id'] as int,
      fileName: json['fileName'] as String,
      fileType: json['fileType'] as String,
      content: json['content'] as String,
      savedAt: json['savedAt'] as String,
    );
  }
}
