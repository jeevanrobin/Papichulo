import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  void track(String event, {Map<String, dynamic>? params}) {
    final payload = {
      'event': event,
      'params': params ?? <String, dynamic>{},
      'timestamp': DateTime.now().toIso8601String(),
    };
    debugPrint('[analytics] $payload');
  }
}
