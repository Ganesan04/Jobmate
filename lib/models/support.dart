import 'package:flutter/material.dart';

import 'enums.dart';

/// FAQ / help article.
class HelpArticle {
  const HelpArticle({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });

  final String id;
  final String question;
  final String answer;
  final String category;
}

class HelpCategory {
  const HelpCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

/// A support / safety report created by a user.
class SupportReport {
  const SupportReport({
    required this.id,
    required this.reason,
    required this.details,
    required this.submittedAt,
    required this.relatedJob,
  });

  final String id;
  final ReportReason reason;
  final String details;
  final DateTime submittedAt;
  final String relatedJob;
}

/// A user submitted support ticket stored locally.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.body,
    required this.createdAt,
    this.status = 'Open',
  });

  final String id;
  final String subject;
  final String body;
  final DateTime createdAt;
  final String status;
}
