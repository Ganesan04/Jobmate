import '../../models/application.dart';
import '../../models/earning.dart';
import '../../models/enums.dart';
import '../../models/job.dart';
import '../../models/messaging.dart';
import '../../models/user.dart';
import 'json.dart';
import 'wire.dart';

/// Converts API payloads into the app's domain models.
///
/// Keeping the translation in one place means the domain models stay free of
/// JSON concerns and the screens never see a raw DTO. Anything the API omits
/// falls back to the same default the model declares, so a sparse payload still
/// produces a usable object.
abstract final class Mappers {
  // ------------------------------------------------------------- identity

  static UserProfile userProfile(Map<String, dynamic> json) => UserProfile(
    id: json.str('id'),
    name: json.str('name'),
    phone: json.str('phone'),
    email: json.str('email'),
    role: userRoleFromWire(json['role']),
    area: json.str('area'),
    skills: json.strings('skills'),
    rating: json.decimal('rating'),
    jobsCompleted: json.integer('jobsCompleted'),
    isOnline: json.flag('isOnline'),
    initials: json.strOrNull('initials'),
  );

  /// `AuthResultDto.user` plus the selected role, which the API reports
  /// separately from the account's own role.
  static UserProfile authenticatedUser(Map<String, dynamic> auth) {
    final Map<String, dynamic> user = auth.object('user');
    return userProfile(<String, dynamic>{
      ...user,
      'role': auth['selectedRole'] ?? user['role'],
    });
  }

  static WorkGiverProfile workGiverProfile(Map<String, dynamic> json) =>
      WorkGiverProfile(
        organisation: json.str('organisation'),
        contactPerson: json.str('contactPerson'),
        totalHired: json.integer('totalHired'),
        rating: json.decimal('rating'),
      );

  static VerificationSummary verificationSummary(Map<String, dynamic> json) =>
      VerificationSummary(
        identity: verificationStatusFromWire(json['identity']),
        phone: verificationStatusFromWire(json['phone']),
        email: verificationStatusFromWire(json['email']),
        skills: verificationStatusFromWire(json['skills']),
      );

  static VerificationRecord verificationRecord(Map<String, dynamic> json) =>
      VerificationRecord(
        type: verificationTypeFromWire(json['type']),
        // A request that is still `pending` shows the pending badge; `approved`
        // is the API's word for what the app calls verified.
        status: verificationStatusFromWire(
          json.strOrNull('badgeStatus') ?? _statusToBadge(json.str('status')),
        ),
        submittedOn: json.date('submittedAt'),
        note: json.str('note'),
        documentName: json.str('documentName'),
      );

  static String _statusToBadge(String requestStatus) => switch (requestStatus) {
    'approved' => 'verified',
    'rejected' => 'rejected',
    'pending' => 'pending',
    _ => 'notVerified',
  };

  // ------------------------------------------------------------------ jobs

  static Job job(Map<String, dynamic> json) => Job(
    id: json.str('id'),
    title: json.str('title'),
    company: json.str('company'),
    giverId: json.str('giverId'),
    category: jobCategoryFromWire(json['category']),
    description: json.str('description'),
    date: json.dateOr('date', DateTime.now()),
    startTime: json.str('startTime'),
    endTime: json.str('endTime'),
    reportTime: json.str('reportTime'),
    pay: json.integer('pay'),
    payType: payTypeFromWire(json['payType']),
    workersNeeded: json.integer('workersNeeded'),
    workersFilled: json.integer('workersFilled'),
    area: json.str('area'),
    address: json.str('address'),
    applicants: json.integer('applicants'),
    skills: json.strings('skills'),
    experience: json.str('experience'),
    distanceKm: json.decimal('distanceKm'),
    status: jobStatusFromWire(json['status']),
    workplaceType: workplaceTypeFromWire(json['workplaceType']),
    jobType: jobTypeFromWire(json['jobType']),
    breakMinutes: json.integer('breakMinutes', 30),
    overtimeRate: json.intOrNull('overtimeRate'),
    travelAllowance: json.integer('travelAllowance'),
    foodAllowance: json.integer('foodAllowance'),
    paymentDate: json.date('paymentDate'),
    paymentMethod: paymentMethodFromWire(json['paymentMethod']),
    isRecurring: json.flag('isRecurring'),
    weekdays: <WorkDay>[
      for (final int day in json.integers('weekdays'))
        if (workDayFromNumber(day) case final WorkDay value) value,
    ],
    dressCode: json.str('dressCode'),
    physicalRequirement: json.str('physicalRequirement'),
    vehicleRequired: json.flag('vehicleRequired'),
    safetyInfo: json.str('safetyInfo'),
    emergencyContact: json.str('emergencyContact'),
    contactPerson: json.str('contactPerson'),
    locationVisible: json.flag('locationVisible', true),
    isUrgent: json.flag('isUrgent'),
    createdAt: json.date('createdAt'),
  );

  // ---------------------------------------------------------- applications

  static JobApplication jobApplication(Map<String, dynamic> json) =>
      JobApplication(
        id: json.str('id'),
        jobId: json.str('jobId'),
        workerId: json.str('workerId'),
        status: applicationStatusFromWire(json['status']),
        message: json.str('message'),
        expectedPay: json.intOrNull('expectedPay'),
        availableFrom: json.str('availableFrom', 'Immediately available'),
        appliedAt: json.date('appliedAt'),
        viewedAt: json.date('viewedAt'),
        shortlistedAt: json.date('shortlistedAt'),
        acceptedAt: json.date('acceptedAt'),
      );

  static JobApplicant jobApplicant(Map<String, dynamic> json) => JobApplicant(
    id: json.str('id'),
    jobId: json.str('jobId'),
    worker: userProfile(json.object('worker')),
    status: applicantStatusFromWire(json['status']),
    proposedPay: json.intOrNull('proposedPay'),
    message: json.str('message'),
    appliedAt: json.date('appliedAt'),
    expectedPay: json.intOrNull('expectedPay'),
    distanceKm: json.decimal('distanceKm'),
  );

  static WorkerAssignment workerAssignment(Map<String, dynamic> json) =>
      WorkerAssignment(
        id: json.str('id'),
        jobId: json.str('jobId'),
        workerId: json.str('workerId'),
        giverId: json.str('giverId'),
        agreedPay: json.integer('agreedPay'),
        confirmedAt: json.dateOr('confirmedAt', DateTime.now()),
        paymentStatus: paymentStatusFromWire(json['paymentStatus']),
        checkedInAt: json.date('checkedInAt'),
        checkInCode: json.strOrNull('checkInCode'),
        completedAt: json.date('completedAt'),
        paymentId: json.strOrNull('paymentId'),
        paidAt: json.date('paidAt'),
      );

  static WorkHistoryEntry workHistoryEntry(Map<String, dynamic> json) =>
      WorkHistoryEntry(
        id: json.str('id'),
        jobTitle: json.str('jobTitle'),
        company: json.str('company'),
        date: json.dateOr('date', DateTime.now()),
        durationHours: json.decimal('durationHours'),
        earnings: json.integer('earnings'),
        paymentStatus: paymentStatusFromWire(json['paymentStatus']),
        rating: json.decimalOrNull('rating'),
        ratedByGiver: json.flag('ratedByGiver'),
      );

  static GiverStats giverStats(Map<String, dynamic> json) => GiverStats(
    activeJobs: json.integer('activeJobs'),
    applications: json.integer('applications'),
    toConfirm: json.integer('toConfirm'),
    totalHired: json.integer('totalHired'),
    spentThisMonth: json.integer('spentThisMonth'),
  );

  static WorkerStats workerStats(Map<String, dynamic> json) => WorkerStats(
    applied: json.integer('applied'),
    active: json.integer('active'),
    completed: json.integer('completed'),
    earnings: json.integer('earnings'),
  );

  // -------------------------------------------------------------- earnings

  static Earning earning(Map<String, dynamic> json) => Earning(
    id: json.str('id'),
    workerId: json.str('workerId'),
    jobId: json.str('jobId'),
    jobTitle: json.str('jobTitle'),
    company: json.str('company'),
    date: json.dateOr('date', DateTime.now()),
    amount: json.integer('amount'),
    status: paymentStatusFromWire(json['status']),
    assignmentId: json.strOrNull('assignmentId'),
    paymentId: json.strOrNull('paymentId'),
    method: paymentMethodFromWire(json['method']),
    hours: json.decimalOrNull('hours'),
  );

  static EarningSummary earningSummary(Map<String, dynamic> json) =>
      EarningSummary(
        month: json.str('month', json.str('label')),
        earned: json.integer('earned'),
        pending: json.integer('pending'),
      );

  static PaymentReceipt paymentReceipt(Map<String, dynamic> json) =>
      PaymentReceipt(
        paymentId: json.strOrNull('paymentId') ?? json.str('id'),
        amount: json.integer('amount', json.integer('totalAmount')),
        method: paymentMethodFromWire(json['method']),
        paidAt: json.dateOr('paidAt', DateTime.now()),
        workerName: json.str('workerName'),
        fee: json.integer('fee'),
        overtime: json.integer('overtime'),
      );

  // -------------------------------------------------- messaging + alerts

  static Conversation conversation(Map<String, dynamic> json) => Conversation(
    id: json.str('id'),
    participantId: json.str('participantId'),
    participantName: json.str('participantName'),
    jobContext: json.str('jobContext'),
    unread: json.integer('unread'),
    isOnline: json.flag('isOnline'),
    lastMessage: json.str('lastMessage'),
    lastMessageAt: json.date('lastMessageAt'),
  );

  static Message message(Map<String, dynamic> json) => Message(
    id: json.str('id'),
    conversationId: json.str('conversationId'),
    text: json.str('text'),
    sentAt: json.dateOr('sentAt', DateTime.now()),
    isMine: json.flag('isMine'),
    isRead: json.flag('isRead', true),
  );

  static AppNotification notification(Map<String, dynamic> json) =>
      AppNotification(
        id: json.str('id'),
        type: notificationTypeFromWire(json['type']),
        title: json.str('title'),
        body: json.str('body'),
        createdAt: json.dateOr('createdAt', DateTime.now()),
        isRead: json.flag('isRead'),
        targetRoute: json.strOrNull('targetRoute'),
        targetId: json.strOrNull('targetId'),
      );

  // ---------------------------------------------------------------- ratings

  static WorkerRating workerRating(Map<String, dynamic> json) => WorkerRating(
    id: json.str('id'),
    jobId: json.str('jobId'),
    workerId: json.str('workerId'),
    giverId: json.str('giverId'),
    stars: json.integer('stars'),
    feedback: json.str('feedback'),
    createdAt: json.date('createdAt'),
  );
}
