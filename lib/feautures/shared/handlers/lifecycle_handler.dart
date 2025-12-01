import 'package:flutter/widgets.dart';

import '../services/enhanced_pusher_manager.dart';
import '../services/pusher_background_service.dart';

class LifecycleEventHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final pusherManager = EnhancedPusherManager();
    final backgroundService = PusherBackgroundService();

    switch (state) {
      case AppLifecycleState.resumed:
        print('🔄 App in FOREGROUND');
        pusherManager.setBackgroundState(false);
        // Process any pending background events
        _processPendingEvents();
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        print('⏸️ App in BACKGROUND');
        pusherManager.setBackgroundState(true);
        break;

      case AppLifecycleState.detached:
        print('🔴 App DETACHED');
        break;

      case AppLifecycleState.hidden: // ✅ ADDED: Handle hidden state
        print('👻 App HIDDEN');
        pusherManager.setBackgroundState(true);
        break;
    }
  }

  Future<void> _processPendingEvents() async {
    try {
      final backgroundService = PusherBackgroundService();
      final pendingEvents = await backgroundService.getPendingEvents();

      if (pendingEvents.isNotEmpty) {
        print('📨 Processing ${pendingEvents.length} pending events');

        for (final event in pendingEvents) {
          print('   - ${event['type']} at ${event['timestamp']}');
          // You can broadcast these events to your controllers using GetX
          // Get.find<YourController>().handleBackgroundEvent(event);
        }
      }
    } catch (e) {
      print('❌ Error processing pending events: $e');
    }
  }
}
