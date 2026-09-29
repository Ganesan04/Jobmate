import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../constants/app_spacing.dart';
import '../utils/context_extensions.dart';

/// Generated avatar (initials on a role-tinted gradient) with optional online dot
/// and a tap target. Keeps a consistent size across every screen.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.size = AppSizes.avatarMd,
    this.initials,
    this.color,
    this.isOnline = false,
    this.showOnlineDot = false,
    this.onTap,
    this.semanticLabel,
    this.badge,
  });

  factory ProfileAvatar.user(
    UserProfile user, {
    double size = AppSizes.avatarMd,
    bool showOnlineDot = false,
    VoidCallback? onTap,
  }) {
    return ProfileAvatar(
      name: user.name,
      initials: user.displayInitials,
      size: size,
      showOnlineDot: showOnlineDot,
      isOnline: user.isOnline,
      onTap: onTap,
    );
  }

  final String name;
  final double size;
  final String? initials;
  final Color? color;
  final bool isOnline;
  final bool showOnlineDot;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Widget? badge;

  static const List<List<Color>> _gradients = <List<Color>>[
    <Color>[Color(0xFF0F766E), Color(0xFF14B8A6)],
    <Color>[Color(0xFF7C3AED), Color(0xFFA78BFA)],
    <Color>[Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    <Color>[Color(0xFFF59E0B), Color(0xFFFBBF24)],
    <Color>[Color(0xFF10B981), Color(0xFF34D399)],
    <Color>[Color(0xFFEF4444), Color(0xFFF87171)],
  ];

  String get _initials {
    if (initials != null && initials!.isNotEmpty) return initials!;
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  List<Color> get _colors {
    final int index = name.codeUnits.fold<int>(0, (int sum, int c) => sum + c);
    return _gradients[index % _gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = color == null
        ? _colors
        : <Color>[color!, color!];
    final double fontSize = (size * 0.38).clamp(11, 26);
    final double dotSize = (size * 0.28).clamp(9, 16);

    final Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: size > 60 ? 3 : 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );

    final Widget withBadge = showOnlineDot
        ? Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              avatar,
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          )
        : avatar;

    final Widget content = badge == null
        ? withBadge
        : Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              withBadge,
              Positioned(right: -2, top: -2, child: badge!),
            ],
          );

    return Semantics(
      label: semanticLabel ?? name,
      button: onTap != null,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                child: content,
              ),
            ),
    );
  }
}

/// Rating row (stars + numeric value) used on cards and profiles.
class RatingRow extends StatelessWidget {
  const RatingRow({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 15,
    this.color = const Color(0xFFF59E0B),
  });

  final double rating;
  final int? reviewCount;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.star_rounded, size: size + 2, color: color),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontSize: size - 1),
        ),
        if (reviewCount != null) ...<Widget>[
          const SizedBox(width: 3),
          Text('($reviewCount)', style: Theme.of(context).textTheme.caption),
        ],
      ],
    );
  }
}
