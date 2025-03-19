library media_picker_widget;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:photo_manager/photo_manager.dart';
import 'package:picker/src/media_conversion_service.dart';
import 'package:picker/src/media_view_model.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'src/album_selector.dart';
import 'src/header.dart';
import 'src/media_list.dart';
import 'src/widgets/loading_widget.dart';
import 'src/widgets/no_media.dart';

part 'src/enums.dart';
part 'src/media.dart';
part 'src/media_picker.dart';
part 'src/picker_decoration.dart';

Future<List<Media>?> openImagePicker({
  required BuildContext context,
  ValueChanged<List<Media>>? onPicked,
  VoidCallback? onCancel,
  MediaCount mediaCount = MediaCount.multiple,
  MediaType mediaType = MediaType.all,
}) async {
  return await showModalBottomSheet<List<Media>>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20), // Rounded top corners
      ),
    ),
    builder: (context) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: MediaPicker(
          onPicked: (selectedList) {
            onPicked?.call(selectedList); // Call callback
            Navigator.pop(context, selectedList); // Return selectedList
          },
          onCancel: () {
            onCancel?.call(); // Call cancel callback
            Navigator.pop(context, null); // Return null if canceled
          },
          mediaCount: mediaCount, // Use passed mediaCount
          mediaType: mediaType, // Use passed mediaType
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
}
