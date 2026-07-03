import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import 'api_service.dart';
import 'app_config.dart';
import 'app_logger.dart';

class NotificationService with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();
  final _random = Random();

  ReverbClient? _reverbClient;
  bool _isInitialized = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  String? _currentSubscribedUserId;
  Timer? _reconnectTimer;
  bool _shouldMaintainConnection = false;

  NotificationService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        AppLogger.debug('Notification clicked: ${details.payload}');
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    if (AppConfig.reverbEnabled) {
      _apiService.authStateNotifier.removeListener(_handleAuthChange);
      _apiService.authStateNotifier.addListener(_handleAuthChange);
      _handleAuthChange();
    } else {
      AppLogger.info('Reverb disabled by environment configuration.');
    }
    _isInitialized = true;
  }

  Future<void> _connectReverb() async {
    if (!_shouldMaintainConnection) return;

    if (_reverbClient != null) {
      try {
        await _reverbClient?.connect();
      } catch (e) {
        AppLogger.error('Reverb connect failed', error: e);
        _scheduleReconnect();
      }
      return;
    }

    try {
      _reverbClient = ReverbClient.instance(
        host: AppConfig.reverbHost,
        port: AppConfig.reverbPort,
        appKey: AppConfig.reverbAppKey,
        useTLS: AppConfig.reverbUseTls,
        authEndpoint: AppConfig.reverbAuthEndpoint,
        authorizer: (channelName, socketId) async {
          final token = await _apiService.getToken();
          if (token == null || token.isEmpty) {
            throw Exception('Authentication required for notifications.');
          }
          AppLogger.debug('Authorizing channel: $channelName');
          return {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          };
        },
        onConnected: (socketId) {
          _reconnectTimer?.cancel();
          _reconnectAttempts = 0;
          AppLogger.info('Reverb connected. Socket: ${_maskId(socketId)}');
        },
        onDisconnected: _scheduleReconnect,
        onError: (error) {
          AppLogger.error('Reverb connection error', error: error);
        },
      );

      try {
        await _reverbClient?.connect();
      } catch (e) {
        AppLogger.error('Reverb initial connect failed', error: e);
        _scheduleReconnect();
      }
    } catch (e) {
      AppLogger.error('Reverb init failed', error: e);
      _scheduleReconnect();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.debug('App lifecycle: $state');

    if (state == AppLifecycleState.resumed) {
      if (AppConfig.reverbEnabled && _apiService.authStateNotifier.value) {
        _shouldMaintainConnection = true;
        AppLogger.debug('App resumed: reconnecting Reverb...');
        unawaited(_connectReverb());
      }
    }
  }

  void _handleAuthChange() async {
    if (!AppConfig.reverbEnabled) {
      return;
    }
    if (_apiService.authStateNotifier.value) {
      _shouldMaintainConnection = true;
      try {
        await _connectReverb();
        final profile = await _apiService.fetchProfile();
        final userId = profile['user']?['id']?.toString();
        if (userId != null &&
            userId.isNotEmpty &&
            userId != _currentSubscribedUserId) {
          if (_currentSubscribedUserId != null) {
            _stopReverbConnection();
            _shouldMaintainConnection = true;
            await _connectReverb();
          }
          _subscribeToUserChannel(userId);
          _currentSubscribedUserId = userId;
        }
      } catch (e) {
        AppLogger.error(
          'Failed to fetch profile for Reverb subscription',
          error: e,
        );
      }
    } else {
      _stopReverbConnection();
      _currentSubscribedUserId = null;
    }
  }

  void _subscribeToUserChannel(String userId) {
    if (_reverbClient == null) return;

    final channelName = "private-App.Models.User.$userId";
    try {
      AppLogger.debug('Subscribing to: $channelName');
      final channel = _reverbClient!.subscribeToPrivateChannel(channelName);

      channel
          .on('Illuminate\\Notifications\\Events\\BroadcastNotificationCreated')
          .listen((event) {
            AppLogger.debug('Notification event received: ${event.eventName}');
            _onNotificationReceived(event);
          });
    } catch (e) {
      AppLogger.error('Reverb subscribe error', error: e);
    }
  }

  void _scheduleReconnect() {
    if (!_shouldMaintainConnection ||
        !_apiService.authStateNotifier.value ||
        _reconnectTimer?.isActive == true) {
      return;
    }
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.warning(
        'Reverb: Max reconnect attempts ($_maxReconnectAttempts) reached.',
      );
      return;
    }

    _reconnectAttempts++;
    final baseSeconds = (1 << _reconnectAttempts).clamp(1, 60);
    final jitterMs = (baseSeconds * 1000 * 0.3 * (_random.nextDouble() - 0.5))
        .toInt();
    final delay = Duration(
      milliseconds: (baseSeconds * 1000 + jitterMs).clamp(500, 60000),
    );

    AppLogger.warning(
      'Reverb disconnected. '
      'Attempt $_reconnectAttempts/$_maxReconnectAttempts, '
      'retry in ${delay.inSeconds}s...',
    );

    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      if (!_shouldMaintainConnection || !_apiService.authStateNotifier.value) {
        return;
      }
      try {
        await _reverbClient?.connect();
      } catch (e) {
        AppLogger.error('Reverb reconnection failed', error: e);
        _scheduleReconnect();
      }
    });
  }

  void _stopReverbConnection() {
    _shouldMaintainConnection = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    try {
      AppLogger.debug('Disconnecting from Reverb...');
      _reverbClient?.disconnect();
    } catch (e) {
      AppLogger.error('Reverb disconnect error', error: e);
    }
  }

  void _onNotificationReceived(ChannelEvent event) {
    try {
      final data = event.data;
      if (data is Map) {
        final message = data['message'] ?? "You have a new notification";
        _showLocalNotification(
          "Order Notification",
          message,
          payload: jsonEncode(data),
        );
      } else if (data is String) {
        final decoded = jsonDecode(data);
        final message = decoded['message'] ?? "You have a new notification";
        _showLocalNotification("Order Notification", message, payload: data);
      }
      _apiService.updateNotificationCount();
    } catch (e) {
      AppLogger.error('Failed to process notification event', error: e);
    }
  }

  Future<void> _showLocalNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'order_notifications',
      'Order Notifications',
      channelDescription: 'Notifications for order status changes',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _localNotifications.show(
        id: DateTime.now().microsecondsSinceEpoch % 2147483647,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
      AppLogger.debug('Local notification shown: $title');
    } catch (e) {
      AppLogger.error('Failed to show local notification', error: e);
    }
  }

  String _maskId(String? id) {
    if (id == null) return 'null';
    if (id.length <= 4) return '****';
    return '${id.substring(0, 4)}****';
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apiService.authStateNotifier.removeListener(_handleAuthChange);
    _stopReverbConnection();
  }
}
