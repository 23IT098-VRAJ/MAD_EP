import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'trip.g.dart';

@HiveType(typeId: 0)
class Trip extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String destination;

  @HiveField(3)
  final DateTime startDate;

  @HiveField(4)
  final DateTime endDate;

  @HiveField(5)
  final List<String> participants;

  Trip({
    String? id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.participants,
  }) : id = id ?? const Uuid().v4();

  /// Returns a new [Trip] with the given fields replaced.
  Trip copyWith({
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? participants,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      participants: participants ?? List.from(this.participants),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'participants': participants,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      name: map['name'] as String,
      destination: map['destination'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      participants: List<String>.from(map['participants'] as List),
    );
  }

  @override
  String toString() =>
      'Trip(id: $id, name: $name, destination: $destination, '
      'start: $startDate, end: $endDate, participants: $participants)';
}
