import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../models/tribe.dart';
import 'firestore.dart';

class TribeCache extends ChangeNotifier {
  final Firestore _firestore;
  
  List<Tribe> _tribes = [];
  bool _isLoading = false;
  DateTime? _lastFetched;
  
  TribeCache(this._firestore);
  
  List<Tribe> get tribes => _tribes;
  bool get isLoading => _isLoading;
  
  Future<void> fetchTribes() async {
    if (_isLoading) return;
    
    final now = DateTime.now();
    if (_lastFetched != null && 
        now.difference(_lastFetched!).inMinutes < 15 && 
        _tribes.isNotEmpty) {
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
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
  
  List<Tribe> searchTribes(String query) {
    if (query.isEmpty) return _tribes;
    
    final lowercaseQuery = query.toLowerCase();
    return _tribes.where((tribe) => 
      tribe.name.toLowerCase().contains(lowercaseQuery) ||
      (tribe.description?.toLowerCase().contains(lowercaseQuery) ?? false)
    ).toList();
  }
  
  Future<Tribe> createTribe(String name, {String? description, String? iconEmoji}) async {
    final tribe = await _firestore.createTribe(
      name: name,
      description: description,
      iconEmoji: iconEmoji,
    );
    
    _tribes = [..._tribes, tribe];
    notifyListeners();
    
    return tribe;
  }
}