import 'package:flutter/material.dart';
import 'package:jobmate/models/admin.dart';
import 'package:jobmate/models/application.dart';
import 'package:jobmate/models/earning.dart';
import 'package:jobmate/models/enums.dart';
import 'package:jobmate/models/job.dart';
import 'package:jobmate/models/messaging.dart';
import 'package:jobmate/models/support.dart';
import 'package:jobmate/models/user.dart';

/// Seed data for the in-memory data layer used by the widget tests.
///
/// The ids and names are the contract the tests assert on, so they live here
/// rather than being scattered through the fakes.
abstract final class Fixtures {
  /// Every seeded account shares this password.
  static const String memberPassword = 'jobmate123';

  /// The console is a separate sign-in from the member app.
  static const String adminEmail = 'admin@jobmate.in';
  static const String adminPassword = 'admin123';

  /// The account the tests act as when no session has been established.
  static const String defaultActorId = 'u-giver-1';

  // ------------------------------------------------------------- accounts

  static UserProfile ravi() => const UserProfile(
    id: 'u-worker-1',
    name: 'Ravi Kumar',
    phone: '9876543210',
    email: 'ravi@jobmate.in',
    role: UserRole.worker,
    area: 'Koramangala',
    skills: <String>['Packing', 'Loading'],
    rating: 4.6,
    jobsCompleted: 12,
  );

  static UserProfile priya() => const UserProfile(
    id: 'u-worker-2',
    name: 'Priya Nair',
    phone: '9876543211',
    email: 'priya.nair@example.com',
    role: UserRole.worker,
    area: 'Indiranagar',
    skills: <String>['Retail'],
  );

  static UserProfile amit() => const UserProfile(
    id: 'u-worker-3',
    name: 'Amit Verma',
    phone: '9876543212',
    email: 'amit.verma@example.com',
    role: UserRole.worker,
    area: 'Whitefield',
  );

  static UserProfile aarav() => const UserProfile(
    id: 'u-giver-1',
    name: 'Aarav Malhotra',
    phone: '9811122233',
    email: 'aarav@brightevents.in',
    role: UserRole.workGiver,
    area: 'Koramangala',
  );

  static UserProfile meera() => const UserProfile(
    id: 'u-giver-2',
    name: 'Meera Shah',
    phone: '9811100011',
    email: 'meera@shop.in',
    role: UserRole.workGiver,
    area: 'Jayanagar',
  );

  static UserProfile deepak() => const UserProfile(
    id: 'u-giver-3',
    name: 'Deepak Rao',
    phone: '9811100022',
    email: 'deepak@stores.in',
    role: UserRole.workGiver,
    area: 'Jayanagar',
  );

  /// Members only. The console account is deliberately absent so that
  /// `totalUsers == workers + workGivers` holds on the admin dashboard.
  static List<UserProfile> members() => <UserProfile>[
    ravi(),
    priya(),
    amit(),
    aarav(),
    meera(),
    deepak(),
  ];

  static List<AdminUser> adminUsers() {
    final DateTime joined = DateTime(2026, 1, 12);
    return <AdminUser>[
      AdminUser(
        id: ravi().id,
        name: ravi().name,
        phone: ravi().phone,
        role: UserRole.worker,
        verification: VerificationStatus.verified,
        isActive: true,
        joinedOn: joined,
        jobsCount: 12,
        area: ravi().area,
      ),
      AdminUser(
        id: priya().id,
        name: priya().name,
        phone: priya().phone,
        role: UserRole.worker,
        verification: VerificationStatus.pending,
        isActive: true,
        joinedOn: joined.add(const Duration(days: 4)),
        jobsCount: 3,
        area: priya().area,
      ),
      AdminUser(
        id: amit().id,
        name: amit().name,
        phone: amit().phone,
        role: UserRole.worker,
        verification: VerificationStatus.notVerified,
        isActive: false,
        joinedOn: joined.add(const Duration(days: 9)),
        area: amit().area,
      ),
      AdminUser(
        id: aarav().id,
        name: aarav().name,
        phone: aarav().phone,
        role: UserRole.workGiver,
        verification: VerificationStatus.verified,
        isActive: true,
        joinedOn: joined,
        jobsCount: 8,
        area: aarav().area,
      ),
      AdminUser(
        id: meera().id,
        name: meera().name,
        phone: meera().phone,
        role: UserRole.workGiver,
        verification: VerificationStatus.notVerified,
        isActive: true,
        joinedOn: joined.add(const Duration(days: 6)),
        jobsCount: 2,
        area: meera().area,
      ),
      AdminUser(
        id: deepak().id,
        name: deepak().name,
        phone: deepak().phone,
        role: UserRole.workGiver,
        verification: VerificationStatus.verified,
        isActive: true,
        joinedOn: joined.add(const Duration(days: 2)),
        jobsCount: 5,
        area: deepak().area,
      ),
    ];
  }

  static WorkGiverProfile giverProfile(String id) => WorkGiverProfile(
    organisation: switch (id) {
      'u-giver-2' => 'Meera Textiles',
      'u-giver-3' => 'Rao Superstores',
      _ => 'Bright Events',
    },
    contactPerson: members()
        .firstWhere((UserProfile p) => p.id == id)
        .name,
    totalHired: 12,
    rating: 4.8,
  );

  // ----------------------------------------------------------------- jobs

  /// Builds a job with sensible defaults so each fixture only states what the
  /// test cares about.
  static Job job({
    required String id,
    required String title,
    required String company,
    required String giverId,
    required JobCategory category,
    required String description,
    required int pay,
    required DateTime date,
    JobStatus status = JobStatus.active,
    int workersNeeded = 2,
    int workersFilled = 0,
    int applicants = 0,
    double distanceKm = 2.4,
    List<String> skills = const <String>[],
  }) => Job(
    id: id,
    title: title,
    company: company,
    giverId: giverId,
    category: category,
    description: description,
    date: date,
    startTime: '6:00 AM',
    endTime: '2:00 PM',
    reportTime: '5:30 AM',
    pay: pay,
    payType: PayType.daily,
    workersNeeded: workersNeeded,
    workersFilled: workersFilled,
    area: 'Koramangala',
    address: '4th Block, Koramangala, Bengaluru',
    applicants: applicants,
    skills: skills,
    experience: 'Fresher is fine',
    distanceKm: distanceKm,
    status: status,
    createdAt: date,
  );

  static List<Job> jobs() {
    final DateTime now = DateTime.now();
    return <Job>[
      // u-giver-1 owns these; the first is the one the giver lifecycle tests
      // pick up, and it is seeded with applicants led by u-worker-1.
      job(
        id: 'j-2',
        title: 'Warehouse packing helper',
        company: 'Bright Events',
        giverId: 'u-giver-1',
        category: JobCategory.retail,
        description: 'Pack and label incoming cartons on the morning shift.',
        pay: 700,
        date: now.add(const Duration(days: 1)),
        applicants: 2,
        skills: <String>['Packing'],
      ),
      job(
        id: 'j-1',
        title: 'Event setup crew for expo stalls',
        company: 'Bright Events',
        giverId: 'u-giver-1',
        category: JobCategory.events,
        description: 'Build expo stalls and carry furniture before doors open.',
        pay: 900,
        date: now.add(const Duration(days: 2)),
        applicants: 2,
        skills: <String>['Event setup', 'Loading'],
      ),
      job(
        id: 'j-7',
        title: 'Office deep clean',
        company: 'Bright Events',
        giverId: 'u-giver-1',
        category: JobCategory.cleaning,
        description: 'Deep clean the meeting rooms and pantry after hours.',
        pay: 1000,
        date: now.subtract(const Duration(days: 6)),
        status: JobStatus.completed,
        workersNeeded: 1,
        workersFilled: 1,
        applicants: 1,
      ),
      job(
        id: 'j-3',
        title: 'Weekend retail counter',
        company: 'Meera Textiles',
        giverId: 'u-giver-2',
        category: JobCategory.retail,
        description: 'Billing counter and customer help for the weekend sale.',
        pay: 650,
        date: now.add(const Duration(days: 3)),
        applicants: 1,
      ),
      job(
        id: 'j-4',
        title: 'Deep cleaning apartment',
        company: 'Rao Superstores',
        giverId: 'u-giver-3',
        category: JobCategory.cleaning,
        description: 'Full apartment deep clean including kitchen and bathrooms.',
        pay: 1200,
        date: now.add(const Duration(days: 4)),
      ),
      job(
        id: 'j-5',
        title: 'Security guard for event venue',
        company: 'Rao Superstores',
        giverId: 'u-giver-3',
        category: JobCategory.security,
        description: 'Gate and floor security for a weekend event venue.',
        pay: 1100,
        date: now.add(const Duration(days: 5)),
        skills: <String>['Security'],
      ),
      job(
        id: 'j-6',
        title: 'Garden maintenance',
        company: 'Meera Textiles',
        giverId: 'u-giver-2',
        category: JobCategory.other,
        description: 'Weeding and pruning for a small apartment garden.',
        pay: 800,
        date: now.add(const Duration(days: 7)),
        status: JobStatus.draft,
      ),
    ];
  }

  // --------------------------------------------------------- applications

  static List<JobApplication> applications() {
    final DateTime now = DateTime.now();
    return <JobApplication>[
      JobApplication(
        id: 'a-1',
        jobId: 'j-3',
        workerId: 'u-worker-1',
        status: ApplicationStatus.applied,
        message: 'Available all weekend.',
        appliedAt: now.subtract(const Duration(days: 1)),
      ),
      JobApplication(
        id: 'a-2',
        jobId: 'j-2',
        workerId: 'u-worker-1',
        status: ApplicationStatus.accepted,
        message: 'Three years of packing experience.',
        appliedAt: now.subtract(const Duration(days: 2)),
        acceptedAt: now.subtract(const Duration(days: 1)),
      ),
      JobApplication(
        id: 'a-3',
        jobId: 'j-5',
        workerId: 'u-worker-1',
        status: ApplicationStatus.withdrawn,
        message: 'Clashed with another booking.',
        appliedAt: now.subtract(const Duration(days: 3)),
      ),
      JobApplication(
        id: 'a-4',
        jobId: 'j-7',
        workerId: 'u-worker-1',
        status: ApplicationStatus.accepted,
        message: 'Happy to take the late slot.',
        appliedAt: now.subtract(const Duration(days: 8)),
        acceptedAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }

  /// The giver's view. u-worker-1 leads j-2 so the payment tests end up crediting
  /// the wallet that the worker provider is already watching.
  static List<JobApplicant> jobApplicants() => <JobApplicant>[
    JobApplicant(
      id: 'ap-1',
      jobId: 'j-2',
      worker: ravi(),
      status: ApplicantStatus.applied,
      message: 'Three years of packing experience.',
      expectedPay: 750,
      appliedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    JobApplicant(
      id: 'ap-2',
      jobId: 'j-2',
      worker: priya(),
      status: ApplicantStatus.shortlisted,
      message: 'Can start at 6 AM.',
      expectedPay: 700,
      appliedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    JobApplicant(
      id: 'ap-3',
      jobId: 'j-1',
      worker: priya(),
      status: ApplicantStatus.applied,
      message: 'Did two expos last season.',
      expectedPay: 900,
      appliedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    JobApplicant(
      id: 'ap-4',
      jobId: 'j-1',
      worker: amit(),
      status: ApplicantStatus.applied,
      expectedPay: 850,
      appliedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    JobApplicant(
      id: 'ap-5',
      jobId: 'j-7',
      worker: ravi(),
      status: ApplicantStatus.selected,
      proposedPay: 1000,
      appliedAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
  ];

  static List<WorkerAssignment> assignments() {
    final DateTime now = DateTime.now();
    return <WorkerAssignment>[
      WorkerAssignment(
        id: 'as-1',
        jobId: 'j-2',
        workerId: 'u-worker-1',
        giverId: 'u-giver-1',
        agreedPay: 800,
        confirmedAt: now.subtract(const Duration(days: 1)),
        checkInCode: '4821',
      ),
      WorkerAssignment(
        id: 'as-2',
        jobId: 'j-7',
        workerId: 'u-worker-1',
        giverId: 'u-giver-1',
        agreedPay: 1000,
        confirmedAt: now.subtract(const Duration(days: 7)),
        completedAt: now.subtract(const Duration(days: 6)),
        paymentStatus: PaymentStatus.paid,
        paymentId: 'pay-seed-1',
        paidAt: now.subtract(const Duration(days: 6)),
      ),
    ];
  }

  static List<WorkHistoryEntry> workHistory() {
    final DateTime now = DateTime.now();
    return <WorkHistoryEntry>[
      WorkHistoryEntry(
        id: 'as-2',
        jobTitle: 'Office deep clean',
        company: 'Bright Events',
        date: now.subtract(const Duration(days: 6)),
        durationHours: 7.5,
        earnings: 1000,
        paymentStatus: PaymentStatus.paid,
        rating: 4.8,
        ratedByGiver: true,
      ),
    ];
  }

  // -------------------------------------------------------------- earnings

  static List<Earning> earnings() {
    final DateTime now = DateTime.now();
    return <Earning>[
      Earning(
        id: 'e-1',
        workerId: 'u-worker-1',
        assignmentId: 'as-2',
        jobId: 'j-7',
        jobTitle: 'Office deep clean',
        company: 'Bright Events',
        date: now.subtract(const Duration(days: 6)),
        amount: 1000,
        status: PaymentStatus.paid,
        paymentId: 'pay-seed-1',
        hours: 7.5,
      ),
      Earning(
        id: 'e-2',
        workerId: 'u-worker-1',
        jobId: 'j-4',
        jobTitle: 'Deep cleaning apartment',
        company: 'Rao Superstores',
        date: now.subtract(const Duration(days: 3)),
        amount: 850,
        status: PaymentStatus.paid,
        hours: 6,
      ),
      Earning(
        id: 'e-3',
        workerId: 'u-worker-1',
        jobId: 'j-5',
        jobTitle: 'Security guard for event venue',
        company: 'Rao Superstores',
        date: now,
        amount: 500,
        status: PaymentStatus.pending,
      ),
    ];
  }

  // ------------------------------------------------------------ messaging

  static List<Conversation> conversations() {
    final DateTime now = DateTime.now();
    return <Conversation>[
      Conversation(
        id: 'c-1',
        participantId: 'u-giver-1',
        participantName: 'Aarav Malhotra',
        jobContext: 'Event setup crew for expo stalls',
        unread: 2,
        isOnline: true,
        lastMessage: 'See you at 6 AM.',
        lastMessageAt: now.subtract(const Duration(minutes: 20)),
      ),
      Conversation(
        id: 'c-2',
        participantId: 'u-worker-2',
        participantName: 'Priya Nair',
        jobContext: 'Weekend retail counter',
        lastMessage: 'Thanks, will do.',
        lastMessageAt: now.subtract(const Duration(hours: 3)),
      ),
      Conversation(
        id: 'c-3',
        participantId: 'u-giver-3',
        participantName: 'Deepak Rao',
        jobContext: 'Security guard for event venue',
        unread: 1,
        lastMessage: 'Please carry your ID.',
        lastMessageAt: now.subtract(const Duration(days: 1)),
      ),
      Conversation(
        id: 'c-4',
        participantId: 'u-giver-2',
        participantName: 'Meera Shah',
        jobContext: 'Garden maintenance',
        lastMessage: 'Any update?',
        lastMessageAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  static Map<String, List<Message>> threads() {
    final DateTime now = DateTime.now();
    return <String, List<Message>>{
      'c-1': <Message>[
        Message(
          id: 'm-1',
          conversationId: 'c-1',
          text: 'Are you available on Saturday?',
          sentAt: now.subtract(const Duration(hours: 1)),
          isMine: false,
        ),
        Message(
          id: 'm-2',
          conversationId: 'c-1',
          text: 'See you at 6 AM.',
          sentAt: now.subtract(const Duration(minutes: 20)),
          isMine: true,
        ),
      ],
    };
  }

  static List<AppNotification> notifications() {
    final DateTime now = DateTime.now();
    return <AppNotification>[
      AppNotification(
        id: 'n-1',
        type: NotificationType.payment,
        title: 'Payment released',
        body: 'Rs 1000 released for Office deep clean.',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n-2',
        type: NotificationType.payment,
        title: 'Payment pending',
        body: 'Rs 500 is still processing.',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: 'n-3',
        type: NotificationType.applicationUpdate,
        title: 'Application viewed',
        body: 'Meera Textiles viewed your application.',
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
      AppNotification(
        id: 'n-4',
        type: NotificationType.jobReminder,
        title: 'Shift tomorrow',
        body: 'Warehouse packing helper starts at 6:00 AM.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  // ----------------------------------------------------------------- admin

  static List<Dispute> disputes() {
    final DateTime now = DateTime.now();
    return <Dispute>[
      Dispute(
        id: 'd-1',
        reason: ReportReason.notPaid,
        raisedBy: 'Ravi Kumar',
        againstUser: 'Aarav Malhotra',
        jobTitle: 'Warehouse packing helper',
        company: 'Bright Events',
        raisedAt: now.subtract(const Duration(hours: 6)),
        status: DisputeStatus.open,
        amount: 800,
        details: 'Released on 12 May but never received.',
      ),
      Dispute(
        id: 'd-2',
        reason: ReportReason.noShow,
        raisedBy: 'Priya Nair',
        againstUser: 'Meera Shah',
        jobTitle: 'Weekend retail counter',
        company: 'Meera Textiles',
        raisedAt: now.subtract(const Duration(days: 2)),
        status: DisputeStatus.underReview,
        amount: 650,
      ),
      Dispute(
        id: 'd-3',
        reason: ReportReason.fakeJob,
        raisedBy: 'Amit Verma',
        againstUser: 'Deepak Rao',
        jobTitle: 'Garden maintenance',
        company: 'Rao Superstores',
        raisedAt: now.subtract(const Duration(days: 9)),
        status: DisputeStatus.resolved,
        amount: 800,
        notes: 'Listing removed.',
      ),
    ];
  }

  static List<VerificationRequest> verificationRequests() {
    final DateTime now = DateTime.now();
    return <VerificationRequest>[
      VerificationRequest(
        id: 'vr-1',
        userId: 'u-worker-2',
        userName: 'Priya Nair',
        userRole: UserRole.worker,
        type: VerificationType.identity,
        submittedAt: now.subtract(const Duration(hours: 5)),
        document: 'priya-aadhaar.pdf',
      ),
      VerificationRequest(
        id: 'vr-2',
        userId: 'u-giver-2',
        userName: 'Meera Shah',
        userRole: UserRole.workGiver,
        type: VerificationType.address,
        submittedAt: now.subtract(const Duration(days: 1)),
        document: 'shop-lease.pdf',
      ),
      VerificationRequest(
        id: 'vr-3',
        userId: 'u-worker-1',
        userName: 'Ravi Kumar',
        userRole: UserRole.worker,
        type: VerificationType.identity,
        submittedAt: now.subtract(const Duration(days: 12)),
        status: VerificationStatus.verified,
        document: 'ravi-aadhaar.pdf',
        note: 'Checked against the profile details.',
      ),
    ];
  }

  /// Per-member verification rows, keyed by account then check type.
  static Map<String, Map<VerificationType, VerificationRecord>> verifications() {
    return <String, Map<VerificationType, VerificationRecord>>{
      'u-worker-1': <VerificationType, VerificationRecord>{
        VerificationType.identity: VerificationRecord(
          type: VerificationType.identity,
          status: VerificationStatus.verified,
          submittedOn: DateTime(2026, 1, 12),
          documentName: 'ravi-aadhaar.pdf',
        ),
        VerificationType.phone: VerificationRecord(
          type: VerificationType.phone,
          status: VerificationStatus.verified,
          submittedOn: DateTime(2026, 1, 12),
        ),
        VerificationType.email: VerificationRecord(
          type: VerificationType.email,
          status: VerificationStatus.notVerified,
        ),
        VerificationType.skills: VerificationRecord(
          type: VerificationType.skills,
          status: VerificationStatus.notVerified,
        ),
      },
    };
  }

  // ------------------------------------------------------------------ help

  static List<HelpArticle> articles() => const <HelpArticle>[
    HelpArticle(
      id: 'ha-1',
      question: 'How do I get paid?',
      answer: 'The work giver releases pay from the app once the shift is done.',
      category: 'Payments',
    ),
    HelpArticle(
      id: 'ha-2',
      question: 'How do I apply for a job?',
      answer: 'Open the job and tap Apply. The giver replies from My jobs.',
      category: 'Finding work',
    ),
    HelpArticle(
      id: 'ha-3',
      question: 'What if I am not paid?',
      answer: 'Raise a report from Help and support and we will follow up.',
      category: 'Payments',
    ),
  ];

  static List<HelpCategory> helpCategories() => const <HelpCategory>[
    HelpCategory(
      title: 'Payments',
      subtitle: 'Pay cycles, releases and disputes',
      icon: Icons.payments_rounded,
      color: Color(0xFF7C3AED),
    ),
    HelpCategory(
      title: 'Finding work',
      subtitle: 'Applications and interviews',
      icon: Icons.work_rounded,
      color: Color(0xFF0EA5E9),
    ),
  ];
}
