import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:honeyday/app/theme.dart';
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
///
/// What: Stores entry ID, user description, amount in primary currency, and type.
/// Why: Provides an immutable model for live financial arithmetic on the canvas page.
@immutable
class BudgetEntryItem {
  /// Constructs a [BudgetEntryItem].
  const BudgetEntryItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
  });

  /// Decodes entry from a JSON map.
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

  /// Unique entry identifier.
  final String id;

  /// Text label explaining the transaction (e.g. 'Salario', 'Comestibles').
  final String description;

  /// Monetary value of the item.
  final double amount;

  /// Discriminator indicating income or expense.
  final BudgetEntryType type;

  /// Creates a copy with optionally updated fields.
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

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type.name,
    };
  }
}

/// Parsed configuration for the [BudgetWidget].
///
/// What: Stores budget title, currency symbol, and the list of entries.
/// Why: Provides aggregate calculation methods for total income, total expenses, and net balance.
@immutable
class BudgetConfig {
  /// Constructs a [BudgetConfig].
  const BudgetConfig({
    required this.title,
    required this.currency,
    required this.entries,
  });

  /// Parses JSON string into a [BudgetConfig] with graceful fallback.
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
    } on Object catch (_) {
      // Fallback on JSON parse failure
    }
    return BudgetConfig.defaultConfig();
  }

  /// Default configuration for newly added budget widgets.
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

  /// Header title of the budget widget.
  final String title;

  /// Currency symbol prefix (e.g. '$', '€', '£').
  final String currency;

  /// Collection of budget items.
  final List<BudgetEntryItem> entries;

  /// Sum of all entries marked as [BudgetEntryType.income].
  double get totalIncome => entries
      .where((e) => e.type == BudgetEntryType.income)
      .fold(0, (sum, e) => sum + e.amount);

  /// Sum of all entries marked as [BudgetEntryType.expense].
  double get totalExpenses => entries
      .where((e) => e.type == BudgetEntryType.expense)
      .fold(0, (sum, e) => sum + e.amount);

  /// Net balance calculated as `totalIncome - totalExpenses`.
  double get netBalance => totalIncome - totalExpenses;

  /// Creates a copy with optionally updated fields.
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

  /// Serializes to JSON string.
  String toJsonString() {
    return jsonEncode({
      'title': title,
      'currency': currency,
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }
}

/// Catalog definition for [BudgetWidget].
///
/// What: Implements [AgendaWidgetDefinition] for the budget calculator.
/// Why: Enables registration in the catalog registry for canvas element insertion.
class BudgetWidgetDefinition extends AgendaWidgetDefinition {
  /// Const constructor for definition registration.
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

/// Presentation widget providing a clean, non-Excel Material 3 budget calculator.
///
/// What: Displays live summary metrics (Total Income, Total Expenses, Net Balance)
/// and a flexible list of entries with inline editing and deletion when interactive.
/// Why: Delivers aesthetic personal finance tracking that matches Honeyday's physical agenda feel.
class BudgetWidget extends StatefulWidget {
  /// Constructs a [BudgetWidget].
  const BudgetWidget({
    required this.elementId,
    required this.configJson,
    required this.isInteractive,
    required this.onConfigChanged,
    super.key,
  });

  /// Canvas element UUID.
  final String elementId;

  /// Serialized budget JSON configuration.
  final String configJson;

  /// Interactive state flag.
  final bool isInteractive;

  /// Callback to persist updated JSON configuration.
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HoneydayTheme.paperBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Title
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: HoneydayTheme.honeyAmber,
              ),
              const SizedBox(width: 6),
              Text(
                _config.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HoneydayTheme.inkSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Summary Metric Cards Banner: Ingresos | Gastos | Balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: HoneydayTheme.paperLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HoneydayTheme.paperBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryTile(
                  label: 'Ingresos',
                  value:
                      '+${_config.currency}${_formatNumber(_config.totalIncome)}',
                  color: const Color(0xFF15803D), // Emerald green
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: HoneydayTheme.paperBorder,
                ),
                _SummaryTile(
                  label: 'Gastos',
                  value:
                      '-${_config.currency}${_formatNumber(_config.totalExpenses)}',
                  color: const Color(0xFFB91C1C), // Deep rose/red
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: HoneydayTheme.paperBorder,
                ),
                _SummaryTile(
                  label: 'Balance',
                  value:
                      '${isPositive ? '+' : ''}${_config.currency}${_formatNumber(netBalance)}',
                  color: isPositive
                      ? HoneydayTheme.honeyAmber
                      : const Color(0xFFB91C1C),
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Entries List
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
                      // Type Toggle Icon (+/-)
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

                      // Description
                      Expanded(
                        child: widget.isInteractive
                            ? TextFormField(
                                initialValue: entry.description,
                                key: ValueKey('desc_${entry.id}'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: HoneydayTheme.inkSlate,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: HoneydayTheme.honeyAmber,
                                    ),
                                  ),
                                ),
                                onFieldSubmitted: (val) =>
                                    _updateDescription(index, val),
                              )
                            : Text(
                                entry.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: HoneydayTheme.inkSlate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      const SizedBox(width: 8),

                      // Amount
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
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C),
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixText: _config.currency,
                                  prefixStyle: const TextStyle(
                                    fontSize: 11,
                                    color: HoneydayTheme.inkSlate,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: HoneydayTheme.honeyAmber,
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
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                      ),

                      // Delete action
                      if (widget.isInteractive)
                        InkWell(
                          onTap: () => _removeEntry(index),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Add Entry Action Button
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
                    foregroundColor: HoneydayTheme.honeyAmber,
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

/// Helper tile rendering a single summary statistic inside the banner.
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: HoneydayTheme.inkSlate.withValues(alpha: 0.6),
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
