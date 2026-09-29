import 'enums.dart';

/// Multi-step Create Job form state.
///
/// Mirrors the prototype's field set exactly so the same data can be sent to a
/// real backend later as one `CreateJobRequest` payload.
class JobDraft {
  const JobDraft({
    this.title = '',
    this.category,
    this.description = '',
    this.workersNeeded = 1,
    this.skills = const <String>[],
    this.experience = '',
    this.date,
    this.startTime,
    this.endTime,
    this.reportTime,
    this.isRecurring = false,
    this.weekdays = const <WorkDay>[],
    this.breakMinutes = 30,
    this.pay,
    this.payType = PayType.daily,
    this.overtimeRate,
    this.travelAllowance = 0,
    this.foodAllowance = 0,
    this.paymentDate,
    this.paymentMethod = PaymentMethod.upi,
    this.area = '',
    this.address = '',
    this.workplaceType = WorkplaceType.onSite,
    this.locationVisible = true,
    this.contactPerson = '',
    this.safetyInfo = '',
    this.physicalRequirement = '',
    this.dressCode = '',
    this.vehicleRequired = false,
    this.emergencyContact = '',
  });

  // Step 1 — basic details
  final String title;
  final JobCategory? category;
  final String description;

  // Step 2 — requirements
  final int workersNeeded;
  final List<String> skills;
  final String experience;

  // Step 3 — schedule
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final String? reportTime;
  final bool isRecurring;
  final List<WorkDay> weekdays;
  final int breakMinutes;

  // Step 4 — payment
  final int? pay;
  final PayType payType;
  final int? overtimeRate;
  final int travelAllowance;
  final int foodAllowance;
  final DateTime? paymentDate;
  final PaymentMethod paymentMethod;

  // Step 5 — location
  final String area;
  final String address;
  final WorkplaceType workplaceType;
  final bool locationVisible;

  // Step 6 — contact & safety
  final String contactPerson;
  final String safetyInfo;
  final String physicalRequirement;
  final String dressCode;
  final bool vehicleRequired;
  final String emergencyContact;

  bool get isReadyToPublish =>
      title.trim().isNotEmpty &&
      category != null &&
      description.trim().isNotEmpty &&
      date != null &&
      startTime != null &&
      endTime != null &&
      reportTime != null &&
      pay != null &&
      area.trim().isNotEmpty &&
      address.trim().isNotEmpty;

  /// Progress in the 6 step wizard, used by the step indicator.
  double get completion => isReadyToPublish ? 1 : 0.55;

  JobDraft copyWith({
    String? title,
    JobCategory? category,
    String? description,
    int? workersNeeded,
    List<String>? skills,
    String? experience,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? reportTime,
    bool? isRecurring,
    List<WorkDay>? weekdays,
    int? breakMinutes,
    int? pay,
    PayType? payType,
    int? overtimeRate,
    int? travelAllowance,
    int? foodAllowance,
    DateTime? paymentDate,
    PaymentMethod? paymentMethod,
    String? area,
    String? address,
    WorkplaceType? workplaceType,
    bool? locationVisible,
    String? contactPerson,
    String? safetyInfo,
    String? physicalRequirement,
    String? dressCode,
    bool? vehicleRequired,
    String? emergencyContact,
  }) {
    return JobDraft(
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      workersNeeded: workersNeeded ?? this.workersNeeded,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reportTime: reportTime ?? this.reportTime,
      isRecurring: isRecurring ?? this.isRecurring,
      weekdays: weekdays ?? this.weekdays,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      pay: pay ?? this.pay,
      payType: payType ?? this.payType,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      travelAllowance: travelAllowance ?? this.travelAllowance,
      foodAllowance: foodAllowance ?? this.foodAllowance,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      area: area ?? this.area,
      address: address ?? this.address,
      workplaceType: workplaceType ?? this.workplaceType,
      locationVisible: locationVisible ?? this.locationVisible,
      contactPerson: contactPerson ?? this.contactPerson,
      safetyInfo: safetyInfo ?? this.safetyInfo,
      physicalRequirement: physicalRequirement ?? this.physicalRequirement,
      dressCode: dressCode ?? this.dressCode,
      vehicleRequired: vehicleRequired ?? this.vehicleRequired,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}
