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
              try {
                var d = await MediaPicker(
                                      context: context,
                                      maxLimit: 5 ?? 1,
                                      mediaType: MediaType.video)
                                  .showPicker();

                if (d != null) {

                  filePath = d.first.mediaFile!.path;
                  setState(() {

                  });
                              }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    duration: Duration(seconds: 2),
                  ),
                );

              }
            },
          ),
          FloatingActionButton(
            child: const Icon(Icons.file_copy),
            onPressed: () async {
              var d = await MediaPicker(context: context,).picFile();
              filePath = d!.path;
              setState(() {

              });
            },
          ),
          FloatingActionButton(
            child: const Icon(Icons.camera),
            onPressed: () async {
              var d = await MediaPicker(
                context: context,
              ).capturedFile();
              filePath = d!.path;
              setState(() {

              });
            },
          ),
        ],
      ),
    );
  }
}
