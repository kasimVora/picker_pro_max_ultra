library picker_pro_max_ultra;

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:picker_pro_max_ultra/src/media_controller.dart';
import 'package:picker_pro_max_ultra/src/media_manager.dart';
import 'package:picker_pro_max_ultra/src/media_sheet.dart';

enum MediaType { image, video, document, unknown }

class MediaPicker {
  BuildContext context;
  int maxLimit;
  MediaType mediaType;

  MediaPicker({
    required this.context,
    this.maxLimit = 1,
    this.mediaType = MediaType.image,
  });

  Future<List<MediaViewModel>?> showPicker() async {
    var status = await PhotoManager.requestPermissionExtend(
      requestOption: PermissionRequestOption(
        iosAccessLevel: IosAccessLevel.readWrite, // Ensure full access on iOS\
        androidPermission: AndroidPermission(
            type: mediaType == MediaType.video
                ? RequestType.video
                : RequestType.image,
            mediaLocation: true), // Ensure media access on Android 13+
      ),
    );

    if (kDebugMode) {
      print("status.name");
      print(status.name);
    }

    if (status.isAuth) {
      if (kDebugMode) {
        print("Full access granted");

        Get.replace(MediaPickerController());
        Get.find<MediaPickerController>().maxLimit = maxLimit;
        Get.find<MediaPickerController>().mediaType = mediaType;
        Get.find<MediaPickerController>().init();
        await Future.delayed(const Duration(seconds: 1));
        return showGridBottomSheet(context, maxLimit);
      }
    } else if (status == PermissionState.limited) {
      await PhotoManager.openSetting();
    }

    return null;
  }
}

extension FileTypeChecker on File {
  MediaType _getFileType() {
    final extension = path.split('.').last.toLowerCase();

    switch (extension) {
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'm4v':
      case '3gp':
        return MediaType.video;

      case 'jpg':
      case 'jpeg':
      case 'png':
        return MediaType.image;

      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      case 'txt':
        return MediaType.document;

      default:
        return MediaType.unknown;
    }
  }

  MediaType get fileType => _getFileType();

  String get fileName => path.split("/").last;
}
