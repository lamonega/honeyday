import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/theme/app_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await AppFonts.load();
  await AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(),
    run: () async => await testMain(),
  );
}
