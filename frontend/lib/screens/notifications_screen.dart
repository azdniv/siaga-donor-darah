import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../utils/formatters.dart';

/// Daftar notifikasi. Mengetuk satu notifikasi menandainya sudah dibaca.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final items = provider.items;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: provider.unread == 0 ? null : provider.markAllRead,
            child: const Text('Tandai semua'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: items.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.notifications_none,
                      size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Belum ada notifikasi.',
                      textAlign: TextAlign.center),
                ],
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = items[i];
                  return ListTile(
                    onTap: () => provider.markRead(n),
                    tileColor: n.isRead
                        ? null
                        : scheme.primaryContainer.withValues(alpha: 0.35),
                    leading: Icon(
                      n.isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: n.isRead ? Colors.grey : scheme.primary,
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                          fontWeight:
                              n.isRead ? FontWeight.normal : FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.message),
                        const SizedBox(height: 2),
                        Text(
                          formatDateTime(n.createdAt),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  );
                },
              ),
      ),
    );
  }
}
