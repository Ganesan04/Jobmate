import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// Standard rounded form field with label, hint, icon, visibility toggle and
/// optional required marker. Validation errors come from the parent form.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.errorText,
    this.semanticLabel,
    this.showCounter = false,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? errorText;
  final String? semanticLabel;
  final bool showCounter;
  final TextCapitalization textCapitalization;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;
    final Widget? trailing = widget.obscure
        ? IconButton(
            onPressed: () => setState(() => _obscured = !_obscured),
            icon: Icon(
              _obscured
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 20,
            ),
            tooltip: _obscured ? 'Show password' : 'Hide password',
          )
        : widget.suffixIcon;

    return Semantics(
      textField: true,
      label: widget.semanticLabel ?? widget.label,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        initialValue: null,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: _obscured,
        maxLines: widget.obscure ? 1 : widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        onChanged: widget.onChanged,
        onTap: widget.onTap,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        inputFormatters: widget.inputFormatters,
        autofocus: widget.autofocus,
        autocorrect: !widget.obscure,
        enableSuggestions: !widget.obscure,
        textCapitalization: widget.obscure
            ? TextCapitalization.none
            : widget.textCapitalization,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          helperText: widget.helper,
          helperMaxLines: 2,
          errorText: hasError ? widget.errorText : null,
          errorMaxLines: 2,
          counterText: widget.showCounter ? '' : null,
          prefixIcon: widget.prefixIcon == null
              ? null
              : Icon(widget.prefixIcon, size: 20),
          suffixIcon: trailing,
          border: hasError
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                )
              : null,
        ),
      ),
    );
  }
}

/// Wraps a field with a required asterisk and helper text.
class RequiredLabel extends StatelessWidget {
  const RequiredLabel({super.key, required this.text, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Text(
            optional ? '$text (optional)' : '$text *',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: optional ? AppColors.textSecondary : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Prevents negative / non-numeric entry in amount fields.
class DigitsOnlyFormatter extends TextInputFormatter {
  DigitsOnlyFormatter({this.maxLength});

  final int? maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String filtered = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final String limited = maxLength == null
        ? filtered
        : filtered.substring(0, filtered.length.clamp(0, maxLength!));
    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(offset: limited.length),
    );
  }
}
