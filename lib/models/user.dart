import 'package:flutter/material.dart';

import 'enums.dart';

/// Lightweight identity shown across the app (avatars are generated locally).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email = '',
    this.area = '',
    this.skills = const <String>[],
    this.rating = 0,
    this.jobsCompleted = 0,
    this.isOnline = false,
    this.avatarColor,
    this.initials,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final String area;
  final List<String> skills;
  final double rating;
  final int jobsCompleted;
  final bool isOnline;
  final Color? avatarColor;
  final String? initials;

  String get displayInitials {
    if (initials != null && initials!.isNotEmpty) {
      return initials!;
    }
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    String? area,
    List<String>? skills,
    double? rating,
    int? jobsCompleted,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      area: area ?? this.area,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      isOnline: isOnline,
      avatarColor: avatarColor,
      initials: initials,
    );
  }
}

/// Work giver profile with organisation + trust details.
class WorkGiverProfile {
  const WorkGiverProfile({
    this.organisation = '',
    this.contactPerson = '',
    this.totalHired = 0,
    this.rating = 0,
  });

  final String organisation;
  final String contactPerson;
  final int totalHired;
  final double rating;

  WorkGiverProfile copyWith({String? organisation, String? contactPerson}) {
    return WorkGiverProfile(
      organisation: organisation ?? this.organisation,
      contactPerson: contactPerson ?? this.contactPerson,
      totalHired: totalHired,
      rating: rating,
    );
  }
}

/// A single verification row in the Verification Centre.
class VerificationRecord {
  const VerificationRecord({
    required this.type,
    required this.status,
    this.submittedOn,
    this.note = '',
    this.documentName = '',
  });

  final VerificationType type;
  final VerificationStatus status;
  final DateTime? submittedOn;
  final String note;
  final String documentName;

  VerificationRecord copyWith({
    VerificationStatus? status,
    DateTime? submittedOn,
    String? note,
    String? documentName,
  }) {
    return VerificationRecord(
      type: type,
      status: status ?? this.status,
      submittedOn: submittedOn ?? this.submittedOn,
      note: note ?? this.note,
      documentName: documentName ?? this.documentName,
    );
  }
}

/// Aggregate trust score shown on profiles and job details.
class VerificationSummary {
  const VerificationSummary({
    this.identity = VerificationStatus.notVerified,
    this.phone = VerificationStatus.notVerified,
    this.email = VerificationStatus.notVerified,
    this.skills = VerificationStatus.notVerified,
  });

  final VerificationStatus identity;
  final VerificationStatus phone;
  final VerificationStatus email;
  final VerificationStatus skills;

  List<VerificationStatus> get all => <VerificationStatus>[
    identity,
    phone,
    email,
    skills,
  ];

  int get verifiedCount => all
      .where((VerificationStatus s) => s == VerificationStatus.verified)
      .length;

  double get ratio => all.isEmpty ? 0 : verifiedCount / all.length;

  VerificationStatus get overall {
    if (verifiedCount == all.length) return VerificationStatus.verified;
    if (verifiedCount == 0) return VerificationStatus.notVerified;
    return VerificationStatus.pending;
  }

  VerificationSummary copyWith({
    VerificationStatus? identity,
    VerificationStatus? phone,
    VerificationStatus? email,
    VerificationStatus? skills,
  }) {
    return VerificationSummary(
      identity: identity ?? this.identity,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      skills: skills ?? this.skills,
    );
  }
}

/// One line item in the shared profile stats grid.
class ProfileStat {
  const ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}
