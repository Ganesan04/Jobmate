import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../state/auth_provider.dart';
import 'splash_screen.dart';

/// One onboarding page: illustration, heading, description.
class OnboardingPage {
  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.points,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> points;
}

const List<OnboardingPage> kOnboardingPages = <OnboardingPage>[
  OnboardingPage(
    title: 'Find daily work near you',
    subtitle:
        'Browse verified jobs in your area and apply in a single tap. No middlemen, no fees.',
    icon: Icons.search_rounded,
    color: AppColors.workerPrimary,
    points: <String>[
      'Jobs by category & distance',
      'Filter by pay and shift',
      'Save jobs for later',
    ],
  ),
  OnboardingPage(
    title: 'Get hired and paid fast',
    subtitle:
        'Track every application, get accepted in one tap and check in with a secure code.',
    icon: Icons.handshake_rounded,
    color: AppColors.workerSecondary,
    points: <String>[
      'Live application status',
      'Check-in and work proof',
      'Direct chat with the giver',
    ],
  ),
  OnboardingPage(
    title: 'Hire reliable workers',
    subtitle:
        'Work givers post jobs, shortlist applicants and pay through Jobmate after the shift.',
    icon: Icons.groups_rounded,
    color: AppColors.giverPrimary,
    points: <String>[
      'Multi-step job posting',
      'Shortlist and select',
      'UPI payouts and receipts',
    ],
  ),
];

/// Paged onboarding with a dot indicator, Skip and Next / Get started.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == kOnboardingPages.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    context.read<AuthProvider>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                children: <Widget>[
                  const BrandMark(size: 38),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Jobmate', style: texts.titleMedium),
                  const Spacer(),
                  TextButton(onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: kOnboardingPages.length,
                onPageChanged: (int value) => setState(() => _index = value),
                itemBuilder: (BuildContext context, int index) {
                  final OnboardingPage page = kOnboardingPages[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: AppSpacing.md),
                        _Illustration(color: page.color, icon: page.icon),
                        const SizedBox(height: AppSpacing.xl),
                        Text(page.title, style: texts.display),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          page.subtitle,
                          style: texts.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        for (final String point in page.points)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Color.lerp(
                                      page.color,
                                      Colors.white,
                                      0.86,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: page.color,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(point, style: texts.bodyLarge),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.lg,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      kOnboardingPages.length,
                      (int i) => AnimatedContainer(
                        duration: AppDurations.fast,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? context.primary
                              : AppColors.borderStrong,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: _isLast ? 'Get started' : 'Next',
                    icon: _isLast
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            height: 190,
            width: 190,
            decoration: BoxDecoration(
              color: Color.lerp(color, Colors.white, 0.9),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: Color.lerp(color, Colors.white, 0.82),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(icon, size: 44, color: Colors.white),
          ),
          Positioned(
            top: 10,
            right: 18,
            child: _Bubble(
              icon: Icons.payments_rounded,
              color: AppColors.success,
            ),
          ),
          Positioned(
            bottom: 6,
            left: 8,
            child: _Bubble(
              icon: Icons.location_on_rounded,
              color: AppColors.giverPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.4),
        boxShadow: AppShadows.card,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
