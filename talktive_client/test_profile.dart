import 'package:talktive_client/talktive_client.dart';

void main() async {
  var client = Client('http://localhost:8080/');
  try {
    var userId = '019c8ddf-31dd-773a-9161-6aff5715a9d4';
    var profile = await client.userProfile.getUserProfile(userId);
    print('Profile: $profile');
  } catch (e, stack) {
    print('Exception: $e');
    print(stack);
  }
}
