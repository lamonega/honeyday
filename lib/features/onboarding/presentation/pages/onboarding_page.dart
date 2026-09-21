import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

// ──────────────────────────────────────────────
// Onboarding page constants (used only here)
// ──────────────────────────────────────────────

/// Active pagination dot width.
const double kOnboardingActiveDotWidth = 16;
/// Inactive pagination dot width.
const double kOnboardingInactiveDotWidth = 8;
/// Large spacing value for onboarding layout.
const double kSpacingLarge = 24;
/// Medium spacing value for onboarding layout.
const double kSpacingMedium = 16;
/// Onboarding step icon size.
const double kOnboardingIconSize = 72;
/// Padding around onboarding step icons.
const double kOnboardingStepIconPadding = 32;
/// Horizontal padding for onboarding step content.
const double kOnboardingStepHorizontalPadding = 32;
/// Font size for onboarding step titles.
const double kOnboardingTitleFontSize = 28;
/// Font size for onboarding descriptions and button text.
const double kOnboardingDescriptionFontSize = 16;
/// Line height for onboarding description text.
const double kOnboardingLineHeight = 1.5;
/// Height of the onboarding action button.
const double kOnboardingButtonHeight = 52;
/// Border radius for the onboarding action button.
const double kOnboardingButtonBorderRadius = 14;

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

/// Onboarding screen shown on first launch.
///
/// What: 3-step carousel introducing the app's core value propositions.
/// Why: Lead users to the "aha moment" quickly with progressive disclosure.
class OnboardingPage extends ConsumerStatefulWidget {
  /// Constructs an [OnboardingPage].
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  static List<_OnboardingStep> _pages(BuildContext context) => [
    _OnboardingStep(
      icon: Icons.auto_stories_rounded,
      title: AppLocalizations.of(context).onboardingStep1Title,
      description: AppLocalizations.of(context).onboardingStep1Desc,
      color: const Color(0xFFF59E0B),
      bgColor: const Color(0xFFFEF3C7),
    ),
    _OnboardingStep(
      icon: Icons.draw_rounded,
      title: AppLocalizations.of(context).onboardingStep2Title,
      description: AppLocalizations.of(context).onboardingStep2Desc,
      color: const Color(0xFF8B5CF6),
      bgColor: const Color(0xFFEDE9FE),
    ),
    _OnboardingStep(
      icon: Icons.dashboard_customize_rounded,
      title: AppLocalizations.of(context).onboardingStep3Title,
      description: AppLocalizations.of(context).onboardingStep3Desc,
      color: const Color(0xFF10B981),
      bgColor: const Color(0xFFD1FAE5),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages(context).length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      ref.read(onboardingProvider.notifier).complete();
    }
  }

  void _skip() {
    ref.read(onboardingProvider.notifier).complete();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    AppLocalizations.of(context).onboardingSkip,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages(context).length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final step = _pages(context)[index];
                  return _buildStep(step, colorScheme);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages(context).length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? kOnboardingActiveDotWidth : kOnboardingInactiveDotWidth,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: kOnboardingButtonHeight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kOnboardingButtonBorderRadius),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _next,
                  child: Text(
                    _currentPage == _pages(context).length - 1
                        ? AppLocalizations.of(context).onboardingStart
                        : AppLocalizations.of(context).onboardingNext,
                    style: const TextStyle(
                      fontSize: kOnboardingDescriptionFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(_OnboardingStep step, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kOnboardingStepHorizontalPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                padding: const EdgeInsets.all(kOnboardingStepIconPadding),
                decoration: BoxDecoration(
                  color: step.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, size: kOnboardingIconSize, color: step.color),
              )
              .animate()
              .scale(duration: 500.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: kSpacingLarge),
          Text(
                step.title,
                style: GoogleFonts.fraunces(
                  fontSize: kOnboardingTitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 150.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 400.ms,
                delay: 150.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: kSpacingMedium),
          Text(
                step.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: kOnboardingDescriptionFontSize,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                  height: kOnboardingLineHeight,
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 250.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 400.ms,
                delay: 250.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color bgColor;
}
