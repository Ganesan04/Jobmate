import 'enums.dart';

/// A job listing. One model covers both the worker feed and the giver's jobs.
class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.giverId,
    required this.category,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reportTime,
    required this.pay,
    required this.payType,
    required this.workersNeeded,
    required this.workersFilled,
    required this.area,
    required this.address,
    required this.applicants,
    required this.skills,
    required this.experience,
    required this.distanceKm,
    this.status = JobStatus.active,
    this.workplaceType = WorkplaceType.onSite,
    this.jobType = JobType.oneTime,
    this.breakMinutes = 30,
    this.overtimeRate,
    this.travelAllowance = 0,
    this.foodAllowance = 0,
    this.paymentDate,
    this.paymentMethod = PaymentMethod.upi,
    this.isRecurring = false,
    this.weekdays = const <WorkDay>[],
    this.dressCode = 'Casual / neat attire',
    this.physicalRequirement = 'No heavy lifting',
    this.vehicleRequired = false,
    this.safetyInfo = 'Safety equipment will be provided on site.',
    this.emergencyContact = '',
    this.contactPerson = '',
    this.locationVisible = true,
    this.isUrgent = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String company;
  final String giverId;
  final JobCategory category;
  final String description;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String reportTime;
  final int pay;
  final PayType payType;
  final int workersNeeded;
  final int workersFilled;
  final String area;
  final String address;
  final int applicants;
  final List<String> skills;
  final String experience;
  final double distanceKm;
  final JobStatus status;
  final WorkplaceType workplaceType;
  final JobType jobType;
  final int breakMinutes;
  final int? overtimeRate;
  final int travelAllowance;
  final int foodAllowance;
  final DateTime? paymentDate;
  final PaymentMethod paymentMethod;
  final bool isRecurring;
  final List<WorkDay> weekdays;
  final String dressCode;
  final String physicalRequirement;
  final bool vehicleRequired;
  final String safetyInfo;
  final String emergencyContact;
  final String contactPerson;
  final bool locationVisible;
  final bool isUrgent;
  final DateTime? createdAt;

  /// Total payout for one worker, including allowances.
  int get totalPayout => pay + travelAllowance + foodAllowance;

  String get timeRange => '$startTime – $endTime';

  int get remainingWorkers => (workersNeeded - workersFilled).clamp(0, 999);

  String get experienceLabel =>
      experience.isEmpty ? 'Any experience' : experience;

  Job copyWith({
    String? title,
    String? company,
    JobCategory? category,
    String? description,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? reportTime,
    int? pay,
    PayType? payType,
    int? workersNeeded,
    int? workersFilled,
    String? area,
    String? address,
    int? applicants,
    List<String>? skills,
    String? experience,
    double? distanceKm,
    JobStatus? status,
    WorkplaceType? workplaceType,
    JobType? jobType,
    int? breakMinutes,
    int? overtimeRate,
    int? travelAllowance,
    int? foodAllowance,
    DateTime? paymentDate,
    PaymentMethod? paymentMethod,
    bool? isRecurring,
    List<WorkDay>? weekdays,
    String? dressCode,
    String? physicalRequirement,
    bool? vehicleRequired,
    String? safetyInfo,
    String? emergencyContact,
    String? contactPerson,
    bool? locationVisible,
    bool? isUrgent,
    DateTime? createdAt,
  }) {
    return Job(
      id: id,
      title: title ?? this.title,
      company: company ?? this.company,
      giverId: giverId,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reportTime: reportTime ?? this.reportTime,
      pay: pay ?? this.pay,
      payType: payType ?? this.payType,
      workersNeeded: workersNeeded ?? this.workersNeeded,
      workersFilled: workersFilled ?? this.workersFilled,
      area: area ?? this.area,
      address: address ?? this.address,
      applicants: applicants ?? this.applicants,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      distanceKm: distanceKm ?? this.distanceKm,
      status: status ?? this.status,
      workplaceType: workplaceType ?? this.workplaceType,
      jobType: jobType ?? this.jobType,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      travelAllowance: travelAllowance ?? this.travelAllowance,
      foodAllowance: foodAllowance ?? this.foodAllowance,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRecurring: isRecurring ?? this.isRecurring,
      weekdays: weekdays ?? this.weekdays,
      dressCode: dressCode ?? this.dressCode,
      physicalRequirement: physicalRequirement ?? this.physicalRequirement,
      vehicleRequired: vehicleRequired ?? this.vehicleRequired,
      safetyInfo: safetyInfo ?? this.safetyInfo,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      contactPerson: contactPerson ?? this.contactPerson,
      locationVisible: locationVisible ?? this.locationVisible,
      isUrgent: isUrgent ?? this.isUrgent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Filters used by the Search Jobs screen.
class JobFilter {
  const JobFilter({
    this.query = '',
    this.categories = const <JobCategory>{},
    this.date,
    this.minPay,
    this.maxPay,
    this.maxDistanceKm,
    this.jobType,
    this.verifiedOnly = false,
    this.urgentOnly = false,
  });

  final String query;
  final Set<JobCategory> categories;
  final DateTime? date;
  final int? minPay;
  final int? maxPay;
  final double? maxDistanceKm;
  final JobType? jobType;
  final bool verifiedOnly;
  final bool urgentOnly;

  int get activeCount {
    int count = categories.length;
    if (date != null) count++;
    if (minPay != null || maxPay != null) count++;
    if (maxDistanceKm != null) count++;
    if (jobType != null) count++;
    if (verifiedOnly) count++;
    if (urgentOnly) count++;
    return count;
  }

  JobFilter copyWith({
    String? query,
    Set<JobCategory>? categories,
    DateTime? date,
    int? minPay,
    int? maxPay,
    double? maxDistanceKm,
    JobType? jobType,
    bool? verifiedOnly,
    bool? urgentOnly,
    bool clearDate = false,
    bool clearPay = false,
    bool clearDistance = false,
    bool clearJobType = false,
  }) {
    return JobFilter(
      query: query ?? this.query,
      categories: categories ?? this.categories,
      date: clearDate ? null : (date ?? this.date),
      minPay: clearPay ? null : (minPay ?? this.minPay),
      maxPay: clearPay ? null : (maxPay ?? this.maxPay),
      maxDistanceKm: clearDistance
          ? null
          : (maxDistanceKm ?? this.maxDistanceKm),
      jobType: clearJobType ? null : (jobType ?? this.jobType),
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      urgentOnly: urgentOnly ?? this.urgentOnly,
    );
  }
}

enum JobSort {
  newest('Newest first'),
  payHigh('Pay: high to low'),
  payLow('Pay: low to high'),
  nearest('Nearest first');

  const JobSort(this.label);

  final String label;
}

/// A saved / favourite job id tracked per user.
class SavedJob {
  const SavedJob({required this.jobId, required this.savedAt});

  final String jobId;
  final DateTime savedAt;
}
