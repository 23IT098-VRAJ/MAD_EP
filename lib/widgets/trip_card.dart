import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trip.dart';
import '../router/app_router.dart';

class TripCard extends StatelessWidget {
  final Trip trip;

  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, yyyy');

    // Pick a stable gradient colour pair from the trip ID so every card looks
    // distinct but the same trip always has the same colour.
    final palette = _gradientPalettes[trip.id.codeUnitAt(0) % _gradientPalettes.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 3,
        shadowColor: palette[0].withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => AppRouter.goTripDetail(context, trip),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Coloured header ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: palette,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),

              // ── Details ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: trip.destination,
                      color: palette[0],
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.date_range_outlined,
                      label:
                          '${dateFmt.format(trip.startDate)}  →  ${dateFmt.format(trip.endDate)}',
                      color: palette[0],
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.group_outlined,
                      label:
                          '${trip.participants.length} participant${trip.participants.length == 1 ? '' : 's'}',
                      color: palette[0],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared row widget ─────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoRow({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Gradient palette pool ─────────────────────────────────────────────────────

const List<List<Color>> _gradientPalettes = [
  [Color(0xFF6C63FF), Color(0xFF48CAE4)],
  [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
  [Color(0xFF43AA8B), Color(0xFF90BE6D)],
  [Color(0xFFF77F00), Color(0xFFD62828)],
  [Color(0xFF3A86FF), Color(0xFF8338EC)],
  [Color(0xFF2D6A4F), Color(0xFF52B788)],
  [Color(0xFFE63946), Color(0xFFf4a261)],
];
