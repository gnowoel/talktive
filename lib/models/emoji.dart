class Emoji {
  final String name;
  final String code;

  Emoji({
    required this.name,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
    };
  }

  factory Emoji.fromJson(Map<String, dynamic> json) {
    return Emoji(
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}
