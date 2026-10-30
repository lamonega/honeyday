import 'package:flutter/material.dart';
import 'package:honeyday/features/agendas/presentation/controllers/save_session.dart';
import 'package:honeyday/features/agendas/presentation/widgets/save_session_scope.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/presentation/widgets/budget/budget_config.dart';
import 'package:honeyday/features/catalog/presentation/widgets/budget/budget_entry_form.dart';
import 'package:honeyday/features/catalog/presentation/widgets/budget/budget_entry_row.dart';
import 'package:honeyday/features/catalog/presentation/widgets/budget/budget_summary_cards.dart';
import 'package:honeyday/features/catalog/presentation/widgets/catalog_widget_mixin.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

export 'package:honeyday/features/catalog/presentation/widgets/budget/budget_config.dart';

class BudgetWidgetDefinition extends AgendaWidgetDefinition {
  const BudgetWidgetDefinition();

  @override
  String get id => 'budget_calculator';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogBudgetName;

  @override
  IconData get icon => Icons.account_balance_wallet_rounded;

  @override
  Size get defaultSize => const Size(340, 280);

  @override
  String get initialConfigJson => BudgetConfig.defaultConfig().toJsonString();

  @override
  Widget build(
    BuildContext context, {
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  }) {
    return BudgetWidget(
      elementId: elementId,
      configJson: configJson,
      isInteractive: isInteractive,
      onConfigChanged: onConfigChanged,
    );
  }
}

class BudgetWidget extends StatefulWidget {
  const BudgetWidget({
    required this.elementId,
    required this.configJson,
    required this.isInteractive,
    required this.onConfigChanged,
    super.key,
  });

  final String elementId;
  final String configJson;
  final bool isInteractive;
  final ValueChanged<String> onConfigChanged;

  @override
  State<BudgetWidget> createState() => _BudgetWidgetState();
}

class _BudgetWidgetState extends State<BudgetWidget> {
  late CatalogConfigHelper<BudgetConfig> _configHelper;
  SaveSession? _saveSession;

  BudgetConfig get _config => _configHelper.config;

  @override
  void initState() {
    super.initState();
    _configHelper = CatalogConfigHelper<BudgetConfig>(
      parseConfig: BudgetConfig.fromJsonString,
      configToJson: (c) => c.toJsonString(),
      initialJson: widget.configJson,
    )..onConfigChanged = widget.onConfigChanged;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SaveSessionScope.maybeOf(context);
    if (identical(session, _saveSession)) return;
    _saveSession?.unregisterEditor(_configHelper.flush);
    _saveSession = session;
    _saveSession?.registerEditor(_configHelper.flush);
  }

  @override
  void didUpdateWidget(BudgetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configHelper.onConfigChanged = widget.onConfigChanged;
    if (oldWidget.configJson != widget.configJson) {
      _configHelper.updateFromJson(widget.configJson);
    }
  }

  @override
  void dispose() {
    _saveSession?.unregisterEditor(_configHelper.flush);
    _configHelper.dispose();
    super.dispose();
  }

  void _addEntry() {
    if (!widget.isInteractive) return;
    final l10n = AppLocalizations.of(context);
    final newEntry = BudgetEntryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: l10n.catalogBudgetNewExpense,
      amount: 0,
      type: BudgetEntryType.expense,
    );
    final updated = [..._config.entries, newEntry];
    final newConfig = _config.copyWith(entries: updated);
    setState(() => _configHelper.updateConfig(newConfig));
  }

  void _removeEntry(int index) {
    if (!widget.isInteractive) return;
    final updated = List<BudgetEntryItem>.from(_config.entries)
      ..removeAt(index);
    final newConfig = _config.copyWith(entries: updated);
    setState(() => _configHelper.updateConfig(newConfig));
  }

  void _toggleType(int index) {
    if (!widget.isInteractive) return;
    final item = _config.entries[index];
    final nextType = item.type == BudgetEntryType.income
        ? BudgetEntryType.expense
        : BudgetEntryType.income;
    final updated = List<BudgetEntryItem>.from(_config.entries);
    updated[index] = item.copyWith(type: nextType);
    final newConfig = _config.copyWith(entries: updated);
    setState(() => _configHelper.updateConfig(newConfig));
  }

  void _updateDescription(int index, String desc) {
    if (!widget.isInteractive) return;
    final updated = List<BudgetEntryItem>.from(_config.entries);
    updated[index] = updated[index].copyWith(description: desc);
    final newConfig = _config.copyWith(entries: updated);
    setState(() => _configHelper.updateConfig(newConfig));
  }

  void _updateAmount(int index, String rawAmount) {
    if (!widget.isInteractive) return;
    if (index < 0 || index >= _config.entries.length) return;
    final normalized = rawAmount.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || !parsed.isFinite || parsed < 0) return;

    final updated = List<BudgetEntryItem>.from(_config.entries);
    updated[index] = updated[index].copyWith(amount: parsed);
    setState(() {
      _configHelper.updateConfig(_config.copyWith(entries: updated));
    });
  }

  String _formatNumber(double val) {
    return val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2);
  }

  String _localizedDescription(BudgetEntryItem entry, AppLocalizations l10n) {
    if (entry.description.isNotEmpty) return entry.description;
    return switch (entry.id) {
      '1' => l10n.catalogBudgetDefaultIncome,
      '2' => l10n.catalogBudgetDefaultExpense1,
      '3' => l10n.catalogBudgetDefaultExpense2,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final netBalance = _config.netBalance;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isDefaultTitle =
        _config.title.isEmpty || _config.title == l10n.catalogBudgetTitle;
    final displayTitle = isDefaultTitle
        ? l10n.catalogBudgetTitle
        : _config.title;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: cs.primary,
              ),
              const SizedBox(width: 6),
              Text(
                displayTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BudgetSummaryCards(
            totalIncome: _config.totalIncome,
            totalExpenses: _config.totalExpenses,
            netBalance: netBalance,
            currency: _config.currency,
            formatNumber: _formatNumber,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _config.entries.length,
              itemBuilder: (context, index) {
                final entry = _config.entries[index];
                final displayDesc = _localizedDescription(entry, l10n);

                return BudgetEntryRow(
                  entry: entry,
                  currency: _config.currency,
                  isInteractive: widget.isInteractive,
                  onToggleType: () => _toggleType(index),
                  onUpdateDescription: (val) => _updateDescription(index, val),
                  onUpdateAmount: (val) => _updateAmount(index, val),
                  onRemove: () => _removeEntry(index),
                  formatNumber: _formatNumber,
                  displayDescription: displayDesc,
                );
              },
            ),
          ),
          if (widget.isInteractive) BudgetEntryForm(onAdd: _addEntry),
        ],
      ),
    );
  }
}
