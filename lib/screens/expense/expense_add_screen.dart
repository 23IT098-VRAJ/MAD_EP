import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/main_scaffold.dart';

class ExpenseAddScreen extends StatefulWidget {
  final String tripId;
  final List<String> participants;

  const ExpenseAddScreen({
    super.key,
    required this.tripId,
    required this.participants,
  });

  @override
  State<ExpenseAddScreen> createState() => _ExpenseAddScreenState();
}

class _ExpenseAddScreenState extends State<ExpenseAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _paidBy;
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;

  final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    if (widget.participants.isNotEmpty) _paidBy = widget.participants.first;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fix the errors in the form')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await context.read<ExpenseProvider>().addExpense(
            Expense(
              tripId: widget.tripId,
              amount: double.parse(_amountCtrl.text.trim()),
              paidBy: _paidBy!,
              description: _descCtrl.text.trim(),
              date: _date,
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save expense: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MainScaffold(
      title: 'Add Expense',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            // ── Amount ──────────────────────────────────────────────────
            _SectionHeader(label: 'Amount', icon: Icons.currency_rupee),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount (₹) *',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount is required';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid positive amount';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Description ─────────────────────────────────────────────
            _SectionHeader(
                label: 'Description', icon: Icons.receipt_outlined),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description *',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),

            const SizedBox(height: 24),

            // ── Paid By ─────────────────────────────────────────────────
            _SectionHeader(label: 'Paid By', icon: Icons.person_outline),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _paidBy,
              decoration: const InputDecoration(
                labelText: 'Paid By *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              items: widget.participants
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _paidBy = v),
              validator: (v) => v == null ? 'Select who paid' : null,
            ),

            const SizedBox(height: 24),

            // ── Date ────────────────────────────────────────────────────
            _SectionHeader(
                label: 'Date', icon: Icons.calendar_today_outlined),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: theme.colorScheme.primary, width: 1.6),
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(_dateFmt.format(_date),
                        style: theme.textTheme.bodyLarge),
                    const Spacer(),
                    Icon(Icons.edit_calendar_outlined,
                        color: theme.colorScheme.primary, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // ── Submit ──────────────────────────────────────────────────
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 8),
                          Text('Add Expense',
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
