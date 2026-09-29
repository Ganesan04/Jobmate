import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/admin.dart';
import '../../../models/enums.dart';
import '../../../state/admin_provider.dart';
import '../../../state/job_feed_provider.dart';

/// Admin disputes: triage queue with resolve / reject decisions.
class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminProvider>().loadDisputes(),
    );
  }

  Future<void> _refresh() => context.read<AdminProvider>().loadDisputes();

  Future<void> _decide(Dispute dispute, DisputeStatus status) async {
    final String? notes = await showInputDialog(
      context,
      title: status == DisputeStatus.resolved
          ? 'Resolve dispute'
          : 'Reject dispute',
      message: '${dispute.id} • ${dispute.reason.label}',
      label: 'Moderator notes',
      initialValue: dispute.notes,
      hint: 'What was decided and why',
      maxLines: 3,
      confirmLabel: status == DisputeStatus.resolved ? 'Resolve' : 'Reject',
      icon: Icons.gavel_rounded,
    );
    if (notes == null || !mounted) return;
    final String? error = await context.read<AdminProvider>().resolveDispute(
      dispute.id,
      status,
      notes: notes,
    );
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
      appBar: const AppTopBar(title: 'Disputes'),
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
                  selected: admin.disputeFilter == null,
                  onTap: () => admin.setDisputeFilter(null),
                ),
                for (final DisputeStatus status
                    in DisputeStatus.values) ...<Widget>[
                  const SizedBox(width: AppSpacing.xs),
                  SelectableChip(
                    label: status.label,
                    selected: admin.disputeFilter == status,
                    onTap: () => admin.setDisputeFilter(
                      admin.disputeFilter == status ? null : status,
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: switch (admin.disputesState) {
              LoadState.loading ||
              LoadState.idle => const SkeletonList(count: 4),
              LoadState.error => ErrorStateView(onRetry: admin.loadDisputes),
              LoadState.ready =>
                admin.disputes.isEmpty
                    ? const EmptyStateView(
                        title: 'No disputes',
                        message:
                            'Nothing needs a moderator decision right now.',
                        icon: Icons.gavel_rounded,
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
                          itemCount: admin.disputes.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (BuildContext context, int index) =>
                              _DisputeCard(
                                dispute: admin.disputes[index],
                                onResolve: () => _decide(
                                  admin.disputes[index],
                                  DisputeStatus.resolved,
                                ),
                                onReject: () => _decide(
                                  admin.disputes[index],
                                  DisputeStatus.rejected,
                                ),
                                onReview: () => _decide(
                                  admin.disputes[index],
                                  DisputeStatus.underReview,
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

class _DisputeCard extends StatelessWidget {
  const _DisputeCard({
    required this.dispute,
    required this.onResolve,
    required this.onReject,
    required this.onReview,
  });

  final Dispute dispute;
  final VoidCallback onResolve;
  final VoidCallback onReject;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final bool actionable =
        dispute.status == DisputeStatus.open ||
        dispute.status == DisputeStatus.underReview;

    return AppCard(
      onTap: () => _showDetails(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(dispute.reason.label, style: texts.label),
                    const SizedBox(height: 2),
                    Text(
                      '${dispute.jobTitle} • ${dispute.company}',
                      style: texts.caption,
                    ),
                  ],
                ),
              ),
              StatusChip.dispute(dispute.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              StatusChip.neutral(
                'Raised by ${dispute.raisedBy}',
                icon: Icons.person_outline_rounded,
              ),
              StatusChip.neutral(
                AppFormat.timeAgo(dispute.raisedAt),
                icon: Icons.schedule_rounded,
              ),
              if (dispute.amount > 0)
                StatusChip.neutral(
                  AppFormat.money(dispute.amount),
                  icon: Icons.payments_rounded,
                  color: AppColors.error,
                ),
            ],
          ),
          if (actionable) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                if (dispute.status == DisputeStatus.open)
                  Expanded(
                    child: SecondaryButton(
                      label: 'Review',
                      icon: Icons.hourglass_top_rounded,
                      onPressed: onReview,
                    ),
                  ),
                if (dispute.status == DisputeStatus.open)
                  const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SecondaryButton(
                    label: 'Reject',
                    icon: Icons.block_rounded,
                    onPressed: onReject,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Resolve',
                    icon: Icons.check_rounded,
                    onPressed: onResolve,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showAppSheet<void>(
      context: context,
      title: dispute.reason.label,
      subtitle: dispute.id,
      child: Builder(
        builder: (BuildContext sheetContext) {
          final TextTheme texts = Theme.of(sheetContext).textTheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InfoRow(
                label: 'Job',
                value: '${dispute.jobTitle} (${dispute.company})',
                icon: Icons.work_rounded,
              ),
              InfoRow(
                label: 'Raised by',
                value: dispute.raisedBy,
                icon: Icons.person_outline_rounded,
              ),
              InfoRow(
                label: 'Against',
                value: dispute.againstUser,
                icon: Icons.person_search_rounded,
              ),
              InfoRow(
                label: 'Raised',
                value: AppFormat.dayMonthYear(dispute.raisedAt),
                icon: Icons.event_rounded,
              ),
              InfoRow(
                label: 'Amount',
                value: dispute.amount == 0
                    ? 'Not applicable'
                    : AppFormat.money(dispute.amount),
                icon: Icons.payments_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Details', style: texts.label),
              const SizedBox(height: 2),
              Text(dispute.details, style: texts.bodyMedium),
              if (dispute.notes.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text('Moderator notes', style: texts.label),
                const SizedBox(height: 2),
                Text(dispute.notes, style: texts.bodyMedium),
              ],
            ],
          );
        },
      ),
    );
  }
}
