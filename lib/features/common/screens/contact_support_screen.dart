import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../navigation/app_router.dart';
import '../../../state/support_provider.dart';

/// Contact support: phone, email, chat hours and a callback request.
class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  bool _requested = false;
  bool _callbackRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    final SupportProvider support = context.read<SupportProvider>();
    if (support.phone.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => support.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final SupportProvider support = context.watch<SupportProvider>();
    final bool loading = support.phone.isEmpty && support.email.isEmpty;

    return AppScaffold(
      appBar: const AppTopBar(title: 'Contact support'),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.xs,
                AppSpacing.screen,
                AppSpacing.xl,
              ),
              children: <Widget>[
                AppCard(
                  elevated: true,
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: context.primaryTint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.support_agent_rounded,
                          size: 28,
                          color: context.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Jobmate support', style: texts.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'We are available 6:00 AM – 10:00 PM, all days',
                        style: texts.caption,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InfoRow(
                        label: 'Phone',
                        value: support.phone,
                        icon: Icons.call_rounded,
                        bold: true,
                      ),
                      InfoRow(
                        label: 'Email',
                        value: support.email,
                        icon: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: SecondaryButton(
                              label: 'Call',
                              icon: Icons.call_rounded,
                              onPressed: () =>
                                  _snack('Calling ${support.phone}'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Chat',
                              icon: Icons.chat_bubble_rounded,
                              onPressed: () =>
                                  AppRouter.push(context, AppRoutes.messages),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Other options'),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Request a callback', style: texts.label),
                                const SizedBox(height: 2),
                                Text(
                                  _callbackRequested
                                      ? 'We will call you within 30 minutes'
                                      : 'We call you back during support hours',
                                  style: texts.caption,
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _callbackRequested,
                            onChanged: (bool value) {
                              setState(() => _callbackRequested = value);
                              if (value) {
                                _snack(
                                  'Callback requested. Keep your phone nearby.',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  color: AppColors.surfaceMuted,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Before you write in', style: texts.label),
                      const SizedBox(height: AppSpacing.xs),
                      const InfoRow(
                        label: 'Payments',
                        value:
                            'Earnings screen shows every release and dispute',
                        icon: Icons.payments_rounded,
                      ),
                      const InfoRow(
                        label: 'Applications',
                        value: 'My applications shows the full status timeline',
                        icon: Icons.assignment_turned_in_rounded,
                      ),
                      const InfoRow(
                        label: 'Safety',
                        value: 'Use Report a problem for urgent safety issues',
                        icon: Icons.shield_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(
                  label: 'Report a problem',
                  icon: Icons.flag_rounded,
                  onPressed: () =>
                      AppRouter.push(context, AppRoutes.reportProblem),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: StatusChip.neutral(
                    'Demo support details',
                    icon: Icons.science_rounded,
                  ),
                ),
              ],
            ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
