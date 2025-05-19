class JoinRequest {
  final String id;
  final String userId;
  final String groupId;
  final String status; // "pending", "approved", "rejected"

  JoinRequest({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.status,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['id'],
      userId: json['user'],
      groupId: json['group'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'group': groupId,
      'status': status,
    };
  }
}
