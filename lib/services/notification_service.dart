import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'api_service.dart';

class NotificationService with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();
  ReverbClient? _reverbClient;
  bool _isInitialized = false;

  NotificationService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (kDebugMode) {
          print("Notification clicked: ${details.payload}");
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // 3. Initialize Reverb
    _connectReverb();
    _isInitialized = true;
  }

  Future<void> _connectReverb() async {
    try {
      _reverbClient = ReverbClient.instance(
        host: '192.168.1.106',
        port: 8080,
        appKey: "coffepluskey123",
        useTLS: false,
        authEndpoint: 'http://192.168.1.106/coffee_plus/broadcasting/auth',
        authorizer: (channelName, socketId) async {
          final token = await _apiService.getToken();
          if (kDebugMode) print("Authorizing channel: $channelName");
          return {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          };
        },
        onConnected: (socketId) {
          if (kDebugMode) {
            print("Reverb Connected successfully! Socket ID: $socketId");
          }
        },
        onDisconnected: () async {
          if (kDebugMode) {
            print("Reverb Disconnected. Waiting 5s to reconnect...");
          }
          await Future.delayed(const Duration(seconds: 5));
          try {
            await _reverbClient?.connect();
          } catch (e) {
            if (kDebugMode) print("Reverb Reconnection Error: $e");
          }
        },
        onError: (error) {
          if (kDebugMode) print("Reverb Connection Error: $error");
        },
      );

      try {
        await _reverbClient?.connect();
      } catch (e) {
        if (kDebugMode) print("Reverb Initial Connect Error: $e");
      }

      _apiService.authStateNotifier.removeListener(_handleAuthChange);
      _apiService.authStateNotifier.addListener(_handleAuthChange);
      _handleAuthChange(); // Initial check
    } catch (e) {
      if (kDebugMode) print("Reverb Init/Connect Error: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) print("App Lifecycle State Changed: $state");

    if (state == AppLifecycleState.resumed) {
      // Re-verify connection when app comes to foreground
      if (_reverbClient != null) {
        if (kDebugMode) print("App Resumed: Checking Reverb connection...");
        _reverbClient!.connect(); // Re-trigger connect if dropped
      }
    }
  }

  void _handleAuthChange() async {
    if (_apiService.authStateNotifier.value) {
      final profile = await _apiService.fetchProfile();
      final userId = profile['user']?['id'];
      if (userId != null) {
        _subscribeToUserChannel(userId);
      }
    } else {
      _unsubscribeAll();
    }
  }

  void _subscribeToUserChannel(int userId) {
    if (_reverbClient == null) return;

    final channelName = "private-App.Models.User.$userId";
    try {
      if (kDebugMode) print("Subscribing to channel: $channelName");
      final channel = _reverbClient!.subscribeToPrivateChannel(channelName);

      // Listen for notification creation event
      channel
          .on('Illuminate\\Notifications\\Events\\BroadcastNotificationCreated')
          .listen((event) {
            if (kDebugMode) {
              print("RECEIVED EVENT IN SERVICE: ${event.eventName}");
            }
            if (kDebugMode) {
              print("EVENT DATA: ${event.data}");
            }
            _onNotificationReceived(event);
          });
    } catch (e) {
      if (kDebugMode) print("Reverb Subscribe Error: $e");
    }
  }

  void _unsubscribeAll() {
    try {
      if (kDebugMode) print("Unsubscribing and disconnecting from Reverb...");
      _reverbClient?.disconnect();
    } catch (e) {
      if (kDebugMode) print("Reverb Disconnect Error: $e");
    }
  }

  void _onNotificationReceived(ChannelEvent event) {
    try {
      final data = event.data;
      if (data is Map) {
        final message = data['message'] ?? "You have a new notification";
        const title = "Order Notification";

        if (kDebugMode) print("Triggering local notification: $message");
        _showLocalNotification(title, message, payload: jsonEncode(data));
      } else if (data is String) {
        // Sometimes data is sent as stringified JSON
        final decoded = jsonDecode(data);
        final message = decoded['message'] ?? "You have a new notification";
        _showLocalNotification("Order Notification", message, payload: data);
      }
      _apiService.updateNotificationCount();
    } catch (e) {
      if (kDebugMode) print("Error processing notification event: $e");
    }
  }

  Future<void> _showLocalNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'order_notifications',
          'Order Notifications',
          channelDescription: 'Notifications for order status changes',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        platformDetails,
        payload: payload,
      );
      if (kDebugMode) print("Local notification displayed successfully");
    } catch (e) {
      if (kDebugMode) print("Failed to show local notification: $e");
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribeAll();
  }
}
