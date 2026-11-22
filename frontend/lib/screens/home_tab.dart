import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/donor_profile.dart';
import '../providers/auth_provider.dart';
import '../utils/formatters.dart';

/// Beranda untuk pengguna biasa: ringkasan status sebagai pendonor.
class HomeTab extends StatelessWidget {
  final VoidCallback onGoToProfile;

  const HomeTab({super.key, required this.onGoToProfile});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final profile = user.donor;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Halo, ${user.name}', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text('Apa yang ingin kamu lakukan hari ini?'),
        const SizedBox(height: 20),
        if (profile == null)
          _CompleteProfileCard(onTap: onGoToProfile)
        else
          _DonorStatusCard(profile: profile, onEdit: onGoToProfile),
      ],
    );
  }
}

class _CompleteProfileCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CompleteProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volunteer_activism,
                    color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jadi pendonor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lengkapi profil pendonor (golongan darah dan lokasi) supaya kamu '
              'bisa menerima undangan saat ada yang membutuhkan darahmu.',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onTap,
              child: const Text('Lengkapi profil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonorStatusCard extends StatelessWidget {
  final DonorProfile profile;
  final VoidCallback onEdit;

  const _DonorStatusCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interval = AppConfig.donorIntervalDays;
    final canDonate = profile.canDonateNow(interval);
    final next = profile.nextEligibleDate(interval);

    final String eligibility;
    if (profile.lastDonationDate == null) {
      eligibility = 'Belum pernah donor di aplikasi ini';
    } else if (canDonate) {
      eligibility = 'Masa jeda donor sudah terpenuhi';
    } else {
      eligibility = 'Bisa donor lagi mulai ${formatDate(next!)}';
    }

    final bool receivesInvites = profile.isAvailable && canDonate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    profile.bloodLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status pendonor',
                          style: theme.textTheme.titleMedium),
                      Text(
                        receivesInvites
                            ? 'Siap menerima undangan'
                            : 'Belum menerima undangan',
                        style: TextStyle(
                          color: receivesInvites
                              ? Colors.green.shade700
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _InfoRow(
              icon: profile.isAvailable
                  ? Icons.toggle_on_outlined
                  : Icons.toggle_off_outlined,
              text: profile.isAvailable
                  ? 'Ketersediaan: aktif'
                  : 'Ketersediaan: nonaktif (kamu tidak akan diundang)',
            ),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.event_available_outlined, text: eligibility),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.place_outlined,
              text: 'Lokasi: ${profile.latitude.toStringAsFixed(4)}, '
                  '${profile.longitude.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Ubah profil pendonor'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
