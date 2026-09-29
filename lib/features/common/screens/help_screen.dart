import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/support.dart';
import '../../../navigation/app_router.dart';
import '../../../state/support_provider.dart';

/// Help centre: category grid, searchable FAQ list and support shortcuts.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    final SupportProvider support = context.read<SupportProvider>();
    if (support.articles.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => support.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final SupportProvider support = context.watch<SupportProvider>();
    final List<HelpArticle> articles = support.visibleArticles;

    return AppScaffold(
      appBar: const AppTopBar(title: 'Help & support'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        children: <Widget>[
          PrimaryButton(
            label: 'Report a problem',
            icon: Icons.flag_rounded,
            onPressed: () => AppRouter.push(context, AppRoutes.reportProblem),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Contact us',
            icon: Icons.support_agent_rounded,
            onPressed: () => AppRouter.push(context, AppRoutes.contactSupport),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Browse by topic'),
          const SizedBox(height: AppSpacing.xs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: support.categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisExtent: 104,
            ),
            itemBuilder: (BuildContext context, int index) {
              final HelpCategory category = support.categories[index];
              return AppCard(
                onTap: () => support.setCategory(
                  support.selectedCategory == category.title
                      ? null
                      : category.title,
                ),
                color: support.selectedCategory == category.title
                    ? context.primaryTint
                    : AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color.lerp(category.color, Colors.white, 0.85),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        category.icon,
                        size: 18,
                        color: category.color,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        category.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.label,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        category.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Frequently asked questions',
            subtitle: support.selectedCategory,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (articles.isEmpty)
            const EmptyStateView(
              title: 'No articles',
              message: 'Try another topic or contact support.',
              icon: Icons.help_outline_rounded,
              compact: true,
            )
          else
            for (final HelpArticle article in articles)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _FaqTile(article: article),
              ),
          if (support.tickets.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(title: 'Your reports'),
            const SizedBox(height: AppSpacing.xs),
            for (final SupportTicket ticket in support.tickets)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              ticket.subject,
                              style: Theme.of(context).textTheme.label,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ticket.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      StatusChip.neutral(
                        ticket.status,
                        icon: Icons.pending_rounded,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.article});

  final HelpArticle article;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return AppCard(
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  widget.article.question,
                  style: texts.label?.copyWith(
                    color: _open ? context.primary : null,
                  ),
                ),
              ),
              Icon(
                _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: AppDurations.normal,
            crossFadeState: _open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(widget.article.answer, style: texts.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
