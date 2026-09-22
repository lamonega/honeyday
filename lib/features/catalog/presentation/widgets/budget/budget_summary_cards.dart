import 'package:flutter/material.dart';
import 'package:honeyday/core/theme/app_colors.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Displays the three summary tiles (Income, Expenses, Net Balance)
/// inside a rounded container.
class BudgetSummaryCards extends StatelessWidget {
  const BudgetSummaryCards({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    required this.currency,
    required this.formatNumber,
    super.key,
  });

  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final String currency;
  final String Function(double) formatNumber;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isPositive = netBalance >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryTile(
            label: l10n.catalogBudgetIncome,
            value: '+$currency${formatNumber(totalIncome)}',
            color: AppColors.incomeGreen,
          ),
          Container(width: 1, height: 24, color: cs.outline),
          _SummaryTile(
            label: l10n.catalogBudgetExpenses,
            value: '-$currency${formatNumber(totalExpenses)}',
            color: AppColors.expenseRed,
          ),
          Container(width: 1, height: 24, color: cs.outline),
          _SummaryTile(
            label: l10n.catalogBudgetBalance,
            value:
                '${isPositive ? '+' : ''}$currency${formatNumber(netBalance)}',
            color: isPositive ? cs.primary : AppColors.expenseRed,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
