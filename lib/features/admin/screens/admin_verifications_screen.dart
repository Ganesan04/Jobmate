import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/admin.dart';
import '../../../models/enums.dart';
import '../../../state/admin_provider.dart';
import '../../../state/job_feed_provider.dart';

/// Admin verification queue: approve or reject submitted documents.
class AdminVerificationsScreen extends StatefulWidget {
  const AdminVerificationsScreen({super.key});

  @override
  State<AdminVerificationsScreen> createState() =>
      _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends State<AdminVerificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminProvider>().loadVerifications(),
    );
  }

  Future<void> _refresh() => context.read<AdminProvider>().loadVerifications();

  Future<void> _review(
    VerificationRequest request,
    VerificationStatus decision,
  ) async {
    final String? note = await showInputDialog(
      context,
      title: decision == VerificationStatus.verified
          ? 'Approve request'
          : 'Reject request',
      message: '${request.userName} • ${request.type.label}',
      label: 'Reviewer note',
      initialValue: request.note,
      hint: 'What did you check?',
      confirmLabel: decision == VerificationStatus.verified
          ? 'Approve'
          : 'Reject',
      icon: decision == VerificationStatus.verified
          ? Icons.verified_rounded
          : Icons.error_rounded,
    );
    if (note == null || !mounted) return;
    final String? error = await context
        .read<AdminProvider>()
        .reviewVerification(request.id, decision, note: note);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AdminProvider admin = context.watch<AdminProvider>();

    return AppScaffold(
      centerContent: false,
      appBar: AppTopBar(
        title: 'Verifications',
        subtitle: '${admin.pendingVerifications} pending',
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              children: <Widget>[
                SelectableChip(
                  label: 'All',
                  selected: admin.verificationFilter == null,
                  onTap: () => admin.setVerificationFilter(null),
                ),
                for (final VerificationStatus status
                    in VerificationStatus.values) ...<Widget>[
                  const SizedBox(width: AppSpacing.xs),
                  SelectableChip(
                    label: status.label,
                    selected: admin.verificationFilter == status,
                    onTap: () => admin.setVerificationFilter(
                      admin.verificationFilter == status ? null : status,
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: switch (admin.verificationsState) {
              LoadState.loading ||
              LoadState.idle => const SkeletonList(count: 4),
              LoadState.error => ErrorStateView(
                onRetry: admin.loadVerifications,
              ),
              LoadState.ready =>
                admin.verifications.isEmpty
                    ? const EmptyStateView(
                        title: 'Queue is clear',
                        message: 'No verification requests match this filter.',
                        icon: Icons.verified_user_rounded,
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            AppSpacing.xs,
                            AppSpacing.screen,
                            AppSpacing.xl,
                          ),
                          itemCount: admin.verifications.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (BuildContext context, int index) =>
                              _RequestCard(
                                request: admin.verifications[index],
                                onApprove: () => _review(
                                  admin.verifications[index],
                                  VerificationStatus.verified,
                                ),
                                onReject: () => _review(
                                  admin.verifications[index],
                                  VerificationStatus.rejected,
                                ),
                              ),
                        ),
                      ),
            },
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final VerificationRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final bool pending = request.status == VerificationStatus.pending;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  request.type == VerificationType.identity
                      ? Icons.badge_rounded
                      : request.type == VerificationType.skills
                      ? Icons.workspace_premium_rounded
                      : Icons.alternate_email_rounded,
                  size: 20,
                  color: context.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(request.userName, style: texts.label),
                    const SizedBox(height: 2),
                    Text(
                      '${request.type.label} • ${request.userRole.label}',
                      style: texts.caption,
                    ),
                  ],
                ),
              ),
              StatusChip.verification(request.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              StatusChip.neutral(
                AppFormat.timeAgo(request.submittedAt),
                icon: Icons.schedule_rounded,
              ),
              if (request.document.isNotEmpty)
                StatusChip.neutral(
                  request.document,
                  icon: Icons.description_outlined,
                ),
            ],
          ),
          if (pending) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: SecondaryButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    onPressed: onReject,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Approve',
                    icon: Icons.check_rounded,
                    onPressed: onApprove,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
