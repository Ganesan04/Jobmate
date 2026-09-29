import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/job_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../models/job.dart';
import '../../../navigation/app_router.dart';
import '../../../state/job_feed_provider.dart';

/// Search Jobs: query box, sort row, filter sheet and the result list.
class SearchJobsScreen extends StatefulWidget {
  const SearchJobsScreen({super.key});

  @override
  State<SearchJobsScreen> createState() => _SearchJobsScreenState();
}

class _SearchJobsScreenState extends State<SearchJobsScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  JobFilter _filter = const JobFilter();
  JobSort _sort = JobSort.newest;
  List<Job> _results = <Job>[];
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    final JobFeedProvider feed = context.read<JobFeedProvider>();
    if (feed.jobs.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => feed.load());
    }
    _runSearch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    setState(() => _loading = true);
    final JobFeedProvider feed = context.read<JobFeedProvider>();
    final List<Job> results = await feed.search(_filter, _sort);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
      _searched = true;
    });
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _filter = _filter.copyWith(query: value.trim()));
      _runSearch();
    });
  }

  Future<void> _openFilters() async {
    final JobFilter? updated = await showAppSheet<JobFilter>(
      context: context,
      title: 'Filters',
      subtitle: '${_filter.activeCount} filter(s) applied',
      child: _FilterSheet(initial: _filter),
    );
    if (updated == null) return;
    setState(() => _filter = updated);
    _runSearch();
  }

  void _clearAll() {
    setState(() {
      _filter = JobFilter(query: _filter.query);
      _controller.clear();
    });
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final JobFeedProvider feed = context.watch<JobFeedProvider>();

    return AppScaffold(
      appBar: AppTopBar(
        title: 'Find work',
        actions: <Widget>[
          AppIconButton(
            icon: Icons.filter_list_rounded,
            tooltip: 'Filters',
            color: _filter.activeCount > 0 ? context.primary : null,
            onPressed: _openFilters,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              AppSpacing.sm,
            ),
            child: AppTextField(
              controller: _controller,
              hint: 'Search by role, skill or company',
              prefixIcon: Icons.search_rounded,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        _onQueryChanged('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 19),
                      tooltip: 'Clear',
                    ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              children: <Widget>[
                for (final JobSort sort in JobSort.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: SelectableChip(
                      label: sort.label,
                      selected: _sort == sort,
                      onTap: () {
                        setState(() => _sort = sort);
                        _runSearch();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: _loading && _results.isEmpty
                ? const JobCardSkeleton()
                : _results.isEmpty
                ? _EmptyResults(onClear: _clearAll, searched: _searched)
                : RefreshIndicator(
                    onRefresh: _runSearch,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.xs,
                        AppSpacing.screen,
                        AppSpacing.xl,
                      ),
                      children: <Widget>[
                        Text(
                          '${_results.length} job${_results.length == 1 ? '' : 's'} found',
                          style: texts.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        for (final Job job in _results)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: JobCard(
                              job: job,
                              isSaved: feed.isSaved(job.id),
                              onTap: () async {
                                await AppRouter.push(
                                  context,
                                  AppRoutes.jobDetails,
                                  arguments: job.id,
                                );
                                if (mounted) setState(() {});
                              },
                              onSave: () => feed.toggleSaved(job),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onClear, required this.searched});

  final VoidCallback onClear;
  final bool searched;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      title: 'No jobs matched',
      message: searched
          ? 'Try removing a filter or searching a different keyword.'
          : 'Pull to refresh or check back later.',
      icon: Icons.search_off_rounded,
      actionLabel: 'Clear filters',
      onAction: onClear,
    );
  }
}

/// Bottom-sheet filter editor bound to a local copy of the filter.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final JobFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late JobFilter _draft = widget.initial;
  late final TextEditingController _minPay = TextEditingController(
    text: widget.initial.minPay?.toString() ?? '',
  );
  late final TextEditingController _maxPay = TextEditingController(
    text: widget.initial.maxPay?.toString() ?? '',
  );
  late final TextEditingController _distance = TextEditingController(
    text: widget.initial.maxDistanceKm?.toString() ?? '',
  );

  @override
  void dispose() {
    _minPay.dispose();
    _maxPay.dispose();
    _distance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: 'Category',
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          ),
          ChipWrap(
            children: JobCategory.values
                .map(
                  (JobCategory category) => SelectableChip(
                    label: category.label,
                    selected: _draft.categories.contains(category),
                    onTap: () {
                      setState(() {
                        final Set<JobCategory> next = <JobCategory>{
                          ..._draft.categories,
                        };
                        if (!next.remove(category)) next.add(category);
                        _draft = _draft.copyWith(categories: next);
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionHeader(
            title: 'Pay range (per day)',
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: AppTextField(
                  controller: _minPay,
                  hint: 'Min',
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    DigitsOnlyFormatter(maxLength: 5),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: _maxPay,
                  hint: 'Max',
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    DigitsOnlyFormatter(maxLength: 5),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SectionHeader(
            title: 'Maximum distance (km)',
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          ),
          AppTextField(
            controller: _distance,
            hint: 'e.g. 10',
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              DigitsOnlyFormatter(maxLength: 3),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SectionHeader(
            title: 'Job type',
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          ),
          ChipWrap(
            children: JobType.values
                .map(
                  (JobType type) => SelectableChip(
                    label: type.label,
                    selected: _draft.jobType == type,
                    onTap: () => setState(() {
                      _draft = _draft.jobType == type
                          ? _draft.copyWith(clearJobType: true)
                          : _draft.copyWith(jobType: type);
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile.adaptive(
            value: _draft.urgentOnly,
            onChanged: (bool value) =>
                setState(() => _draft = _draft.copyWith(urgentOnly: value)),
            title: const Text('Urgent jobs only'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: _draft.verifiedOnly,
            onChanged: (bool value) =>
                setState(() => _draft = _draft.copyWith(verifiedOnly: value)),
            title: const Text('Verified work givers only'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: SecondaryButton(
                  label: 'Reset',
                  onPressed: () => Navigator.of(context).pop(const JobFilter()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Apply filters',
                  onPressed: () {
                    Navigator.of(context).pop(
                      _draft.copyWith(
                        minPay: int.tryParse(_minPay.text),
                        maxPay: int.tryParse(_maxPay.text),
                        maxDistanceKm: double.tryParse(_distance.text),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
