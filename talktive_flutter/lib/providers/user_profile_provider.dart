import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'client_provider.dart';

/// Provider for user profile data (cached)
final userProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
      try {
        final client = ref.read(clientProvider);
        final profile = await client.userProfile.getUserProfile(userId);
        return profile;
      } catch (e) {
        debugPrint('Error loading user profile for $userId: $e');
        return null;
      }
    });
