import 'package:flutter/material.dart';
import 'package:picker_pro_max_ultra/media_picker_widget.dart';

void main() {
  runApp(const MyApp());
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
  List<Media> mediaList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Picker'),
      ),
      body: previewList(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async{
          openImagePicker(context: context);

          List<Media>? selectedImages = await openImagePicker(
            context: context,
            onPicked: (selectedList) {
              debugPrint("Picked ${selectedList.first.file!.path} images");
            },
            onCancel: () {
              debugPrint("Picker was canceled");
            },
            mediaCount: MediaCount.multiple,
            mediaType: MediaType.image,
          );

          if (selectedImages != null && selectedImages.isNotEmpty) {
            setState(() {
              mediaList = selectedImages;
            });
          }
        },
      ),
    );
  }

  Widget previewList() {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        children: List.generate(
            mediaList.length,
                (index) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 80,
                width: 80,
                child: mediaList[index].thumbnail == null
                    ? const SizedBox()
                    : Image.memory(
                  mediaList[index].thumbnail!,
                  fit: BoxFit.cover,
                ),
              ),
            )),
      ),
    );
  }

}
