import '../services/server_clock.dart';

class Report {
  final String id;
  final String userId;
  final String chatId;
  final String? partnerDisplayName;
  final String status;
  final String? resolution;
  final String? adminId;
  final int createdAt;
  final int? revivedAt;

  const Report({
    required this.id,
    required this.userId,
    required this.chatId,
    this.partnerDisplayName,
    required this.status,
    this.resolution,
    this.adminId,
    required this.createdAt,
    this.revivedAt,
  });

  factory Report.fromJson(String id, Map<String, dynamic> json) {
    return Report(
      id: id,
      userId: json['userId'] as String,
      chatId: json['chatId'] as String,
      partnerDisplayName: json['partnerDisplayName'] as String?,
      status: json['status'] as String,
      resolution: json['resolution'] as String?,
      adminId: json['adminId'] as String?,
      createdAt: json['createdAt'] as int,
      revivedAt: json['revivedAt'] as int?,
    );
  }

  bool get isActive {
    final now = ServerClock().now;
    final twelveHoursAgo = now - 12 * 60 * 60 * 1000;
    return createdAt >= twelveHoursAgo;
  }
}
