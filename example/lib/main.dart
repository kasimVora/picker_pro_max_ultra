import 'package:flutter/material.dart';
import 'package:picker/media_picker_widget.dart';

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
        onPressed: () => openImagePicker(context),
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

  void openImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows custom height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20), // Rounded top corners
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false, // Allows dragging
          initialChildSize: 0.75, // Opens at 75% of screen height
          minChildSize: 0.5, // Minimum height (50%)
          maxChildSize: 1.0, // Maximum height (Full screen)
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: MediaPicker(
                onPicked: (selectedList) {
                  setState(() => mediaList = selectedList);
                  Navigator.pop(context);
                },
                onCancel: () => Navigator.pop(context),
                mediaCount: MediaCount.multiple,
                mediaType: MediaType.image,
                decoration: PickerDecoration(
                  blurStrength: 0,
                  scaleAmount: 1,
                  counterBuilder: (context, index) {
                    if (index == null) return const SizedBox();
                    return Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );


  }
}
