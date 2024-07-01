class Access {
  String? id;
  final String roomId;

  Access({
    this.id,
    required this.roomId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
    };
  }

  factory Access.fromJson(Map<String, dynamic> json) {
    return Access(
      id: json['id'] as String?,
      roomId: json['roomId'] as String,
    );
  }
}
