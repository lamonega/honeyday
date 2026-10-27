import 'package:flutter/widgets.dart';
import 'package:honeyday/features/agendas/presentation/controllers/save_session.dart';

class SaveSessionScope extends InheritedWidget {
  const SaveSessionScope({
    required this.session,
    required super.child,
    super.key,
  });

  final SaveSession session;

  static SaveSession? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SaveSessionScope>()
      ?.session;

  @override
  bool updateShouldNotify(SaveSessionScope oldWidget) =>
      oldWidget.session != session;
}
