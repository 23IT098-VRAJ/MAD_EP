import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'expense.g.dart';

@HiveType(typeId: 2)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tripId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String paidBy;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final DateTime date;

  Expense({
    String? id,
    required this.tripId,
    required this.amount,
    required this.paidBy,
    required this.description,
    required this.date,
  }) : id = id ?? const Uuid().v4();

  /// Returns a new [Expense] with the given fields replaced.
  Expense copyWith({
    String? tripId,
    double? amount,
    String? paidBy,
    String? description,
    DateTime? date,
  }) {
    return Expense(
      id: id,
      tripId: tripId ?? this.tripId,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'amount': amount,
      'paidBy': paidBy,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      tripId: map['tripId'] as String,
      amount: (map['amount'] as num).toDouble(),
      paidBy: map['paidBy'] as String,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  @override
  String toString() =>
      'Expense(id: $id, tripId: $tripId, amount: $amount, '
      'paidBy: $paidBy, description: $description, date: $date)';
}
