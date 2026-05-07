import 'package:flutter/material.dart';
import '../../widgets/main_scaffold.dart';

/// Lists all itinerary items for a given trip.
/// Receives [tripId] and [tripName] via [ItineraryArgs] from the router.
/// TODO: Replace body with ItineraryProvider-driven list + add FAB.
class ItineraryScreen extends StatelessWidget {
  final String tripId;
  final String tripName;

  const ItineraryScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '$tripName — Itinerary',
      child: Center(child: Text('Itinerary for trip: $tripId')),
    );
  }
}
