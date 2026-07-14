import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dreamventz/config/supabase_config.dart';

class NotificationPreferencesModel {
  final bool pushEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool emailNotifications;
  final bool smsAlerts;

  const NotificationPreferencesModel({
    this.pushEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.emailNotifications = false,
    this.smsAlerts = false,
  });

  factory NotificationPreferencesModel.fromMap(Map<String, dynamic> map) {
    return NotificationPreferencesModel(
      pushEnabled: map['push_enabled'] as bool? ?? true,
      soundEnabled: map['sound_enabled'] as bool? ?? true,
      vibrationEnabled: map['vibration_enabled'] as bool? ?? true,
      emailNotifications: map['email_notifications'] as bool? ?? false,
      smsAlerts: map['sms_alerts'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap(String userId) => {
        'user_id': userId,
        'push_enabled': pushEnabled,
        'sound_enabled': soundEnabled,
        'vibration_enabled': vibrationEnabled,
        'email_notifications': emailNotifications,
        'sms_alerts': smsAlerts,
        'updated_at': DateTime.now().toIso8601String(),
      };

  NotificationPreferencesModel copyWith({
    bool? pushEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? emailNotifications,
    bool? smsAlerts,
  }) {
    return NotificationPreferencesModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsAlerts: smsAlerts ?? this.smsAlerts,
    );
  }
}

class NotificationHistoryItem {
  final String id;
  final String title;
  final String? body;
  final String? type;
  final bool read;
  final DateTime createdAt;

  const NotificationHistoryItem({
    required this.id,
    required this.title,
    this.body,
    this.type,
    required this.read,
    required this.createdAt,
  });

  factory NotificationHistoryItem.fromMap(Map<String, dynamic> map) {
    return NotificationHistoryItem(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String?,
      type: map['type'] as String?,
      read: map['read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class NotificationPreferencesService {
  final _client = SupabaseConfig.client;

  Future<NotificationPreferencesModel> getPreferences() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return const NotificationPreferencesModel();

    final data = await _client
        .from('notification_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return const NotificationPreferencesModel();
    return NotificationPreferencesModel.fromMap(data);
  }

  Future<void> savePreferences(NotificationPreferencesModel prefs) async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notification_preferences')
        .upsert(prefs.toMap(userId), onConflict: 'user_id');
  }

  Future<List<NotificationHistoryItem>> getHistory() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('notification_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List)
        .map((e) => NotificationHistoryItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAllRead() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notification_history')
        .update({'read': true})
        .eq('user_id', userId);
  }

  Future<void> deleteHistoryItem(String id) async {
    await _client.from('notification_history').delete().eq('id', id);
  }

  Future<void> clearAllHistory() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('notification_history')
        .delete()
        .eq('user_id', userId);
  }
}