import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../models/itinerary_item.dart';
import '../../models/trip.dart';
import '../../providers/expense_provider.dart';
import '../../providers/itinerary_provider.dart';
import '../../providers/trip_provider.dart';
import '../../router/app_router.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItineraryProvider>().loadItemsForTrip(widget.trip.id);
      context.read<ExpenseProvider>().loadExpensesForTrip(widget.trip.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = widget.trip;
    final expProvider = context.watch<ExpenseProvider>();
    final balances = expProvider.calculateBalances(trip.id, trip.participants);
    final settlementCount = expProvider.calculateSettlements(balances).length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 2,
          title: Text(
            trip.name,
            style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Trip',
              onPressed: () => _confirmDeleteTrip(context, trip),
            ),
          ],
          bottom: TabBar(
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor:
                theme.colorScheme.onPrimary.withValues(alpha: 0.6),
            indicatorColor: theme.colorScheme.onPrimary,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.map_outlined), text: 'Itinerary'),
              Tab(
                  icon: Icon(Icons.receipt_long_outlined),
                  text: 'Expenses'),
            ],
          ),
        ),
        body: Column(
          children: [
            _TripHeader(trip: trip),
            _DashboardRow(
              total: expProvider.totalAll,
              participantCount: trip.participants.length,
              settlementCount: settlementCount,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ItineraryTab(trip: trip),
                  _ExpensesTab(trip: trip),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTrip(BuildContext context, Trip trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip?'),
        content: Text('Are you sure you want to delete "${trip.name}"? This will also delete all associated activities and expenses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<ItineraryProvider>().deleteAllForTrip(trip.id);
        await context.read<ExpenseProvider>().deleteAllForTrip(trip.id);
        await context.read<TripProvider>().deleteTrip(trip.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trip deleted successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete trip: $e')));
        }
      }
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _TripHeader extends StatelessWidget {
  final Trip trip;
  const _TripHeader({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d, yyyy');
    return Container(
      width: double.infinity,
      color: theme.colorScheme.primaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.location_on, size: 15, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(trip.destination,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.date_range_outlined,
                size: 15, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text('${fmt.format(trip.startDate)} → ${fmt.format(trip.endDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer)),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: trip.participants
                .map((p) => Chip(
                      label:
                          Text(p, style: const TextStyle(fontSize: 11)),
                      avatar: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(p[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Row ─────────────────────────────────────────────────────────────

class _DashboardRow extends StatelessWidget {
  final double total;
  final int participantCount;
  final int settlementCount;
  const _DashboardRow(
      {required this.total,
      required this.participantCount,
      required this.settlementCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _Stat(
              icon: Icons.account_balance_wallet_outlined,
              value: fmt.format(total),
              label: 'Spent'),
          _VSep(),
          _Stat(
              icon: Icons.group_outlined,
              value: '$participantCount',
              label: 'Travellers'),
          _VSep(),
          _Stat(
              icon: Icons.swap_horiz_rounded,
              value: '$settlementCount',
              label: 'Pending'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _VSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 36,
      child: VerticalDivider(
          color: Theme.of(context).colorScheme.outlineVariant,
          thickness: 1,
          width: 1));
}

// ── Itinerary Tab ─────────────────────────────────────────────────────────────

class _ItineraryTab extends StatelessWidget {
  final Trip trip;
  const _ItineraryTab({required this.trip});

  Map<DateTime, List<ItineraryItem>> _grouped(List<ItineraryItem> items) {
    final m = <DateTime, List<ItineraryItem>>{};
    for (final i in items) {
      final k = DateTime(i.date.year, i.date.month, i.date.day);
      m.putIfAbsent(k, () => []).add(i);
    }
    final sorted = Map.fromEntries(
        m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ItineraryProvider>().items;
    final grouped = _grouped(items);
    final dayFmt = DateFormat('EEEE, MMM d');
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_itinerary',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => _AddItinerarySheet(tripId: trip.id),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.event_note_outlined,
                  size: 64,
                  color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Text('No activities yet',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Tap + Add Activity to plan your days',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 80),
            ]))
          : ListView.builder(
              padding:
                  const EdgeInsets.only(bottom: 100, top: 8),
              itemCount: grouped.length,
              itemBuilder: (_, i) {
                final date = grouped.keys.elementAt(i);
                final dayItems = grouped[date]!;
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(dayFmt.format(date),
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(
                                color: theme.colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ),
                      ...dayItems.map(
                          (item) => _ItineraryTile(item: item)),
                    ]);
              }),
    );
  }
}

class _ItineraryTile extends StatelessWidget {
  final ItineraryItem item;
  const _ItineraryTile({required this.item});

  String _fmtTime(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    final p = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${dh.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $p';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time =
        item.timeOfDayMinutes != null ? _fmtTime(item.timeOfDayMinutes!) : null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: time != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(time.split(' ')[0],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme
                                .colorScheme.onSecondaryContainer)),
                    Text(time.split(' ')[1],
                        style: TextStyle(
                            fontSize: 9,
                            color: theme
                                .colorScheme.onSecondaryContainer)),
                  ],
                )
              : Icon(Icons.circle_outlined,
                  size: 20,
                  color: theme.colorScheme.onSecondaryContainer),
        ),
        title: Text(item.activityDescription,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline,
              size: 20, color: theme.colorScheme.error),
          onPressed: () => _confirmDeleteItem(context, item),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteItem(BuildContext context, ItineraryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Activity?'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await context.read<ItineraryProvider>().deleteItem(item.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete activity: $e')));
        }
      }
    }
  }
}

// ── Add Itinerary Bottom Sheet ────────────────────────────────────────────────

class _AddItinerarySheet extends StatefulWidget {
  final String tripId;
  const _AddItinerarySheet({required this.tripId});

  @override
  State<_AddItinerarySheet> createState() => _AddItinerarySheetState();
}

class _AddItinerarySheetState extends State<_AddItinerarySheet> {
  final _actCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  int? _timeMinutes;
  bool _includeTime = false;
  bool _saving = false;
  final _dateFmt = DateFormat('EEE, MMM d, yyyy');

  @override
  void dispose() {
    _actCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (p != null) setState(() => _date = p);
  }

  Future<void> _pickTime() async {
    final init = _timeMinutes != null
        ? TimeOfDay(hour: _timeMinutes! ~/ 60, minute: _timeMinutes! % 60)
        : TimeOfDay.now();
    final p = await showTimePicker(context: context, initialTime: init);
    if (p != null) setState(() => _timeMinutes = p.hour * 60 + p.minute);
  }

  String _fmtMin(int? m) {
    if (m == null) return 'Tap to set time';
    final h = m ~/ 60;
    final min = m % 60;
    final p = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${dh.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $p';
  }

  Future<void> _save() async {
    if (_actCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter an activity description')));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<ItineraryProvider>().addItem(ItineraryItem(
            tripId: widget.tripId,
            date: _date,
            activityDescription: _actCtrl.text.trim(),
            timeOfDayMinutes: _includeTime ? _timeMinutes : null,
          ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save activity: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Add Activity',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),

            // Date tile
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: theme.colorScheme.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.2),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Text(_dateFmt.format(_date),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Icon(Icons.edit_calendar_outlined,
                      color: theme.colorScheme.primary, size: 16),
                ]),
              ),
            ),

            const SizedBox(height: 14),

            // Activity field
            TextField(
              controller: _actCtrl,
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Activity Description *',
                prefixIcon: Icon(Icons.edit_note),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // Time toggle
            Row(children: [
              Switch(
                  value: _includeTime,
                  onChanged: (v) => setState(() {
                        _includeTime = v;
                        if (!v) _timeMinutes = null;
                      })),
              const SizedBox(width: 6),
              const Text('Include time'),
            ]),

            if (_includeTime) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: _timeMinutes != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.schedule_outlined,
                        color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(_fmtMin(_timeMinutes),
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: _timeMinutes != null
                                ? null
                                : theme.colorScheme.outline)),
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('Save Activity',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expenses Tab ──────────────────────────────────────────────────────────────

class _ExpensesTab extends StatelessWidget {
  final Trip trip;
  const _ExpensesTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = context.watch<ExpenseProvider>().expenses;
    final currFmt = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFmt = DateFormat('MMM d, yyyy');

    return Column(
      children: [
        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => AppRouter.goExpenseAdd(
                    context, trip.id, trip.participants),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Expense'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => AppRouter.goExpenseSummary(
                    context, trip.id, trip.participants),
                icon: const Icon(Icons.bar_chart_outlined, size: 18),
                label: const Text('Summary'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ]),
        ),

        // List
        Expanded(
          child: expenses.isEmpty
              ? Center(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_outlined,
                            size: 64,
                            color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text('No expenses yet',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Tap Add Expense to record one',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                      ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: expenses.length,
                  itemBuilder: (_, i) {
                    final e = expenses[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.secondaryContainer,
                          child: Text(e.description[0].toUpperCase(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme
                                      .colorScheme.onSecondaryContainer)),
                        ),
                        title: Text(e.description,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            'Paid by ${e.paidBy} · ${dateFmt.format(e.date)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(currFmt.format(e.amount),
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary)),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 20, color: theme.colorScheme.error),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _confirmDeleteExpense(context, e),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteExpense(BuildContext context, Expense e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await context.read<ExpenseProvider>().deleteExpense(e.id);
      } catch (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete expense: $err')));
        }
      }
    }
  }
}
