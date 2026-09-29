import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../utils/context_extensions.dart';

/// The single AppBar implementation for the app: optional back arrow, title /
/// subtitle, and up to two trailing actions.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.subtitle,
    this.showBack = true,
    this.actions = const <Widget>[],
    this.onBack,
    this.leading,
    this.centerTitle = false,
    this.transparent = false,
    this.bottom,
  });

  /// Top bar for screens inside a bottom-nav shell (no back arrow).
  const AppTopBar.tab({
    super.key,
    this.title,
    this.subtitle,
    this.actions = const <Widget>[],
  }) : showBack = false,
       onBack = null,
       leading = null,
       centerTitle = false,
       transparent = false,
       bottom = null;

  final String? title;
  final String? subtitle;
  final bool showBack;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final Widget? leading;
  final bool centerTitle;
  final bool transparent;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
    AppSizes.topBarHeight +
        (subtitle == null ? 0 : 4) +
        (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return AppBar(
      backgroundColor: transparent ? Colors.transparent : AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      toolbarHeight: AppSizes.topBarHeight,
      leading: showBack
          ? IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
            )
          : leading,
      title: title == null
          ? null
          : Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: texts.titleMedium?.copyWith(fontSize: 17),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: texts.caption?.copyWith(fontSize: 11.5),
                  ),
              ],
            ),
      actions: actions,
      bottom: bottom,
    );
  }
}

/// Circular icon button with a tinted background (used in top bars + home).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.badgeCount = 0,
    this.tooltip,
    this.color,
    this.background,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final int badgeCount;
  final String? tooltip;
  final Color? color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color fg = color ?? scheme.primary;
    final Widget button = Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: background ?? Color.lerp(fg, Colors.white, 0.88),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.46, color: fg),
          ),
        ),
      ),
    );

    if (badgeCount <= 0) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        button,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 18),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.background, width: 1.5),
            ),
            child: Text(
              badgeCount > 9 ? '9+' : '$badgeCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Page scaffold with a soft background, safe area and a max content width so
/// the layout never stretches on larger devices.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBody = false,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.centerContent = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBody;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    final Widget content = centerContent
        ? Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
              child: body,
            ),
          )
        : body;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: SafeArea(top: false, bottom: !extendBody, child: content),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
