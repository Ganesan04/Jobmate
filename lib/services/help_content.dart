import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/support.dart';

/// Help-centre copy that ships with the app.
///
/// The API exposes support *reports* but has no endpoint for FAQ content, so
/// this is presentation copy rather than server data. Move it behind an endpoint
/// if the copy ever needs to change without an app release.
abstract final class HelpContent {
  static const List<HelpArticle> articles = <HelpArticle>[
    HelpArticle(
      id: 'f-1',
      question: 'How do I get paid after finishing a job?',
      answer:
          'Work givers release payment from the Payment screen once the work is marked complete. '
          'UPI payments usually reflect within 30 minutes, bank transfers within 2 working days.',
      category: 'Payments',
    ),
    HelpArticle(
      id: 'f-2',
      question: 'Why was my application rejected?',
      answer:
          'Work givers reject applications when the required skills or experience do not match, or '
          'when they have already filled the required number of workers. You will see the reason on '
          'the application detail screen.',
      category: 'Applications',
    ),
    HelpArticle(
      id: 'f-3',
      question: 'What is the check-in code used for?',
      answer:
          'The work giver shares a 4-digit check-in code on the accepted job screen. Enter it once you '
          'reach the workplace so attendance and payment can be verified.',
      category: 'Working',
    ),
    HelpArticle(
      id: 'f-4',
      question: 'How do I report a problem?',
      answer:
          'Open Help from your profile, choose Report a problem, pick the related job and describe the '
          'issue. Our team reads every report within 48 hours.',
      category: 'Safety',
    ),
    HelpArticle(
      id: 'f-5',
      question: 'How do verifications work?',
      answer:
          'Verify once and the badge shows whether you are working or hiring. Your phone is verified '
          'by OTP; ID and skill documents are verified as soon as you submit them.',
      category: 'Account',
    ),
  ];

  static const List<HelpCategory> categories = <HelpCategory>[
    HelpCategory(
      title: 'Frequently asked',
      subtitle: 'Quick answers to common questions',
      icon: Icons.quiz_outlined,
      color: AppColors.workerPrimary,
    ),
    HelpCategory(
      title: 'Contact support',
      subtitle: 'Chat or call us, 9 AM – 9 PM',
      icon: Icons.support_agent_rounded,
      color: AppColors.giverPrimary,
    ),
    HelpCategory(
      title: 'Report a problem',
      subtitle: 'Report an unsafe job or a payment issue',
      icon: Icons.report_gmailerrorred_rounded,
      color: AppColors.error,
    ),
    HelpCategory(
      title: 'Safety & trust',
      subtitle: 'Stay safe on the job',
      icon: Icons.health_and_safety_rounded,
      color: AppColors.warning,
    ),
  ];

  static const String supportPhone = '1800 123 4567';
  static const String supportEmail = 'support@jobmate.in';
}
