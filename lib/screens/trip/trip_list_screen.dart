import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/trip_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/trip_card.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  bool _searchActive = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searchActive = !_searchActive);
    if (!_searchActive) {
      _searchController.clear();
      context.read<TripProvider>().clearSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TripProvider>();
    final trips = provider.filteredTrips;

    return Scaffold(
      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
        centerTitle: false,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _searchActive
              ? TextField(
                  key: const ValueKey('search_field'),
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                  cursorColor: theme.colorScheme.onPrimary,
                  decoration: InputDecoration(
                    hintText: 'Search by name or destination…',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: context.read<TripProvider>().searchTrips,
                )
              : Text(
                  key: const ValueKey('title_text'),
                  'My Trips',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        actions: [
          IconButton(
            tooltip: _searchActive ? 'Close search' : 'Search trips',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _searchActive ? Icons.close : Icons.search,
                key: ValueKey(_searchActive),
                color: theme.colorScheme.onPrimary,
              ),
            ),
            onPressed: _toggleSearch,
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ── Body ────────────────────────────────────────────────────────────
      body: trips.isEmpty
          ? EmptyState(
              icon: provider.searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.luggage_outlined,
              title: provider.searchQuery.isNotEmpty
                  ? 'No trips match "${provider.searchQuery}"'
                  : 'No trips yet',
              subtitle: provider.searchQuery.isNotEmpty
                  ? 'Try a different name or destination.'
                  : 'Tap the button below to plan your\nfirst adventure!',
              actionLabel:
                  provider.searchQuery.isNotEmpty ? null : 'New Trip',
              onAction: provider.searchQuery.isNotEmpty
                  ? null
                  : () => AppRouter.goTripCreate(context),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 100),
              itemCount: trips.length,
              itemBuilder: (_, i) => TripCard(trip: trips[i]),
            ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppRouter.goTripCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
        elevation: 4,
      ),
    );
  }
}
