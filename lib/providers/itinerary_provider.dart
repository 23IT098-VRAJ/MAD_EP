import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/itinerary_item.dart';

class ItineraryProvider extends ChangeNotifier {
  static const String _boxName = 'itinerary';

  /// Items for the currently loaded trip, sorted by date then time.
  List<ItineraryItem> _items = [];

  /// The trip whose items are currently loaded. `null` means nothing is loaded.
  String? _currentTripId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Public read-only getters ──────────────────────────────────────────────

  List<ItineraryItem> get items => List.unmodifiable(_items);

  String? get currentTripId => _currentTripId;

  // ── Hive box helper ───────────────────────────────────────────────────────

  Box<ItineraryItem> get _box => Hive.box<ItineraryItem>(_boxName);

  // ── CRUD operations ───────────────────────────────────────────────────────

  /// Loads all [ItineraryItem]s associated with [tripId] from Hive and
  /// sorts them chronologically (date ascending, then time ascending).
  Future<void> loadItemsForTrip(String tripId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentTripId = tripId;
      _items = _box.values.where((item) => item.tripId == tripId).toList();
      _sortItems();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Persists a new [ItineraryItem]. If it belongs to the currently loaded
  /// trip it is also added to the in-memory list immediately.
  Future<void> addItem(ItineraryItem item) async {
    await _box.put(item.id, item);
    if (item.tripId == _currentTripId) {
      _items.add(item);
      _sortItems();
      notifyListeners();
    }
  }

  /// Replaces the stored [ItineraryItem] with [updated].
  Future<void> updateItem(ItineraryItem updated) async {
    await _box.put(updated.id, updated);
    if (updated.tripId == _currentTripId) {
      final index = _items.indexWhere((i) => i.id == updated.id);
      if (index != -1) {
        _items[index] = updated;
        _sortItems();
        notifyListeners();
      }
    }
  }

  /// Deletes the [ItineraryItem] with [id] from Hive and the in-memory list.
  Future<void> deleteItem(String id) async {
    await _box.delete(id);
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  /// Deletes **all** items belonging to [tripId]. Useful when a Trip is
  /// deleted to keep the Hive box clean.
  Future<void> deleteAllForTrip(String tripId) async {
    final keysToDelete = _box.values
        .where((i) => i.tripId == tripId)
        .map((i) => i.id)
        .toList();
    await _box.deleteAll(keysToDelete);
    if (_currentTripId == tripId) {
      _items.clear();
      notifyListeners();
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Sorts [_items] by date (ascending) then by time-of-day (ascending).
  /// Items without a time value are placed at the end of their day.
  void _sortItems() {
    _items.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;

      // Both have a time → compare numerically.
      if (a.timeOfDayMinutes != null && b.timeOfDayMinutes != null) {
        return a.timeOfDayMinutes!.compareTo(b.timeOfDayMinutes!);
      }
      // Items without a time sink to the bottom of the day.
      if (a.timeOfDayMinutes == null) return 1;
      return -1;
    });
  }
}
