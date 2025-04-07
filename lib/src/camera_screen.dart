import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A screen that provides camera functionality for capturing photos and videos.
class CameraScreen extends StatefulWidget {
  /// Creates a [CameraScreen] widget.
  const CameraScreen({super.key});

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
  bool isRecording = false, captured = false;
  StreamController<int>? seconds;
  Timer? time;
  String? filePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addObserver(this);
      initCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: controller != null
          ? captured
              ? Container(
                  color: Colors.black,
                )
              : Stack(
                  alignment: Alignment.topRight,
                  children: [
                    camera(),
                    Positioned.directional(
                      end: 10,
                      textDirection: Directionality.of(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(
                            height: 50,
                          ),
                          flashButton(context),
                          const SizedBox(
                            height: 20,
                          ),
                          toggleCamera(context),
                        ],
                      ),
                    ),
                    cameraButtons(context),
                    Visibility(
                      visible: filePath != null,
                      child: Positioned.directional(
                        end: 20,
                        bottom: 20,
                        textDirection: Directionality.of(context),
                        child: SafeArea(
                          child: CircleAvatar(
                            backgroundColor: Colors.black,
                            radius: 20,
                            child: InkWell(
                                highlightColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                onTap: () =>
                                    Navigator.of(context).pop(filePath),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 23,
                                )),
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: filePath != null,
                      child: Positioned.directional(
                        start: 20,
                        bottom: 20,
                        textDirection: Directionality.of(context),
                        child: SafeArea(
                          child: CircleAvatar(
                            backgroundColor: Colors.black,
                            radius: 20,
                            child: InkWell(
                                highlightColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                onTap: () => clear(),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 23,
                                )),
                          ),
                        ),
                      ),
                    )
                  ],
                )
          : const SizedBox(),
    );
  }

  zoomControl(BuildContext context) {
    // Calculate the middle value between min and max zoom levels
    double middleZoom = (maxZoomLevel + minZoomLevel) / 2;

    // List to hold the zoom values: min, middle, max
    List<int> zoomValues = [
      minZoomLevel.toInt(),
      middleZoom.toInt(),
      maxZoomLevel.toInt()
    ];

    return SingleChildScrollView(
      primary: false,
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 10,
        children: zoomValues.map((zoomValue) {
          return GestureDetector(
            onTap: () {
              setZoom(zoomValue);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Text(
                  "${zoomValue}x",
                  style: TextStyle(
                    color: zoomValue == scale ? Colors.black : Colors.white,
                    fontWeight: FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  camera() {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height,
      child: CameraPreview(
        controller!,
      ),
    );
  }

  modeSwitch(BuildContext context) {
    return Visibility(
      visible: !isRecording,
      child: IconButton(
        onPressed: () {
          switchMode(camMode == 0 ? 1 : 0);
        },
        icon: Icon(camMode != 0 ? Icons.camera_alt : Icons.videocam_sharp),
        color: Colors.white,
        iconSize: 35,
      ),
    );
  }

  cameraButtons(BuildContext context) {
    return Positioned(
      bottom: 0,
      child: SafeArea(
        child: Center(
          widthFactor: 2.25,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                zoomControl(context),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      typeChip(0),
                      const SizedBox(
                        width: 10,
                      ),
                      typeChip(1),
                      Spacer(flex: 1,),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                camMode != 0
                    ? isRecording
                        ? stopVideoButton()
                        : startVideoButton(
                            context: context,
                          )
                    : imageButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  typeChip(int mode) {
    return InkWell(
      onTap: () {
        switchMode(camMode == 0 ? 1 : 0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: camMode == mode
              ? Colors.grey
              : Colors.grey.withValues(alpha: 0.2),
        ),
        child: Row(
          children: [
            Icon(
              mode == 0 ? CupertinoIcons.camera : CupertinoIcons.video_camera,
              color: camMode == mode ? Colors.white : Colors.grey,
            ),
            const SizedBox(
              width: 3,
            ),
            Text(
              mode == 0 ? "Photo" : "Video",
              style: TextStyle(
                color: camMode == mode ? Colors.white : Colors.grey,
                fontSize: camMode != mode ? 10 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  toggleCamera(BuildContext context) {
    return InkWell(
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: () {
        startCamera(cameIndex == 0 ? 1 : 0);
      },
      child: CircleAvatar(
          backgroundColor: Colors.black,
          radius: 20,
          child: Icon(
            Icons.cameraswitch_outlined,
            color: Colors.white,
            size: 20,
          )),
    );
  }

  flashButton(
    BuildContext context,
  ) {
    return CircleAvatar(
      backgroundColor: Colors.black,
      radius: 20,
      child: InkWell(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: () => toggleFlash(),
          child: Icon(
            flashMode == 0
                ? Icons.flash_on
                : flashMode == 1
                    ? Icons.flash_auto
                    : Icons.flash_off,
            color: Colors.white,
            size: 23,
          )),
    );
  }

  imageButton() {
    return GestureDetector(
      onTap: () async => takePhoto(),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: const BorderRadius.all(Radius.circular(40)),
        ),
        child: Container(
          height: 65,
          width: 65,
          color: Colors.transparent,
        ),
      ),
    );
  }

  startVideoButton({required BuildContext context}) {
    return GestureDetector(
      onTap: () {
        // context.read<CameraBloc>().add(const CameraEvent.recordVideo());
        // timer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
        //   context
        //       .read<CameraBloc>()
        //       .add(CameraEvent.startTimer(count: t.tick));
        // });
      },
      child: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: const BorderRadius.all(Radius.circular(40)),
            color: Colors.red),
      ),
    );
  }

  stopVideoButton() {
    return GestureDetector(
      onTap: () async {
        recordVideo();
        stopTimer();

        // timer!.cancel();
      },
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              borderRadius: const BorderRadius.all(Radius.circular(40)),
              color: Colors.transparent,
            ),
            child: Container(
                decoration: const BoxDecoration(
                    // border: Border.all(color: Colors.transparent, width: 5),
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                    color: Colors.transparent),
                child: const Icon(
                  Icons.square,
                  color: Colors.red,
                  size: 30,
                )),
          ),
          Text(
            getDuration(timer),
            style: const TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }

  void startCamera(index) async {
    if (filePath == null) {
      CameraController cameraController =
          CameraController(cameraDes[index], ResolutionPreset.ultraHigh);
      await cameraController.initialize().then((value) async {
        double max = await cameraController.getMaxZoomLevel();

        double min = await cameraController.getMinZoomLevel();
        await cameraController.setFlashMode(FlashMode.off);

        controller = cameraController;
        scale = min;
        cameIndex = index;
        minZoomLevel = min;
        maxZoomLevel = max;

        setState(() {});
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
    if (isRecording) {
      var cFile = await controller?.stopVideoRecording();

      if (cFile != null) {
        filePath = cFile.path;
        setState(() {});
      } else {
        isRecording = false;
        setState(() {});
      }
    } else {
      await controller?.prepareForVideoRecording();
      await controller?.startVideoRecording();
      isRecording = true;
      time = null;
      setState(() {});
    }
  }

  void initCamera() async {
    await availableCameras().then((value) {
      cameraDes = value;
      startCamera(cameIndex);
    });
  }

  stopTimer() async {
    setState(() {
      timer = 0;
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
}
