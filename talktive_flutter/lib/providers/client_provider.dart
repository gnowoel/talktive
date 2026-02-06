import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';

late Client _client;

void initializeClient(Client client) {
  _client = client;
}

final clientProvider = Provider<Client>((ref) => _client);
