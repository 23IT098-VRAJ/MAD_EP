import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/expense_provider.dart';
import '../../widgets/main_scaffold.dart';

class ExpenseSummaryScreen extends StatefulWidget {
  final String tripId;
  final List<String> participants;

  const ExpenseSummaryScreen({
    super.key,
    required this.tripId,
    required this.participants,
  });

  @override
  State<ExpenseSummaryScreen> createState() => _ExpenseSummaryScreenState();
}

class _ExpenseSummaryScreenState extends State<ExpenseSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpensesForTrip(widget.tripId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ExpenseProvider>();
    final expenses = provider.expenses;
    final currFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFmt = DateFormat('MMM d, yyyy');

    final balances =
        provider.calculateBalances(widget.tripId, widget.participants);
    final settlements = provider.calculateSettlements(balances);

    return MainScaffold(
      title: 'Expense Summary',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // ── Total Card ───────────────────────────────────────────────────
          Card(
            elevation: 6,
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL EXPENSES',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70, letterSpacing: 1.4)),
                  const SizedBox(height: 8),
                  Text(
                    currFmt.format(provider.totalAll),
                    style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${expenses.length} expense${expenses.length == 1 ? '' : 's'}'
                    ' · ${widget.participants.length} participant${widget.participants.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── All Expenses ─────────────────────────────────────────────────
          _SectionHeader(
              label: 'All Expenses', icon: Icons.receipt_long_outlined),
          const SizedBox(height: 12),

          if (expenses.isEmpty)
            _EmptyHint('No expenses recorded yet.')
          else
            ...expenses.map(
              (e) => _ExpenseTile(
                description: e.description,
                amount: currFmt.format(e.amount),
                paidBy: e.paidBy,
                date: dateFmt.format(e.date),
              ),
            ),

          const SizedBox(height: 28),

          // ── Balances ─────────────────────────────────────────────────────
          _SectionHeader(
              label: 'Balances',
              icon: Icons.account_balance_wallet_outlined),
          const SizedBox(height: 12),

          if (balances.isEmpty)
            _EmptyHint('Add expenses to see balances.')
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: balances.entries.map((entry) {
                final isPositive = entry.value >= 0;
                final color = isPositive
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFFB71C1C);
                final bgColor = isPositive
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE);
                final borderColor = isPositive
                    ? const Color(0xFF66BB6A)
                    : const Color(0xFFEF9A9A);

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor:
                                color.withValues(alpha: 0.15),
                            child: Text(
                              entry.key[0].toUpperCase(),
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(entry.key,
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 13,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPositive
                                ? 'gets back ${currFmt.format(entry.value)}'
                                : 'owes ${currFmt.format(entry.value.abs())}',
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 28),

          // ── Settlements ──────────────────────────────────────────────────
          _SectionHeader(
              label: 'Settlements', icon: Icons.swap_horiz_rounded),
          const SizedBox(height: 12),

          if (settlements.isEmpty)
            _EmptyHint(expenses.isEmpty
                ? 'Add expenses to compute settlements.'
                : '🎉 All expenses are already settled!')
          else
            ...settlements.map(
              (s) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            theme.colorScheme.errorContainer,
                        child: Text(s.from[0].toUpperCase(),
                            style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                  text: s.from,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const TextSpan(text: ' pays '),
                              TextSpan(
                                  text: s.to,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currFmt.format(s.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
        Text(label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            )),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final String description;
  final String amount;
  final String paidBy;
  final String date;

  const _ExpenseTile({
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(description[0].toUpperCase(),
                  style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Paid by $paidBy · $date',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(amount,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}
