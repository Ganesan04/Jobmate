import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// An in-process stand-in for the Jobmate backend.
///
/// It speaks the same HTTP contract as `swagger.json`: the same paths, the same
/// `{ success, data, message, errorCode, errors, pagination }` envelope and the
/// same status codes, including the ones that are supposed to fail. The widget
/// tests point the real [ApiClient] at this server, so `ApiClient`, the mappers
/// and every `Api*Repository` are all exercised over real sockets.
///
/// Only the endpoints the app actually calls are implemented. Anything else
/// answers 404 so a missed call surfaces immediately instead of silently
/// returning an empty list.
class FakeBackend {
  FakeBackend({this.seed = true});

  /// Whether to preload the demo dataset the flow tests navigate against.
  final bool seed;

  HttpServer? _server;
  final HttpClient _client = HttpClient();
  final Random _random = Random(7);

  /// Resolved base URL, e.g. `http://127.0.0.1:52341`.
  late final String baseUrl;

  /// Sessions keyed by access token.
  final Map<String, _Session> _sessions = <String, _Session>{};

  /// Incrementing counter used for every generated id, so ids are unique and
  /// stable within a test run.
  int _nextId = 1;

  String _id(String prefix) => '$prefix-${_nextId++}';

  // ------------------------------------------------------------ seed state

  /// Users keyed by id, in the order they were created.
  final Map<String, Map<String, dynamic>> _users =
      <String, Map<String, dynamic>>{};

  /// Phone/email -> user id, for login and OTP lookup.
  final Map<String, String> _userByLogin = <String, String>{};

  /// Access/refresh tokens -> user id.
  final Map<String, String> _userByAccess = <String, String>{};

  /// One-time codes issued by `resend-otp`, keyed by phone.
  final Map<String, String> _otpByPhone = <String, String>{};

  final Map<String, Map<String, dynamic>> _jobs = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _applications =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _assignments =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _workHistory =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _earnings =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _receipts =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _conversations =
      <String, Map<String, dynamic>>{};
  final Map<String, List<Map<String, dynamic>>> _messages =
      <String, List<Map<String, dynamic>>>{};
  final Map<String, List<Map<String, dynamic>>> _notifications =
      <String, List<Map<String, dynamic>>>{};
  final Map<String, Map<String, dynamic>> _verifications =
      <String, Map<String, dynamic>>{};
  final Map<String, List<Map<String, dynamic>>> _supportReports =
      <String, List<Map<String, dynamic>>>{};
  final Map<String, Map<String, dynamic>> _ratings =
      <String, Map<String, dynamic>>{};
  final Set<String> _savedJobKeys = <String>{};

  /// The OTP the fake issues for a phone, so tests can complete verification.
  String? issuedOtp;

  /// The four-digit code per assignment, which the API only hands to the giver.
  final Map<String, String> _checkInCodes = <String, String>{};

  /// The last rejected check-in message, handy for assertions.
  String? lastCheckInError;

  // ------------------------------------------------------------- lifecycle

  /// Starts on an ephemeral port and returns the base URL.
  static Future<FakeBackend> start({bool seed = true}) async {
    final FakeBackend backend = FakeBackend(seed: seed);
    await backend._listen();
    if (seed) backend.seedDemoData();
    return backend;
  }

  Future<void> _listen() async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    _server = server;
    baseUrl = 'http://127.0.0.1:${server.port}';
    unawaited(
      _serve(server).catchError((Object error) {
        // A handler error must fail the test loudly rather than hang it.
        throw error;
      }),
    );
  }

  Future<void> _serve(HttpServer server) async {
    await for (final HttpRequest request in server) {
      try {
        await _handle(request);
      } catch (error) {
        // Mirrors the backend's global exception envelope.
        await _write(request, 500, error: 'Fake backend error: $error');
      }
    }
  }

  /// Stops the server and releases its sockets.
  Future<void> stop() async {
    _client.close(force: true);
    await _server?.close(force: true);
    _server = null;
  }

  // ------------------------------------------------------------ seed data

  /// Accounts the flow tests sign in with.
  static const String workerPhone = '9876543210';
  static const String workerEmail = 'ravi@jobmate.in';
  static const String giverEmail = 'meera@shop.in';
  static const String secondGiverEmail = 'arjun@care.in';
  static const String password = 'jobmate123';

  /// The check-in code issued for the seeded open shift. The API only ever hands
  /// this to the employer, so a test has to read it as the giver before the
  /// worker can use it.
  String? openCheckInCode;

  String? workerId;
  String? giverId;
  String? secondGiverId;

  /// Ids of the seeded jobs, in creation order.
  final List<String> jobIds = <String>[];

  /// Preloads the demo dataset so a test can assert against a populated feed.
  ///
  /// Everything here is test-only scaffolding: `lib` ships with no seeded
  /// content, and every screen still has to cope with empty responses.
  void seedDemoData() {
    if (!seed || _users.isNotEmpty) return;

    final Map<String, dynamic> worker = _createUser(
      name: 'Ravi Kumar',
      phone: workerPhone,
      email: workerEmail,
      password: password,
      role: 'Worker',
    );
    worker
      ..['area'] = 'Koramangala'
      ..['skills'] = <String>['Packing', 'Loading']
      ..['verified'] = true
      ..['rating'] = 4.6
      ..['reviewCount'] = 12;
    workerId = worker['id'] as String;

    final Map<String, dynamic> giver = _createUser(
      name: 'Meera Iyer',
      phone: '9000000001',
      email: giverEmail,
      password: password,
      role: 'WorkGiver',
    );
    giver
      ..['area'] = 'Indiranagar'
      ..['company'] = 'Bloom Events'
      ..['rating'] = 4.8
      ..['reviewCount'] = 30;
    giverId = giver['id'] as String;

    final Map<String, dynamic> secondGiver = _createUser(
      name: 'Arjun Rao',
      phone: '9000000002',
      email: secondGiverEmail,
      password: password,
      role: 'WorkGiver',
    );
    secondGiver
      ..['area'] = 'Whitefield'
      ..['company'] = 'Carepoint Services'
      ..['rating'] = 4.3
      ..['reviewCount'] = 18;
    secondGiverId = secondGiver['id'] as String;

    // A second worker, so the giver has someone to shortlist besides Ravi.
    _createUser(
      name: 'Priya Nair',
      phone: '9000000004',
      email: 'priya@jobmate.in',
      password: password,
      role: 'Worker',
    );

    // Five active jobs, one containing "event" for the search test.
    final List<Map<String, dynamic>> jobs = <Map<String, dynamic>>[
      _makeJob(
        title: 'Event setup crew needed',
        category: 'Events',
        area: 'Indiranagar',
        pay: 900,
        workersNeeded: 3,
        giver: giverId!,
      ),
      _makeJob(
        title: 'Warehouse packing support',
        category: 'Delivery',
        area: 'Koramangala',
        pay: 650,
        workersNeeded: 2,
        giver: giverId!,
      ),
      _makeJob(
        title: 'House deep cleaning',
        category: 'Cleaning',
        area: 'Whitefield',
        pay: 1200,
        workersNeeded: 1,
        giver: secondGiverId!,
      ),
      _makeJob(
        title: 'Event night security',
        category: 'Events',
        area: 'Marathahalli',
        pay: 800,
        workersNeeded: 4,
        giver: secondGiverId!,
      ),
      _makeJob(
        title: 'Shop loaders for morning',
        category: 'Loading',
        area: 'Jayanagar',
        pay: 500,
        workersNeeded: 2,
        giver: giverId!,
      ),
    ];
    for (final Map<String, dynamic> job in jobs) {
      jobIds.add(job['id'] as String);
    }

    // Ravi has already applied to the warehouse job, so the applications screen
    // is not empty and `hasActiveApplication` has something to find.
    _makeApplication(
      jobId: jobIds[1],
      workerId: workerId!,
      message: 'I have packed goods for three years.',
      expectedPay: 650,
    );

    // A completed, paid shift so the earnings and work-history screens have
    // content, including a monthly summary.
    _seedCompletedShift();

    // A conversation with an unread message and a couple of notifications.
    final String conversationId = _id('cnv');
    _conversations[conversationId] = <String, dynamic>{
      'id': conversationId,
      'participants': <String>[workerId!, giverId!],
      'isArchived': false,
      'updatedAt': _nowIso(),
      'lastMessagePreview': 'Please reach the venue by 7 AM.',
    };
    _messages[conversationId] = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': _id('msg'),
        'conversationId': conversationId,
        'senderId': giverId!,
        'body': 'Please reach the venue by 7 AM.',
        'sentAt': _nowIso(),
        'isRead': false,
      },
    ];

    _notifications[workerId!] = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': _id('ntf'),
        'userId': workerId!,
        'title': 'You were shortlisted',
        'body': 'Bloom Events shortlisted you for a warehouse shift.',
        'type': 'Application',
        'isRead': false,
        'createdAt': _nowIso(),
      },
    ];
    _notifications[giverId!] = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': _id('ntf'),
        'userId': giverId!,
        'title': 'New applicant',
        'body': 'Ravi Kumar applied for warehouse packing support.',
        'type': 'Application',
        'isRead': false,
        'createdAt': _nowIso(),
      },
    ];

    // An approved identity check; the API approves on submission.
    _verifications[_id('ver')] = <String, dynamic>{
      'id': _id('ver'),
      'userId': workerId!,
      'type': 'Identity',
      'status': 'Approved',
      'submittedAt': _nowIso(),
      'documentName': 'aadhaar.pdf',
    };
  }

  Map<String, dynamic> _makeJob({
    required String title,
    required String category,
    required String area,
    required int pay,
    required int workersNeeded,
    required String giver,
  }) {
    final Map<String, dynamic> job = <String, dynamic>{
      'id': _id('job'),
      'title': title,
      'description': '$title in $area. Report to the site contact on arrival.',
      'category': category,
      'area': area,
      'address': 'No. 12, $area',
      'pay': pay,
      'payType': 'PerDay',
      'workersNeeded': workersNeeded,
      'workersFilled': 0,
      'date': DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String(),
      'startTime': '09:00:00',
      'endTime': '18:00:00',
      'reportTime': '08:45:00',
      'giverId': giver,
      'status': 'Active',
      'skills': <String>[],
      'isRecurring': false,
      'locationVisible': true,
      'createdAt': _nowIso(),
      'distanceKm': 2.4,
    };
    _jobs[job['id'] as String] = job;
    return job;
  }

  Map<String, dynamic> _makeApplication({
    required String jobId,
    required String workerId,
    String message = '',
    int? expectedPay,
  }) {
    final Map<String, dynamic> application = <String, dynamic>{
      'id': _id('app'),
      'jobId': jobId,
      'workerId': workerId,
      'status': 'Applied',
      'message': message,
      'expectedPay': expectedPay,
      'availableFrom': '1',
      'appliedAt': _nowIso(),
      'proposedPay': null,
    };
    _applications[application['id'] as String] = application;
    return application;
  }

  /// A shift that is booked, checked in, completed and paid, so the earnings
  /// screen has a paid row and the work history has an entry.
  void _seedCompletedShift() {
    final Map<String, dynamic> job = _makeJob(
      title: 'Garden maintenance',
      category: 'Cleaning',
      area: 'Koramangala',
      pay: 700,
      workersNeeded: 1,
      giver: giverId!,
    );
    jobIds.add(job['id'] as String);
    job['status'] = 'Completed';

    final Map<String, dynamic> application = _makeApplication(
      jobId: job['id'] as String,
      workerId: workerId!,
      message: 'Happy to take this one.',
      expectedPay: 700,
    );

    final Map<String, dynamic> assignment = _bookWorker(
      job: job,
      application: application,
      agreedPay: 700,
    );
    application['status'] = 'Selected';
    assignment
      ..['isCheckedIn'] = true
      ..['checkedInAt'] = _nowIso()
      ..['completedAt'] = _nowIso()
      ..['status'] = 'Completed'
      ..['paymentStatus'] = 'Paid';

    final String paymentId = _id('pay');
    assignment
      ..['paymentId'] = paymentId
      ..['paidAt'] = _nowIso();

    _receipts[paymentId] = <String, dynamic>{
      'id': paymentId,
      'paymentId': paymentId,
      'jobId': job['id'],
      'workerId': workerId,
      'amount': 700,
      'fee': 35,
      'overtime': 0,
      'method': 'Upi',
      'status': 'Paid',
      'paidAt': _nowIso(),
      'idempotencyKey': 'seed-$paymentId',
      'workerName': _users[workerId]?['name'],
    };

    _earnings[paymentId] = <String, dynamic>{
      'id': paymentId,
      'workerId': workerId,
      'assignmentId': assignment['id'],
      'jobId': job['id'],
      'jobTitle': job['title'],
      'company': _companyFor(giverId!),
      'date': _nowIso(),
      'amount': 700,
      'status': 'Paid',
      'paymentId': paymentId,
      'method': 'Upi',
    };

    _workHistory[assignment['id'] as String]!
      ..['earnings'] = 700
      ..['paymentStatus'] = 'Paid';

    // An open, unpaid shift so the worker has a booking that still accepts a
    // check in. The code is only readable by the employer.
    final Map<String, dynamic> openJob = _makeJob(
      title: 'Retail store stock count',
      category: 'Loading',
      area: 'Indiranagar',
      pay: 600,
      workersNeeded: 1,
      giver: giverId!,
    );
    jobIds.add(openJob['id'] as String);
    openJob['status'] = 'InProgress';

    final Map<String, dynamic> openApplication = _makeApplication(
      jobId: openJob['id'] as String,
      workerId: workerId!,
      message: 'Available from 9 AM.',
      expectedPay: 600,
    );
    final Map<String, dynamic> openAssignment = _bookWorker(
      job: openJob,
      application: openApplication,
      agreedPay: 600,
    );
    openApplication['status'] = 'Selected';
    openCheckInCode = _checkInCodes[openAssignment['id'] as String];
  }

  // --------------------------------------------------------------- routing

  Future<void> _handle(HttpRequest request) async {
    final String method = request.method;
    final String path = request.uri.path;

    // Media is not modelled; the app only ever links to it.
    if (path.startsWith('/api/v1/media/')) {
      await _write(request, 404, error: 'Media is not served by the fake.');
      return;
    }

    final Map<String, dynamic>? body = await _readBody(request);
    final List<String> segments = path
        .split('/')
        .where((String s) => s.isNotEmpty)
        .toList();

    final String? userId = _authenticatedUser(request);

    // Endpoints that work without a session.
    if (!_isPublic(method, segments)) {
      if (userId == null) {
        await _write(
          request,
          401,
          error: 'Unauthorized',
          message: 'Your session has expired. Please sign in again.',
        );
        return;
      }
    }

    await _route(request, method, segments, body, userId);
  }

  bool _isPublic(String method, List<String> segments) {
    if (segments.isEmpty || segments.first != 'api' || segments.length < 3) {
      return false;
    }
    if (segments[1] != 'v1') return false;

    if (segments[2] == 'auth') {
      return method == 'POST' &&
          <String>{
            'login',
            'register',
            'verify-otp',
            'resend-otp',
            'refresh',
            'forgot-password',
            'reset-password',
          }.contains(segments.length > 3 ? segments[3] : '');
    }
    return false;
  }

  Future<void> _route(
    HttpRequest request,
    String method,
    List<String> segments,
    Map<String, dynamic>? body,
    String? userId,
  ) async {
    // segments[0] == 'api', segments[1] == 'v1'
    final List<String> path = segments.sublist(2);
    if (path.isEmpty) {
      await _write(request, 404, error: 'Not found');
      return;
    }

    final String section = path[0];
    final List<String> rest = path.sublist(1);

    switch (section) {
      case 'auth':
        await _auth(request, method, rest, body, userId);
      case 'profile':
        await _profile(request, method, rest, body, userId!);
      case 'jobs':
        await _jobsRoute(request, method, rest, body, userId!);
      case 'applications':
        await _applicationsRoute(request, method, rest, body, userId!);
      case 'assignments':
        await _assignmentsRoute(request, method, rest, body, userId!);
      case 'worker':
        await _workerRoute(request, method, rest, body, userId!);
      case 'giver':
        await _giverRoute(request, method, rest, body, userId!);
      case 'conversations':
        await _conversationsRoute(request, method, rest, body, userId!);
      case 'notifications':
        await _notificationsRoute(request, method, rest, body, userId!);
      case 'payments':
        await _paymentsRoute(request, method, rest, body, userId!);
      case 'ratings':
        await _ratingsRoute(request, method, rest, body, userId!);
      case 'verifications':
        await _verificationsRoute(request, method, rest, body, userId!);
      case 'support-reports':
        await _supportRoute(request, method, rest, body, userId!);
      case 'devices':
        await _devicesRoute(request, method, rest, body, userId!);
      default:
        await _write(request, 404, error: 'Not found: /$section');
    }
  }

  // ------------------------------------------------------------------ auth

  Future<void> _auth(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String? userId,
  ) async {
    if (method != 'POST' || rest.isEmpty) {
      await _write(request, 405, error: 'Method not allowed');
      return;
    }
    switch (rest[0]) {
      case 'register':
        await _register(request, body);
      case 'login':
        await _login(request, body);
      case 'verify-otp':
        await _verifyOtp(request, body);
      case 'switch-role':
        await _switchRole(request, body, userId!);
      case 'resend-otp':
        await _resendOtp(request, body);
      case 'refresh':
        await _refresh(request, body);
      case 'logout':
        final String? token = _bearer(request);
        if (token != null) _sessions.remove(token);
        await _write(request, 200, data: true);
      case 'forgot-password':
        // Deliberately answers the same way for known and unknown numbers.
        await _write(request, 200, data: true);
      case 'reset-password':
        final String phone = (body?['phone'] ?? '').toString();
        final String? id = _userByLogin[phone];
        if (id == null) {
          await _write(request, 404, error: 'No account for that number.');
          return;
        }
        await _write(request, 200, data: true);
      default:
        await _write(request, 404, error: 'Not found');
    }
  }

  Future<void> _register(HttpRequest request, Map<String, dynamic>? body) async {
    final String phone = (body?['phone'] ?? '').toString().trim();
    final String email = (body?['email'] ?? '').toString().trim();
    if (phone.isEmpty) {
      await _write(
        request,
        400,
        error: 'A phone number is required.',
        errors: <Map<String, String>>[
          <String, String>{'field': 'phone', 'message': 'Required'},
        ],
      );
      return;
    }
    if (_userByLogin.containsKey(phone)) {
      await _write(request, 409, error: 'That number is already registered.');
      return;
    }

    final Map<String, dynamic> user = _createUser(
      name: (body?['name'] ?? '').toString(),
      phone: phone,
      email: email,
      password: (body?['password'] ?? '').toString(),
      // Every account can work and hire; it starts in worker mode.
      role: 'Worker',
    );
    user['area'] = (body?['area'] ?? '').toString();
    user['skills'] = <String>[];
    user['verified'] = false;

    _otpByPhone[phone] = _newOtp();
    issuedOtp = _otpByPhone[phone];
    await _write(request, 201, data: <String, dynamic>{'phone': phone});
  }

  Future<void> _login(HttpRequest request, Map<String, dynamic>? body) async {
    final String identifier = (body?['identifier'] ?? body?['phone'] ?? '')
        .toString()
        .trim();
    final String password = (body?['password'] ?? '').toString();
    final String? id = _userByLogin[identifier];
    if (id == null || _users[id]!['password'] != password) {
      await _write(request, 401, error: 'Those details do not match an account.');
      return;
    }
    await _write(request, 200, data: _sessionFor(id));
  }

  Future<void> _verifyOtp(HttpRequest request, Map<String, dynamic>? body) async {
    final String phone = (body?['phone'] ?? '').toString().trim();
    final String otp = (body?['otp'] ?? '').toString().trim();
    final String? id = _userByLogin[phone];
    final String? expected = _otpByPhone[phone];

    if (id == null || expected == null) {
      await _write(request, 404, error: 'No verification is pending.');
      return;
    }
    if (otp != expected) {
      await _write(request, 400, error: 'That code is not correct.');
      return;
    }

    _otpByPhone.remove(phone);
    await _write(request, 200, data: _sessionFor(id));
  }

  /// Moves the caller into worker or work giver mode and reissues the session,
  /// like the API, whose token carries the active mode.
  Future<void> _switchRole(
    HttpRequest request,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    final String role = (body?['role'] ?? '').toString();
    if (role != 'worker' && role != 'workGiver') {
      await _write(request, 400, error: 'Choose worker or workGiver.');
      return;
    }
    _users[userId]!['role'] = role == 'worker' ? 'Worker' : 'WorkGiver';
    await _write(request, 200, data: _sessionFor(userId));
  }

  Future<void> _resendOtp(HttpRequest request, Map<String, dynamic>? body) async {
    final String phone = (body?['phone'] ?? '').toString().trim();
    if (!_userByLogin.containsKey(phone)) {
      // Answered uniformly so the endpoint cannot be used to enumerate accounts.
      await _write(request, 200, data: true);
      return;
    }
    _otpByPhone[phone] = _newOtp();
    issuedOtp = _otpByPhone[phone];
    await _write(request, 200, data: true);
  }

  Future<void> _refresh(HttpRequest request, Map<String, dynamic>? body) async {
    final String presented = (body?['refreshToken'] ?? '').toString();

    String? accessToken;
    String? userId;
    for (final MapEntry<String, _Session> entry in _sessions.entries) {
      if (entry.value.refreshToken == presented) {
        accessToken = entry.key;
        userId = entry.value.userId;
        break;
      }
    }
    if (userId == null) {
      await _write(request, 401, error: 'That refresh token has expired.');
      return;
    }
    // The pair rotates on every refresh, so the old access token stops working.
    _sessions.remove(accessToken);
    _userByAccess.remove(accessToken);
    await _write(request, 200, data: _sessionFor(userId));
  }

  Map<String, dynamic> _sessionFor(String userId) {
    final String access = 'access-${_id('t')}';
    final String refresh = 'refresh-${_id('t')}';
    _sessions[access] = _Session(userId: userId, refreshToken: refresh);
    _userByAccess[access] = userId;
    return <String, dynamic>{
      'accessToken': access,
      'refreshToken': refresh,
      'accessTokenExpiresAt': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
      'user': _userDto(_users[userId]!),
    };
  }

  String _newOtp() => (1000 + _random.nextInt(9000)).toString();

  // --------------------------------------------------------------- profile

  Future<void> _profile(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    if (rest.isEmpty) {
      await _write(request, 404, error: 'Not found');
      return;
    }
    switch (rest[0]) {
      case 'me':
        if (method == 'GET') {
          await _write(request, 200, data: _userDto(_users[userId]!));
          return;
        }
        final Map<String, dynamic> user = _users[userId]!;
        user
          ..['name'] = (body?['name'] ?? user['name']).toString()
          ..['phone'] = (body?['phone'] ?? user['phone']).toString()
          ..['email'] = (body?['email'] ?? user['email']).toString()
          ..['area'] = (body?['area'] ?? user['area']).toString();
        await _write(request, 200, data: _userDto(user));
      case 'worker':
        final Map<String, dynamic> user = _users[userId]!;
        user['skills'] = _stringList(body?['skills']);
        user['experience'] = body?['experience'] ?? user['experience'];
        user['bio'] = body?['bio'] ?? user['bio'];
        user['updatedAt'] = _nowIso();
        await _write(request, 200, data: _userDto(user));
      case 'giver':
        final Map<String, dynamic> user = _users[userId]!;
        user['company'] = body?['company'] ?? user['company'];
        user['area'] = body?['area'] ?? user['area'];
        user['updatedAt'] = _nowIso();
        await _write(request, 200, data: _userDto(user));
      case 'availability':
        final Map<String, dynamic> user = _users[userId]!;
        user['availability'] = _stringList(body?['availability']);
        await _write(request, 200, data: _userDto(user));
      case 'presence':
        final Map<String, dynamic> user = _users[userId]!;
        user['isOnline'] = body?['isOnline'] ?? false;
        user['lastSeenAt'] = _nowIso();
        await _write(request, 200, data: _userDto(user));
      case 'image':
        final Map<String, dynamic> user = _users[userId]!;
        user['profileImageUrl'] = body?['url'] ?? user['profileImageUrl'];
        await _write(request, 200, data: _userDto(user));
      case 'documents':
        final List<String> docs = _stringList(body?['documents']);
        _users[userId]!['documents'] = docs;
        await _write(request, 200, data: <String, dynamic>{'documents': docs});
      default:
        await _write(request, 404, error: 'Not found');
    }
  }

  // ------------------------------------------------------------------ jobs

  Future<void> _jobsRoute(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    // POST /api/v1/jobs
    if (rest.isEmpty) {
      if (method == 'GET') {
        await _listJobs(request, query: request.uri.queryParameters, userId: userId);
        return;
      }
      if (method == 'POST') {
        await _createJob(request, body, userId);
        return;
      }
      await _write(request, 405, error: 'Method not allowed');
      return;
    }

    final String jobId = rest[0];
    final Map<String, dynamic>? job = _jobs[jobId];
    if (job == null) {
      await _write(request, 404, error: 'That job could not be found.');
      return;
    }

    if (rest.length == 1) {
      if (method == 'GET') {
        await _write(request, 200, data: _jobDto(job));
        return;
      }
      if (method == 'PUT') {
        job.addAll(<String, dynamic>{
          for (final MapEntry<String, dynamic> e in (body ?? <String, dynamic>{}).entries)
            if (e.value != null) e.key: e.value,
        });
        await _write(request, 200, data: _jobDto(job));
        return;
      }
      if (method == 'DELETE') {
        _jobs.remove(jobId);
        await _write(request, 200, data: true);
        return;
      }
    }

    if (rest.length < 2) {
      await _write(request, 404, error: 'Not found');
      return;
    }

    switch (rest[1]) {
      case 'apply':
        await _applyToJob(request, body, jobId, userId);
      case 'applications':
        await _listJobApplications(request, jobId, userId);
      case 'select-workers':
        await _selectWorkers(request, body, jobId, userId);
      case 'publish':
        job['status'] = 'Active';
        job['publishedAt'] = _nowIso();
        await _write(request, 200, data: _jobDto(job));
      case 'start':
        job['status'] = 'InProgress';
        await _write(request, 200, data: _jobDto(job));
      case 'complete':
        job['status'] = 'Completed';
        job['completedAt'] = _nowIso();
        await _write(request, 200, data: _jobDto(job));
      case 'cancel':
        job['status'] = 'Cancelled';
        await _write(request, 200, data: _jobDto(job));
      case 'remind':
        final int reminded = _applications.values
            .where(
              (Map<String, dynamic> a) =>
                  a['jobId'] == jobId && a['status'] == 'Selected',
            )
            .length;
        await _write(
          request,
          200,
          data: <String, dynamic>{'remindedCount': reminded},
        );
      case 'check-in-code':
        if (rest.length < 4) {
          await _write(request, 404, error: 'Not found');
          return;
        }
        await _readCheckInCode(request, jobId, rest[3], userId);
      case 'payments':
        if (rest.length < 3) {
          await _write(request, 404, error: 'Not found');
          return;
        }
        await _releasePayment(request, body, jobId, rest[2], userId);
      default:
        await _write(request, 404, error: 'Not found: /jobs/${rest[1]}');
    }
  }

  Future<void> _createJob(
    HttpRequest request,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    final String giverId = (body?['giverId'] ?? userId).toString();
    final Map<String, dynamic> job = <String, dynamic>{
      'id': _id('job'),
      'title': (body?['title'] ?? '').toString(),
      'description': (body?['description'] ?? '').toString(),
      'category': body?['category'] ?? 'Other',
      'area': (body?['area'] ?? '').toString(),
      'address': (body?['address'] ?? '').toString(),
      'pay': (body?['pay'] as num?)?.toInt() ?? 0,
      'payType': body?['payType'] ?? 'PerDay',
      'workersNeeded': (body?['workersNeeded'] as num?)?.toInt() ?? 1,
      'workersFilled': 0,
      'date': body?['date'] ?? _nowIso(),
      'startTime': body?['startTime'] ?? '09:00:00',
      'endTime': body?['endTime'] ?? '18:00:00',
      'reportTime': body?['reportTime'] ?? '08:45:00',
      'giverId': giverId,
      'status': (body?['status'] ?? 'Draft').toString(),
      'skills': _stringList(body?['skills']),
      'isRecurring': body?['isRecurring'] ?? false,
      'locationVisible': body?['locationVisible'] ?? true,
      'createdAt': _nowIso(),
      'distanceKm': 0,
    };
    _jobs[job['id'] as String] = job;
    await _write(request, 201, data: _jobDto(job));
  }

  Future<void> _listJobs(
    HttpRequest request, {
    required Map<String, String> query,
    required String userId,
  }) async {
    Iterable<Map<String, dynamic>> rows = _jobs.values;

    final String? status = query['status'];
    if (status != null && status.isNotEmpty) {
      rows = rows.where((Map<String, dynamic> j) => j['status'] == status);
    }
    final String? category = query['category'];
    if (category != null && category.isNotEmpty) {
      rows = rows.where(
        (Map<String, dynamic> j) =>
            (j['category'] as String).toLowerCase() == category.toLowerCase(),
      );
    }
    final String? area = query['area'];
    if (area != null && area.isNotEmpty) {
      rows = rows.where(
        (Map<String, dynamic> j) =>
            (j['area'] as String).toLowerCase().contains(area.toLowerCase()),
      );
    }
    final String? text = query['query'] ?? query['q'] ?? query['search'];
    if (text != null && text.isNotEmpty) {
      final String needle = text.toLowerCase();
      rows = rows.where((Map<String, dynamic> j) {
        final Map<String, dynamic> dto = _jobDto(j);
        return <String>[
          '${dto['title']}',
          '${dto['description']}',
          '${dto['company']}',
        ].any((String v) => v.toLowerCase().contains(needle));
      });
    }

    final bool payHigh = _flag(query['sortDescending']) ||
        '${query['sort']}'.toLowerCase().contains('pay_desc');
    final List<Map<String, dynamic>> list = rows.toList()
      ..sort(
        (Map<String, dynamic> a, Map<String, dynamic> b) => payHigh
            ? (b['pay'] as num).compareTo(a['pay'] as num)
            : (b['createdAt'] as String).compareTo(a['createdAt'] as String),
      );

    await _writePaged(request, list);
  }

  // ---------------------------------------------------------- applications

  Future<void> _applyToJob(
    HttpRequest request,
    Map<String, dynamic>? body,
    String jobId,
    String userId,
  ) async {
    final Map<String, dynamic>? job = _jobs[jobId];
    if (job == null) {
      await _write(request, 404, error: 'That job could not be found.');
      return;
    }
    if (job['giverId'] == userId) {
      await _write(request, 400, error: 'You cannot apply to your own job.');
      return;
    }
    if (job['status'] != 'Active') {
      await _write(request, 400, error: 'That job is not accepting applications.');
      return;
    }
    final bool exists = _applications.values.any(
      (Map<String, dynamic> a) =>
          a['jobId'] == jobId &&
          a['workerId'] == userId &&
          <String>{'Applied', 'Shortlisted', 'Selected'}.contains(a['status']),
    );
    if (exists) {
      await _write(request, 409, error: 'You have already applied for this job.');
      return;
    }

    final Map<String, dynamic> application = <String, dynamic>{
      'id': _id('app'),
      'jobId': jobId,
      'workerId': userId,
      'status': 'Applied',
      'message': (body?['message'] ?? '').toString(),
      'expectedPay': (body?['expectedPay'] as num?)?.toInt(),
      'availableFrom': body?['availableFrom'],
      'appliedAt': _nowIso(),
      'proposedPay': null,
    };
    _applications[application['id'] as String] = application;
    await _write(request, 201, data: _applicationDto(application));
  }

  Future<void> _listJobApplications(
    HttpRequest request,
    String jobId,
    String userId,
  ) async {
    final List<Map<String, dynamic>> rows = _applications.values
        .where((Map<String, dynamic> a) => a['jobId'] == jobId)
        .toList();
    await _writePaged(request, rows);
  }

  Future<void> _applicationsRoute(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    if (method != 'POST' || rest.length < 2) {
      await _write(request, 404, error: 'Not found');
      return;
    }
    final String applicationId = rest[0];
    final Map<String, dynamic>? application = _applications[applicationId];
    if (application == null) {
      await _write(request, 404, error: 'That application could not be found.');
      return;
    }

    switch (rest[1]) {
      case 'withdraw':
        if (application['workerId'] != userId) {
          await _write(request, 403, error: 'That is not your application.');
          return;
        }
        application['status'] = 'Withdrawn';
        application['withdrawnAt'] = _nowIso();
        await _write(request, 200, data: _applicationDto(application));
      case 'shortlist':
        application['status'] = 'Shortlisted';
        application['shortlistedAt'] = _nowIso();
        if (body?['proposedPay'] != null) {
          application['proposedPay'] = (body!['proposedPay'] as num).toInt();
        }
        await _write(request, 200, data: _applicationDto(application));
      case 'reject':
        application['status'] = 'Rejected';
        application['rejectedAt'] = _nowIso();
        application['rejectionReason'] = body?['reason'];
        await _write(request, 200, data: _applicationDto(application));
      case 'select':
        await _selectOne(request, body, application, userId);
      default:
        await _write(request, 404, error: 'Not found');
    }
  }

  Future<void> _selectOne(
    HttpRequest request,
    Map<String, dynamic>? body,
    Map<String, dynamic> application,
    String userId,
  ) async {
    final Map<String, dynamic>? job = _jobs[application['jobId'] as String];
    if (job == null) {
      await _write(request, 404, error: 'That job could not be found.');
      return;
    }
    final int needed = (job['workersNeeded'] as num).toInt();
    final int filled = (job['workersFilled'] as num).toInt();
    if (filled >= needed) {
      await _write(request, 409, error: 'All worker slots for this job are taken.');
      return;
    }

    final int agreed =
        (body?['agreedPay'] as num?)?.toInt() ??
        (application['proposedPay'] as num?)?.toInt() ??
        (job['pay'] as num).toInt();

    final Map<String, dynamic> assignment = _bookWorker(
      job: job,
      application: application,
      agreedPay: agreed,
    );
    application['status'] = 'Selected';
    application['acceptedAt'] = _nowIso();

    await _write(request, 201, data: _assignmentDto(assignment, forGiver: true));
  }

  Future<void> _selectWorkers(
    HttpRequest request,
    Map<String, dynamic>? body,
    String jobId,
    String userId,
  ) async {
    final Map<String, dynamic>? job = _jobs[jobId];
    if (job == null) {
      await _write(request, 404, error: 'That job could not be found.');
      return;
    }

    final Map<String, dynamic> raw = <String, dynamic>{
      ...?(body?['selections'] as Map?)?.cast<String, dynamic>(),
    };
    final int needed = (job['workersNeeded'] as num).toInt();
    final int filled = (job['workersFilled'] as num).toInt();

    // The batch is all or nothing, exactly as the spec requires.
    if (filled + raw.length > needed) {
      await _write(
        request,
        400,
        error: 'Only $needed worker slots are open on this job.',
      );
      return;
    }

    final List<Map<String, dynamic>> selected = <Map<String, dynamic>>[];
    final List<String> released = <String>[];

    for (final MapEntry<String, dynamic> entry in raw.entries) {
      final Map<String, dynamic>? application = _applications[entry.key];
      if (application == null) continue;
      final Map<String, dynamic> assignment = _bookWorker(
        job: job,
        application: application,
        agreedPay: (entry.value as num).toInt(),
      );
      application['status'] = 'Selected';
      application['acceptedAt'] = _nowIso();
      selected.add(assignment);
    }

    if (body?['releaseUnselectedShortlists'] == true) {
      for (final Map<String, dynamic> application in _applications.values) {
        if (application['jobId'] == jobId &&
            application['status'] == 'Shortlisted' &&
            !raw.containsKey(application['id'])) {
          application['status'] = 'Applied';
          released.add(application['id'] as String);
        }
      }
    }

    final int nowFilled = (job['workersFilled'] as num).toInt();
    await _write(
      request,
      200,
      data: <String, dynamic>{
        'selected': selected
            .map((Map<String, dynamic> a) => _assignmentDto(a, forGiver: true))
            .toList(),
        'releasedApplicationIds': released,
        'workersFilled': nowFilled,
        'workersNeeded': needed,
        'remainingSlots': needed - nowFilled,
      },
    );
  }

  /// Creates the assignment, the work-history row and the check-in code that a
  /// giver will read out on site.
  Map<String, dynamic> _bookWorker({
    required Map<String, dynamic> job,
    required Map<String, dynamic> application,
    required int agreedPay,
  }) {
    final String jobId = job['id'] as String;
    final String workerId = application['workerId'] as String;
    final String assignmentId = _id('asg');
    final String code = (1000 + _random.nextInt(9000)).toString();

    final Map<String, dynamic> assignment = <String, dynamic>{
      'id': assignmentId,
      'jobId': jobId,
      'workerId': workerId,
      'giverId': job['giverId'],
      'agreedPay': agreedPay,
      'confirmedAt': _nowIso(),
      'paymentStatus': 'Pending',
      'checkedInAt': null,
      'completedAt': null,
      'paymentId': null,
      'paidAt': null,
      'status': 'Confirmed',
      'overtimeAmount': 0,
      'totalPay': agreedPay,
      'isCheckedIn': false,
    };
    _assignments[assignmentId] = assignment;
    _checkInCodes[assignmentId] = code;

    // A booking is listed in work history as soon as it is made.
    _workHistory[assignmentId] = <String, dynamic>{
      'id': assignmentId,
      'jobId': jobId,
      'jobTitle': job['title'],
      'company': _companyFor(job['giverId'] as String),
      'date': job['date'],
      'durationHours': 8,
      'earnings': agreedPay,
      'paymentStatus': 'Pending',
      'rating': null,
      'ratedByGiver': false,
      'counterpartyId': job['giverId'],
      'counterpartyName': _users[job['giverId']]?['name'],
      'category': job['category'],
    };

    job['workersFilled'] = (job['workersFilled'] as num).toInt() + 1;
    return assignment;
  }

  // ----------------------------------------------------------- assignments

  Future<void> _assignmentsRoute(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    if (method != 'POST' || rest.length < 2) {
      await _write(request, 404, error: 'Not found');
      return;
    }
    final String assignmentId = rest[0];
    final Map<String, dynamic>? assignment = _assignments[assignmentId];
    if (assignment == null) {
      await _write(request, 404, error: 'That booking could not be found.');
      return;
    }
    if (assignment['workerId'] != userId) {
      await _write(request, 403, error: 'That booking is not yours.');
      return;
    }

    switch (rest[1]) {
      case 'check-in':
        await _checkIn(request, body, assignment);
      case 'complete':
        await _completeAssignment(request, body, assignment);
      default:
        await _write(request, 404, error: 'Not found');
    }
  }

  Future<void> _checkIn(
    HttpRequest request,
    Map<String, dynamic>? body,
    Map<String, dynamic> assignment,
  ) async {
    final String? expected = _checkInCodes[assignment['id'] as String];
    final String presented = (body?['code'] ?? '').toString().trim();

    if (assignment['isCheckedIn'] == true) {
      lastCheckInError = 'You have already checked in for this shift.';
      await _write(request, 409, error: lastCheckInError);
      return;
    }
    if (expected == null || presented != expected) {
      lastCheckInError = 'That check-in code is not correct.';
      await _write(request, 400, error: lastCheckInError);
      return;
    }

    assignment
      ..['isCheckedIn'] = true
      ..['checkedInAt'] = _nowIso();
    // The code is single use.
    _checkInCodes.remove(assignment['id'] as String);

    await _write(
      request,
      200,
      data: _assignmentDto(assignment, forGiver: false),
    );
  }

  Future<void> _completeAssignment(
    HttpRequest request,
    Map<String, dynamic>? body,
    Map<String, dynamic> assignment,
  ) async {
    if (assignment['isCheckedIn'] != true) {
      await _write(
        request,
        400,
        error: 'You need to check in before completing this shift.',
      );
      return;
    }
    if (assignment['completedAt'] != null) {
      await _write(request, 409, error: 'This shift is already completed.');
      return;
    }

    final int overtime = (body?['overtimeAmount'] as num?)?.toInt() ?? 0;
    final int total =
        (assignment['agreedPay'] as num).toInt() + overtime;

    assignment
      ..['completedAt'] = _nowIso()
      ..['status'] = 'Completed'
      ..['overtimeAmount'] = overtime
      ..['totalPay'] = total;

    final String assignmentId = assignment['id'] as String;
    final Map<String, dynamic>? history = _workHistory[assignmentId];
    if (history != null) {
      history
        ..['earnings'] = total
        ..['paymentStatus'] = 'Paid';
    }

    await _write(
      request,
      200,
      data: _assignmentDto(assignment, forGiver: false),
    );
  }

  /// Only the employer may read a check-in code; the API deliberately withholds
  /// it from the worker.
  Future<void> _readCheckInCode(
    HttpRequest request,
    String jobId,
    String assignmentId,
    String userId,
  ) async {
    final Map<String, dynamic>? job = _jobs[jobId];
    final Map<String, dynamic>? assignment = _assignments[assignmentId];
    if (job == null || assignment == null) {
      await _write(request, 404, error: 'That booking could not be found.');
      return;
    }
    if (job['giverId'] != userId) {
      await _write(
        request,
        403,
        error: 'Only the employer can read the check-in code.',
      );
      return;
    }
    final String? code = _checkInCodes[assignmentId];
    if (code == null) {
      await _write(
        request,
        404,
        error: 'That code has already been used.',
      );
      return;
    }
    await _write(request, 200, data: code);
  }

  // ---------------------------------------------------------------- worker

  Future<void> _workerRoute(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    if (rest.isEmpty) {
      await _write(request, 404, error: 'Not found');
      return;
    }
    switch (rest[0]) {
      case 'applications':
        await _writePaged(request, _applicationRowsFor(userId));
      case 'work-history':
        await _writePaged(request, _historyRowsFor(userId));
      case 'earnings':
        if (rest.length > 1 && rest[1] == 'summary') {
          await _write(request, 200, data: _earningsSummary(userId));
          return;
        }
        await _writePaged(request, _earningRowsFor(userId));
      case 'wallet':
        await _write(request, 200, data: _walletFor(userId));
      case 'stats':
        await _write(request, 200, data: _workerStats(userId));
      case 'jobs':
        await _writePaged(
          request,
          _jobs.values
              .where((Map<String, dynamic> j) => j['status'] == 'Active')
              .toList(),
        );
      case 'saved-jobs':
        if (rest.length > 1) {
          final String jobId = rest[1];
          if (method == 'DELETE') {
            _savedJobKeys.remove('$userId:$jobId');
            await _write(request, 200, data: true);
            return;
          }
          if (method == 'PUT') {
            _savedJobKeys.add('$userId:$jobId');
            await _write(request, 200, data: true);
            return;
          }
        }
        final List<Map<String, dynamic>> saved = <Map<String, dynamic>>[];
        for (final String key in _savedJobKeys) {
          if (!key.startsWith('$userId:')) continue;
          final Map<String, dynamic>? job = _jobs[key.split(':').last];
          if (job != null) saved.add(_jobDto(job));
        }
        await _writePaged(request, saved);
      default:
        await _write(request, 404, error: 'Not found: /worker/${rest[0]}');
    }
  }

  List<Map<String, dynamic>> _applicationRowsFor(String workerId) =>
      <Map<String, dynamic>>[
        for (final Map<String, dynamic> a in _applications.values)
          if (a['workerId'] == workerId) _applicationDto(a),
      ];

  List<Map<String, dynamic>> _historyRowsFor(String workerId) =>
      <Map<String, dynamic>>[
        for (final Map<String, dynamic> a in _assignments.values)
          if (a['workerId'] == workerId) _historyDto(a),
      ];

  List<Map<String, dynamic>> _earningRowsFor(String workerId) =>
      <Map<String, dynamic>>[
        for (final Map<String, dynamic> e in _earnings.values)
          if (e['workerId'] == workerId) e,
      ];

  Map<String, dynamic> _walletFor(String workerId) {
    int total = 0;
    int pending = 0;
    for (final Map<String, dynamic> e in _earnings.values) {
      if (e['workerId'] != workerId) continue;
      total += (e['amount'] as num).toInt();
      if (e['status'] == 'Pending') pending += (e['amount'] as num).toInt();
    }
    return <String, dynamic>{
      'totalEarned': total,
      'pendingAmount': pending,
      'currency': 'INR',
    };
  }

  Map<String, dynamic> _workerStats(String workerId) {
    final List<Map<String, dynamic>> apps = _applicationRowsFor(workerId);
    final List<Map<String, dynamic>> history = _historyRowsFor(workerId);
    return <String, dynamic>{
      'totalApplications': apps.length,
      'activeApplications': apps
          .where((Map<String, dynamic> a) => a['status'] == 'Applied')
          .length,
      'totalJobs': history.length,
      'totalEarned': _walletFor(workerId)['totalEarned'],
    };
  }

  Map<String, dynamic> _earningsSummary(String workerId) {
    final Map<String, Map<String, dynamic>> byMonth =
        <String, Map<String, dynamic>>{};
    for (final Map<String, dynamic> e in _earningRowsFor(workerId)) {
      final String month = (e['date'] as String).substring(0, 7);
      final Map<String, dynamic> row = byMonth.putIfAbsent(
        month,
        () => <String, dynamic>{'month': month, 'total': 0, 'count': 0},
      );
      row['total'] = (row['total'] as num).toInt() + (e['amount'] as num).toInt();
      row['count'] = (row['count'] as num).toInt() + 1;
    }
    final List<Map<String, dynamic>> rows = byMonth.values.toList()
      ..sort(
        (Map<String, dynamic> a, Map<String, dynamic> b) =>
            (b['month'] as String).compareTo(a['month'] as String),
      );
    return <String, dynamic>{'months': rows};
  }

  // ----------------------------------------------------------------- giver

  Future<void> _giverRoute(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    if (rest.isEmpty) {
      await _write(request, 404, error: 'Not found');
      return;
    }
    switch (rest[0]) {
      case 'jobs':
        await _writePaged(
          request,
          _jobs.values
              .where((Map<String, dynamic> j) => j['giverId'] == userId)
              .toList()
              .map(_jobDto)
              .toList(),
        );
      case 'work-history':
        await _writePaged(
          request,
          <Map<String, dynamic>>[
            for (final Map<String, dynamic> a in _assignments.values)
              if (a['giverId'] == userId) _historyDto(a),
          ],
        );
      case 'stats':
        await _write(request, 200, data: <String, dynamic>{
          'activeJobs': _jobs.values
              .where((Map<String, dynamic> j) =>
                  j['giverId'] == userId && j['status'] == 'Active')
              .length,
          'totalHired': _assignments.values
              .where((Map<String, dynamic> a) => a['giverId'] == userId)
              .length,
          'spentThisMonth': 0,
        });
      default:
        await _write(request, 404, error: 'Not found: /giver/${rest[0]}');
    }
  }

  // --------------------------------------------------------------- payments

  Future<void> _paymentsRoute(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    if (rest.isEmpty) {
      if (method == 'GET') {
        await _writePaged(request, _receipts.values.toList());
        return;
      }
      await _write(request, 405, error: 'Method not allowed');
      return;
    }
    final String paymentId = rest[0];
    final Map<String, dynamic>? receipt = _receipts[paymentId];
    if (receipt == null) {
      await _write(request, 404, error: 'That payment could not be found.');
      return;
    }
    if (rest.length < 2) {
      await _write(request, 404, error: 'Not found');
      return;
    }
    switch (rest[1]) {
      case 'confirm':
        receipt['status'] = 'Paid';
        await _write(request, 200, data: receipt);
      case 'refund':
        receipt['status'] = 'Refunded';
        await _write(request, 200, data: receipt);
      default:
        await _write(request, 404, error: 'Not found');
    }
  }

  /// Releases pay for one worker and credits the wallet in the same call.
  ///
  /// [idempotencyKey] makes a repeated tap safe: the first receipt is always
  /// returned, never a second payout.
  Future<void> _releasePayment(
    HttpRequest request,
    Map<String, dynamic>? body,
    String jobId,
    String workerId,
    String userId,
  ) async {
    final Map<String, dynamic>? job = _jobs[jobId];
    if (job == null) {
      await _write(request, 404, error: 'That job could not be found.');
      return;
    }
    if (job['giverId'] != userId) {
      await _write(request, 403, error: 'Only the employer can pay this booking.');
      return;
    }

    final String key = (body?['idempotencyKey'] ?? '').toString();
    Map<String, dynamic>? existing;
    for (final Map<String, dynamic> row in _receipts.values) {
      if (row['idempotencyKey'] == key) {
        existing = row;
        break;
      }
    }
    if (existing != null) {
      // A repeated tap returns the first receipt instead of paying twice.
      await _write(request, 200, data: existing);
      return;
    }

    final Map<String, dynamic>? assignment = _assignmentFor(jobId, workerId);
    if (assignment == null) {
      await _write(request, 404, error: 'That worker is not booked on this job.');
      return;
    }
    if (assignment['completedAt'] == null) {
      await _write(
        request,
        400,
        error: 'The shift has to be completed before it can be paid.',
      );
      return;
    }

    final int base = (body?['basePay'] as num?)?.toInt() ??
        (assignment['agreedPay'] as num).toInt();
    final int overtime = (body?['overtimeAmount'] as num?)?.toInt() ?? 0;
    final int amount = base + overtime;
    final int fee = (amount * 5 / 100).round();
    final String paymentId = _id('pay');

    final Map<String, dynamic> receipt = <String, dynamic>{
      'id': paymentId,
      'paymentId': paymentId,
      'jobId': jobId,
      'workerId': workerId,
      'amount': amount,
      'fee': fee,
      'overtime': overtime,
      'method': (body?['method'] ?? 'Upi').toString(),
      'status': 'Paid',
      'paidAt': _nowIso(),
      'idempotencyKey': key,
      'workerName': _users[workerId]?['name'],
    };
    _receipts[paymentId] = receipt;

    assignment
      ..['paymentId'] = paymentId
      ..['paidAt'] = _nowIso()
      ..['paymentStatus'] = 'Paid';

    _earnings[paymentId] = <String, dynamic>{
      'id': paymentId,
      'workerId': workerId,
      'assignmentId': assignment['id'],
      'jobId': jobId,
      'jobTitle': job['title'],
      'company': _companyFor(userId),
      'date': _nowIso(),
      'amount': amount,
      'status': 'Paid',
      'paymentId': paymentId,
      'method': receipt['method'],
    };

    final Map<String, dynamic>? history = _workHistory[assignment['id'] as String];
    if (history != null) {
      history
        ..['earnings'] = amount
        ..['paymentStatus'] = 'Paid';
    }

    await _write(request, 201, data: receipt);
  }

  Map<String, dynamic>? _assignmentFor(String jobId, String workerId) {
    for (final Map<String, dynamic> a in _assignments.values) {
      if (a['jobId'] == jobId && a['workerId'] == workerId) return a;
    }
    return null;
  }

  // -------------------------------------------------------------- messaging

  Future<void> _conversationsRoute(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    if (rest.isEmpty) {
      await _writePaged(
        request,
        _conversations.values
            .where(
              (Map<String, dynamic> c) =>
                  (c['participants'] as List).contains(userId),
            )
            .toList(),
      );
      return;
    }

    final String conversationId = rest[0];
    final Map<String, dynamic>? conversation = _conversations[conversationId];
    if (conversation == null ||
        !(conversation['participants'] as List).contains(userId)) {
      await _write(request, 404, error: 'That conversation could not be found.');
      return;
    }

    if (rest.length == 1) {
      await _write(request, 200, data: conversation);
      return;
    }

    switch (rest[1]) {
      case 'messages':
        if (method == 'POST') {
          final Map<String, dynamic> message = <String, dynamic>{
            'id': _id('msg'),
            'conversationId': conversationId,
            'senderId': userId,
            'body': (body?['body'] ?? '').toString(),
            'sentAt': _nowIso(),
            'isRead': false,
          };
          _messages
              .putIfAbsent(conversationId, () => <Map<String, dynamic>>[])
              .add(message);
          await _write(request, 201, data: message);
          return;
        }
        await _writePaged(
          request,
          _messages[conversationId] ?? <Map<String, dynamic>>[],
        );
      case 'read':
        for (final Map<String, dynamic> m
            in _messages[conversationId] ?? <Map<String, dynamic>>[]) {
          m['isRead'] = true;
        }
        await _write(request, 200, data: true);
      case 'archive':
        conversation['isArchived'] = true;
        await _write(request, 200, data: conversation);
      default:
        await _write(request, 404, error: 'Not found');
    }
  }

  // ----------------------------------------------------------- notifications

  Future<void> _notificationsRoute(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    final List<Map<String, dynamic>> mine =
        _notifications[userId] ?? <Map<String, dynamic>>[];

    if (rest.isEmpty) {
      await _writePaged(request, mine);
      return;
    }
    if (rest[0] == 'read-all') {
      for (final Map<String, dynamic> n in mine) {
        n['isRead'] = true;
      }
      await _write(request, 200, data: <String, dynamic>{'updated': mine.length});
      return;
    }
    if (rest[0] == 'unread-count') {
      await _write(
        request,
        200,
        data: <String, dynamic>{
          'count': mine.where((Map<String, dynamic> n) => n['isRead'] != true).length,
        },
      );
      return;
    }
    if (rest.length >= 2 && rest[1] == 'read') {
      final Map<String, dynamic>? notification = _findNotification(
        mine,
        rest[0],
      );
      if (notification == null) {
        await _write(request, 404, error: 'That alert could not be found.');
        return;
      }
      notification['isRead'] = true;
      await _write(request, 200, data: notification);
      return;
    }
    await _write(request, 404, error: 'Not found');
  }

  Map<String, dynamic>? _findNotification(
    List<Map<String, dynamic>> rows,
    String id,
  ) {
    for (final Map<String, dynamic> row in rows) {
      if (row['id'] == id) return row;
    }
    return null;
  }

  // ---------------------------------------------------------------- ratings

  Future<void> _ratingsRoute(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    if (method == 'GET') {
      final Map<String, String> query = request.uri.queryParameters;
      final String? jobId = query['jobId'];
      final String? toUserId = query['toUserId'] ?? query['ToUserId'];
      final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
        for (final Map<String, dynamic> r in _ratings.values)
          if ((jobId == null || r['jobId'] == jobId) &&
              (toUserId == null || r['workerId'] == toUserId))
            r,
      ];
      await _writePaged(request, rows);
      return;
    }

    if (method != 'POST') {
      await _write(request, 405, error: 'Method not allowed');
      return;
    }

    final String jobId = (body?['jobId'] ?? '').toString();
    final String toUserId = (body?['toUserId'] ?? '').toString();
    final int stars = (body?['stars'] as num?)?.toInt() ?? 0;

    if (stars < 1 || stars > 5) {
      await _write(request, 400, error: 'A rating must be between 1 and 5.');
      return;
    }
    final Map<String, dynamic>? job = _jobs[jobId];
    if (job == null) {
      await _write(request, 404, error: 'That job could not be found.');
      return;
    }
    if (job['status'] != 'Completed') {
      await _write(
        request,
        400,
        error: 'You can only rate a worker once the job is completed.',
      );
      return;
    }
    if (userId != job['giverId'] && userId != _assignmentFor(jobId, toUserId)?['workerId']) {
      await _write(request, 403, error: 'You were not part of this job.');
      return;
    }
    if (_ratings.containsKey('$userId:$jobId:$toUserId')) {
      await _write(request, 409, error: 'You have already rated this job.');
      return;
    }

    final bool asGiver = userId == job['giverId'];
    final Map<String, dynamic> rating = <String, dynamic>{
      'id': _id('rate'),
      'jobId': jobId,
      'workerId': asGiver ? toUserId : userId,
      'giverId': asGiver ? userId : job['giverId'],
      'stars': stars,
      'feedback': body?['feedback'],
      'createdAt': _nowIso(),
      'jobTitle': job['title'],
      'fromUserName': _users[userId]?['name'],
    };
    _ratings['$userId:$jobId:$toUserId'] = rating;

    final Map<String, dynamic>? history = _assignmentFor(jobId, toUserId) == null
        ? null
        : _workHistory[_assignmentFor(jobId, toUserId)!['id'] as String];
    if (asGiver && history != null) {
      history
        ..['rating'] = stars.toDouble()
        ..['ratedByGiver'] = true;
    }

    await _write(request, 201, data: rating);
  }

  // ---------------------------------------------------------- verifications

  Future<void> _verificationsRoute(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    if (rest.isEmpty) {
      if (method == 'GET') {
        await _writePaged(
          request,
          _verifications.values
              .where((Map<String, dynamic> v) => v['userId'] == userId)
              .toList(),
        );
        return;
      }
      if (method == 'POST') {
        final String type = (body?['type'] ?? 'Identity').toString();
        final Map<String, dynamic> record = <String, dynamic>{
          'id': _id('ver'),
          'userId': userId,
          'type': type,
          // Approved on submission: there is no reviewer.
          'status': 'Approved',
          'submittedAt': _nowIso(),
          'documentName': body?['documentName'],
        };
        _verifications[record['id'] as String] = record;
        await _write(request, 201, data: record);
        return;
      }
      await _write(request, 405, error: 'Method not allowed');
      return;
    }

    if (rest[0] == 'summary') {
      final List<Map<String, dynamic>> mine = _verifications.values
          .where((Map<String, dynamic> v) => v['userId'] == userId)
          .toList();
      await _write(request, 200, data: <String, dynamic>{
        'phone': 'Verified',
        'email': mine.any((Map<String, dynamic> v) => v['type'] == 'Email')
            ? 'Verified'
            : 'NotVerified',
        'identity': mine.any((Map<String, dynamic> v) => v['type'] == 'Identity')
              ? 'Verified'
            : 'NotVerified',
        'skills': 'NotVerified',
      });
      return;
    }

    if (rest.length >= 2 && rest[1] == 'withdraw') {
      final Map<String, dynamic>? record = _verifications[rest[0]];
      if (record == null || record['userId'] != userId) {
        await _write(request, 404, error: 'That request could not be found.');
        return;
      }
      _verifications.remove(rest[0]);
      await _write(request, 200, data: true);
      return;
    }

    await _write(request, 404, error: 'Not found');
  }

  // ---------------------------------------------------------------- support

  Future<void> _supportRoute(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    if (method == 'GET') {
      await _writePaged(
        request,
        _supportReports[userId] ?? <Map<String, dynamic>>[],
      );
      return;
    }
    if (method == 'POST') {
      final Map<String, dynamic> report = <String, dynamic>{
        'id': _id('rep'),
        'userId': userId,
        'category': (body?['category'] ?? 'Other').toString(),
        'description': (body?['description'] ?? '').toString(),
        'status': 'Open',
        'createdAt': _nowIso(),
      };
      _supportReports
          .putIfAbsent(userId, () => <Map<String, dynamic>>[])
          .add(report);
      await _write(request, 201, data: report);
      return;
    }
    await _write(request, 405, error: 'Method not allowed');
  }

  // ---------------------------------------------------------------- devices

  Future<void> _devicesRoute(
    HttpRequest request,
    String method,
    List<String> rest,
    Map<String, dynamic>? body,
    String userId,
  ) async {
    if (rest.isEmpty || rest[0] == 'register') {
      await _write(request, 201, data: <String, dynamic>{
        'id': _id('dev'),
        'token': body?['token'],
        'platform': body?['platform'],
      });
      return;
    }
    await _write(request, 200, data: true);
  }

  // ------------------------------------------------------------------ DTOs

  Map<String, dynamic> _userDto(Map<String, dynamic> user) =>
      <String, dynamic>{
        'id': user['id'],
        'name': user['name'],
        'phone': user['phone'],
        'email': user['email'],
        'role': user['role'],
        'area': user['area'] ?? '',
        'skills': user['skills'] ?? <String>[],
        'rating': user['rating'] ?? 0.0,
        'reviewCount': user['reviewCount'] ?? 0,
        'isVerified': user['verified'] ?? false,
        'isOnline': user['isOnline'] ?? false,
        'status': user['status'] ?? 'Active',
        'company': user['company'],
        'profileImageUrl': user['profileImageUrl'],
        'createdAt': user['createdAt'] ?? _nowIso(),
      };

  Map<String, dynamic> _jobDto(Map<String, dynamic> job) => <String, dynamic>{
    ...job,
    'company': _companyFor(job['giverId'] as String? ?? ''),
    'applicants': _applications.values
        .where((Map<String, dynamic> a) => a['jobId'] == job['id'])
        .length,
  };

  Map<String, dynamic> _applicationDto(Map<String, dynamic> application) =>
      <String, dynamic>{
        ...application,
        'worker': _userDto(
          _users[application['workerId']] ?? <String, dynamic>{'id': ''},
        ),
        'job': _jobs[application['jobId']] == null
            ? null
            : _jobDto(_jobs[application['jobId']]!),
      };

  /// The worker's own view: never carries a check-in code.
  Map<String, dynamic> _assignmentDto(
    Map<String, dynamic> assignment, {
    required bool forGiver,
  }) => <String, dynamic>{
    ...assignment,
    'checkInCode': forGiver ? _checkInCodes[assignment['id'] as String] : null,
    'job': _jobs[assignment['jobId']] == null
        ? null
        : _jobDto(_jobs[assignment['jobId']]!),
    'workerName': _users[assignment['workerId']]?['name'],
  };

  Map<String, dynamic> _historyDto(Map<String, dynamic> assignment) =>
      <String, dynamic>{
        'id': assignment['id'],
        'jobId': assignment['jobId'],
        'jobTitle': _jobs[assignment['jobId']]?['title'],
        'company': _companyFor(assignment['giverId'] as String? ?? ''),
        'date': assignment['confirmedAt'],
        'durationHours': 8,
        'earnings': assignment['totalPay'],
        'paymentStatus': assignment['paymentStatus'],
        'rating': null,
        'ratedByGiver': false,
        'counterpartyId': assignment['giverId'],
        'counterpartyName': _users[assignment['giverId']]?['name'],
        'category': _jobs[assignment['jobId']]?['category'],
      };

  String _companyFor(String giverId) =>
      '${_users[giverId]?['company'] ?? _users[giverId]?['name'] ?? 'Organisation'}';

  // ----------------------------------------------------------------- util

  Map<String, dynamic> _createUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) {
    final Map<String, dynamic> user = <String, dynamic>{
      'id': _id('usr'),
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'role': role,
      'area': '',
      'skills': <String>[],
      'status': 'Active',
      'verified': false,
      'rating': 0.0,
      'reviewCount': 0,
      'createdAt': _nowIso(),
    };
    _users[user['id'] as String] = user;
    if (phone.isNotEmpty) _userByLogin[phone] = user['id'] as String;
    if (email.isNotEmpty) _userByLogin[email] = user['id'] as String;
    return user;
  }

  String? _bearer(HttpRequest request) {
    final String? header = request.headers.value(HttpHeaders.authorizationHeader);
    if (header == null || !header.startsWith('Bearer ')) return null;
    return header.substring(7).trim();
  }

  String? _authenticatedUser(HttpRequest request) {
    final String? token = _bearer(request);
    if (token == null) return null;
    final String? userId = _userByAccess[token];
    if (userId == null) return null;
    return userId;
  }

  Future<Map<String, dynamic>?> _readBody(HttpRequest request) async {
    if (request.method == 'GET' || request.method == 'DELETE') {
      // DELETE still carries a body in a few places.
      if (request.headers.contentLength == 0) return null;
    }
    final String raw = await utf8.decoder.bind(request).join();
    if (raw.trim().isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } on FormatException {
      return null;
    }
  }

  String _nowIso() => DateTime.now().toUtc().toIso8601String();

  List<String> _stringList(Object? value) => <String>[
    if (value is Iterable)
      for (final Object? v in value) '$v'
    else if (value is String && value.isNotEmpty)
      value,
  ];

  bool _flag(String? value) =>
      value != null && <String>['true', '1', 'yes'].contains(value.toLowerCase());

  // ------------------------------------------------------------- responses

  /// The response envelope.
  ///
  /// [error] is the human-readable text the real API puts in `message` on a
  /// failure, so it is an alias for [message] at the call sites.
  Future<void> _write(
    HttpRequest request,
    int status, {
    Object? data,
    String? message,
    String? error,
    List<Map<String, String>>? errors,
  }) async {
    final String? text = message ?? error;
    final Map<String, dynamic> body = <String, dynamic>{
      'success': status >= 200 && status < 300,
      'data': ?data,
      'message': ?text,
      'errors': ?errors,
    };
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await request.response.close();
  }

  /// Wraps [rows] in a paged envelope.
  Future<void> _writePaged(
    HttpRequest request,
    List<Map<String, dynamic>> rows,
  ) async {
    final int pageSize =
        int.tryParse(request.uri.queryParameters['PageSize'] ?? '') ?? 50;
    final int page =
        int.tryParse(request.uri.queryParameters['Page'] ?? '') ?? 1;
    final int total = rows.length;
    final int totalPages = pageSize == 0 ? 1 : (total / pageSize).ceil();
    final List<Map<String, dynamic>> window = pageSize == 0
        ? rows
        : rows.skip((page - 1) * pageSize).take(pageSize).toList();

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(
        jsonEncode(<String, dynamic>{
          'success': true,
          'data': window,
          'pagination': <String, dynamic>{
            'page': page,
            'pageSize': pageSize,
            'totalItems': total,
            'totalPages': totalPages,
            'hasNext': page < totalPages,
            'hasPrevious': page > 1,
          },
        }),
      );
    await request.response.close();
  }
}

class _Session {
  _Session({required this.userId, required this.refreshToken});

  final String userId;
  final String refreshToken;
}
