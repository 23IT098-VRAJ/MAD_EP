import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/trip.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/main_scaffold.dart';

class TripCreateScreen extends StatefulWidget {
  const TripCreateScreen({super.key});

  @override
  State<TripCreateScreen> createState() => _TripCreateScreenState();
}

class _TripCreateScreenState extends State<TripCreateScreen> {
  // ── Form state ────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _participantCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _participants = [];
  bool _isSubmitting = false;
  bool _participantError = false; // shown after first submit attempt

  final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _destCtrl.dispose();
    _participantCtrl.dispose();
    super.dispose();
  }

  // ── Date pickers ──────────────────────────────────────────────────────────

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      if (_endDate != null && !_endDate!.isAfter(picked)) _endDate = null;
    });
  }

  Future<void> _pickEnd() async {
    if (_startDate == null) {
      _showSnack('Select a start date first.');
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  // ── Participants ──────────────────────────────────────────────────────────

  void _addParticipant() {
    final name = _participantCtrl.text.trim();
    if (name.isEmpty) return;
    if (_participants.map((p) => p.toLowerCase()).contains(name.toLowerCase())) {
      _showSnack('"$name" is already in the list.');
      return;
    }
    setState(() {
      _participants.add(name);
      _participantCtrl.clear();
      _participantError = false;
    });
  }

  void _removeParticipant(int index) =>
      setState(() => _participants.removeAt(index));

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Force show participant error on first attempt
    setState(() => _participantError = _participants.isEmpty);

    final formValid = _formKey.currentState!.validate();
    final datesValid = _startDate != null && _endDate != null;
    final participantsValid = _participants.isNotEmpty;

    if (!formValid || !datesValid || !participantsValid) {
      if (!datesValid) {
        _showSnack('Please select both start and end dates.');
      } else if (!formValid || !participantsValid) {
        _showSnack('Please fix the errors in the form.');
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await context.read<TripProvider>().addTrip(Trip(
            name: _nameCtrl.text.trim(),
            destination: _destCtrl.text.trim(),
            startDate: _startDate!,
            endDate: _endDate!,
            participants: _participants,
          ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save trip: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MainScaffold(
      title: 'New Trip',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            // ── Trip Details ───────────────────────────────────────────────
            _SectionHeader(label: 'Trip Details', icon: Icons.card_travel),
            const SizedBox(height: 14),

            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Trip Name *',
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Trip name is required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _destCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Destination *',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Destination is required' : null,
            ),

            const SizedBox(height: 28),

            // ── Dates ──────────────────────────────────────────────────────
            _SectionHeader(label: 'Travel Dates', icon: Icons.date_range_outlined),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: 'Start Date',
                    icon: Icons.flight_takeoff_outlined,
                    date: _startDate,
                    formatter: _dateFmt,
                    onTap: _pickStart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTile(
                    label: 'End Date',
                    icon: Icons.flight_land_outlined,
                    date: _endDate,
                    formatter: _dateFmt,
                    onTap: _pickEnd,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Participants ───────────────────────────────────────────────
            _SectionHeader(
                label: 'Participants', icon: Icons.group_add_outlined),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _participantCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                      errorText: _participantError
                          ? 'Add at least one participant'
                          : null,
                    ),
                    onFieldSubmitted: (_) => _addParticipant(),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: FilledButton(
                    onPressed: _addParticipant,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),

            if (_participants.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_participants.length, (i) {
                  final name = _participants[i];
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    label: Text(name),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeParticipant(i),
                  );
                }),
              ),
            ],

            const SizedBox(height: 36),

            // ── Submit ─────────────────────────────────────────────────────
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 8),
                          Text('Create Trip',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? date;
  final DateFormat formatter;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.icon,
    required this.date,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDate = date != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasDate
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: hasDate ? 1.8 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: hasDate
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 15,
                    color: hasDate
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: hasDate
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasDate ? formatter.format(date!) : 'Tap to select',
              style: hasDate
                  ? theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)
                  : theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
