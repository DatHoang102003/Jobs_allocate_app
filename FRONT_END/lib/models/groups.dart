class Group {
  final String id;
  final String name;
  final String description;
  final String owner;
  final DateTime created;
  final DateTime updated;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.owner,
    required this.created,
    required this.updated,
  });

  /// Tạo Group từ JSON (dữ liệu lấy từ PocketBase)
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      owner: json['owner'] ?? '',
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  /// Chuyển Group thành JSON (dùng khi tạo hoặc cập nhật)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'owner': owner,
    };
  }
}


