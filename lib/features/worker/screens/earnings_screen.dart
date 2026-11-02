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
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/earning.dart';
import '../../../models/enums.dart';
import '../../../state/worker_provider.dart';

/// Worker wallet: totals, month summary and the payment ledger with filters.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  PaymentStatus? _filter;
  List<Earning> _earnings = <Earning>[];
  List<EarningSummary> _summary = <EarningSummary>[];
  bool _loading = true;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    final WorkerProvider worker = context.read<WorkerProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (worker.earnings.isEmpty) await worker.load();
      await _load();
    });
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final WorkerProvider worker = context.read<WorkerProvider>();
    final List<Earning> items = await worker.earningsFiltered(_filter);
    final List<EarningSummary> summary = await worker.monthlySummary();
    if (!mounted) return;
    setState(() {
      _earnings = items;
      _summary = summary;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final WorkerProvider worker = context.watch<WorkerProvider>();

    return AppScaffold(
      appBar: const AppTopBar(title: 'Earnings'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          children: <Widget>[
            BalanceCard(
              title: 'Total earned',
              amount: AppFormat.money(worker.totalEarned),
              subtitle: 'Across ${worker.history.length} completed job(s)',
              icon: Icons.savings_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            StatGrid(
              columns: 2,
              stats: <StatCard>[
                StatCard(
                  label: 'Pending release',
                  value: AppFormat.moneyCompact(worker.pendingAmount),
                  icon: Icons.schedule_rounded,
                  color: AppColors.warning,
                  compact: true,
                ),
                StatCard(
                  label: 'Jobs completed',
                  value: '${worker.history.length}',
                  icon: Icons.task_alt_rounded,
                  color: AppColors.success,
                  compact: true,
                ),
              ],
            ),
            if (_summary.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Month by month'),
              const SizedBox(height: AppSpacing.xs),
              AppCard(
                child: Column(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < _summary.length;
                      index++
                    ) ...<Widget>[
                      InfoRow(
                        label: _summary[index].month,
                        value: AppFormat.money(_summary[index].total),
                        valueColor: context.primary,
                        bold: true,
                        icon: Icons.calendar_month_rounded,
                      ),
                      if (_summary[index].pending > 0)
                        InfoRow(
                          label: '  of which pending',
                          value: AppFormat.money(_summary[index].pending),
                          icon: Icons.schedule_rounded,
                        ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              title: 'Payments',
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: SelectableChip(
                      label: 'All',
                      selected: _filter == null,
                      onTap: () {
                        setState(() => _filter = null);
                        _load();
                      },
                    ),
                  ),
                  for (final PaymentStatus status in PaymentStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: SelectableChip(
                        label: status.label,
                        selected: _filter == status,
                        onTap: () {
                          setState(() => _filter = status);
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (_loading)
              const InlineLoader(label: 'Loading payments')
            else if (_earnings.isEmpty)
              EmptyStateView(
                title: 'No payments yet',
                message:
                    'Completed work and released payments will appear here.',
                icon: Icons.account_balance_wallet_rounded,
                compact: true,
              )
            else
              for (final Earning earning in _earnings)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: context.primaryTint,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            Icons.payments_rounded,
                            size: 20,
                            color: context.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                earning.jobTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: texts.label,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${earning.company} • ${AppFormat.dayMonth(earning.date)}',
                                style: texts.caption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              AppFormat.money(earning.amount),
                              style: texts.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            StatusChip.payment(earning.status, dense: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
