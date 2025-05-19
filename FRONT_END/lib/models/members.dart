class Members {
  final String id;
  final String userId;
  final String groupId;
  final String role;
  final DateTime joinedAt;

  Members({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.role,
    required this.joinedAt,
  });

  factory Members.fromJson(Map<String, dynamic> json) {
    return Members(
      id: json['id'],
      userId: json['user'],
      groupId: json['group'],
      role: json['role'],
      joinedAt: DateTime.parse(json['joinedAt']),
    );
  }
}
