import 'package:dreamventz/utils/constants.dart';
import 'package:dreamventz/services/notification_preferences_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final GlobalKey<NavigatorState> clientNavigatorKey =
    GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Two channels: one with sound+vibration, one silent ────────────────────
  static const AndroidNotificationChannel _channelFull =
      AndroidNotificationChannel(
        'new_services_channel',
        'New Services',
        description: 'Notifications when vendors add new services',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  static const AndroidNotificationChannel _channelSilent =
      AndroidNotificationChannel(
        'new_services_channel_silent',
        'New Services (Silent)',
        description: 'Silent notifications when vendors add new services',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );

  static const AndroidNotificationChannel _channelVibrateOnly =
      AndroidNotificationChannel(
        'new_services_channel_vibrate',
        'New Services (Vibrate Only)',
        description: 'Vibrate only notifications',
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      );

  static const AndroidNotificationChannel _channelSoundOnly =
      AndroidNotificationChannel(
        'new_services_channel_sound',
        'New Services (Sound Only)',
        description: 'Sound only notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: false,
      );

  Future<void> initialize() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Register all 4 channels
    await androidPlugin?.createNotificationChannel(_channelFull);
    await androidPlugin?.createNotificationChannel(_channelSilent);
    await androidPlugin?.createNotificationChannel(_channelVibrateOnly);
    await androidPlugin?.createNotificationChannel(_channelSoundOnly);
    await androidPlugin?.requestNotificationsPermission();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Client notification tapped: ${response.payload}');
        _handleLocalNotificationTap(response.payload);
      },
    );

    // ── Foreground ──────────────────────────────────────────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // ── Background tap ──────────────────────────────────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📩 Background tap — data: ${message.data}');
      _navigateFromData(message.data);
    });

    // ── Terminated tap ──────────────────────────────────────────────────────
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📩 Terminated tap — data: ${initialMessage.data}');
      await Future.delayed(const Duration(milliseconds: 1000));
      _navigateFromData(initialMessage.data);
    }

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('✅ Client NotificationService initialized');
  }

  // ── Called when tapping a local notification (foreground case) ─────────────
  void _handleLocalNotificationTap(String? payload) {
    if (payload == null) return;
    debugPrint('📲 Local notification payload: $payload');
    try {
      final parts = payload.split('|');
      if (parts.isEmpty) return;
      final type = parts[0];

      if (type == 'favourite_vendor_new_product' && parts.length >= 4) {
        final vendorId = parts[1];
        final categoryId = int.tryParse(parts[2]) ?? 1;
        final categoryName = parts[3];
        _navigateToVendorList(vendorId, categoryId, categoryName);
      } else if (type == 'bulk_new_services') {
        _navigateToVendorCategories();
      }
    } catch (e) {
      debugPrint('⚠️ Error handling local tap: $e');
    }
  }

  // ── Called for background + terminated taps (FCM data payload) ─────────────
  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    debugPrint('🔀 Navigate from type: $type | data: $data');

    if (type == 'favourite_vendor_new_product') {
      final vendorId = data['vendor_id'] as String? ?? '';
      final categoryId =
          int.tryParse(data['category_id'] as String? ?? '1') ?? 1;
      final categoryName = data['category_name'] as String? ?? 'Services';
      _navigateToVendorList(vendorId, categoryId, categoryName);
    } else if (type == 'bulk_new_services') {
      _navigateToVendorCategories();
    }
  }

  // ── Navigation targets ──────────────────────────────────────────────────────

  void _navigateToVendorList(
    String vendorId,
    int categoryId,
    String categoryName,
  ) {
    final navigator = clientNavigatorKey.currentState;
    if (navigator == null) {
      debugPrint('⚠️ Client navigator not ready');
      return;
    }
    navigator.pushNamedAndRemoveUntil(
      '/vendorlist',
      (route) => route.settings.name == AppConstants.homeRoute,
      arguments: {
        'categoryName': categoryName,
        'categoryId': categoryId,
        'vendorId': vendorId,
      },
    );
  }

  void _navigateToVendorCategories() {
    final navigator = clientNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushNamedAndRemoveUntil(
      '/vendorcategories',
      (route) => route.settings.name == AppConstants.homeRoute,
    );
  }

  // ── Show local notification with hardware-level sound/vibration control ────
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Fetch user preferences
    NotificationPreferencesModel prefs;
    try {
      prefs = await NotificationPreferencesService().getPreferences();
    } catch (e) {
      // If fetch fails, use defaults (sound + vibration on)
      prefs = const NotificationPreferencesModel();
    }

    // If push is disabled, don't show anything
    if (!prefs.pushEnabled) {
      debugPrint('🔕 Push disabled — skipping notification');
      return;
    }

    final data = message.data;
    final type = data['type'] as String? ?? '';
    final vendorId = data['vendor_id'] as String? ?? '';
    final categoryId = data['category_id'] as String? ?? '1';
    final categoryName = data['category_name'] as String? ?? 'Services';
    final payload = '$type|$vendorId|$categoryId|$categoryName';

    // Pick the right channel based on sound + vibration prefs
    final AndroidNotificationChannel channel;
    if (prefs.soundEnabled && prefs.vibrationEnabled) {
      channel = _channelFull; // sound + vibration
    } else if (!prefs.soundEnabled && prefs.vibrationEnabled) {
      channel = _channelVibrateOnly; // vibration only
    } else if (prefs.soundEnabled && !prefs.vibrationEnabled) {
      channel = _channelSoundOnly; // sound only
    } else {
      channel = _channelSilent; // completely silent
    }

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: prefs.soundEnabled ? Priority.high : Priority.low,
          playSound: prefs.soundEnabled,
          enableVibration: prefs.vibrationEnabled,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  // ── Save FCM token ──────────────────────────────────────────────────────────
  Future<void> saveFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      final user = Supabase.instance.client.auth.currentUser;

      debugPrint('📱 Client FCM Token: $token');

      if (user != null && token != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
        debugPrint('✅ Client FCM token saved');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          await Supabase.instance.client
              .from('profiles')
              .update({'fcm_token': newToken})
              .eq('id', currentUser.id);
          debugPrint('✅ Client FCM token refreshed');
        }
      });
    } catch (e) {
      debugPrint('⚠️ Failed to save client FCM token: $e');
    }
  }
}
