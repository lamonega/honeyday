import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/app/app.dart';
import 'package:honeyday/core/database/app_database.dart';
import 'package:honeyday/core/database/database_provider.dart';

void main() {
  testWidgets('HoneydayApp boots and displays Tus agendas', (tester) async {
    final inMemoryDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(inMemoryDb)],
        child: const HoneydayApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tus agendas'), findsOneWidget);
    expect(find.text('Honeyday'), findsOneWidget);

    await inMemoryDb.close();
  });
}
