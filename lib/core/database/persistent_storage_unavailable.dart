/// The browser cannot provide a durable database for agendas.
final class PersistentStorageUnavailable implements Exception {
  /// Constructs an error with the underlying cause, if known.
  const PersistentStorageUnavailable([this.cause]);

  /// The error from the browser database opener, if it failed to open.
  final Object? cause;

  @override
  String toString() =>
      'Browser database unavailable${cause == null ? '' : ': $cause'}';
}
