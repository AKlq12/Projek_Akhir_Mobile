import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:provider/provider.dart';

import '../../core/providers/pose_estimation_provider.dart';

class PoseEstimationScreen extends StatefulWidget {
  const PoseEstimationScreen({super.key});

  @override
  State<PoseEstimationScreen> createState() => _PoseEstimationScreenState();
}

class _PoseEstimationScreenState extends State<PoseEstimationScreen> {
  @override
  void initState() {
    super.initState();
    // Inisialisasi kamera setelah frame pertama (provider sudah di-inject)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PoseEstimationProvider>().initCamera();
    });
  }

  @override
  void deactivate() {
    // Memberhentikan stream jika keluar dari layar
    context.read<PoseEstimationProvider>().cameraController?.stopImageStream();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PoseEstimationProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black, // Gelap karena fokus ke kamera
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Squat Counter',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () {
              provider.toggleCamera();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              provider.resetCount();
            },
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Tampilan Kamera
          if (provider.isInitialized && provider.cameraController != null)
            CameraPreview(provider.cameraController!)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 2. Overlay Skeleton Painter
          if (provider.currentPose != null && provider.cameraController != null)
            CustomPaint(
              painter: PosePainter(
                pose: provider.currentPose!,
                imageSize: provider.cameraController!.value.previewSize ?? const Size(480, 640),
                rotation: provider.cameraController!.description.sensorOrientation,
                cameraLensDirection: provider.cameraController!.description.lensDirection,
              ),
            ),

          // 3. UI Status & Repetisi
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.feedbackMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'REPS',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '${provider.repCount}',
                            style: GoogleFonts.plusJakartaSans(
                              color: colorScheme.primaryContainer, // Warna aksen
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.white24,
                      ),
                      Column(
                        children: [
                          Text(
                            'STATUS',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(provider.workoutState),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(provider.workoutState),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          // 4. Start Button / Countdown Overlay
          if (!provider.isStarted)
            Positioned.fill(
              child: Center(
                child: provider.isCountingDown
                    ? Text(
                        '${provider.countdown}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 120,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primaryContainer,
                          shadows: const [Shadow(color: Colors.black, blurRadius: 20)],
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 10,
                        ),
                        onPressed: () {
                          provider.startWorkout();
                        },
                        child: Text(
                          'START SQUAT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(WorkoutState state) {
    switch (state) {
      case WorkoutState.neutral:
        return Colors.grey;
      case WorkoutState.down:
        return Colors.orange;
      case WorkoutState.up:
        return Colors.green;
    }
  }

  String _getStatusText(WorkoutState state) {
    switch (state) {
      case WorkoutState.neutral:
        return 'SIAP';
      case WorkoutState.down:
        return 'TURUN';
      case WorkoutState.up:
        return 'NAIK';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER UNTUK SKELETON POSTUR
// ─────────────────────────────────────────────────────────────────────────────
class PosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final int rotation;
  final CameraLensDirection cameraLensDirection;

  PosePainter({
    required this.pose,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final paintPoint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 10.0
      ..style = PaintingStyle.fill;

    // Transformasi koodinat dari gambar kamera (imageSize) ke ukuran layar (size)
    double translateX(double x) {
      if (rotation == 90 || rotation == 270) {
        // Mode potret
        double scale = size.width / imageSize.height; // Note: height & width ditukar
        if (cameraLensDirection == CameraLensDirection.front) {
          // Mirror x
          return size.width - (x * scale);
        }
        return x * scale;
      }
      return x * (size.width / imageSize.width);
    }

    double translateY(double y) {
      if (rotation == 90 || rotation == 270) {
        double scale = size.height / imageSize.width; // Note: height & width ditukar
        return y * scale;
      }
      return y * (size.height / imageSize.height);
    }

    // Fungsi helper untuk menggambar sendi dan garis penghubung
    void paintLineFromTypes(PoseLandmarkType t1, PoseLandmarkType t2) {
      final l1 = pose.landmarks[t1];
      final l2 = pose.landmarks[t2];
      if (l1 != null && l2 != null) {
        canvas.drawLine(
            Offset(translateX(l1.x), translateY(l1.y)),
            Offset(translateX(l2.x), translateY(l2.y)),
            paintLine);
      }
    }

    // Gambar titik (Joints)
    for (final landmark in pose.landmarks.values) {
      canvas.drawCircle(
          Offset(translateX(landmark.x), translateY(landmark.y)), 5, paintPoint);
    }

    // Gambar kerangka (Skeleton)
    // Tangan Kiri
    paintLineFromTypes(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    paintLineFromTypes(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    // Tangan Kanan
    paintLineFromTypes(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    paintLineFromTypes(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    // Bahu
    paintLineFromTypes(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    // Pinggul
    paintLineFromTypes(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    // Badan (Bahu ke Pinggul)
    paintLineFromTypes(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    paintLineFromTypes(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    // Kaki Kiri
    paintLineFromTypes(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    paintLineFromTypes(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    // Kaki Kanan
    paintLineFromTypes(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    paintLineFromTypes(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.pose != pose;
  }
}
