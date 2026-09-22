import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the user has completed onboarding.
class OnboardingState {
  /// Whether onboarding has been completed.
  const OnboardingState({this.completed = false});

  /// Whether onboarding has been completed.
  final bool completed;

  OnboardingState copyWith({bool? completed}) {
    return OnboardingState(completed: completed ?? this.completed);
  }
}

/// Notifier for onboarding state using Riverpod's Notifier.
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  /// Marks onboarding as completed.
  void complete() => state = state.copyWith(completed: true);
}

/// Provider for onboarding state.
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );
