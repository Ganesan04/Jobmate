import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../models/job.dart';
import '../../../models/job_draft.dart';
import '../../../services/api/api_exception.dart';
import '../../../state/giver_provider.dart';

/// Six-step "Post a job" wizard: basics, requirements, schedule, payment,
/// location and contact/safety, with a review summary before publishing.
class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  static const List<String> _stepTitles = <String>[
    'Job basics',
    'Requirements',
    'Schedule',
    'Payment',
    'Location',
    'Contact & safety',
  ];

  int _step = 0;
  JobDraft _draft = const JobDraft();
  bool _busy = false;

  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _experience = TextEditingController();
  final TextEditingController _skill = TextEditingController();
  final List<String> _skills = <String>[];
  final TextEditingController _pay = TextEditingController();
  final TextEditingController _overtime = TextEditingController();
  final TextEditingController _travel = TextEditingController();
  final TextEditingController _food = TextEditingController();
  final TextEditingController _area = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  final TextEditingController _safety = TextEditingController();
  final TextEditingController _physical = TextEditingController();
  final TextEditingController _dress = TextEditingController();
  final TextEditingController _emergency = TextEditingController();

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _controllers => <TextEditingController>[
    _title,
    _description,
    _experience,
    _skill,
    _pay,
    _overtime,
    _travel,
    _food,
    _area,
    _address,
    _contact,
    _safety,
    _physical,
    _dress,
    _emergency,
  ];

  void _update(JobDraft next) => setState(() => _draft = next);

  void _addSkill(String value) {
    final String skill = value.trim();
    if (skill.isEmpty ||
        _skills.any((String s) => s.toLowerCase() == skill.toLowerCase())) {
      return;
    }
    setState(() {
      _skills.add(skill);
      _skill.clear();
    });
  }

  bool _validateStep() {
    switch (_step) {
      case 0:
        if (_title.text.trim().isEmpty) {
          _toast('Enter a job title');
          return false;
        }
        if (_draft.category == null) {
          _toast('Select a category');
          return false;
        }
        if (_description.text.trim().length < 20) {
          _toast('Describe the work in at least 20 characters');
          return false;
        }
        return true;
      case 1:
        if (_draft.workersNeeded < 1) {
          _toast('At least one worker is required');
          return false;
        }
        return true;
      case 2:
        if (_draft.date == null) {
          _toast('Choose a work date');
          return false;
        }
        if (_draft.startTime == null ||
            _draft.endTime == null ||
            _draft.reportTime == null) {
          _toast('Set the shift and report times');
          return false;
        }
        if (_draft.isRecurring && _draft.weekdays.isEmpty) {
          _toast('Select at least one weekday for a recurring job');
          return false;
        }
        return true;
      case 3:
        if (int.tryParse(_pay.text) == null) {
          _toast('Enter the pay amount');
          return false;
        }
        return true;
      case 4:
        if (_area.text.trim().length < 3) {
          _toast('Enter the area or city');
          return false;
        }
        if (_address.text.trim().length < 5) {
          _toast('Enter the full address');
          return false;
        }
        return true;
      case 5:
        return true;
      default:
        return true;
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _next() {
    if (!_validateStep()) return;
    _collect();
    if (_step < _stepTitles.length - 1) {
      setState(() => _step++);
    } else {
      _publish();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  void _collect() {
    _update(
      _draft.copyWith(
        title: _title.text.trim(),
        description: _description.text.trim(),
        experience: _experience.text.trim(),
        skills: List<String>.of(_skills),
        pay: int.tryParse(_pay.text),
        overtimeRate: int.tryParse(_overtime.text),
        travelAllowance: int.tryParse(_travel.text) ?? 0,
        foodAllowance: int.tryParse(_food.text) ?? 0,
        area: _area.text.trim(),
        address: _address.text.trim(),
        contactPerson: _contact.text.trim(),
        safetyInfo: _safety.text.trim(),
        physicalRequirement: _physical.text.trim(),
        dressCode: _dress.text.trim(),
        emergencyContact: _emergency.text.trim(),
      ),
    );
  }

  Future<void> _publish() async {
    _collect();
    setState(() => _busy = true);
    final GiverProvider giver = context.read<GiverProvider>();
    try {
      final Job job = await giver.publishDraft(
        _draft,
        publishImmediately: true,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await showSuccessDialog(
        context,
        title: 'Job published',
        message: '"${job.title}" is now visible to workers near ${job.area}.',
        primaryLabel: 'View my jobs',
        onPrimary: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      );
    } on ApiException catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(failure.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('Could not publish the job. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return AppScaffold(
      appBar: AppTopBar(
        title: 'Step ${_step + 1} of ${_stepTitles.length}',
        onBack: _back,
        actions: <Widget>[
          if (_step > 0)
            TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Start over'),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: <Widget>[
          _StepIndicator(current: _step, titles: _stepTitles),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.screen,
                AppSpacing.xl,
              ),
              children: <Widget>[
                Text(_stepTitles[_step], style: texts.headline),
                const SizedBox(height: AppSpacing.xs),
                Text(_stepHint(_step), style: texts.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                _buildStep(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                if (_step > 0) ...<Widget>[
                  Expanded(
                    child: SecondaryButton(
                      label: 'Back',
                      icon: Icons.arrow_back_rounded,
                      onPressed: _busy ? null : _back,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: _step == _stepTitles.length - 1
                        ? 'Publish job'
                        : 'Continue',
                    icon: _step == _stepTitles.length - 1
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    loading: _busy,
                    onPressed: _busy ? null : _next,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stepHint(int step) {
    switch (step) {
      case 0:
        return 'Tell workers what the job involves.';
      case 1:
        return 'How many workers do you need and what should they know?';
      case 2:
        return 'Set the date, shift and reporting time.';
      case 3:
        return 'Decide the pay, allowances and payment method.';
      case 4:
        return 'Where should workers report?';
      default:
        return 'Add a contact person and safety instructions.';
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _basicsStep();
      case 1:
        return _requirementsStep();
      case 2:
        return _scheduleStep();
      case 3:
        return _paymentStep();
      case 4:
        return _locationStep();
      default:
        return _contactStep();
    }
  }

  Widget _basicsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const RequiredLabel(text: 'Job title'),
        AppTextField(
          controller: _title,
          hint: 'e.g. Packing helper for evening shift',
          prefixIcon: Icons.badge_outlined,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Category'),
        ChipWrap(
          children: JobCategory.values
              .map(
                (JobCategory category) => SelectableChip(
                  label: category.label,
                  icon: category.icon,
                  selected: _draft.category == category,
                  onTap: () => _update(_draft.copyWith(category: category)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Description'),
        AppTextField(
          controller: _description,
          hint:
              'Describe the tasks, the site and anything workers should bring',
          maxLines: 5,
          minLines: 4,
        ),
      ],
    );
  }

  Widget _requirementsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const RequiredLabel(text: 'Workers needed'),
        Row(
          children: <Widget>[
            AppIconButton(
              icon: Icons.remove_rounded,
              tooltip: 'Decrease',
              onPressed: _draft.workersNeeded <= 1
                  ? null
                  : () => _update(
                      _draft.copyWith(workersNeeded: _draft.workersNeeded - 1),
                    ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                '${_draft.workersNeeded}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline,
              ),
            ),
            AppIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Increase',
              onPressed: _draft.workersNeeded >= 50
                  ? null
                  : () => _update(
                      _draft.copyWith(workersNeeded: _draft.workersNeeded + 1),
                    ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Preferred skills', optional: true),
        AppTextField(
          controller: _skill,
          hint: 'Type a skill and press add',
          prefixIcon: Icons.handyman_outlined,
          onSubmitted: _addSkill,
          suffixIcon: IconButton(
            onPressed: () => _addSkill(_skill.text),
            icon: const Icon(Icons.add_circle_rounded),
            tooltip: 'Add skill',
          ),
        ),
        if (_skills.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          ChipWrap(
            children: _skills
                .map(
                  (String skill) => InputChip(
                    label: Text(skill),
                    onDeleted: () => setState(() => _skills.remove(skill)),
                    deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Experience required', optional: true),
        AppTextField(
          controller: _experience,
          hint: 'e.g. 1+ year in packing or warehouse work',
          prefixIcon: Icons.workspace_premium_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        const InfoBanner(
          message:
              'Workers with matching skills are notified first, so keep the requirement list short.',
          icon: Icons.lightbulb_outline_rounded,
        ),
      ],
    );
  }

  Widget _scheduleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchListTile.adaptive(
          value: _draft.isRecurring,
          onChanged: (bool value) =>
              _update(_draft.copyWith(isRecurring: value)),
          title: const Text('Recurring job'),
          subtitle: const Text('Repeats on the weekdays you choose'),
          contentPadding: EdgeInsets.zero,
        ),
        const RequiredLabel(text: 'Work date'),
        InkWell(
          onTap: () async {
            final DateTime now = DateTime.now();
            final DateTime firstDate = now.add(const Duration(days: 1));
            final DateTime lastDate = now.add(const Duration(days: 180));
            // A wizard left open can hold a date that has since fallen outside
            // the window, and showDatePicker asserts on an out of range
            // initialDate instead of opening.
            final DateTime seed = _draft.date ?? firstDate;
            final DateTime initialDate = seed.isBefore(firstDate)
                ? firstDate
                : (seed.isAfter(lastDate) ? lastDate : seed);
            final DateTime? picked = await showDatePicker(
              context: context,
              firstDate: firstDate,
              lastDate: lastDate,
              initialDate: initialDate,
            );
            if (picked != null && mounted) {
              _update(_draft.copyWith(date: picked));
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InputDecorator(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.calendar_today_rounded),
              labelText: 'Date',
            ),
            child: Text(
              _draft.date == null
                  ? 'Select a date'
                  : AppFormat.weekdayDate(_draft.date!),
            ),
          ),
        ),
        if (_draft.isRecurring) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          const RequiredLabel(text: 'Weekdays'),
          ChipWrap(
            children: WorkDay.values
                .map(
                  (WorkDay day) => SelectableChip(
                    label: day.shortLabel,
                    selected: _draft.weekdays.contains(day),
                    onTap: () {
                      final List<WorkDay> next = <WorkDay>[..._draft.weekdays];
                      if (!next.remove(day)) next.add(day);
                      _update(_draft.copyWith(weekdays: next));
                    },
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: _TimeField(
                label: 'Shift starts',
                value: _draft.startTime,
                onPicked: (String value) =>
                    _update(_draft.copyWith(startTime: value)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TimeField(
                label: 'Shift ends',
                value: _draft.endTime,
                onPicked: (String value) =>
                    _update(_draft.copyWith(endTime: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _TimeField(
          label: 'Report time',
          value: _draft.reportTime,
          onPicked: (String value) =>
              _update(_draft.copyWith(reportTime: value)),
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Break duration (minutes)'),
        ChipWrap(
          children: <int>[15, 30, 45, 60]
              .map(
                (int minutes) => SelectableChip(
                  label: '$minutes min',
                  selected: _draft.breakMinutes == minutes,
                  onTap: () => _update(_draft.copyWith(breakMinutes: minutes)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _paymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const RequiredLabel(text: 'Pay type'),
        ChipWrap(
          children: PayType.values
              .map(
                (PayType type) => SelectableChip(
                  label: type.label,
                  selected: _draft.payType == type,
                  onTap: () => _update(_draft.copyWith(payType: type)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Pay amount'),
        AppTextField(
          controller: _pay,
          hint: 'e.g. 650',
          prefixIcon: Icons.currency_rupee_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            DigitsOnlyFormatter(maxLength: 5),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Overtime rate (per hour)', optional: true),
        AppTextField(
          controller: _overtime,
          hint: 'e.g. 100',
          prefixIcon: Icons.more_time_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            DigitsOnlyFormatter(maxLength: 4),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const RequiredLabel(text: 'Travel', optional: true),
                  AppTextField(
                    controller: _travel,
                    hint: '0',
                    prefixIcon: Icons.directions_bus_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      DigitsOnlyFormatter(maxLength: 4),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const RequiredLabel(text: 'Food', optional: true),
                  AppTextField(
                    controller: _food,
                    hint: '0',
                    prefixIcon: Icons.restaurant_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      DigitsOnlyFormatter(maxLength: 4),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Payment method'),
        ChipWrap(
          children: PaymentMethod.values
              .map(
                (PaymentMethod method) => SelectableChip(
                  label: method.label,
                  icon: method.icon,
                  selected: _draft.paymentMethod == method,
                  onTap: () => _update(_draft.copyWith(paymentMethod: method)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        _DraftSummary(draft: _draft),
      ],
    );
  }

  Widget _locationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const RequiredLabel(text: 'Workplace type'),
        ChipWrap(
          children: WorkplaceType.values
              .map(
                (WorkplaceType type) => SelectableChip(
                  label: type.label,
                  selected: _draft.workplaceType == type,
                  onTap: () => _update(_draft.copyWith(workplaceType: type)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Area or city'),
        AppTextField(
          controller: _area,
          hint: 'e.g. Koramangala, Bengaluru',
          prefixIcon: Icons.location_city_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Full address'),
        AppTextField(
          controller: _address,
          hint: 'Building, street, landmark',
          prefixIcon: Icons.map_outlined,
          maxLines: 2,
          minLines: 2,
        ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile.adaptive(
          value: _draft.locationVisible,
          onChanged: (bool value) =>
              _update(_draft.copyWith(locationVisible: value)),
          title: const Text('Show exact address to workers'),
          subtitle: const Text('Turn off to reveal it only after confirmation'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _contactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const RequiredLabel(text: 'Contact person', optional: true),
        AppTextField(
          controller: _contact,
          hint: 'Name of the person on site',
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Safety instructions', optional: true),
        AppTextField(
          controller: _safety,
          hint: 'PPE provided, first-aid location, entry rules',
          prefixIcon: Icons.health_and_safety_rounded,
          maxLines: 3,
          minLines: 2,
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Physical requirements', optional: true),
        AppTextField(
          controller: _physical,
          hint: 'e.g. Ability to lift 15 kg',
          prefixIcon: Icons.accessibility_new_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Dress code', optional: true),
        AppTextField(
          controller: _dress,
          hint: 'e.g. Navy blue T-shirt, jeans',
          prefixIcon: Icons.checkroom_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        const RequiredLabel(text: 'Emergency contact', optional: true),
        AppTextField(
          controller: _emergency,
          hint: 'Name and phone number',
          prefixIcon: Icons.emergency_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile.adaptive(
          value: _draft.vehicleRequired,
          onChanged: (bool value) =>
              _update(_draft.copyWith(vehicleRequired: value)),
          title: const Text('Two-wheeler required'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        const SectionHeader(title: 'Review before publishing'),
        const SizedBox(height: AppSpacing.xs),
        _DraftSummary(draft: _draft),
        if (!_draft.isReadyToPublish) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          const InfoBanner(
            message:
                'Some required fields are still empty. Use Back to complete them.',
            icon: Icons.info_outline_rounded,
            color: AppColors.warning,
          ),
        ],
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onPicked;

  static const List<String> _slots = <String>[
    '6:00 AM',
    '7:00 AM',
    '8:00 AM',
    '8:45 AM',
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
    '9:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      readOnly: true,
      label: label,
      hint: value ?? 'Select',
      prefixIcon: Icons.schedule_rounded,
      onTap: () async {
        final String? picked = await showAppSheet<String>(
          context: context,
          title: label,
          child: SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: <Widget>[
                for (final String slot in _slots)
                  ListTile(
                    title: Text(slot),
                    trailing: value == slot
                        ? Icon(Icons.check_rounded, color: context.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(slot),
                  ),
              ],
            ),
          ),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }
}

class _DraftSummary extends StatelessWidget {
  const _DraftSummary({required this.draft});

  final JobDraft draft;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceMuted,
      child: Column(
        children: <Widget>[
          InfoRow(
            label: 'Title',
            value: draft.title.isEmpty ? 'Not set' : draft.title,
            icon: Icons.badge_outlined,
            bold: true,
          ),
          InfoRow(
            label: 'Category',
            value: draft.category?.label ?? 'Not set',
            icon: Icons.category_outlined,
          ),
          InfoRow(
            label: 'Workers',
            value: '${draft.workersNeeded}',
            icon: Icons.groups_rounded,
          ),
          InfoRow(
            label: 'Date',
            value: draft.date == null
                ? 'Not set'
                : AppFormat.weekdayDate(draft.date!),
            icon: Icons.calendar_today_rounded,
          ),
          InfoRow(
            label: 'Shift',
            value: draft.startTime == null
                ? 'Not set'
                : '${draft.startTime} – ${draft.endTime}',
            icon: Icons.schedule_rounded,
          ),
          InfoRow(
            label: 'Pay',
            value: draft.pay == null ? 'Not set' : AppFormat.money(draft.pay!),
            icon: Icons.currency_rupee_rounded,
            bold: true,
          ),
          InfoRow(
            label: 'Allowances',
            value:
                '${AppFormat.money(draft.travelAllowance + draft.foodAllowance)} total',
            icon: Icons.card_giftcard_rounded,
          ),
          InfoRow(
            label: 'Area',
            value: draft.area.isEmpty ? 'Not set' : draft.area,
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.titles});

  final int current;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            children: <Widget>[
              for (int index = 0; index < titles.length; index++) ...<Widget>[
                Expanded(
                  child: AnimatedContainer(
                    duration: AppDurations.normal,
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= current
                          ? context.primary
                          : AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                if (index != titles.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.screen),
              child: StatusChip.neutral(
                'Step ${current + 1}/${titles.length}',
                icon: Icons.flag_rounded,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.screen),
              child: Text(
                titles[current],
                style: Theme.of(context).textTheme.caption,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
