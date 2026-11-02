import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../state/auth_provider.dart';

/// Profile setup after registration: photo, contact details,
/// skills and location. Saves into the session and enters the app shell.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, this.isEdit = false});

  final bool isEdit;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _area;
  final TextEditingController _skill = TextEditingController();

  final List<String> _skills = <String>[];
  final List<String> _suggestions = <String>[
    'Packing',
    'Loading',
    'Driving',
    'Cleaning',
    'Security',
    'Retail billing',
    'Data entry',
    'Teaching',
    'Event setup',
    'Cooking',
  ];
  bool _photoAdded = false;

  @override
  void initState() {
    super.initState();
    final dynamic user = context.read<AuthProvider>().user;
    final String name = user?.name as String? ?? '';
    _name = TextEditingController(text: name);
    _phone = TextEditingController(text: user?.phone as String? ?? '');
    _email = TextEditingController(text: user?.email as String? ?? '');
    _area = TextEditingController(text: user?.area as String? ?? '');
    final dynamic existing = user?.skills;
    if (existing is List) _skills.addAll(existing.cast<String>());
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _area.dispose();
    _skill.dispose();
    super.dispose();
  }

  void _addSkill(String value) {
    final String skill = value.trim();
    if (skill.isEmpty) return;
    if (_skills.any((String s) => s.toLowerCase() == skill.toLowerCase())) {
      return;
    }
    setState(() {
      _skills.add(skill);
      _skill.clear();
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AuthProvider auth = context.read<AuthProvider>();
    final bool ok = await auth.saveProfile(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      area: _area.text.trim(),
      skills: _skills,
    );
    if (!ok || !mounted) return;
    if (widget.isEdit) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final AuthProvider auth = context.watch<AuthProvider>();
    final UserRole role = auth.role;

    return AppScaffold(
      appBar: AppTopBar(
        title: widget.isEdit ? 'Edit profile' : 'Set up your profile',
        showBack: widget.isEdit,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          children: <Widget>[
            _PhotoPicker(
              name: _name.text.trim().isEmpty ? 'You' : _name.text.trim(),
              added: _photoAdded,
              onAdd: () => setState(() => _photoAdded = true),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (auth.error != null) ...<Widget>[
              ErrorBanner(message: auth.error!, onDismiss: auth.clearError),
              const SizedBox(height: AppSpacing.md),
            ],
            const RequiredLabel(text: 'Full name'),
            AppTextField(
              controller: _name,
              label: 'Full name',
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              enabled: !auth.busy,
              validator: Validators.fullName,
            ),
            const SizedBox(height: AppSpacing.md),
            const RequiredLabel(text: 'Mobile number'),
            AppTextField(
              controller: _phone,
              label: 'Mobile number',
              prefixIcon: Icons.phone_iphone_rounded,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: <TextInputFormatter>[
                DigitsOnlyFormatter(maxLength: 10),
              ],
              enabled: !auth.busy,
              validator: Validators.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            const RequiredLabel(text: 'Email address', optional: true),
            AppTextField(
              controller: _email,
              label: 'Email address',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !auth.busy,
              validator: Validators.optionalEmail,
            ),
            const SizedBox(height: AppSpacing.md),
            RequiredLabel(
              text: role == UserRole.worker ? 'Area / city' : 'Business area',
            ),
            AppTextField(
              controller: _area,
              label: role == UserRole.worker ? 'Area or city' : 'Business area',
              hint: 'e.g. Koramangala, Bengaluru',
              prefixIcon: Icons.location_on_outlined,
              textInputAction: TextInputAction.next,
              enabled: !auth.busy,
              validator: (String? value) =>
                  Validators.minLength(value, 3, field: 'Location'),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (role == UserRole.worker) ...<Widget>[
              const RequiredLabel(text: 'Skills'),
              AppTextField(
                controller: _skill,
                label: 'Add a skill',
                hint: 'Type and press add',
                prefixIcon: Icons.handyman_outlined,
                textInputAction: TextInputAction.done,
                enabled: !auth.busy,
                onSubmitted: _addSkill,
                suffixIcon: IconButton(
                  onPressed: () => _addSkill(_skill.text),
                  icon: const Icon(Icons.add_circle_rounded),
                  tooltip: 'Add skill',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_skills.isNotEmpty)
                ChipWrap(
                  children: _skills
                      .map(
                        (String skill) => _RemovableSkill(
                          label: skill,
                          onRemove: () => setState(() => _skills.remove(skill)),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text('Popular skills', style: texts.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              ChipWrap(
                children: _suggestions
                    .map(
                      (String skill) => SelectableChip(
                        label: skill,
                        selected: _skills.contains(skill),
                        onTap: () => _skills.contains(skill)
                            ? setState(() => _skills.remove(skill))
                            : _addSkill(skill),
                      ),
                    )
                    .toList(),
              ),
            ] else ...<Widget>[
              const RequiredLabel(text: 'Organisation or business name'),
              const InfoBanner(
                message:
                    'Work givers are verified against the organisation name and GST details before '
                    'the first payout.',
                icon: Icons.verified_user_rounded,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: widget.isEdit ? 'Save changes' : 'Save and continue',
              loading: auth.busy,
              icon: widget.isEdit ? Icons.save_rounded : Icons.check_rounded,
              onPressed: auth.busy ? null : _save,
            ),
            if (!widget.isEdit) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You can update these details any time from your profile.',
                textAlign: TextAlign.center,
                style: texts.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.name,
    required this.added,
    required this.onAdd,
  });

  final String name;
  final bool added;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        ProfileAvatar(name: name, size: 84, initials: added ? 'RK' : null),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Profile photo', style: texts.labelLarge),
              const SizedBox(height: 2),
              Text(
                added
                    ? 'Photo added. You can change it later.'
                    : 'Add a clear photo so work givers recognise you.',
                style: texts.caption,
              ),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: Icon(
                  added ? Icons.refresh_rounded : Icons.camera_alt_rounded,
                  size: 17,
                ),
                label: Text(added ? 'Change' : 'Add photo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RemovableSkill extends StatelessWidget {
  const _RemovableSkill({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      backgroundColor: context.primaryTint,
      side: BorderSide(color: context.primary.withValues(alpha: 0.25)),
      labelStyle: Theme.of(context).textTheme.labelLarge,
    );
  }
}
