class Comment {
  final String id;
  final String taskId;
  final String userId;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      taskId: json['taskId'],
      userId: json['userId'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'userId': userId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
