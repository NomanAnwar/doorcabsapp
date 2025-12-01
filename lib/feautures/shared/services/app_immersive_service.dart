import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AppImmersiveService {
  static final AppImmersiveService _instance = AppImmersiveService._internal();
  factory AppImmersiveService() => _instance;
  AppImmersiveService._internal();

  bool _isImmersiveEnabled = false;
  bool _isWakeLockEnabled = false;

  /// Initialize immersive mode for the entire app
  Future<void> initializeAppImmersiveMode() async {
    try {
      // Enable immersive mode (hide navigation bar)
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );

      // Enable wake lock (keep screen on)
      await WakelockPlus.enable();

      _isImmersiveEnabled = true;
      _isWakeLockEnabled = true;

      print('🚀 App Immersive Mode Enabled: Screen always on + Navigation hidden');

    } catch (e) {
      print('❌ Failed to enable app immersive mode: $e');
    }
  }

  /// Disable immersive mode (restore normal behavior)
  Future<void> disableAppImmersiveMode() async {
    try {
      // Restore system UI
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );

      // Disable wake lock
      await WakelockPlus.disable();

      _isImmersiveEnabled = false;
      _isWakeLockEnabled = false;

      print('🔄 App Immersive Mode Disabled');

    } catch (e) {
      print('❌ Failed to disable app immersive mode: $e');
    }
  }

  /// Toggle immersive mode based on driver online status
  Future<void> toggleImmersiveMode(bool isDriverOnline) async {
    if (isDriverOnline) {
      await initializeAppImmersiveMode();
    } else {
      await disableAppImmersiveMode();
    }
  }

  bool get isImmersiveEnabled => _isImmersiveEnabled;
  bool get isWakeLockEnabled => _isWakeLockEnabled;
}