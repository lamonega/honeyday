import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/data/repositories/reading_position_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;
  late ReadingPositionStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    store = ReadingPositionStore(preferences);
  });

  test('new agendas have no saved page', () {
    expect(store.lastPage('agenda'), isNull);
  });

  test('page identities persist across store instances', () async {
    await store.remember('agenda', 'page-id');
    final reopened = ReadingPositionStore(preferences);
    expect(reopened.lastPage('agenda'), 'page-id');
  });

  test('positions are independent for each agenda', () async {
    await store.remember('first', 'page-a');
    await store.remember('second', 'page-b');
    expect(store.lastPage('first'), 'page-a');
    expect(store.lastPage('second'), 'page-b');
  });

  test('rapid navigation persists the last requested page', () async {
    await Future.wait([
      store.remember('agenda', 'page-1'),
      store.remember('agenda', 'page-2'),
      store.remember('agenda', 'page-3'),
    ]);
    expect(store.lastPage('agenda'), 'page-3');
  });
}
