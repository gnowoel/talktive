import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var response = await http.post(
    Uri.parse('http://localhost:8080/userProfile'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({"method": "getUserProfile", "userId": "019c8ddf-31dd-773a-9161-6aff5715a9d4"})
  );
  print(response.body);
}
