import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../models/enums.dart';
import '../../../state/auth_provider.dart';

/// Role picker with two large selectable cards. Continue stays disabled until a
/// role is chosen.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final AuthProvider auth = context.watch<AuthProvider>();
    final UserRole selection = _selected ?? auth.role;

    return AppScaffold(
      appBar: const AppTopBar(title: 'Choose your role'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.sm,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        children: <Widget>[
          Text('How will you use Jobmate?', style: texts.headline),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'You can switch roles any time from Settings.',
            style: texts.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          _RoleCard(
            role: UserRole.worker,
            color: AppColors.workerPrimary,
            icon: Icons.handyman_rounded,
            highlights: <String>[
              'Browse and apply to jobs nearby',
              'Track applications and check in',
              'Receive earnings and work history',
            ],
            selected: selection == UserRole.worker,
            onTap: () {
              setState(() => _selected = UserRole.worker);
              auth.selectRole(UserRole.worker);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _RoleCard(
            role: UserRole.workGiver,
            color: AppColors.giverPrimary,
            icon: Icons.business_center_rounded,
            highlights: <String>[
              'Post jobs in a guided 6-step flow',
              'Shortlist and select workers',
              'Pay via UPI and rate workers',
            ],
            selected: selection == UserRole.workGiver,
            onTap: () {
              setState(() => _selected = UserRole.workGiver);
              auth.selectRole(UserRole.workGiver);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.read<AuthProvider>().continueFromRole(),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.color,
    required this.icon,
    required this.highlights,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final Color color;
  final IconData icon;
  final List<String> highlights;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${role.label}. ${role.tagline}',
      child: Material(
        color: selected
            ? Color.lerp(color, Colors.white, 0.94)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: AnimatedContainer(
            duration: AppDurations.normal,
            padding: const EdgeInsets.all(AppSpacing.md + 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: selected ? color : AppColors.border,
                width: selected ? 1.8 : 1.2,
              ),
              boxShadow: selected ? AppShadows.raised : AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Color.lerp(color, Colors.white, 0.85),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Icon(icon, size: 26, color: color),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(role.label, style: texts.titleMedium),
                          const SizedBox(height: 2),
                          Text(role.tagline, style: texts.caption),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: AppDurations.fast,
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: selected ? color : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? color : AppColors.borderStrong,
                          width: 1.6,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (final String highlight in highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(highlight, style: texts.bodyMedium),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
