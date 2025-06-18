class InviteRequest {
  final String id;
  final String inviterId;
  final String inviteeId;
  final String groupId;
  final String status; // "pending", "accepted", "rejected"

  InviteRequest({
    required this.id,
    required this.inviterId,
    required this.inviteeId,
    required this.groupId,
    required this.status,
  });

  factory InviteRequest.fromJson(Map<String, dynamic> json) {
    return InviteRequest(
      id: json['id'],
      inviterId: json['inviter'],
      inviteeId: json['invitee'],
      groupId: json['group'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inviter': inviterId,
      'invitee': inviteeId,
      'group': groupId,
      'status': status,
    };
  }
}
