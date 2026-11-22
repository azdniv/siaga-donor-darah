import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'admin_verify_tab.dart';
import 'home_tab.dart';
import 'placeholder_tab.dart';
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
          builder: _invitationsPlaceholder,
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
          builder: _statsPlaceholder,
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

  static Widget _invitationsPlaceholder() => const PlaceholderTab(
        icon: Icons.mail_outline,
        title: 'Undangan donor',
        description: 'Undangan dari pemohon di sekitarmu akan muncul di sini.',
      );

  static Widget _statsPlaceholder() => const PlaceholderTab(
        icon: Icons.bar_chart_outlined,
        title: 'Statistik',
        description: 'Ringkasan permintaan dan pendonor.',
      );

  static Widget _userProfile() => const ProfileTab(showDonorForm: true);

  static Widget _adminProfile() => const ProfileTab(showDonorForm: false);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final tabs = user.isAdmin ? _adminTabs() : _userTabs();
    final index = _index >= tabs.length ? 0 : _index;

    return Scaffold(
      appBar: AppBar(title: Text(tabs[index].label)),
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
    );
  }
}
