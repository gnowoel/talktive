import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../models/tribe.dart';
import 'firestore.dart';
import 'server_clock.dart';

class TribeCache extends ChangeNotifier {
  final Firestore _firestore;

  List<Tribe> _tribes = [];
  bool _isLoading = false;
  DateTime? _lastFetched;

  // Longer cache TTL since tribes are now predefined
  static const int _cacheTtlHours = 6;

  TribeCache(this._firestore);

  List<Tribe> get tribes => _tribes;
  bool get hasTribes => _tribes.isNotEmpty;

  // Initialization method to be called on app startup
  Future<void> initialize() async {
    await fetchTribes(forceRefresh: true);
  }

  // Improved fetch method with force refresh option
  Future<void> fetchTribes({bool forceRefresh = false}) async {
    if (_isLoading) return;

    final now = DateTime.fromMillisecondsSinceEpoch(ServerClock().now);
    if (!forceRefresh &&
        _lastFetched != null &&
        now.difference(_lastFetched!).inHours < _cacheTtlHours &&
        _tribes.isNotEmpty) {
      return;
    }

    _isLoading = true;

    try {
      final tribes = await _firestore.fetchTribes();
      _tribes = tribes;
      _lastFetched = now;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Tribe? getTribeById(String id) {
    return _tribes.firstWhereOrNull((tribe) => tribe.id == id);
  }

  // Get tribe by name, useful for predefined tribes
  Tribe? getTribeByName(String name) {
    return _tribes.firstWhereOrNull(
        (tribe) => tribe.name.toLowerCase() == name.toLowerCase());
  }

  // Get a tribe by ID, fetching if needed
  Future<Tribe?> ensureTribeLoaded(String id) async {
    final tribe = getTribeById(id);
    if (tribe != null) return tribe;

    // If tribe not found in cache, refresh and try again
    await fetchTribes(forceRefresh: true);
    return getTribeById(id);
  }

  List<Tribe> searchTribes(String query) {
    if (query.isEmpty) return _tribes;

    final lowercaseQuery = query.toLowerCase();
    return _tribes
        .where(
          (tribe) =>
              tribe.name.toLowerCase().contains(lowercaseQuery) ||
              (tribe.description?.toLowerCase().contains(lowercaseQuery) ??
                  false),
        )
        .toList();
  }

  // Get predefined tribes (those with sort values)
  List<Tribe> get predefinedTribes =>
      _tribes.where((tribe) => tribe.sort != null).toList()
        ..sort((a, b) => (a.sort ?? 999).compareTo(b.sort ?? 999));

  @override
  void dispose() {
    _tribes.clear();
    _isLoading = false;
    _lastFetched = null;
    super.dispose();
  }
}
