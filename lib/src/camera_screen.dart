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

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver{

   List<CameraDescription> cameraDes = [];
   CameraController? controller;
  int camMode = 0;
  double scale = 0;
   double min = 0;
  double max = 0;
  int flashMode = 0,timer = 0;
  int cameIndex = 0;
   bool isRecording = false,captured = false;
   StreamController<int>?  seconds;
   Timer? time;
   String? filePath;




  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      WidgetsBinding.instance.addObserver(this);
     initCamera();
    });

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: controller!= null ? captured ? Container(
          color: Colors.black,
        ) : Stack(
          alignment: Alignment.topRight,
          children: [
            camera(),
            select(context),
            Positioned(
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 50,),
                  flashButton(context),
                  const SizedBox(height: 20,),
                  toggleCamera(context),
                ],
              ),
            ),
            cameraButtons(context),
          ],
        ) : const SizedBox(),
      ),
    );
  }

  zoomControl(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        itemCount: max.toInt(),
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (_, index) {
          return GestureDetector(
            onTap: () {
             setZoom( index + 1);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Text(
                    "${index + 1}x",
                    style: TextStyle(
                        color: index + 1 == scale
                            ? Colors.yellow
                            : Colors.white,
                        fontWeight: FontWeight.normal,
                        fontSize: 10),
                  )),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(
            width: 10,
          );
        },
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

  modeSwitch( BuildContext context) {
    return Visibility(
      visible: !isRecording,
      child: IconButton(
        onPressed: () {
         switchMode(camMode == 0 ? 1 : 0);
        },
        icon:
        Icon(camMode != 0 ? Icons.camera_alt : Icons.videocam_sharp),
        color: Colors.white,
        iconSize: 35,
      ),
    );
  }

  select(BuildContext context) {
    return Positioned(
        top: 0,
        right: 5,
        child: Visibility(
          visible: filePath!=null,
          child: Row(
            children: [

              TextButton(
                onPressed: () {
                  clear();
                  //Navigator.of(context).pop(null);
                },
                child: Text("Cancel"),),

              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(filePath);
                },
                child: Text("Done"),),
            ],
          ),
        ));
  }

  cameraButtons(BuildContext context) {
    return Positioned(
      bottom: 0,
      child: SafeArea(
        child: Center(
          widthFactor:3.5,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               // zoomControl(context),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      typeChip(0),
                      const SizedBox(width: 10,),
                      //typeChip(1),
                      // Spacer(flex: 1,),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                camMode != 0
                    ? isRecording
                    ? stopVideoButton()
                    : startVideoButton(context: context,)
                    : imageButton(),

              ],
            ),
          ),
        ),
      ),
    );
  }

  typeChip( int mode) {
    return InkWell(
      onTap: (){
        switchMode(camMode == 0 ? 1 : 0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: camMode == mode ? Colors.grey : Colors.grey.withValues(alpha: 0.2),
        ),
        child: Row(
          children: [
            Icon(
              mode == 0 ? CupertinoIcons.camera : CupertinoIcons.video_camera,
              color: camMode == mode ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 3,),
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
          child: Icon(CupertinoIcons.switch_camera,color: Colors.white,size: 16,)
      ),
    );
  }

  flashButton(BuildContext context, ) {
    return CircleAvatar(
      backgroundColor: Colors.black,
      radius: 20,
      child: InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: () =>toggleFlash(),
        child: Icon(flashMode == 0
            ? Icons.flash_on
            : flashMode == 1
            ? Icons.flash_auto
            : Icons.flash_off,
        color: Colors.white,
        size: 23,)
      ),
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



   startCamera(index) async {
     CameraController cameraController =
     CameraController(cameraDes[index], ResolutionPreset.ultraHigh);
     await cameraController.initialize().then((value) async {
       double max = await cameraController.getMaxZoomLevel();
       double min = await cameraController.getMinZoomLevel();
       await cameraController.setFlashMode(FlashMode.off);

           controller = cameraController;
           scale = min;
           cameIndex = index;
           min = min;
           max =  max;

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

   toggleFlash() {

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

   takePhoto() async {

     captured = true;
     setState(() {});

     await Future.delayed(const Duration(milliseconds: 10),(){});
     captured = false;
     setState(() {});

     try {
       var image = await controller?.takePicture();
       await controller?.pausePreview();

       if(image!=null){

         filePath = image.path;
         setState(() {});
       }

     } catch (e) {
       // e.toString()
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
       isRecording = true ;
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

   switchMode(mode) {
     setState(() {
       camMode =  mode;
     });
   }

   @override
  void dispose() async {
    super.dispose();
     await controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
   }

   void clear() async{
    setState(() {
      filePath = null;
    });
    initCamera();
   }

   void setZoom(int level) {
     setState(() {
       controller?.setZoomLevel(level.toDouble());
       scale = level.toDouble();
     });
   }


    String getDuration(int totalSeconds) {
     String seconds = (totalSeconds % 60).toInt().toString().padLeft(2, '0');
     String minutes =
     ((totalSeconds / 60) % 60).toInt().toString().padLeft(2, '0');
     String hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');

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
