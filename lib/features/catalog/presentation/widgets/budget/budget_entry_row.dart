import 'package:flutter/material.dart';
import 'package:honeyday/core/theme/app_colors.dart';
import 'package:honeyday/features/catalog/presentation/widgets/budget/budget_config.dart';

/// Renders a single budget entry as a [Row] with a type-toggle icon,
/// an optional description field, an amount field, and a delete button.
///
/// When [isInteractive] is false the fields are displayed as read-only text.
class BudgetEntryRow extends StatelessWidget {
  const BudgetEntryRow({
    required this.entry,
    required this.currency,
    required this.isInteractive,
    required this.onToggleType,
    required this.onUpdateDescription,
    required this.onUpdateAmount,
    required this.onRemove,
    required this.formatNumber,
    required this.displayDescription,
    super.key,
  });

  final BudgetEntryItem entry;
  final String currency;
  final bool isInteractive;
  final VoidCallback onToggleType;
  final ValueChanged<String> onUpdateDescription;
  final ValueChanged<String> onUpdateAmount;
  final VoidCallback onRemove;
  final String Function(double) formatNumber;
  final String displayDescription;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIncome = entry.type == BudgetEntryType.income;
    final entryColor = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          InkWell(
            onTap: isInteractive ? onToggleType : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isIncome
                    ? AppColors.incomeGreenLight
                    : AppColors.expenseRedLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: isIncome
                    ? AppColors.incomeGreenDark
                    : AppColors.expenseRedDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isInteractive
                ? TextFormField(
                    initialValue: displayDescription,
                    key: ValueKey('desc_${entry.id}'),
                    style: TextStyle(fontSize: 12, color: cs.onSurface),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      border: InputBorder.none,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: cs.primary),
                      ),
                    ),
                    onChanged: onUpdateDescription,
                  )
                : Text(
                    displayDescription,
                    style: TextStyle(fontSize: 12, color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 75,
            child: isInteractive
                ? TextFormField(
                    initialValue: formatNumber(entry.amount),
                    key: ValueKey('amt_${entry.id}'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: entryColor,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixText: currency,
                      prefixStyle: TextStyle(fontSize: 11, color: cs.onSurface),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      border: InputBorder.none,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: cs.primary),
                      ),
                    ),
                    onChanged: onUpdateAmount,
                  )
                : Text(
                    '${isIncome ? '+' : '-'}$currency${formatNumber(entry.amount)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: entryColor,
                    ),
                  ),
          ),
          if (isInteractive)
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
