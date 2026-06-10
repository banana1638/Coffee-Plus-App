import 'dart:convert';
import 'dart:math'; // ✅ [新增] 用于指数退避的随机抖动

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import 'api_service.dart';
import 'app_logger.dart'; // ✅ [新增] 替代 kDebugMode + print

class NotificationService with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();
  ReverbClient? _reverbClient;
  bool _isInitialized = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  int? _currentSubscribedUserId;

  // ✅ [新增] 用于指数退避抖动
  final _random = Random();

  NotificationService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> init() async {
    if (_isInitialized) return;

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
        // ✅ [修改] kDebugMode print → AppLogger.debug
        AppLogger.debug('Notification clicked: ${details.payload}');
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _connectReverb();
    _isInitialized = true;
  }

  Future<void> _connectReverb() async {
    try {
      _reverbClient = ReverbClient.instance(
        host: '192.168.1.103',
        port: 8080,
        appKey: "coffepluskey123",
        useTLS: false,
        authEndpoint: 'http://192.168.1.103/coffee_plus/broadcasting/auth',
        authorizer: (channelName, socketId) async {
          final token = await _apiService.getToken();
          // ✅ [修改] kDebugMode print → AppLogger.debug
          //    注意：channel name 不含敏感数据，可以 debug 记录
          AppLogger.debug('Authorizing channel: $channelName');
          return {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          };
        },
        onConnected: (socketId) {
          _reconnectAttempts = 0;
          // ✅ [修改] 只显示 Socket ID 前 4 位，防止完整 ID 泄露
          AppLogger.info('Reverb connected. Socket: ${_maskId(socketId)}');
        },

        // ✅ [修改] 线性退避 → 指数退避 + Jitter（随机抖动）
        //
        //    ❌ 原来：Duration(seconds: 5 * attempt)
        //       第1次: 5s, 第2次: 10s, 第3次: 15s...
        //       服务器宕机时，线性增长 → 短时间内仍有大量重连请求
        //
        //    ✅ 现在：2^attempt 秒 + ±30% 随机抖动
        //       第1次: ~2s, 第2次: ~4s, 第3次: ~8s, 第4次: ~16s, 第5次: ~32s
        //       随机抖动防止多个 App 实例同时重连（Thundering Herd 问题）
        //       最大 60 秒封顶，防止等待过久
        onDisconnected: () async {
          if (_reconnectAttempts >= _maxReconnectAttempts) {
            AppLogger.warning(
              'Reverb: Max reconnect attempts ($_maxReconnectAttempts) reached.',
            );
            return;
          }

          _reconnectAttempts++;

          // 指数退避：2^n 秒，最大 60 秒
          final baseSeconds = (1 << _reconnectAttempts).clamp(1, 60);
          // Jitter：在 ±30% 范围内随机偏移，防止多客户端同时重连
          final jitterMs =
              (baseSeconds * 1000 * 0.3 * (_random.nextDouble() - 0.5)).toInt();
          final delay = Duration(
            milliseconds: (baseSeconds * 1000 + jitterMs).clamp(500, 60000),
          );

          AppLogger.warning(
            'Reverb disconnected. '
            'Attempt $_reconnectAttempts/$_maxReconnectAttempts, '
            'retry in ${delay.inSeconds}s...',
          );

          await Future.delayed(delay);
          try {
            await _reverbClient?.connect();
          } catch (e) {
            AppLogger.error('Reverb reconnection failed', error: e);
          }
        },

        onError: (error) {
          // ✅ [修改] kDebugMode print → AppLogger.error
          AppLogger.error('Reverb connection error', error: error);
        },
      );

      try {
        await _reverbClient?.connect();
      } catch (e) {
        AppLogger.error('Reverb initial connect failed', error: e);
      }

      _apiService.authStateNotifier.removeListener(_handleAuthChange);
      _apiService.authStateNotifier.addListener(_handleAuthChange);
      _handleAuthChange();
    } catch (e) {
      AppLogger.error('Reverb init failed', error: e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ [修改] kDebugMode print → AppLogger.debug
    AppLogger.debug('App lifecycle: $state');

    if (state == AppLifecycleState.resumed) {
      if (_reverbClient != null) {
        AppLogger.debug('App resumed: reconnecting Reverb...');
        _reverbClient!.connect();
      }
    }
  }

  void _handleAuthChange() async {
    if (_apiService.authStateNotifier.value) {
      try {
        final profile = await _apiService.fetchProfile();
        final userId = profile['user']?['id'];
        if (userId != null && userId != _currentSubscribedUserId) {
          _unsubscribeAll();
          _subscribeToUserChannel(userId);
          _currentSubscribedUserId = userId;
        }
      } catch (e) {
        AppLogger.error('Failed to fetch profile for Reverb subscription', error: e);
      }
    } else {
      _unsubscribeAll();
      _currentSubscribedUserId = null;
    }
  }

  void _subscribeToUserChannel(int userId) {
    if (_reverbClient == null) return;

    final channelName = "private-App.Models.User.$userId";
    try {
      AppLogger.debug('Subscribing to: $channelName');
      final channel = _reverbClient!.subscribeToPrivateChannel(channelName);

      channel
          .on('Illuminate\\Notifications\\Events\\BroadcastNotificationCreated')
          .listen((event) {
            // ✅ [修改] 只在 debug 模式记录事件，不记录完整 data（可能含用户信息）
            AppLogger.debug('Notification event received: ${event.eventName}');
            _onNotificationReceived(event);
          });
    } catch (e) {
      AppLogger.error('Reverb subscribe error', error: e);
    }
  }

  void _unsubscribeAll() {
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
        DateTime.now().microsecondsSinceEpoch % 2147483647,
        title,
        body,
        platformDetails,
        payload: payload,
      );
      AppLogger.debug('Local notification shown: $title');
    } catch (e) {
      AppLogger.error('Failed to show local notification', error: e);
    }
  }

  /// 遮蔽 ID，只显示前 4 位，用于日志（防止完整 ID 泄露）
  String _maskId(String id) {
    if (id.length <= 4) return '****';
    return '${id.substring(0, 4)}****';
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribeAll();
  }
}