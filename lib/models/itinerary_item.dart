import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'itinerary_item.g.dart';

@HiveType(typeId: 1)
class ItineraryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tripId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String activityDescription;

  /// Optional time stored as minutes-since-midnight (null = no time set).
  @HiveField(4)
  final int? timeOfDayMinutes;

  ItineraryItem({
    String? id,
    required this.tripId,
    required this.date,
    required this.activityDescription,
    this.timeOfDayMinutes,
  }) : id = id ?? const Uuid().v4();

  /// Returns a new [ItineraryItem] with the given fields replaced.
  ItineraryItem copyWith({
    String? tripId,
    DateTime? date,
    String? activityDescription,
    int? timeOfDayMinutes,
    bool clearTime = false,
  }) {
    return ItineraryItem(
      id: id,
      tripId: tripId ?? this.tripId,
      date: date ?? this.date,
      activityDescription: activityDescription ?? this.activityDescription,
      timeOfDayMinutes:
          clearTime ? null : (timeOfDayMinutes ?? this.timeOfDayMinutes),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'date': date.toIso8601String(),
      'activityDescription': activityDescription,
      'timeOfDayMinutes': timeOfDayMinutes,
    };
  }

  factory ItineraryItem.fromMap(Map<String, dynamic> map) {
    return ItineraryItem(
      id: map['id'] as String,
      tripId: map['tripId'] as String,
      date: DateTime.parse(map['date'] as String),
      activityDescription: map['activityDescription'] as String,
      timeOfDayMinutes: map['timeOfDayMinutes'] as int?,
    );
  }

  @override
  String toString() =>
      'ItineraryItem(id: $id, tripId: $tripId, date: $date, '
      'activity: $activityDescription, timeOfDayMinutes: $timeOfDayMinutes)';
}
