import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../../../navigation/app_router.dart';
import '../../../state/admin_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_jobs_screen.dart';
import 'admin_users_screen.dart';
import 'admin_verifications_screen.dart';

/// Admin console tab host. Each section keeps its own navigation state.
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  late int _index = widget.initialIndex;

  static const List<NavItem> _items = <NavItem>[
    NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    NavItem(
      label: 'Users',
      icon: Icons.group_outlined,
      activeIcon: Icons.group_rounded,
    ),
    NavItem(
      label: 'Jobs',
      icon: Icons.work_outline_rounded,
      activeIcon: Icons.work_rounded,
    ),
    NavItem(
      label: 'Disputes',
      icon: Icons.gavel_outlined,
      activeIcon: Icons.gavel_rounded,
    ),
    NavItem(
      label: 'Verify',
      icon: Icons.verified_user_outlined,
      activeIcon: Icons.verified_user_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Loading the section here keeps the console usable even if a tab is the
    // first thing an admin opens.
    final AdminProvider admin = context.watch<AdminProvider>();

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: <Widget>[
            const AdminDashboardScreen(),
            const AdminUsersScreen(),
            const AdminJobsScreen(),
            const AdminDisputesScreen(),
            const AdminVerificationsScreen(),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppBottomNav(
              items: _items,
              currentIndex: _index,
              onTap: (int value) => setState(() => _index = value),
            ),
            if (admin.signedIn) const _ConsoleFooter(),
          ],
        ),
      ),
    );
  }
}

class _ConsoleFooter extends StatelessWidget {
  const _ConsoleFooter();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF1F5F9),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              onPressed: () => AppRouter.push(context, AppRoutes.adminSettings),
              child: const Text('Console settings'),
            ),
          ],
        ),
      ),
    );
  }
}
