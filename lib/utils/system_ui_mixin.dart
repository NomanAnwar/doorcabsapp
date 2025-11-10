// utils/system_ui_mixin.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

mixin SystemUIMixin {
  void enableImmersiveMode() {
    // Hide both status bar and navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  void disableImmersiveMode() {
    // Restore normal system UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> enableWakelock() async {
    await WakelockPlus.enable();
  }

  Future<void> disableWakelock() async {
    await WakelockPlus.disable();
  }

  Future<void> setupSystemUI() async {
    enableImmersiveMode();
    await enableWakelock();
  }

  Future<void> restoreSystemUI() async {
    disableImmersiveMode();
    await disableWakelock();
  }
}