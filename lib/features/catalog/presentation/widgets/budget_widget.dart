import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';

/// Entry type discriminator for budget calculations.
enum BudgetEntryType {
  /// Incoming funds contributing positively to the balance.
  income,

  /// Outgoing expenditures reducing the net balance.
  expense;

  /// Parses entry type from string with fallback to [BudgetEntryType.expense].
  static BudgetEntryType fromString(String? val) {
    if (val?.toLowerCase() == 'income') {
      return BudgetEntryType.income;
    }
    return BudgetEntryType.expense;
  }
}

/// Representation of an individual income or expense entry.
@immutable
class BudgetEntryItem {
  const BudgetEntryItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
  });

  factory BudgetEntryItem.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final amount = (rawAmount is num) ? rawAmount.toDouble() : 0.0;

    return BudgetEntryItem(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      description: json['description']?.toString() ?? '',
      amount: amount,
      type: BudgetEntryType.fromString(json['type']?.toString()),
    );
  }

  final String id;
  final String description;
  final double amount;
  final BudgetEntryType type;

  BudgetEntryItem copyWith({
    String? id,
    String? description,
    double? amount,
    BudgetEntryType? type,
  }) {
    return BudgetEntryItem(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type.name,
    };
  }
}

@immutable
class BudgetConfig {
  const BudgetConfig({
    required this.title,
    required this.currency,
    required this.entries,
  });

  factory BudgetConfig.fromJsonString(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return BudgetConfig.defaultConfig();
    }
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        final title = decoded['title']?.toString() ?? 'Presupuesto';
        final currency = decoded['currency']?.toString() ?? r'$';
        final rawEntries = decoded['entries'] as List<dynamic>? ?? const [];
        final entries = rawEntries
            .whereType<Map<String, dynamic>>()
            .map(BudgetEntryItem.fromJson)
            .toList();

        return BudgetConfig(
          title: title,
          currency: currency,
          entries: entries.isNotEmpty
              ? entries
              : BudgetConfig.defaultConfig().entries,
        );
      }
    } on Object catch (_) {}
    return BudgetConfig.defaultConfig();
  }

  factory BudgetConfig.defaultConfig() {
    return const BudgetConfig(
      title: 'Presupuesto',
      currency: r'$',
      entries: [
        BudgetEntryItem(
          id: '1',
          description: 'Ingreso Principal',
          amount: 2200,
          type: BudgetEntryType.income,
        ),
        BudgetEntryItem(
          id: '2',
          description: 'Alquiler y Servicios',
          amount: 750,
          type: BudgetEntryType.expense,
        ),
        BudgetEntryItem(
          id: '3',
          description: 'Supermercado y Alimentos',
          amount: 320,
          type: BudgetEntryType.expense,
        ),
      ],
    );
  }

  final String title;
  final String currency;
  final List<BudgetEntryItem> entries;

  double get totalIncome => entries
      .where((e) => e.type == BudgetEntryType.income)
      .fold(0, (sum, e) => sum + e.amount);

  double get totalExpenses => entries
      .where((e) => e.type == BudgetEntryType.expense)
      .fold(0, (sum, e) => sum + e.amount);

  double get netBalance => totalIncome - totalExpenses;

  BudgetConfig copyWith({
    String? title,
    String? currency,
    List<BudgetEntryItem>? entries,
  }) {
    return BudgetConfig(
      title: title ?? this.title,
      currency: currency ?? this.currency,
      entries: entries ?? List<BudgetEntryItem>.from(this.entries),
    );
  }

  String toJsonString() {
    return jsonEncode({
      'title': title,
      'currency': currency,
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }
}

class BudgetWidgetDefinition extends AgendaWidgetDefinition {
  const BudgetWidgetDefinition();

  @override
  String get id => 'budget_calculator';

  @override
  String get name => 'Calculadora de Presupuesto';

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
  late BudgetConfig _config;

  @override
  void initState() {
    super.initState();
    _config = BudgetConfig.fromJsonString(widget.configJson);
  }

  @override
  void didUpdateWidget(BudgetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.configJson != widget.configJson) {
      _config = BudgetConfig.fromJsonString(widget.configJson);
    }
  }

  void _addEntry() {
    if (!widget.isInteractive) return;

    final newEntry = BudgetEntryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: 'Gasto nuevo',
      amount: 0,
      type: BudgetEntryType.expense,
    );

    final updated = [..._config.entries, newEntry];
    final newConfig = _config.copyWith(entries: updated);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  void _removeEntry(int index) {
    if (!widget.isInteractive) return;

    final updated = List<BudgetEntryItem>.from(_config.entries)
      ..removeAt(index);
    final newConfig = _config.copyWith(entries: updated);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
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
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  void _updateDescription(int index, String desc) {
    if (!widget.isInteractive) return;

    final updated = List<BudgetEntryItem>.from(_config.entries);
    updated[index] = updated[index].copyWith(description: desc);
    final newConfig = _config.copyWith(entries: updated);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  void _updateAmount(int index, String rawAmount) {
    if (!widget.isInteractive) return;

    final parsed = double.tryParse(rawAmount.replaceAll(',', '.')) ?? 0.0;
    final updated = List<BudgetEntryItem>.from(_config.entries);
    updated[index] = updated[index].copyWith(amount: parsed);
    final newConfig = _config.copyWith(entries: updated);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  String _formatNumber(double val) {
    return val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2);
  }

  @override
  Widget build(BuildContext context) {
    final netBalance = _config.netBalance;
    final isPositive = netBalance >= 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
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
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _config.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryTile(
                  label: 'Ingresos',
                  value:
                      '+${_config.currency}${_formatNumber(_config.totalIncome)}',
                  color: const Color(0xFF16A34A),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: colorScheme.outline,
                ),
                _SummaryTile(
                  label: 'Gastos',
                  value:
                      '-${_config.currency}${_formatNumber(_config.totalExpenses)}',
                  color: const Color(0xFFDC2626),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: colorScheme.outline,
                ),
                _SummaryTile(
                  label: 'Balance',
                  value:
                      '${isPositive ? '+' : ''}${_config.currency}${_formatNumber(netBalance)}',
                  color: isPositive
                      ? colorScheme.primary
                      : const Color(0xFFDC2626),
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _config.entries.length,
              itemBuilder: (context, index) {
                final entry = _config.entries[index];
                final isIncome = entry.type == BudgetEntryType.income;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: widget.isInteractive
                            ? () => _toggleType(index)
                            : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isIncome
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFFE4E6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: isIncome
                                ? const Color(0xFF166534)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: widget.isInteractive
                            ? TextFormField(
                                initialValue: entry.description,
                                key: ValueKey('desc_${entry.id}'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                onFieldSubmitted: (val) =>
                                    _updateDescription(index, val),
                              )
                            : Text(
                                entry.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 75,
                        child: widget.isInteractive
                            ? TextFormField(
                                initialValue: _formatNumber(entry.amount),
                                key: ValueKey('amt_${entry.id}'),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isIncome
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixText: _config.currency,
                                  prefixStyle: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                onFieldSubmitted: (val) =>
                                    _updateAmount(index, val),
                              )
                            : Text(
                                '${isIncome ? '+' : '-'}${_config.currency}${_formatNumber(entry.amount)}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isIncome
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                      ),
                      if (widget.isInteractive)
                        InkWell(
                          onTap: () => _removeEntry(index),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (widget.isInteractive)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addEntry,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Nueva entrada',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
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
