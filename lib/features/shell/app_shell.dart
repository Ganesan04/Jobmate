import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../models/enums.dart';
import '../../state/auth_provider.dart';
import '../../state/navigation_state.dart';
import '../common/screens/messages_screen.dart';
import '../common/screens/notifications_screen.dart';
import '../common/screens/profile_screen.dart';
import '../giver/screens/giver_home_screen.dart';
import '../giver/screens/my_jobs_screen.dart';
import '../worker/screens/applications_screen.dart';
import '../worker/screens/search_jobs_screen.dart';
import '../worker/screens/worker_home_screen.dart';

/// Role aware tab host. The tab set is derived from the active role so a worker
/// never sees giver destinations, and the active tab survives a role switch.
class AppShell extends StatelessWidget {
  const AppShell({super.key, this.initialIndex});

  final int? initialIndex;

  @override
  Widget build(BuildContext context) {
    final UserRole role = context.watch<AuthProvider>().role;
    final NavigationState navigation = context.watch<NavigationState>();
    final bool isWorker = role == UserRole.worker;
    final List<Widget> screens = isWorker ? _workerScreens : _giverScreens;
    final int index = (initialIndex ?? navigation.indexFor(role)).clamp(
      0,
      screens.length - 1,
    );

    return Scaffold(
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: AppBottomNav(
        items: isWorker ? _workerTabs : _giverTabs,
        currentIndex: index,
        onTap: (int value) => navigation.setIndex(role, value),
      ),
    );
  }

  static const List<NavItem> _workerTabs = <NavItem>[
    NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    NavItem(
      label: 'Find work',
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
    ),
    NavItem(
      label: 'Applications',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
    ),
    NavItem(
      label: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
    ),
    NavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  static const List<NavItem> _giverTabs = <NavItem>[
    NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    NavItem(
      label: 'My jobs',
      icon: Icons.work_outline_rounded,
      activeIcon: Icons.work_rounded,
    ),
    NavItem(
      label: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
    ),
    NavItem(
      label: 'Alerts',
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded,
    ),
    NavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  static const List<Widget> _workerScreens = <Widget>[
    WorkerHomeScreen(),
    SearchJobsScreen(),
    ApplicationsScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  static const List<Widget> _giverScreens = <Widget>[
    GiverHomeScreen(),
    MyJobsScreen(),
    MessagesScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];
}

/// Gap helper reused by screens that pad around the bottom navigation.
const Widget shellBottomGap = SizedBox(height: AppSpacing.lg);
