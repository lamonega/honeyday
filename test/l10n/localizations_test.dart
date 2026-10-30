import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/l10n/generated/app_localizations_en.dart';

void main() {
  test('English multiline messages contain line breaks, not escaped text', () {
    final l10n = AppLocalizationsEn();
    for (final message in [
      l10n.onboardingStep1Desc,
      l10n.onboardingStep2Desc,
      l10n.onboardingStep3Desc,
      l10n.catalogTextboxDefaultContent,
    ]) {
      expect(message, contains('\n'));
      expect(message, isNot(contains(r'\n')));
    }
  });
}
