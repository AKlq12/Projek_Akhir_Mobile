import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Centralized sensor service for FitPro.
///
/// Provides:
/// - **Step counting** via the device's hardware pedometer.
///   Tracks a baseline so only steps taken *during this session* are counted.
/// - **Shake detection** via accelerometer. Fires a callback when the
///   device acceleration exceeds a configurable threshold.
///
/// Usage:
/// ```dart
/// final sensor = SensorService.instance;
/// sensor.startStepCounting(onStep: (steps) => print(steps));
/// sensor.startShakeDetection(onShake: () => print('shaken!'));
/// // …later
/// sensor.dispose();
/// ```
class SensorService {
  SensorService._();
  static final SensorService instance = SensorService._();

  // ─────────────────────────────────────────────────────────────────────────
  // STEP COUNTING
  // ─────────────────────────────────────────────────────────────────────────

  StreamSubscription<StepCount>? _stepSubscription;
  int _baselineSteps = -1;
  int _sessionSteps = 0;
  bool _isStepCountingActive = false;

  bool get isStepCountingActive => _isStepCountingActive;
  int get sessionSteps => _sessionSteps;

  /// Starts listening to the hardware pedometer.
  ///
  /// [onStep] is called every time the step count updates, with the
  /// number of steps taken *since [startStepCounting]* was called.
  /// [initialSteps] can be set to resume from a previous session count.
  void startStepCounting({
    required ValueChanged<int> onStep,
    int initialSteps = 0,
  }) {
    if (_isStepCountingActive) return;

    _sessionSteps = initialSteps;
    _baselineSteps = -1;
    _isStepCountingActive = true;

    _stepSubscription = Pedometer.stepCountStream.listen(
      (StepCount event) {
        if (_baselineSteps < 0) {
          // First reading → set baseline
          _baselineSteps = event.steps;
        }
        _sessionSteps = initialSteps + (event.steps - _baselineSteps);
        onStep(_sessionSteps);
      },
      onError: (error) {
        debugPrint('[SensorService] Pedometer error: $error');
      },
      cancelOnError: false,
    );
  }

  /// Stops step counting and cleans up the subscription.
  void stopStepCounting() {
    _stepSubscription?.cancel();
    _stepSubscription = null;
    _isStepCountingActive = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHAKE DETECTION
  // ─────────────────────────────────────────────────────────────────────────

  StreamSubscription<AccelerometerEvent>? _shakeSubscription;
  bool _isShakeDetectionActive = false;

  /// Minimum acceleration magnitude (m/s²) to trigger a shake.
  static const double shakeThreshold = 15.0;

  /// Cooldown between shake events to prevent rapid-fire triggers.
  static const Duration shakeCooldown = Duration(milliseconds: 1500);

  DateTime _lastShakeTime = DateTime(2000);

  bool get isShakeDetectionActive => _isShakeDetectionActive;

  /// Starts listening for shake gestures via the accelerometer.
  ///
  /// [onShake] fires each time a shake is detected (respecting cooldown).
  void startShakeDetection({required VoidCallback onShake}) {
    if (_isShakeDetectionActive) return;

    _isShakeDetectionActive = true;
    _lastShakeTime = DateTime(2000);

    _shakeSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen(
      (AccelerometerEvent event) {
        final magnitude = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );

        if (magnitude > shakeThreshold) {
          final now = DateTime.now();
          if (now.difference(_lastShakeTime) > shakeCooldown) {
            _lastShakeTime = now;
            onShake();
          }
        }
      },
      onError: (error) {
        debugPrint('[SensorService] Accelerometer error: $error');
      },
      cancelOnError: false,
    );
  }

  /// Stops shake detection and cleans up the subscription.
  void stopShakeDetection() {
    _shakeSubscription?.cancel();
    _shakeSubscription = null;
    _isShakeDetectionActive = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────

  /// Stops all sensor subscriptions.
  void dispose() {
    stopStepCounting();
    stopShakeDetection();
  }
}
