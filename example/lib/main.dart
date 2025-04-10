import 'dart:async';

import 'package:flutter/material.dart';
import 'package:picker_pro_max_ultra/media_picker_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        title: const Text('Image Psicker'),
      ),
      body: Center(child: Text("Picked or Captured file path is $filePath")),
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
                      mediaType: MediaType.image)
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
              ).capturedFile().then((file) {
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
        ],
      ),
    );
  }
}
