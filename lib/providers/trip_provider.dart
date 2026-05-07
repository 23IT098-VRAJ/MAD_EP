import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/trip.dart';

class TripProvider extends ChangeNotifier {
  static const String _boxName = 'trips';

  /// All trips stored in Hive, ordered by start date (newest first).
  List<Trip> _trips = [];

  /// The current search query. Empty string means no filter.
  String _searchQuery = '';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Public read-only getters ──────────────────────────────────────────────

  /// Full, unfiltered trip list.
  List<Trip> get trips => List.unmodifiable(_trips);

  /// Trips filtered by the current [_searchQuery] (matches name or destination,
  /// case-insensitive).
  List<Trip> get filteredTrips {
    if (_searchQuery.isEmpty) return List.unmodifiable(_trips);
    final q = _searchQuery.toLowerCase();
    return _trips
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.destination.toLowerCase().contains(q))
        .toList();
  }

  String get searchQuery => _searchQuery;

  // ── Hive box helper ───────────────────────────────────────────────────────

  Box<Trip> get _box => Hive.box<Trip>(_boxName);

  // ── CRUD operations ───────────────────────────────────────────────────────

  /// Reads all persisted [Trip]s from Hive and refreshes the in-memory list.
  Future<void> loadTrips() async {
    _isLoading = true;
    notifyListeners();
    try {
      _trips = _box.values.toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Persists a new [Trip] and adds it to the in-memory list.
  Future<void> addTrip(Trip trip) async {
    await _box.put(trip.id, trip);
    _trips.add(trip);
    _trips.sort((a, b) => b.startDate.compareTo(a.startDate));
    notifyListeners();
  }

  /// Replaces the persisted [Trip] with [updated] and refreshes the list.
  Future<void> updateTrip(Trip updated) async {
    await _box.put(updated.id, updated);
    final index = _trips.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _trips[index] = updated;
      _trips.sort((a, b) => b.startDate.compareTo(a.startDate));
      notifyListeners();
    }
  }

  /// Removes a [Trip] from Hive and the in-memory list by its [id].
  Future<void> deleteTrip(String id) async {
    await _box.delete(id);
    _trips.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  /// Updates [_searchQuery] and notifies listeners so [filteredTrips] is
  /// recomputed automatically.
  void searchTrips(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  /// Clears the active search filter.
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // ── Convenience helpers ───────────────────────────────────────────────────

  /// Returns a single trip by [id], or `null` if not found.
  Trip? getById(String id) {
    try {
      return _trips.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
