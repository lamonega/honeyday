import 'package:flutter/material.dart';
import 'package:honeyday/core/theme/app_colors.dart';
import 'package:honeyday/features/catalog/presentation/widgets/budget/budget_config.dart';

/// Renders a single budget entry as a [Row] with a type-toggle icon,
/// an optional description field, an amount field, and a delete button.
///
/// When [isInteractive] is false the fields are displayed as read-only text.
class BudgetEntryRow extends StatefulWidget {
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
  State<BudgetEntryRow> createState() => _BudgetEntryRowState();
}

class _BudgetEntryRowState extends State<BudgetEntryRow> {
  late final TextEditingController _descController;
  late final TextEditingController _amountController;
  late final FocusNode _amountFocusNode;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.entry.description);
    _amountController = TextEditingController(
      text: widget.formatNumber(widget.entry.amount),
    );
    _amountFocusNode = FocusNode()..addListener(_onAmountFocusChanged);
  }

  void _onAmountFocusChanged() {
    if (!_amountFocusNode.hasFocus) {
      _resetAmountIfInvalid();
    }
  }

  void _resetAmountIfInvalid() {
    final normalized = _amountController.text.trim().replaceAll(',', '.');
    final parsed = normalized.isEmpty ? 0.0 : double.tryParse(normalized);
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      final formatted = widget.formatNumber(widget.entry.amount);
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  void didUpdateWidget(BudgetEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry.description != _descController.text) {
      _descController.value = TextEditingValue(
        text: widget.entry.description,
        selection: TextSelection.collapsed(
          offset: widget.entry.description.length,
        ),
      );
    }
    if (oldWidget.isInteractive && !widget.isInteractive) {
      _resetAmountIfInvalid();
    }
    if (oldWidget.entry.amount != widget.entry.amount ||
        oldWidget.entry.id != widget.entry.id) {
      final currentParsed = double.tryParse(
        _amountController.text.trim().replaceAll(',', '.'),
      );
      final isEmptyZero =
          _amountController.text.trim().isEmpty && widget.entry.amount == 0;
      if (oldWidget.entry.id != widget.entry.id ||
          (currentParsed != widget.entry.amount && !isEmptyZero)) {
        final formatted = widget.formatNumber(widget.entry.amount);
        _amountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountFocusNode
      ..removeListener(_onAmountFocusChanged)
      ..dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIncome = widget.entry.type == BudgetEntryType.income;
    final entryColor = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          InkWell(
            onTap: widget.isInteractive ? widget.onToggleType : null,
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
            child: widget.isInteractive
                ? TextFormField(
                    controller: _descController,
                    key: ValueKey('desc_${widget.entry.id}'),
                    style: TextStyle(fontSize: 12, color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: widget.displayDescription,
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
                    onChanged: widget.onUpdateDescription,
                  )
                : Text(
                    widget.displayDescription,
                    style: TextStyle(fontSize: 12, color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 75,
            child: widget.isInteractive
                ? TextFormField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    key: ValueKey('amt_${widget.entry.id}'),
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
                      prefixText: widget.currency,
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
                    onChanged: widget.onUpdateAmount,
                  )
                : Text(
                    '${isIncome ? '+' : '-'}${widget.currency}${widget.formatNumber(widget.entry.amount)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: entryColor,
                    ),
                  ),
          ),
          if (widget.isInteractive)
            InkWell(
              onTap: widget.onRemove,
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
