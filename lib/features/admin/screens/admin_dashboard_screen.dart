import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/admin.dart';
import '../../../navigation/app_router.dart';
import '../../../state/admin_provider.dart';
import '../../../state/job_feed_provider.dart';

/// Admin dashboard: platform metrics, pending queues and recent activity.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminProvider>().loadDashboard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final AdminProvider admin = context.watch<AdminProvider>();

    return AppScaffold(
      centerContent: false,
      appBar: const AppTopBar.tab(
        title: 'Dashboard',
        subtitle: 'Platform overview',
      ),
      body: switch (admin.dashboardState) {
        LoadState.loading || LoadState.idle => const SkeletonList(count: 4),
        LoadState.error => ErrorStateView(
          title: 'Could not load metrics',
          message: admin.error ?? 'Something went wrong',
          onRetry: admin.loadDashboard,
        ),
        LoadState.ready => RefreshIndicator(
          onRefresh: admin.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              AppSpacing.xl,
            ),
            children: <Widget>[
              _KpiRow(stats: admin.stats),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: 'Action needed',
                subtitle: 'Queues waiting for a decision',
              ),
              const SizedBox(height: AppSpacing.xs),
              _QueueRow(
                icon: Icons.verified_user_rounded,
                color: AppColors.warning,
                title: 'Verification requests',
                count: admin.stats.verificationRequests,
                route: AppRoutes.adminVerifications,
              ),
              const SizedBox(height: AppSpacing.sm),
              _QueueRow(
                icon: Icons.gavel_rounded,
                color: AppColors.error,
                title: 'Open disputes',
                count: admin.stats.openDisputes,
                route: AppRoutes.adminDisputes,
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Platform'),
              const SizedBox(height: AppSpacing.xs),
              AppCard(
                child: Column(
                  children: <Widget>[
                    InfoRow(
                      label: 'Total users',
                      value: '${admin.stats.totalUsers}',
                      icon: Icons.people_alt_rounded,
                      bold: true,
                    ),
                    InfoRow(
                      label: 'Workers',
                      value: '${admin.stats.workers}',
                      icon: Icons.construction_rounded,
                    ),
                    InfoRow(
                      label: 'Work givers',
                      value: '${admin.stats.workGivers}',
                      icon: Icons.storefront_rounded,
                    ),
                    InfoRow(
                      label: 'Active jobs',
                      value: '${admin.stats.activeJobs}',
                      icon: Icons.bolt_rounded,
                    ),
                    InfoRow(
                      label: 'Completed jobs',
                      value: '${admin.stats.completedJobs}',
                      icon: Icons.task_alt_rounded,
                    ),
                    InfoRow(
                      label: 'Applications',
                      value: '${admin.stats.applications}',
                      icon: Icons.send_rounded,
                    ),
                    InfoRow(
                      label: 'Payments processed',
                      value: AppFormat.money(admin.stats.payments),
                      icon: Icons.payments_rounded,
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Shortcuts'),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AdminShortcut(
                      label: 'Users',
                      icon: Icons.people_alt_rounded,
                      onTap: () =>
                          AppRouter.push(context, AppRoutes.adminUsers),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AdminShortcut(
                      label: 'Jobs',
                      icon: Icons.work_rounded,
                      onTap: () => AppRouter.push(context, AppRoutes.adminJobs),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AdminShortcut(
                      label: 'Disputes',
                      icon: Icons.gavel_rounded,
                      onTap: () =>
                          AppRouter.push(context, AppRoutes.adminDisputes),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                color: AppColors.surfaceMuted,
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Live console. Actions here change real accounts and jobs.',
                        style: texts.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      },
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    return StatGrid(
      columns: 2,
      stats: <StatCard>[
        StatCard(
          label: 'Users',
          value: '${stats.totalUsers}',
          caption: '${stats.workers} workers',
          icon: Icons.people_alt_rounded,
        ),
        StatCard(
          label: 'Active jobs',
          value: '${stats.activeJobs}',
          caption: '${stats.completedJobs} completed',
          icon: Icons.bolt_rounded,
          color: AppColors.giverPrimary,
        ),
        StatCard(
          label: 'Applications',
          value: '${stats.applications}',
          icon: Icons.send_rounded,
          color: AppColors.info,
        ),
        StatCard(
          label: 'Payments',
          value: AppFormat.moneyCompact(stats.payments),
          icon: Icons.payments_rounded,
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
    required this.route,
  });

  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final String route;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return AppCard(
      onTap: () => AppRouter.push(context, route),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color.lerp(color, Colors.white, 0.86),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: texts.label),
                const SizedBox(height: 2),
                Text(
                  count == 0 ? 'Nothing pending' : 'Needs review',
                  style: texts.caption,
                ),
              ],
            ),
          ),
          StatusChip.neutral(
            '$count',
            color: count == 0 ? AppColors.success : color,
            icon: count == 0 ? Icons.check_rounded : null,
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class AdminShortcut extends StatelessWidget {
  const AdminShortcut({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: AppColors.surface,
      child: Column(
        children: <Widget>[
          Icon(icon, color: AppColors.adminPrimary),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.label),
        ],
      ),
    );
  }
}
