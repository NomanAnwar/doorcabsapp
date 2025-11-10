import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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

        // ✅ ADDED: Enable immersive mode and wakelock when app comes to foreground
        _enableImmersiveMode();
        _enableWakelock();

        // Process any pending background events
        _processPendingEvents();
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        print('⏸️ App in BACKGROUND');
        pusherManager.setBackgroundState(true);

        // ✅ ADDED: Disable wakelock when app goes to background (save battery)
        _disableWakelock();
        break;

      case AppLifecycleState.detached:
        print('🔴 App DETACHED');

        // ✅ ADDED: Clean up system UI when app is detached
        _restoreSystemUI();
        break;

      case AppLifecycleState.hidden:
        print('👻 App HIDDEN');
        pusherManager.setBackgroundState(true);

        // ✅ ADDED: Disable wakelock when app is hidden
        _disableWakelock();
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

  // ✅ ADDED: System UI and Wakelock methods

  Future<void> _enableImmersiveMode() async {
    try {
      // Hide both status bar and navigation bar
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));

      print('📱 Immersive mode enabled - Navigation bars hidden');
    } catch (e) {
      print('❌ Error enabling immersive mode: $e');
    }
  }

  Future<void> _disableImmersiveMode() async {
    try {
      // Restore normal system UI mode
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      print('📱 Immersive mode disabled - Navigation bars visible');
    } catch (e) {
      print('❌ Error disabling immersive mode: $e');
    }
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
      print('🔆 Wakelock enabled - Screen will stay awake');
    } catch (e) {
      print('❌ Error enabling wakelock: $e');
    }
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
      print('🔅 Wakelock disabled - Screen can sleep normally');
    } catch (e) {
      print('❌ Error disabling wakelock: $e');
    }
  }

  Future<void> _restoreSystemUI() async {
    try {
      await _disableImmersiveMode();
      await _disableWakelock();
      print('🔄 System UI restored to normal state');
    } catch (e) {
      print('❌ Error restoring system UI: $e');
    }
  }

  // ✅ ADDED: Optional method to force enable system features
  // Call this from your screens if needed
  static Future<void> setupSystemUIForRideScreens() async {
    try {
      // Enable immersive mode
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
       SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));

      // Enable wakelock
      await WakelockPlus.enable();

      print('🚗 Ride screen system UI configured');
    } catch (e) {
      print('❌ Error setting up ride screen system UI: $e');
    }
  }

  // ✅ ADDED: Optional method to force disable system features
  static Future<void> restoreNormalSystemUI() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await WakelockPlus.disable();
      print('🏁 Normal system UI restored');
    } catch (e) {
      print('❌ Error restoring normal system UI: $e');
    }
  }
}