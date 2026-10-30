import 'dart:convert';

import 'package:flutter/material.dart';

/// Entry type discriminator for budget calculations.
enum BudgetEntryType {
  income,
  expense;

  static BudgetEntryType fromString(String? val) {
    if (val?.toLowerCase() == 'income') {
      return BudgetEntryType.income;
    }
    return BudgetEntryType.expense;
  }
}

/// A single budget line item (income or expense).
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

/// Persistent configuration for the budget calculator widget.
///
/// Holds the title, currency symbol, and list of [BudgetEntryItem]s.
/// Serialises to / from JSON for widget config storage.
@immutable
class BudgetConfig {
  const BudgetConfig({
    required this.title,
    required this.currency,
    required this.entries,
  });

  factory BudgetConfig.fromJsonString(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return BudgetConfig.defaultConfig();
      final rawEntries = decoded['entries'];
      if (rawEntries != null && rawEntries is! List) {
        return BudgetConfig.defaultConfig();
      }
      return BudgetConfig(
        title: decoded['title']?.toString() ?? '',
        currency: decoded['currency']?.toString() ?? r'$',
        entries: rawEntries == null
            ? BudgetConfig.defaultConfig().entries
            : (rawEntries as List)
                  .whereType<Map<String, dynamic>>()
                  .map(BudgetEntryItem.fromJson)
                  .toList(),
      );
    } on Object {
      return BudgetConfig.defaultConfig();
    }
  }

  factory BudgetConfig.defaultConfig() {
    return const BudgetConfig(
      title: '',
      currency: r'$',
      entries: [
        BudgetEntryItem(
          id: '1',
          description: '',
          amount: 2200,
          type: BudgetEntryType.income,
        ),
        BudgetEntryItem(
          id: '2',
          description: '',
          amount: 750,
          type: BudgetEntryType.expense,
        ),
        BudgetEntryItem(
          id: '3',
          description: '',
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
