import 'image_message.dart';
import 'text_message.dart';

abstract class Message {
  final String? id;
  final int createdAt;
  final String type; // 'text' or 'image'
  final bool recalled;

  const Message({
    this.id,
    required this.createdAt,
    required this.type,
    this.recalled = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'image') {
      return ImageMessage.fromJson(json);
    } else {
      return TextMessage.fromJson(json);
    }
  }
}
