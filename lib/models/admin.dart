class Admin {
  final String id;
  final String role; // 'admin' or 'moderator'
  final int createdAt;
  final int updatedAt;

  const Admin({
    required this.id,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] as String,
      role: json['role'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}
