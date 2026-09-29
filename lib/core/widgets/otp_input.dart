import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../utils/context_extensions.dart';

/// Six-box OTP entry with auto-focus, paste support and animated focus rings.
///
/// A single transparent [TextField] sits above the boxes so typing, pasting and
/// hardware keyboards behave natively while the boxes stay fully custom.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
    this.errorText,
    this.enabled = true,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;
  final String? errorText;
  final bool enabled;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = FocusNode();
  String _value = '';
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestFocus());
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocus() {
    if (!mounted) return;
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  void _requestFocus() {
    if (!mounted) return;
    _focusNode.requestFocus();
  }

  void _handleChange(String value) {
    final String cleaned = value.replaceAll(RegExp(r'\D'), '');
    final String digits = cleaned.length > widget.length
        ? cleaned.substring(0, widget.length)
        : cleaned;
    if (digits == _value) return;
    setState(() => _value = digits);
    widget.onChanged?.call(digits);
    if (digits.length == widget.length) {
      _focusNode.unfocus();
      widget.onCompleted?.call(digits);
    }
  }

  void _clear() {
    _controller.clear();
    setState(() => _value = '');
    widget.onChanged?.call('');
    _requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;
    final Color activeColor = hasError ? AppColors.error : scheme.primary;

    final List<Widget> boxes = <Widget>[];
    for (int i = 0; i < widget.length; i++) {
      final bool filled = i < _value.length;
      final bool isNext = _hasFocus && i == _value.length;
      boxes.add(
        Expanded(
          child: AnimatedContainer(
            duration: AppDurations.fast,
            margin: EdgeInsets.only(
              right: i == widget.length - 1 ? 0 : AppSpacing.xs,
            ),
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : (filled || isNext ? activeColor : AppColors.border),
                width: (filled || isNext) ? 1.6 : 1.1,
              ),
              boxShadow: isNext ? AppShadows.subtle : null,
            ),
            alignment: Alignment.center,
            child: Text(
              filled ? _value[i] : '',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Semantics(
                textField: true,
                label: 'Enter ${widget.length} digit verification code',
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Row(children: boxes),
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: widget.enabled,
                          autofocus: false,
                          showCursor: false,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          textAlign: TextAlign.center,
                          enableInteractiveSelection: false,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(widget.length),
                          ],
                          onChanged: _handleChange,
                          onSubmitted: (_) => _focusNode.unfocus(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_value.isNotEmpty)
              IconButton(
                onPressed: _clear,
                tooltip: 'Clear code',
                icon: const Icon(Icons.close_rounded, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: context.texts.bodyMedium!.color,
                ),
              ),
          ],
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                size: 15,
                color: AppColors.error,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: Theme.of(context).textTheme.caption?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
