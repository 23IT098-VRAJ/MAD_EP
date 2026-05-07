import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/trip_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/trip_card.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill if the provider already has an active query.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = context.read<TripProvider>().searchQuery;
      if (q.isNotEmpty) {
        _searchCtrl.text = q;
        _searchCtrl.selection =
            TextSelection.fromPosition(TextPosition(offset: q.length));
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clear() {
    _searchCtrl.clear();
    context.read<TripProvider>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TripProvider>();
    final trips = provider.filteredTrips;
    final hasQuery = provider.searchQuery.isNotEmpty;

    return Scaffold(
      // ── AppBar with embedded search ──────────────────────────────────────
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: TextStyle(color: theme.colorScheme.onPrimary),
          cursorColor: theme.colorScheme.onPrimary,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search by name or destination…',
            hintStyle: TextStyle(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.55)),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: context.read<TripProvider>().searchTrips,
        ),
        actions: [
          if (hasQuery)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear',
              onPressed: _clear,
            )
          else
            const SizedBox(width: 48),
        ],
      ),

      body: Column(
        children: [
          // ── Results count banner ───────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: hasQuery
                ? Container(
                    width: double.infinity,
                    color: theme.colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      trips.isEmpty
                          ? 'No results for "${provider.searchQuery}"'
                          : '${trips.length} result${trips.length == 1 ? '' : 's'}'
                              ' for "${provider.searchQuery}"',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: !hasQuery
                ? _IdleState()
                : trips.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No trips found',
                        subtitle:
                            'Try a different name or destination.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 12, bottom: 24),
                        itemCount: trips.length,
                        itemBuilder: (_, i) => TripCard(trip: trips[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Idle state (nothing typed yet) ───────────────────────────────────────────

class _IdleState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.travel_explore,
              size: 72,
              color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 18),
          Text(
            'Search your trips',
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Filter by trip name or destination.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
