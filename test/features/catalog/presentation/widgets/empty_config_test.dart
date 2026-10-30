import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/catalog/presentation/widgets/budget/budget_config.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar/calendar_config.dart';

void main() {
  test('empty budget entries survive serialization', () {
    const config = BudgetConfig(title: '', currency: r'$', entries: []);
    expect(BudgetConfig.fromJsonString(config.toJsonString()).entries, isEmpty);
  });

  test('empty habit lists survive serialization', () {
    const config = CalendarGridConfig(title: '', habits: []);
    expect(
      CalendarGridConfig.fromJsonString(config.toJsonString()).habits,
      isEmpty,
    );
  });

  for (final raw in ['', '{}', '{"entries":null,"habits":null}', 'invalid']) {
    test('missing or invalid lists retain defaults: $raw', () {
      expect(BudgetConfig.fromJsonString(raw).entries, hasLength(3));
      expect(CalendarGridConfig.fromJsonString(raw).habits, hasLength(3));
    });
  }
}
