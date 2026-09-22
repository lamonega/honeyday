import 'package:haptic_feedback/haptic_feedback.dart';

/// Shows a haptic light feedback.
Future<void> hapticLight() =>
    Haptics.vibrate(HapticsType.light).onError((_, _) {});
