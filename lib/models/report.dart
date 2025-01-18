class Report {
  final String id;
  final String userId;
  final String chatId;
  final String partnerId;
  final String status;
  final String? resolution;
  final String? adminId;
  final int createdAt;
  final int? resolvedAt;

  const Report({
    required this.id,
    required this.userId,
    required this.chatId,
    required this.partnerId,
    required this.status,
    this.resolution,
    this.adminId,
    required this.createdAt,
    this.resolvedAt,
  });

  factory Report.fromJson(String id, Map<String, dynamic> json) {
    return Report(
      id: id,
      userId: json['userId'] as String,
      chatId: json['chatId'] as String,
      partnerId: json['partnerId'] as String,
      status: json['status'] as String,
      resolution: json['resolution'] as String?,
      adminId: json['adminId'] as String?,
      createdAt: json['createdAt'] as int,
      resolvedAt: json['resolvedAt'] as int?,
    );
  }
}
