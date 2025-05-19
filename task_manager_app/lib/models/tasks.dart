class Task {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final String assignUserId;
  final String status;
  final DateTime? deadline;
  final String createdByUserId;

  Task({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.assignUserId,
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
      assignUserId: json['assign'],
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
      'assign': assignUserId,
      'status': status,
      'deadline': deadline?.toIso8601String(),
      'createdBy': createdByUserId,
    };
  }
}
