class Task {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final List<String> assigneeUserIds; // <-- từ String thành List<String>
  final String status;
  final DateTime? deadline;
  final String createdByUserId;

  Task({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.assigneeUserIds,
    required this.status,
    this.deadline,
    required this.createdByUserId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      groupId: json['group'],
      title: json['title'],
      description: json['description'],
      // giả sử key trong JSON là 'assignee' và nó là mảng các ID user
      assigneeUserIds: List<String>.from(json['assignee'] as List),
      status: json['status'],
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      createdByUserId: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group': groupId,
      'title': title,
      'description': description,
      // trả về mảng các ID
      'assignee': assigneeUserIds,
      'status': status,
      'deadline': deadline?.toIso8601String(),
      'createdBy': createdByUserId,
    };
  }
}
