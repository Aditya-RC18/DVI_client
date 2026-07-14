import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreamventz/services/notification_preferences_service.dart';
import 'package:dreamventz/services/notification_service.dart';

// ── Service provider ────────────────────────────────────────────────────────
final notificationPreferencesServiceProvider =
    Provider<NotificationPreferencesService>(
  (ref) => NotificationPreferencesService(),
);

// ── Preferences state ───────────────────────────────────────────────────────
class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreferencesModel> {
  @override
  Future<NotificationPreferencesModel> build() async {
    return ref
        .read(notificationPreferencesServiceProvider)
        .getPreferences();
  }

  Future<void> toggle({
    bool? pushEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? emailNotifications,
    bool? smsAlerts,
  }) async {
    final current = state.valueOrNull ?? const NotificationPreferencesModel();
    final updated = current.copyWith(
      pushEnabled: pushEnabled,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      emailNotifications: emailNotifications,
      smsAlerts: smsAlerts,
    );
    state = AsyncData(updated);
    await ref
        .read(notificationPreferencesServiceProvider)
        .savePreferences(updated);

    // When push is explicitly toggled, update FCM token accordingly
    if (pushEnabled != null) {
      if (pushEnabled) {
        // Re-register FCM token so server can send notifications again
        await NotificationService().saveFcmToken();
      } else {
        // Delete token so server cannot send push notifications
        await FirebaseMessaging.instance.deleteToken();
      }
    }
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<NotificationPreferencesNotifier,
        NotificationPreferencesModel>(
  NotificationPreferencesNotifier.new,
);

// ── History state ───────────────────────────────────────────────────────────
class NotificationHistoryNotifier
    extends AsyncNotifier<List<NotificationHistoryItem>> {
  @override
  Future<List<NotificationHistoryItem>> build() async {
    return ref
        .read(notificationPreferencesServiceProvider)
        .getHistory();
  }

  Future<void> markAllRead() async {
    await ref.read(notificationPreferencesServiceProvider).markAllRead();
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((e) => NotificationHistoryItem(
                id: e.id,
                title: e.title,
                body: e.body,
                type: e.type,
                read: true,
                createdAt: e.createdAt,
              ))
          .toList(),
    );
  }

  Future<void> deleteItem(String id) async {
    await ref
        .read(notificationPreferencesServiceProvider)
        .deleteHistoryItem(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((e) => e.id != id).toList(),
    );
  }

  Future<void> clearAll() async {
    await ref.read(notificationPreferencesServiceProvider).clearAllHistory();
    state = const AsyncData([]);
  }
}

final notificationHistoryProvider =
    AsyncNotifierProvider<NotificationHistoryNotifier,
        List<NotificationHistoryItem>>(
  NotificationHistoryNotifier.new,
);