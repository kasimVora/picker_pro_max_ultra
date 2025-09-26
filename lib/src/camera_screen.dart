import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../picker_pro_max_ultra.dart';

/// A screen that provides camera functionality for capturing photos and videos.
class CameraScreen extends StatefulWidget {
  /// Whether video recording is allowed on this screen.
  final bool allowRecord;

  /// Creates a [CameraScreen] widget.
  ///
  /// The [allowRecord] parameter specifies if video recording is enabled.
  const CameraScreen({super.key, required this.allowRecord});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> cameraDes = [];
  CameraController? controller;
  int camMode = 0;
  double scale = 0;
  double minZoomLevel = 0;
  double maxZoomLevel = 0;
  int flashMode = 0, timer = 0;
  int cameIndex = 0;
  bool isRecording = false,
      captured = false,
      isHDR = false,
      filterVisibility = false;
  StreamController<int>? seconds;
  Timer? time;
  String? filePath;
  Matrix4 rotation = Matrix4.identity();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              Brightness.light, // For light status bar icons
        ),
      );
      WidgetsBinding.instance.addObserver(this);
      initCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: controller != null
            ? captured
                ? Container(color: Colors.black)
                : Stack(
                    children: [
                      // Camera Preview
                      _buildCameraPreview(),

                      // Top controls
                      _buildTopControls(),

                      // Bottom controls
                      _buildBottomControls(),

                      // Capture confirmation buttons
                      if (filePath != null) _buildConfirmationButtons(),
                    ],
                  )
            : Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller!.value.previewSize!.height,
          height: controller!.value.previewSize!.width,
          child: CameraPreview(controller!),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: SafeArea(
        child: Column(
          children: [
            _buildIconButton(
              icon: Icon(
                flashMode == 0
                    ? Icons.flash_on
                    : flashMode == 1
                        ? Icons.flash_auto
                        : Icons.flash_off,
                color: Colors.white,
                size: 28,
              ),
              onPressed: toggleFlash,
            ),
            const SizedBox(height: 16),
            _buildIconButton(
              icon:
                  const Icon(Icons.cameraswitch, color: Colors.white, size: 28),
              onPressed: () => startCamera(index: cameIndex == 0 ? 1 : 0),
            ),
            const SizedBox(height: 16),
            _buildIconButton(
              icon: Icon(Icons.hd,
                  color: isHDR ? Colors.blue : Colors.white, size: 28),
              onPressed: () {
                setState(() {
                  isHDR = !isHDR;
                  startCamera(
                    index: cameIndex,
                    resolution: isHDR
                        ? ResolutionPreset.ultraHigh
                        : ResolutionPreset.high,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Zoom controls
          _buildZoomControls(),
          const SizedBox(height: 16),

          // Mode selector
          _buildModeSelector(),
          const SizedBox(height: 24),

          // Capture button
          _buildCaptureButton(),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (double zoom in [
            minZoomLevel,
            (maxZoomLevel + minZoomLevel) / 2,
            maxZoomLevel
          ])
            GestureDetector(
              onTap: () => setZoom(zoom.toInt()),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scale.toInt() == zoom.toInt()
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${zoom.toInt()}x",
                  style: TextStyle(
                    color: scale.toInt() == zoom.toInt() ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.allowRecord)
            _buildModeButton(0, Icons.camera_alt, "Photo"),
          if (widget.allowRecord) _buildModeButton(1, Icons.videocam, "Video"),
        ],
      ),
    );
  }

  Widget _buildModeButton(int mode, IconData icon, String label) {
    return InkWell(
      onTap: () => switchMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: camMode == mode
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: camMode == mode ? Colors.white : Colors.white70,
                size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: camMode == mode ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.4), width: 4),
          ),
        ),

        // Main capture button
        GestureDetector(
          onTap: camMode != 0
              ? isRecording
                  ? () {
                      recordVideo();
                      stopTimer();
                    }
                  : recordVideo
              : takePhoto,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: camMode != 0 && isRecording ? Colors.red : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: camMode != 0 && isRecording
                ? const Icon(Icons.stop_rounded, color: Colors.white, size: 45)
                : null,
          ),
        ),

        // Recording timer
        if (camMode != 0 && isRecording)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                getDuration(timer),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConfirmationButtons() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cancel button
          _buildControlButton(
            icon: Icons.close,
            onPressed: clear,
          ),

          // Confirm button
          _buildControlButton(
            icon: Icons.check,
            onPressed: () async {
              if (!context.mounted) return;
              Navigator.of(context).pop(File(filePath!));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 28),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildIconButton(
      {required Icon icon, required VoidCallback onPressed}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }

  void startCamera(
      {int index = 0,
      ResolutionPreset resolution = ResolutionPreset.high}) async {
    if (filePath == null) {
      CameraController cameraController =
          CameraController(cameraDes[index], resolution);
      await cameraController.initialize().then((value) async {
        double max = await cameraController.getMaxZoomLevel();

        double min = await cameraController.getMinZoomLevel();
        await cameraController.setFlashMode(FlashMode.off);

        setState(() {
          camMode = widget.allowRecord ? 1 : 0;
          controller = cameraController;
          scale = min;
          cameIndex = index;
          minZoomLevel = min;
          maxZoomLevel = max;
          if (controller!.description.lensDirection ==
              CameraLensDirection.front) {
            rotation = Matrix4.identity()..rotateY(math.pi);
          } else {
            rotation = Matrix4.identity();
          }
        });
      }).catchError((Object e) {
        if (e is CameraException) {
          switch (e.code) {
            case 'CameraAccessDenied':
              // e.description
              break;
            default:
              //  error: "Some thing went wrong",
              break;
          }
        }
      });
    }
  }

  void toggleFlash() {
    if (filePath == null) {
      flashMode = flashMode == 0
          ? 1
          : flashMode == 1
              ? 2
              : 0;

      if (flashMode == 0) {
        controller?.setFlashMode(FlashMode.always);
      } else if (flashMode == 1) {
        controller?.setFlashMode(FlashMode.auto);
      } else {
        controller?.setFlashMode(FlashMode.off);
      }
      setState(() {});
    }
  }

  void takePhoto() async {
    if (filePath == null) {
      captured = true;
      setState(() {});

      await Future.delayed(const Duration(milliseconds: 10), () {});
      captured = false;
      setState(() {});

      try {
        var image = await controller?.takePicture();
        await controller?.pausePreview();

        if (image != null) {
          filePath = image.path;
          setState(() {});
        }
      } catch (e) {
        // e.toString()
      }
    }
  }

  void recordVideo() async {
    try {
      if (isRecording) {
        await controller?.pausePreview();
        var cFile = await controller?.stopVideoRecording();
        isRecording = false;
        if (cFile != null) {
          if (Platform.isAndroid) {
            var f =
                await PickerProMaxUltra().compressFile(inputPath: cFile.path);
            if (f != null) {
              filePath = f;
            }
          } else {
            filePath = cFile.path;
          }
        }
        setState(() {});
      } else {
        await controller?.prepareForVideoRecording();
        await controller?.startVideoRecording();
        isRecording = true;
        timer = 0;
        startTimer();
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print("recording error == ${e.toString()}");
      }
    }
  }

  void initCamera() async {
    await availableCameras().then((value) {
      cameraDes = value;
      startCamera(index: cameIndex);
    });
  }

  void stopTimer() async {
    time?.cancel();
    setState(() {
      timer = 0;
      time = null;
    });
  }

  void startTimer() {
    time = Timer.periodic(const Duration(seconds: 1), (timerInstance) {
      setState(() {
        timer++;
      });
    });
  }

  void switchMode(mode) {
    if (filePath == null) {
      setState(() {
        camMode = mode;
      });
    }
  }

  @override
  void dispose() async {
    super.dispose();
    await controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  void clear() async {
    setState(() {
      filePath = null;
    });
    initCamera();
  }

  void setZoom(int level) {

    if (filePath == null) {
      setState(() {
        controller?.setZoomLevel(level.toDouble());
        scale = level.toDouble();
      });
      print(scale);
    }
  }

  String getDuration(int totalSeconds) {
    String seconds = (totalSeconds % 60).toInt().toString().padLeft(2, '0');
    String minutes =
        ((totalSeconds / 60) % 60).toInt().toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null || !controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller!.dispose(); // Release resources when app goes to background
    } else if (state == AppLifecycleState.resumed) {
      initCamera(); // Reinitialize camera when app resumes
    }
  }

  void toggleFilter() {
    setState(() {
      filterVisibility = !filterVisibility;
    });
  }
}
