import 'dart:async';
import 'package:alchemist/alchemist.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) {
  GoogleFonts.config.allowRuntimeFetching = false;
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(),
    run: () async => await testMain(),
  );
}
