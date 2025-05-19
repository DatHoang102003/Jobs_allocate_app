class User {
  final String username;
  final String fullName;
  final String email;

  User({
    required this.username,
    required this.fullName,
    required this.email,
  });

  /// Parse từ JSON thành User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
    );
  }

  /// Chuyển User thành JSON
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'fullName': fullName,
      'email': email,
    };
  }
}
