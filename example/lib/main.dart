import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picker_pro_max_ultra/media_picker_widget.dart';
import 'package:share_plus/share_plus.dart';

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
          if(filePath.isNotEmpty)Image.file(File(filePath),height: 400,width: double.infinity,)
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
                /// hide loader
                if (file != null) {
                  filePath = file.first.mediaFile!.path;
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
             MediaPicker(
                context: context,
              ).capturedFile(allowRecord: true).then((file) {
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
                if (file != null) {
                  filePath = file.first.mediaFile!.path;
                  setState(() {});
                }
              }).catchError((onError) {
                /// hide loader
              });
            },
          ),
          FloatingActionButton(
            child: const Icon(Icons.share),
            onPressed: () async {

                // Get temp directory

                // Create a sample text file to share (you can use any file)
                final file = File(filePath);
                await file.writeAsString('Hello from Share Plus! 🎉');

                // Share the file
                await Share.shareXFiles([XFile(file.path)], text: 'Check this file out!');

            },
          ),
        ],
      ),
    );
  }
}
