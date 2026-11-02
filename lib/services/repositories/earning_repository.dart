import '../../models/earning.dart';
import '../../models/enums.dart';

/// Worker wallet data and payment release.
///
/// Implemented against `/api/v1/worker/earnings*`, `/api/v1/worker/wallet` and
/// `POST /api/v1/jobs/{jobId}/payments/{workerId}`.
abstract class EarningRepository {
  Future<List<Earning>> allEarnings(String workerId);

  Future<List<Earning>> earningsByStatus(
    String workerId,
    PaymentStatus? status,
  );

  Future<int> totalEarned(String workerId);

  Future<int> pendingAmount(String workerId);

  /// Month label -> totals, newest month first.
  Future<List<EarningSummary>> monthlySummary(String workerId);

  /// Releases pay for one confirmed booking.
  ///
  /// The backend credits the worker's wallet as part of the same call, so this
  /// replaces the old "record an earning locally" step. [idempotencyKey] makes
  /// a repeated tap safe: the same key always returns the first receipt.
  Future<PaymentReceipt> releasePayment({
    required String jobId,
    required String workerId,
    required int basePay,
    required int overtime,
    required PaymentMethod method,
    required String idempotencyKey,
  });

  /// Settles a payment the gateway left in flight.
  Future<PaymentReceipt> confirmPayment(
    String paymentId, {
    String transactionReference,
  });

  /// The caller's own payments, newest first.
  Future<List<PaymentReceipt>> payments();
}
