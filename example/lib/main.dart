
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picker_pro_max_ultra/media_picker_widget.dart';
import 'package:picker_pro_max_ultra/platform_config.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Picker',
      theme: ThemeData(
        primarySwatch: Colors.green,
        extensions: <ThemeExtension<dynamic>>[
          // const PickerThemeData(
          //   bottomSheetBackgroundColor: Colors.black,
          //   bottomSheetIndicatorColor: Colors.blue,
          //   tabDisableColor: Colors.grey,
          //   tabEnableColor: Colors.red,
          //   doneTextStyle: TextStyle(color: Colors.orange),
          //   cancelTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          //   borderRadius: 10,
          // ),
        ],
      ),

      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String filePath = "";
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image picker demo'),
      ),
      body: Column(
        children: [
          Center(child: Text("Picked or Captured file path is $filePath")),
          //if(filePath.isNotEmpty && !kIsWeb) Image.file(File(filePath),height: 400,width: double.infinity,),
          if(filePath.isNotEmpty && kIsWeb) Image.network(filePath,height: 400,width: double.infinity,)
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          FloatingActionButton(
            child: const Icon(Icons.filter),
            onPressed: () async {

              /// show loader
              MediaPicker(
                      context: context,
                      maxLimit: 5 ?? 1,
                      cancelText: "No",
                      doneText: "Yes",
                      mediaType: MediaType.image
              )
                  .showPicker()
                  .then((file) {

                    print("file");
                    print(file);
                /// hide loader
                if (file.isNotEmpty) {
                  filePath = file.first;
                  setState(() {});
                }
              }).catchError((onError) {
                /// hide loader
              });
            },
          ),
          FloatingActionButton(
            child: const Icon(Icons.video_call_sharp),
            onPressed: () async {
              /// show loader
              MediaPicker(
                      context: context,
                      maxLimit: 5 ?? 1,
                      cancelText: "No",
                      doneText: "Yes",
                      mediaType: MediaType.video
              )
                  .showPicker()
                  .then((file) {
                /// hide loader
                if (file.isNotEmpty) {
                  filePath = file.first;
                  setState(() {});
                }
              }).catchError((onError) {
                /// hide loader
              });
            },
          ),
          FloatingActionButton(
            child: const Icon(Icons.file_copy),
            onPressed: () async {
              MediaPicker(
                context: context,
                mediaType: MediaType.audio
              ).picFile().then((file) {
                /// hide loader
                if (file != null) {
                  filePath = file.path;
                  setState(() {});
                }
              }).catchError((onError) {
                /// hide loader
              });
            },
          ),
          FloatingActionButton(
            child: const Icon(Icons.camera),
            onPressed: () async {
            var d = await MediaPicker(
                context: context,
              ).capturedFile(allowRecord: false).then((file) {
               /// hide loader
               if (file != null) {
                 filePath = file.path;
                 print("capture == $filePath");
                 setState(() {});
               }
             }).catchError((onError) {
               /// hide loader
                print("capture == $onError");
             });

            print("object");
            },
          ),
          FloatingActionButton(
            child: const Icon(Icons.music_note),
            onPressed: () async {
              /// show loader
              MediaPicker(
                  context: context,
                  maxLimit: 5 ?? 1,
                  mediaType: MediaType.audio
              )
                  .showPicker()
                  .then((file) {
                /// hide loader
                if (file.isNotEmpty) {
                  filePath = file.first;
                  setState(() {});
                }
              }).catchError((onError) {
                /// hide loader
              });
            },
          ),
        ],
      ),
    );
  }
}
