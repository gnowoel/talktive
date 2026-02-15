import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';

part 'resident_provider.g.dart';

@riverpod
class CurrentResident extends _$CurrentResident {
  @override
  FutureOr<Resident?> build() async {
    return fetchResident();
  }

  Future<Resident?> fetchResident() async {
    final client = ref.read(clientProvider);
    try {
      return await client.resident.getResident();
    } catch (e) {
      return null;
    }
  }
}

/// Provider to fetch a resident by their user ID
@riverpod
Future<Resident?> residentById(ResidentByIdRef ref, String userId) async {
  final client = ref.read(clientProvider);
  try {
    return await client.resident.getResidentById(userId);
  } catch (e) {
    return null;
  }
}
