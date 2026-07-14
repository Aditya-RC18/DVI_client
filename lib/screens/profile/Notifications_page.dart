import 'package:dreamventz/services/Notification_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dreamventz/services/notification_preferences_service.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    final historyAsync = ref.watch(notificationHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F3F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.urbanist(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // ── Settings card ──────────────────────────────────────────────
            prefsAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (prefs) => _buildSettingsCard(context, ref, prefs),
            ),

            const SizedBox(height: 12),

            // ── History card ───────────────────────────────────────────────
            historyAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (history) =>
                  _buildHistoryCard(context, ref, history),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  Widget _buildSettingsCard(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferencesModel prefs,
  ) {
    return _SectionCard(
      title: 'Preferences',
      children: [
        _ToggleTile(
          icon: Icons.notifications_active_outlined,
          label: 'Push Notifications',
          subtitle: 'Receive alerts on your device',
          value: prefs.pushEnabled,
          onChanged: (v) => ref
              .read(notificationPreferencesProvider.notifier)
              .toggle(pushEnabled: v),
        ),
        _divider(),
        _ToggleTile(
          icon: Icons.volume_up_outlined,
          label: 'Sound',
          subtitle: 'Play sound for notifications',
          value: prefs.soundEnabled,
          enabled: prefs.pushEnabled,
          onChanged: (v) => ref
              .read(notificationPreferencesProvider.notifier)
              .toggle(soundEnabled: v),
        ),
        _divider(),
        _ToggleTile(
          icon: Icons.vibration_outlined,
          label: 'Vibration',
          subtitle: 'Vibrate on notification',
          value: prefs.vibrationEnabled,
          enabled: prefs.pushEnabled,
          onChanged: (v) => ref
              .read(notificationPreferencesProvider.notifier)
              .toggle(vibrationEnabled: v),
        ),
        _divider(),
        _ToggleTile(
          icon: Icons.email_outlined,
          label: 'Email Notifications',
          subtitle: 'Receive updates via email',
          value: prefs.emailNotifications,
          onChanged: (v) => ref
              .read(notificationPreferencesProvider.notifier)
              .toggle(emailNotifications: v),
        ),
        _divider(),
        _ToggleTile(
          icon: Icons.sms_outlined,
          label: 'SMS Alerts',
          subtitle: 'Receive SMS for order updates',
          value: prefs.smsAlerts,
          onChanged: (v) => ref
              .read(notificationPreferencesProvider.notifier)
              .toggle(smsAlerts: v),
        ),
      ],
    );
  }

  // ── History ────────────────────────────────────────────────────────────────

  Widget _buildHistoryCard(
    BuildContext context,
    WidgetRef ref,
    List<NotificationHistoryItem> history,
  ) {
    final unreadCount = history.where((e) => !e.read).length;

    return _SectionCard(
      title: 'Notification History',
      trailing: unreadCount > 0
          ? GestureDetector(
              onTap: () => ref
                  .read(notificationHistoryProvider.notifier)
                  .markAllRead(),
              child: Text(
                'Mark all read',
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: const Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : history.isNotEmpty
              ? GestureDetector(
                  onTap: () => _confirmClearAll(context, ref),
                  child: Text(
                    'Clear all',
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
      children: history.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none,
                          size: 40, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        'No notifications yet',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          : history
              .map((item) => _HistoryTile(
                    item: item,
                    onDelete: () => ref
                        .read(notificationHistoryProvider.notifier)
                        .deleteItem(item.id),
                  ))
              .toList(),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear History',
            style: GoogleFonts.urbanist(fontWeight: FontWeight.w700)),
        content: Text('Remove all notification history?',
            style: GoogleFonts.urbanist()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.urbanist()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(notificationHistoryProvider.notifier).clearAll();
            },
            child: Text('Clear',
                style: GoogleFonts.urbanist(color: const Color(0xFFE53935))),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey[100]);
}

// ── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = enabled ? 1.0 : 0.4;

    return Opacity(
      opacity: effectiveOpacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.grey[700]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87)),
                  Text(subtitle,
                      style: GoogleFonts.urbanist(
                          fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: const Color(0xFFE53935),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final NotificationHistoryItem item;
  final VoidCallback onDelete;

  const _HistoryTile({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red[50],
        child: Icon(Icons.delete_outline, color: Colors.red[400]),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.read ? Colors.grey[100] : const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 20,
                color: item.read ? Colors.grey[400] : const Color(0xFFE53935),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight:
                          item.read ? FontWeight.w400 : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (item.body != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.body!,
                      style: GoogleFonts.urbanist(
                          fontSize: 12, color: Colors.grey[500]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(item.createdAt),
                    style: GoogleFonts.urbanist(
                        fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            if (!item.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE53935),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text('Error: $message',
          style: GoogleFonts.urbanist(color: Colors.red)),
    );
  }
}