import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

/// Onboarding screen shown on first launch.
///
/// What: 3-step carousel introducing the app's core value propositions.
/// Why: Lead users to the "aha moment" quickly with progressive disclosure.
class OnboardingPage extends StatefulWidget {
  /// Constructs an [OnboardingPage].
  const OnboardingPage({
    required this.onComplete,
    this.completing = false,
    super.key,
  });

  final VoidCallback onComplete;
  final bool completing;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
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
      widget.onComplete();
    }
  }

  void _previous() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToPage(int index) {
    if (widget.completing || index == _currentPage) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pages = _pages(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Semantics(
                      button: true,
                      label: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      child: IconButton(
                        onPressed: widget.completing ? null : _previous,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.completing ? null : widget.onComplete,
                    child: Text(
                      AppLocalizations.of(context).onboardingSkip,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return _buildStep(pages[index], colorScheme);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final isActive = i == _currentPage;
                  return Semantics(
                    button: true,
                    selected: isActive,
                    label: pages[i].title,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: widget.completing ? null : () => _goToPage(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 10,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isActive
                              ? kOnboardingActiveDotWidth
                              : kOnboardingInactiveDotWidth,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    minHeight: kOnboardingButtonHeight,
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          kOnboardingButtonBorderRadius,
                        ),
                      ),
                      elevation: 2,
                    ),
                    onPressed: widget.completing ? null : _next,
                    child: Text(
                      _currentPage == pages.length - 1
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(_OnboardingStep step, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final badgeColor = isDark
        ? step.color.withValues(alpha: 0.18)
        : step.bgColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 340;
        final iconSize = isCompactHeight ? 48.0 : kOnboardingIconSize;
        final iconPadding = isCompactHeight ? 20.0 : kOnboardingStepIconPadding;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: kOnboardingStepHorizontalPadding,
            vertical: 12,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 24).clamp(0, double.infinity),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                          padding: EdgeInsets.all(iconPadding),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            step.icon,
                            size: iconSize,
                            color: step.color,
                          ),
                        )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.easeOutBack)
                        .fadeIn(duration: 400.ms),
                    SizedBox(
                      height: isCompactHeight ? kSpacingMedium : kSpacingLarge,
                    ),
                    Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fraunces(
                            fontSize: isCompactHeight
                                ? 22
                                : kOnboardingTitleFontSize,
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
                    SizedBox(height: isCompactHeight ? 8 : kSpacingMedium),
                    Text(
                          step.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: kOnboardingDescriptionFontSize,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
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
              ),
            ),
          ),
        );
      },
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
