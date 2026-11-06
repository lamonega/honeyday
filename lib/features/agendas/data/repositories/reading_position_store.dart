import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/core/constants/preferences_keys.dart';
import 'package:honeyday/core/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final readingPositionStoreProvider = FutureProvider<ReadingPositionStore>((
  ref,
) async {
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  return ReadingPositionStore(preferences);
});

/// Device-local reading positions. IDs survive page reorder; indices do not.
/// These preferences are intentionally not part of editable content backups.
class ReadingPositionStore {
  ReadingPositionStore(this._preferences);

  final SharedPreferences _preferences;
  Future<void> _pending = Future<void>.value();

  String? lastPage(String agendaId) =>
      _preferences.getString(PreferencesKeys.lastPage(agendaId));

  /// Serialize platform writes so rapid navigation cannot persist an old page
  /// after a newer one. A failed preference write must not poison the queue.
  Future<void> remember(String agendaId, String pageId) {
    final next = _pending.then((_) async {
      final stored = await _preferences.setString(
        PreferencesKeys.lastPage(agendaId),
        pageId,
      );
      if (!stored) throw StateError('Could not remember the current page.');
    });
    _pending = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
