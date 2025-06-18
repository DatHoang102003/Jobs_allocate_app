class Comment {
  final String id;
  final String taskId;
  final String authorId;
  final String contents;
  final List<String> attachments;
  final DateTime created;
  final DateTime? updated;

  Comment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.contents,
    required this.attachments,
    required this.created,
    this.updated,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      taskId: json['task'] as String,
      authorId: json['author'] as String,
      contents: json['contents'] as String? ?? '',
      attachments: List<String>.from(json['attachments'] as List? ?? []),
      created: DateTime.parse(json['created'] as String),
      updated: json['updated'] != null
          ? DateTime.parse(json['updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // NOTE: không cần gửi 'id' lên khi tạo mới
      'task': taskId,
      'author': authorId,
      'contents': contents,
      'attachments': attachments, // array of filenames or URLs
      // PocketBase tự xử lý created/updated timestamps
    };
  }
}
