import 'dart:math';
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum WorkoutState { neutral, down, up }

class PoseEstimationProvider extends ChangeNotifier {
  CameraController? _cameraController;
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());
  Timer? _countdownTimer;
  final FlutterTts _tts = FlutterTts();
  
  bool _isInitialized = false;
  bool _isProcessing = false;
  CameraLensDirection _currentLensDirection = CameraLensDirection.front;
  
  // State for UI
  Pose? _currentPose;
  int _repCount = 0;
  WorkoutState _workoutState = WorkoutState.neutral;
  String _feedbackMessage = "Tekan START untuk memulai";
  
  bool _isStarted = false;
  bool _isCountingDown = false;
  int _countdown = 10;

  // Getters
  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  Pose? get currentPose => _currentPose;
  int get repCount => _repCount;
  WorkoutState get workoutState => _workoutState;
  String get feedbackMessage => _feedbackMessage;
  bool get isStarted => _isStarted;
  bool get isCountingDown => _isCountingDown;
  int get countdown => _countdown;

  PoseEstimationProvider() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("id-ID");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5); // Jangan terlalu cepat
  }

  void _speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _feedbackMessage = "Kamera tidak ditemukan";
        notifyListeners();
        return;
      }

      // Gunakan kamera berdasarkan _currentLensDirection
      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == _currentLensDirection,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.nv21 
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      _isInitialized = true;
      notifyListeners();

      // Mulai streaming gambar
      _cameraController!.startImageStream((CameraImage image) {
        if (!_isProcessing) {
          _processImage(image);
        }
      });
    } catch (e) {
      _feedbackMessage = "Gagal menginisialisasi kamera: $e";
      notifyListeners();
    }
  }

  Future<void> toggleCamera() async {
    // 1. Beritahu UI untuk segera menyembunyikan CameraPreview & Painter
    _isInitialized = false;
    _currentPose = null;
    notifyListeners();

    // 2. Hentikan dan buang controller lama dengan aman
    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
      } catch (_) {} // Abaikan jika stream sudah berhenti
      await _cameraController!.dispose();
      _cameraController = null;
    }

    // 3. Balik arah lensa
    _currentLensDirection = _currentLensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    // 4. Inisialisasi ulang
    await initCamera();
  }

  Future<void> _processImage(CameraImage image) async {
    if (_cameraController == null) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);
      
      if (poses.isNotEmpty) {
        _currentPose = poses.first;
        _analyzeSquat(_currentPose!);
      } else {
        _currentPose = null;
        _feedbackMessage = "Postur tubuh tidak terdeteksi";
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error processing pose: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _analyzeSquat(Pose pose) {
    // ═══════════════════════════════════════════════════════════════════════
    // STRATEGI BARU: Deteksi Squat yang Robust (Anti Fake-Rep)
    // 
    // Landmark yang digunakan: Shoulder, Hip, Knee, Ankle
    //
    // Syarat squat yang sah (DOWN):
    // 1. Sudut Lutut (Knee Angle) < 110° (Lutut menekuk)
    // 2. Sudut Pinggul (Hip Angle) < 130° (Badan condong ke depan / pinggul menekuk)
    // 3. Posisi Pinggul (Hip) turun secara nyata mendekati lantai (Floor Y).
    //    Jika user sekadar mengangkat satu kaki, posisi pinggul tidak akan turun.
    // 4. Jika kedua kaki terlihat, pastikan keduanya ditekuk bersamaan (mencegah jalan di tempat).
    // ═══════════════════════════════════════════════════════════════════════

    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final lHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rHip = pose.landmarks[PoseLandmarkType.rightHip];
    final lKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final lAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    final bool leftOk = (lShoulder != null && lHip != null && lKnee != null && lAnkle != null);
    final bool rightOk = (rShoulder != null && rHip != null && rKnee != null && rAnkle != null);

    PoseLandmark? shoulder, hip, knee, ankle;
    
    // Pilih sisi tubuh terbaik untuk pengukuran sudut utama
    if (leftOk && rightOk) {
      final leftAvg = (lShoulder.likelihood + lHip.likelihood + lKnee.likelihood + lAnkle.likelihood) / 4;
      final rightAvg = (rShoulder.likelihood + rHip.likelihood + rKnee.likelihood + rAnkle.likelihood) / 4;
      if (leftAvg >= rightAvg) {
        shoulder = lShoulder; hip = lHip; knee = lKnee; ankle = lAnkle;
      } else {
        shoulder = rShoulder; hip = rHip; knee = rKnee; ankle = rAnkle;
      }
    } else if (leftOk) {
      shoulder = lShoulder; hip = lHip; knee = lKnee; ankle = lAnkle;
    } else if (rightOk) {
      shoulder = rShoulder; hip = rHip; knee = rKnee; ankle = rAnkle;
    }

    if (shoulder == null || hip == null || knee == null || ankle == null) {
      _feedbackMessage = _isStarted
          ? "Pastikan seluruh badan terlihat (Bahu s/d Kaki)"
          : "Mundur agar seluruh badan terlihat";
      return;
    }

    // --- 1. Hitung Sudut ---
    final kneeAngle = _calculateAngle(hip.x, hip.y, knee.x, knee.y, ankle.x, ankle.y);
    final hipAngle = _calculateAngle(shoulder.x, shoulder.y, hip.x, hip.y, knee.x, knee.y);

    // --- 2. Hitung Penurunan Pinggul (Hip Drop) ---
    // Cari titik terendah (kaki yang menapak di lantai)
    double floorY = ankle.y;
    if (lAnkle != null && rAnkle != null) {
      floorY = max(lAnkle.y, rAnkle.y); // Nilai Y membesar ke bawah
    }

    final hipToFloor = (floorY - hip.y).abs();
    final torsoLength = (hip.y - shoulder.y).abs();
    
    // Pada saat berdiri tegak, jarak pinggul ke lantai kira-kira 2x panjang torso.
    // Pada saat squat, jarak pinggul ke lantai mendekati 1x panjang torso (karena paha sejajar lantai).
    final isHipDropped = hipToFloor < (torsoLength * 1.5);

    // --- 3. Pengecekan Dua Kaki (Mencegah Angkat 1 Kaki / Marching) ---
    bool isBothKneesBent = true;
    if (leftOk && rightOk) {
      final leftKneeAngle = _calculateAngle(lHip.x, lHip.y, lKnee.x, lKnee.y, lAnkle.x, lAnkle.y);
      final rightKneeAngle = _calculateAngle(rHip.x, rHip.y, rKnee.x, rKnee.y, rAnkle.x, rAnkle.y);
      
      // Jika salah satu lutut sangat lurus (>140) tapi yang lain ditekuk tajam (<110), ini bukan squat.
      if ((leftKneeAngle > 140 && rightKneeAngle < 110) || (rightKneeAngle > 140 && leftKneeAngle < 110)) {
        isBothKneesBent = false;
      }
    }

    // --- 4. Feedback sebelum start ---
    if (!_isStarted) {
      if (kneeAngle > 150 && hipAngle > 150) {
        _feedbackMessage = "Berdiri tegak ✓ Tekan START.";
      } else {
        _feedbackMessage = "Berdiri tegak dahulu, lalu tekan START.";
      }
      return;
    }

    // --- 5. Logika State Machine Squat ---
    final isDownPose = kneeAngle < 110 && hipAngle < 130 && isHipDropped && isBothKneesBent;
    final isUpPose = kneeAngle > 150 && hipAngle > 150;

    if (isDownPose && _workoutState != WorkoutState.down) {
      _workoutState = WorkoutState.down;
      _feedbackMessage = "⬇ Bagus! Sekarang berdiri...";
    } else if (isUpPose && _workoutState == WorkoutState.down) {
      _workoutState = WorkoutState.up;
      _repCount++;
      _feedbackMessage = "✓ Rep $_repCount!";
      _speak("$_repCount");
    } else if (_workoutState == WorkoutState.up && isUpPose) {
      _feedbackMessage = "Turunkan badan (Squat)...";
    } else if (_workoutState == WorkoutState.neutral) {
      if (!isUpPose && !isDownPose) {
        _feedbackMessage = "Perbaiki postur tubuh Anda";
      } else {
        _feedbackMessage = "Mulai gerakan Squat";
      }
    }
  }

  double _calculateAngle(double ax, double ay, double bx, double by, double cx, double cy) {
    final radians = atan2(cy - by, cx - bx) - atan2(ay - by, ax - bx);
    var angle = (radians * 180.0 / pi).abs();
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _cameraController!.value.deviceOrientation.index;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void startWorkout() {
    if (_isCountingDown || _isStarted) return;
    
    _isCountingDown = true;
    _countdown = 10;
    _feedbackMessage = "Persiapan... $_countdown detik";
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        _countdown--;
        _feedbackMessage = "Persiapan... $_countdown detik";
        
        // Ucapkan 3, 2, 1
        if (_countdown <= 3) {
          _speak("$_countdown");
        }
        
        notifyListeners();
      } else {
        timer.cancel();
        _isCountingDown = false;
        _isStarted = true;
        _workoutState = WorkoutState.neutral;
        _feedbackMessage = "Mulai gerakan Squat!";
        
        // Ucapkan "Mulai"
        _speak("Mulai!");
        notifyListeners();
      }
    });
  }

  void resetCount() {
    _countdownTimer?.cancel();
    _isCountingDown = false;
    _isStarted = false;
    _countdown = 10;
    _repCount = 0;
    _workoutState = WorkoutState.neutral;
    _feedbackMessage = "Tekan START untuk memulai";
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }
}
