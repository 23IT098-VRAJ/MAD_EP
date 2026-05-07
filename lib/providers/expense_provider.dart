import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/expense.dart';

/// Represents a single payment that settles a debt.
class Settlement {
  final String from;
  final String to;
  final double amount;

  const Settlement({
    required this.from,
    required this.to,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {'from': from, 'to': to, 'amount': amount};

  @override
  String toString() =>
      'Settlement($from → $to: ${amount.toStringAsFixed(2)})';
}

class ExpenseProvider extends ChangeNotifier {
  static const String _boxName = 'expenses';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// All expenses for the currently loaded trip (no filter applied).
  List<Expense> _expenses = [];

  /// The currently active view: filtered result of [_expenses].
  List<Expense> _filtered = [];

  /// The trip whose expenses are currently loaded.
  String? _currentTripId;

  // ── Public read-only getters ──────────────────────────────────────────────

  /// Full unfiltered expense list for the current trip.
  List<Expense> get expenses => List.unmodifiable(_expenses);

  /// Currently visible (possibly filtered) expense list.
  List<Expense> get filtered => List.unmodifiable(_filtered);

  String? get currentTripId => _currentTripId;

  /// Total amount spent in the current (filtered) view.
  double get totalFiltered =>
      _filtered.fold(0.0, (sum, e) => sum + e.amount);

  /// Total amount spent across all expenses for the current trip.
  double get totalAll =>
      _expenses.fold(0.0, (sum, e) => sum + e.amount);

  // ── Hive box helper ───────────────────────────────────────────────────────

  Box<Expense> get _box => Hive.box<Expense>(_boxName);

  // ── CRUD operations ───────────────────────────────────────────────────────

  /// Loads all [Expense]s for [tripId] from Hive, newest first.
  Future<void> loadExpensesForTrip(String tripId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentTripId = tripId;
      _expenses = _box.values.where((e) => e.tripId == tripId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      _filtered = List.from(_expenses);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  /// Persists a new [Expense] and prepends it to the in-memory lists when it
  /// belongs to the currently loaded trip.
  Future<void> addExpense(Expense expense) async {
    await _box.put(expense.id, expense);
    if (expense.tripId == _currentTripId) {
      _expenses.insert(0, expense);
      _filtered.insert(0, expense);
      notifyListeners();
    }
  }

  /// Removes the [Expense] with [id] from Hive and both in-memory lists.
  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
    _expenses.removeWhere((e) => e.id == id);
    _filtered.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Deletes **all** expenses for [tripId]. Call when a Trip is deleted.
  Future<void> deleteAllForTrip(String tripId) async {
    final keysToDelete = _box.values
        .where((e) => e.tripId == tripId)
        .map((e) => e.id)
        .toList();
    await _box.deleteAll(keysToDelete);
    if (_currentTripId == tripId) {
      _expenses.clear();
      _filtered.clear();
      notifyListeners();
    }
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  /// Shows only expenses paid by [name]. Pass an empty string to clear.
  void filterByParticipant(String name) {
    if (name.isEmpty) {
      clearFilter();
      return;
    }
    _filtered = _expenses
        .where((e) => e.paidBy.toLowerCase() == name.toLowerCase())
        .toList();
    notifyListeners();
  }

  /// Shows only expenses whose date matches [date] (year + month + day only).
  void filterByDate(DateTime date) {
    _filtered = _expenses.where((e) {
      return e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
    notifyListeners();
  }

  /// Resets [_filtered] to show all expenses for the current trip.
  void clearFilter() {
    _filtered = List.from(_expenses);
    notifyListeners();
  }

  // ── Balance & settlement logic ────────────────────────────────────────────

  /// Calculates the **net balance** of every participant for [tripId].
  ///
  /// Algorithm:
  ///   1. Compute the equal share each person owes: total / n.
  ///   2. For each participant, net = (amount they paid) − (their share).
  ///   3. A positive balance means the group owes them money.
  ///   4. A negative balance means they still owe the group money.
  ///
  /// Returns `Map<participantName, netBalance>`.
  Map<String, double> calculateBalances(
    String tripId,
    List<String> participants,
  ) {
    if (participants.isEmpty) return {};

    // Pull all expenses for this trip directly from Hive so the result is
    // always accurate regardless of which trip is currently "loaded".
    final tripExpenses =
        _box.values.where((e) => e.tripId == tripId).toList();

    final double total =
        tripExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final double share = total / participants.length;

    // Start everyone at 0.
    final Map<String, double> paid = {for (final p in participants) p: 0.0};

    for (final expense in tripExpenses) {
      // Only attribute payments to known participants.
      if (paid.containsKey(expense.paidBy)) {
        paid[expense.paidBy] = paid[expense.paidBy]! + expense.amount;
      }
    }

    // net = paid − owed (share)
    return paid.map((name, amountPaid) {
      final net = amountPaid - share;
      return MapEntry(name, double.parse(net.toStringAsFixed(2)));
    });
  }

  /// Converts a net-balance map into a minimal list of [Settlement]s using a
  /// **greedy two-pointer algorithm**:
  ///
  ///   1. Separate participants into creditors (net > 0) and debtors (net < 0).
  ///   2. Sort both lists by absolute amount descending.
  ///   3. At each step, match the largest debtor with the largest creditor:
  ///      - The payment is min(|debtor|, creditor).
  ///      - Reduce both balances; if one reaches 0 advance that pointer.
  ///   4. Repeat until all balances are settled.
  ///
  /// This produces at most n−1 transactions (optimal in the number of transfers
  /// for a general debt graph).
  List<Settlement> calculateSettlements(Map<String, double> balances) {
    if (balances.length <= 1) return [];

    const double epsilon = 0.005; // ignore floating-point dust

    // Mutable copies sorted by absolute value descending.
    final debtors = balances.entries
        .where((e) => e.value < -epsilon)
        .map((e) => _MutableBalance(e.key, e.value))
        .toList()
      ..sort((a, b) => a.amount.compareTo(b.amount)); // most negative first

    final creditors = balances.entries
        .where((e) => e.value > epsilon)
        .map((e) => _MutableBalance(e.key, e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount)); // most positive first

    final settlements = <Settlement>[];

    int di = 0, ci = 0;

    while (di < debtors.length && ci < creditors.length) {
      final debtor = debtors[di];
      final creditor = creditors[ci];

      // The payment is the smaller of what the debtor owes and what the
      // creditor is owed.
      final payment = debtor.amount.abs() < creditor.amount
          ? debtor.amount.abs()
          : creditor.amount;

      if (payment > epsilon) {
        settlements.add(Settlement(
          from: debtor.name,
          to: creditor.name,
          amount: double.parse(payment.toStringAsFixed(2)),
        ));
      }

      debtor.amount += payment; // moves toward 0
      creditor.amount -= payment; // moves toward 0

      if (debtor.amount.abs() <= epsilon) di++;
      if (creditor.amount.abs() <= epsilon) ci++;
    }

    return settlements;
  }
}

// ── Private helper ────────────────────────────────────────────────────────────

/// Mutable wrapper used only inside [ExpenseProvider.calculateSettlements].
class _MutableBalance {
  final String name;
  double amount;
  _MutableBalance(this.name, this.amount);
}
