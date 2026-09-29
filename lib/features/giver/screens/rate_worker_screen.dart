import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../state/giver_provider.dart';

/// Post-payment rating for a worker: 1-5 stars plus optional feedback.
class RateWorkerScreen extends StatefulWidget {
  const RateWorkerScreen({
    super.key,
    required this.jobId,
    required this.workerId,
    required this.workerName,
  });

  final String jobId;
  final String workerId;
  final String workerName;

  @override
  State<RateWorkerScreen> createState() => _RateWorkerScreenState();
}

class _RateWorkerScreenState extends State<RateWorkerScreen> {
  final TextEditingController _feedback = TextEditingController();
  int _stars = 0;
  bool _busy = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    if (context.read<GiverProvider>().hasRated(widget.jobId, widget.workerId)) {
      _saved = true;
      _stars = 5;
    }
  }

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap a star to rate the worker')),
      );
      return;
    }
    setState(() => _busy = true);
    await context.read<GiverProvider>().rateWorker(
      jobId: widget.jobId,
      workerId: widget.workerId,
      stars: _stars,
      feedback: _feedback.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _saved = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Thanks for the feedback!')));
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return AppScaffold(
      appBar: const AppTopBar(title: 'Rate worker'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        children: <Widget>[
          Center(child: ProfileAvatar(name: widget.workerName, size: 84)),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'How was ${widget.workerName}?',
              style: texts.headline,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              'Your rating helps other work givers and keeps the platform fair.',
              style: texts.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (int star = 1; star <= 5; star++)
                      IconButton(
                        onPressed: _saved
                            ? null
                            : () => setState(() => _stars = star),
                        icon: Icon(
                          star <= _stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 38,
                          color: star <= _stars
                              ? AppColors.warning
                              : AppColors.borderStrong,
                        ),
                        tooltip: '$star star(s)',
                      ),
                  ],
                ),
                if (_stars > 0) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  StatusChip.neutral(
                    _labelFor(_stars),
                    icon: Icons.emoji_emotions_rounded,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(
            title: 'Add feedback',
            padding: EdgeInsets.only(bottom: AppSpacing.xs),
          ),
          AppTextField(
            controller: _feedback,
            hint: 'What went well? Anything to improve?',
            maxLines: 4,
            minLines: 3,
            enabled: !_saved && !_busy,
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        child: _saved
            ? PrimaryButton(
                label: 'Rating submitted',
                icon: Icons.check_rounded,
                success: true,
                onPressed: () => Navigator.of(context).pop(),
              )
            : PrimaryButton(
                label: 'Submit rating',
                icon: Icons.star_rounded,
                loading: _busy,
                onPressed: _busy ? null : _submit,
              ),
      ),
    );
  }

  String _labelFor(int stars) {
    switch (stars) {
      case 1:
        return 'Needs improvement';
      case 2:
        return 'Below expectations';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      default:
        return 'Excellent';
    }
  }
}
