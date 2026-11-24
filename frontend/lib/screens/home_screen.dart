import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/api_client.dart';
import 'admin_stats_tab.dart';
import 'admin_verify_tab.dart';
import 'home_tab.dart';
import 'invitations_tab.dart';
import 'notifications_screen.dart';
import 'profile_tab.dart';
import 'requests_tab.dart';

class _TabDef {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;

  const _TabDef({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });
}

/// Kerangka utama setelah login: menu bawah yang berbeda untuk pengguna dan admin.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  late final NotificationProvider _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = NotificationProvider(context.read<ApiClient>())
      ..onNew = _onNewNotification
      ..start();
  }

  @override
  void dispose() {
    _notifications.dispose();
    super.dispose();
  }

  void _onNewNotification(AppNotification notification) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${notification.title}\n${notification.message}'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: 'Lihat', onPressed: _openNotifications),
        ),
      );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<NotificationProvider>.value(
          value: _notifications,
          child: const NotificationsScreen(),
        ),
      ),
    );
  }

  void _goTo(int index) => setState(() => _index = index);

  List<_TabDef> _userTabs() => [
        _TabDef(
          label: 'Beranda',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          builder: () => HomeTab(onGoToProfile: () => _goTo(3)),
        ),
        const _TabDef(
          label: 'Permintaan',
          icon: Icons.list_alt_outlined,
          selectedIcon: Icons.list_alt,
          builder: _requests,
        ),
        const _TabDef(
          label: 'Undangan',
          icon: Icons.mail_outline,
          selectedIcon: Icons.mail,
          builder: _invitations,
        ),
        const _TabDef(
          label: 'Profil',
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          builder: _userProfile,
        ),
      ];

  List<_TabDef> _adminTabs() => const [
        _TabDef(
          label: 'Verifikasi',
          icon: Icons.verified_outlined,
          selectedIcon: Icons.verified,
          builder: _verify,
        ),
        _TabDef(
          label: 'Statistik',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          builder: _stats,
        ),
        _TabDef(
          label: 'Akun',
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          builder: _adminProfile,
        ),
      ];

  static Widget _requests() => const RequestsTab();

  static Widget _verify() => const AdminVerifyTab();

  static Widget _invitations() => const InvitationsTab();

  static Widget _stats() => const AdminStatsTab();

  static Widget _userProfile() => const ProfileTab(showDonorForm: true);

  static Widget _adminProfile() => const ProfileTab(showDonorForm: false);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final tabs = user.isAdmin ? _adminTabs() : _userTabs();
    final index = _index >= tabs.length ? 0 : _index;

    return ChangeNotifierProvider<NotificationProvider>.value(
      value: _notifications,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tabs[index].label),
          actions: [
            ListenableBuilder(
              listenable: _notifications,
              builder: (context, _) => IconButton(
                tooltip: 'Notifikasi',
                onPressed: _openNotifications,
                icon: Badge(
                  isLabelVisible: _notifications.unread > 0,
                  label: Text('${_notifications.unread}'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: index,
          children: [for (final t in tabs) t.builder()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _goTo,
          destinations: [
            for (final t in tabs)
              NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.selectedIcon),
                label: t.label,
              ),
          ],
        ),
      ),
    );
  }
}
