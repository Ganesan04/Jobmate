import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../utils/context_extensions.dart';

/// Confirmation dialog used before destructive or irreversible actions.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData icon = Icons.help_outline_rounded,
}) async {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final Color tint = destructive ? scheme.error : scheme.primary;
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Color.lerp(tint, Colors.white, 0.88),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: tint),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? scheme.error : scheme.primary,
              minimumSize: const Size(96, 44),
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Single field prompt used where a form would be overkill (document names,
/// cancellation reasons, short notes).
Future<String?> showInputDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String label,
  String initialValue = '',
  String hint = '',
  String confirmLabel = 'Save',
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  int? maxLength,
  IconData icon = Icons.edit_rounded,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) => _InputDialog(
      title: title,
      message: message,
      label: label,
      initialValue: initialValue,
      hint: hint,
      confirmLabel: confirmLabel,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      icon: icon,
    ),
  );
}

class _InputDialog extends StatefulWidget {
  const _InputDialog({
    required this.title,
    required this.message,
    required this.label,
    required this.initialValue,
    required this.hint,
    required this.confirmLabel,
    required this.keyboardType,
    required this.maxLines,
    required this.maxLength,
    required this.icon,
  });

  final String title;
  final String? message;
  final String label;
  final String initialValue;
  final String hint;
  final String confirmLabel;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final IconData icon;

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _controller.text.trim();
    Navigator.of(context).pop(value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    final bool multiline = widget.maxLines > 1;
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Color.lerp(
                Theme.of(context).colorScheme.primary,
                Colors.white,
                0.88,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.message case final String message) ...<Widget>[
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: multiline && widget.keyboardType == TextInputType.text
                ? TextInputType.multiline
                : widget.keyboardType,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            textInputAction: multiline
                ? TextInputAction.newline
                : TextInputAction.done,
            onSubmitted: multiline ? null : (_) => _submit(),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint.isEmpty ? null : widget.hint,
              counterText: '',
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Bottom sheet shell: rounded top, drag handle, scrollable body.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
  String? title,
  String? subtitle,
  Widget? trailingAction,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: context.surface,
    builder: (BuildContext sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              if (title != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: Theme.of(
                                sheetContext,
                              ).textTheme.titleMedium,
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                style: Theme.of(
                                  sheetContext,
                                ).textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ),
                      if (trailingAction case final Widget action) action,
                    ],
                  ),
                ),
              ],
              Flexible(child: child),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      );
    },
  );
}

/// Success feedback dialog used after publishing, applying, paying, etc.
Future<void> showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  String primaryLabel = 'Done',
  VoidCallback? onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.6, end: 1),
              duration: AppDurations.slow,
              curve: Curves.easeOutBack,
              builder: (BuildContext context, double value, Widget? child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Color.lerp(scheme.primary, Colors.white, 0.86),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 40,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: <Widget>[
          if (secondaryLabel case final String secondary)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onSecondary?.call();
              },
              child: Text(secondary),
            ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onPrimary?.call();
            },
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            child: Text(primaryLabel),
          ),
        ],
      );
    },
  );
}

/// Inline error banner (auth errors, form-level problems).
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            size: 19,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.caption?.copyWith(
                color: const Color(0xFFB91C1C),
                fontSize: 12.5,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Success / info banner (OTP sent, saved, etc).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color = AppColors.info,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.white, 0.88),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.caption?.copyWith(
                color: Color.lerp(color, Colors.black, 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
