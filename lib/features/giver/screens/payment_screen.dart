import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/earning.dart';
import '../../../models/enums.dart';
import '../../../navigation/app_router.dart';
import '../../../state/giver_provider.dart';

/// Release payment to one selected worker: UPI / bank details, overtime and
/// platform fee, then a receipt.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.jobId,
    required this.workerId,
    required this.workerName,
  });

  final String jobId;
  final String workerId;
  final String workerName;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const int _platformFeePercent = 5;

  final TextEditingController _basePay = TextEditingController();
  final TextEditingController _overtime = TextEditingController();
  PaymentMethod _method = PaymentMethod.upi;
  bool _busy = false;
  PaymentReceipt? _receipt;

  int get _base => int.tryParse(_basePay.text) ?? 0;
  int get _overtimeAmount => int.tryParse(_overtime.text) ?? 0;
  int get _fee =>
      ((_base + _overtimeAmount) * _platformFeePercent / 100).round();

  @override
  void dispose() {
    _basePay.dispose();
    _overtime.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    FocusScope.of(context).unfocus();
    if (_base <= 0) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the base pay for this worker')),
      );
      return;
    }
    setState(() => _busy = true);
    final PaymentReceipt receipt = await context.read<GiverProvider>().pay(
      jobId: widget.jobId,
      workerId: widget.workerId,
      basePay: _base,
      overtime: _overtimeAmount,
      method: _method,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _receipt = receipt;
    });
    await showSuccessDialog(
      context,
      title: 'Payment released',
      message:
          '${AppFormat.money(receipt.amount)} paid to ${widget.workerName}.',
      primaryLabel: 'Rate worker',
      onPrimary: () {
        Navigator.of(context).pop();
        AppRouter.pushReplacement(
          context,
          AppRoutes.rateWorker,
          arguments: <String, dynamic>{
            'jobId': widget.jobId,
            'workerId': widget.workerId,
            'workerName': widget.workerName,
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final PaymentReceipt? receipt = _receipt;

    return AppScaffold(
      appBar: const AppTopBar(title: 'Release payment'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        children: <Widget>[
          AppCard(
            child: Row(
              children: <Widget>[
                ProfileAvatar(name: widget.workerName, size: 46),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(widget.workerName, style: texts.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Payment for the completed shift',
                        style: texts.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const RequiredLabel(text: 'Base pay'),
          AppTextField(
            controller: _basePay,
            hint: 'e.g. 650',
            prefixIcon: Icons.currency_rupee_rounded,
            keyboardType: TextInputType.number,
            enabled: receipt == null && !_busy,
            inputFormatters: <TextInputFormatter>[
              DigitsOnlyFormatter(maxLength: 5),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          const RequiredLabel(text: 'Overtime', optional: true),
          AppTextField(
            controller: _overtime,
            hint: 'e.g. 100',
            prefixIcon: Icons.more_time_rounded,
            keyboardType: TextInputType.number,
            enabled: receipt == null && !_busy,
            inputFormatters: <TextInputFormatter>[
              DigitsOnlyFormatter(maxLength: 5),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          const RequiredLabel(text: 'Payment method'),
          ChipWrap(
            children: PaymentMethod.values
                .map(
                  (PaymentMethod method) => SelectableChip(
                    label: method.label,
                    icon: method.icon,
                    selected: _method == method,
                    onTap: receipt == null
                        ? () => setState(() => _method = method)
                        : () {},
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            color: AppColors.surfaceMuted,
            child: Column(
              children: <Widget>[
                InfoRow(
                  label: 'Base pay',
                  value: AppFormat.money(_base),
                  icon: Icons.payments_rounded,
                ),
                if (_overtimeAmount > 0)
                  InfoRow(
                    label: 'Overtime',
                    value: AppFormat.money(_overtimeAmount),
                    icon: Icons.more_time_rounded,
                  ),
                InfoRow(
                  label: 'Platform fee (est. $_platformFeePercent%)',
                  value: '- ${AppFormat.money(_fee)}',
                  icon: Icons.percent_rounded,
                ),
                const AppDivider(height: AppSpacing.sm),
                InfoRow(
                  label: 'Total to worker (est.)',
                  value: AppFormat.money(_base + _overtimeAmount - _fee),
                  icon: Icons.account_balance_rounded,
                  bold: true,
                  valueColor: context.primary,
                ),
              ],
            ),
          ),
          if (receipt != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              color: AppColors.successSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Payment successful', style: texts.labelLarge),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InfoRow(
                    label: 'Reference',
                    value: receipt.paymentId,
                    icon: Icons.tag_rounded,
                  ),
                  InfoRow(
                    label: 'Paid at',
                    value:
                        '${AppFormat.dayMonthYear(receipt.paidAt)}, '
                        '${AppFormat.time(receipt.paidAt)}',
                    icon: Icons.schedule_rounded,
                  ),
                  InfoRow(
                    label: 'Method',
                    value: receipt.method.label,
                    icon: receipt.method.icon,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: receipt == null
          ? StickyActionBar(
              child: PrimaryButton(
                label: 'Pay ${AppFormat.money(_base + _overtimeAmount - _fee)}',
                icon: Icons.lock_rounded,
                loading: _busy,
                onPressed: _busy ? null : _pay,
              ),
            )
          : StickyActionBar(
              child: PrimaryButton(
                label: 'Rate this worker',
                icon: Icons.star_rounded,
                onPressed: () => AppRouter.pushReplacement(
                  context,
                  AppRoutes.rateWorker,
                  arguments: <String, dynamic>{
                    'jobId': widget.jobId,
                    'workerId': widget.workerId,
                    'workerName': widget.workerName,
                  },
                ),
              ),
            ),
    );
  }
}
