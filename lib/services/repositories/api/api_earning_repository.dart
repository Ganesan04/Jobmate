import '../../../models/earning.dart';
import '../../../models/enums.dart';
import '../../api/api_client.dart';
import '../../api/envelope.dart';
import '../../api/json.dart';
import '../../api/mappers.dart';
import '../../api/wire.dart';
import '../earning_repository.dart';
import 'api_query.dart';

/// [EarningRepository] backed by the worker wallet and payment endpoints.
class ApiEarningRepository implements EarningRepository {
  ApiEarningRepository(this._api);

  final ApiClient _api;

  /// The wallet totals change whenever a payment lands, so they are read once
  /// per load rather than on every call.
  Map<String, dynamic>? _wallet;

  @override
  Future<List<Earning>> allEarnings(String workerId) => _earnings();

  @override
  Future<List<Earning>> earningsByStatus(
    String workerId,
    PaymentStatus? status,
  ) => _earnings(
    query: <String, Object?>{
      if (status != null) 'Statuses': <String>[wirePaymentStatus(status)],
    },
  );

  @override
  Future<int> totalEarned(String workerId) async =>
      (await _walletTotals()).integer('totalEarned');

  @override
  Future<int> pendingAmount(String workerId) async =>
      (await _walletTotals()).integer('pendingAmount');

  @override
  Future<List<EarningSummary>> monthlySummary(String workerId) async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/worker/earnings/summary',
    );
    return body.dataList(Mappers.earningSummary);
  }

  @override
  Future<PaymentReceipt> releasePayment({
    required String jobId,
    required String workerId,
    required int basePay,
    required int overtime,
    required PaymentMethod method,
    required String idempotencyKey,
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/jobs/$jobId/payments/$workerId',
      body: <String, dynamic>{
        'basePay': basePay,
        'overtime': overtime,
        'method': wirePaymentMethod(method),
        'idempotencyKey': idempotencyKey,
      },
    );
    // The wallet moved, so the cached totals are stale.
    _wallet = null;
    return Mappers.paymentReceipt(body.dataMap());
  }

  @override
  Future<PaymentReceipt> confirmPayment(
    String paymentId, {
    String transactionReference = '',
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/payments/$paymentId/confirm',
      body: jsonBody(<String, dynamic>{
        'transactionReference': transactionReference.trim(),
      }, nulls: <String>{'transactionReference'}),
    );
    return Mappers.paymentReceipt(body.dataMap());
  }

  @override
  Future<List<PaymentReceipt>> payments() async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/payments',
      query: pageArgs(),
    );
    return body.dataList(Mappers.paymentReceipt);
  }

  // ------------------------------------------------------------- internals

  Future<List<Earning>> _earnings({
    Map<String, Object?> query = const <String, Object?>{},
  }) async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/worker/earnings',
      query: <String, Object?>{...pageArgs(), ...query},
    );
    return body.dataList(Mappers.earning);
  }

  Future<Map<String, dynamic>> _walletTotals() async {
    final Map<String, dynamic>? cached = _wallet;
    if (cached != null) return cached;
    final Map<String, dynamic> body = await _api.get('/api/v1/worker/wallet');
    return _wallet = body.dataMap();
  }
}
