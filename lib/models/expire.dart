class Expire {
  String? id;
  final String roomId;

  Expire({
    this.id,
    required this.roomId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
    };
  }

  factory Expire.fromJson(Map<String, dynamic> json) {
    return Expire(
      id: json['id'] as String?,
      roomId: json['roomId'] as String,
    );
  }
}
