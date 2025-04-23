library;

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picker_pro_max_ultra/picker_pro_max_ultra.dart';
import 'package:picker_pro_max_ultra/src/camera_screen.dart';
import 'package:picker_pro_max_ultra/src/media_manager.dart';
import 'package:picker_pro_max_ultra/src/media_sheet.dart';

import 'platform_config.dart';

/// Represents different types of media files.
enum MediaType {
  /// An image file (e.g., PNG, JPG).
  image,

  /// A video file (e.g., MP4, AVI).
  video,

  /// A document file (e.g., PDF, DOCX).
  document,

  /// A audio file (e.g., mp3).
  audio,

  /// An unknown or unsupported media type.
  unknown,
}

/// A class for handling media selection and capture.
class MediaPicker {
  /// The build context where the media picker is used.
  final BuildContext context;

  /// The maximum number of media items that can be selected.
  final int maxLimit;

  /// The type of media that can be picked (image, video, or document).
  final MediaType mediaType;

  /// The text shown on the cancel button in the picker UI.
  final String cancelText;

  /// The text shown on the done/confirm button in the picker UI.
  final String doneText;

  /// Creates a [MediaPicker] instance.
  ///
  /// - [context]: The [BuildContext] of the screen where the picker is used.
  /// - [maxLimit]: The maximum number of media items to select. Defaults to `1`.
  /// - [mediaType]: The type of media to pick. Defaults to `MediaType.image`.
  MediaPicker({
    required this.context,
    this.maxLimit = 1,
    this.cancelText = "Cancel",
    this.doneText = "done",
    this.mediaType = MediaType.image,
  });

  /// Opens the media picker and returns a list of selected media files.
  ///
  /// If the user grants permission, it displays a bottom sheet grid
  /// to select images or videos.
  ///
  /// Returns a list of [MediaViewModel] if media is selected, otherwise `null`.
  Future<List<XFile>?> showPicker() async {

    if (context.mounted) {
      if (kIsWeb) {
        return await WebImplementation(mediaType: mediaType, maxLimit: maxLimit)
            .pickMultipleImages();
      } else {
        if(Platform.isIOS && mediaType == MediaType.audio){
          throw "Audio picking is not supported for ios , You can use picFile () by passing MediaType.audio";
        }
        return showGridBottomSheet(
            context, maxLimit, mediaType, cancelText, doneText);
      }
    }

    return null;
  }

  /// Opens the camera screen and returns the captured file path.
  ///
  /// Navigates to the [CameraScreen] and waits for a file to be captured.
  /// Returns the file path if successful, otherwise returns `null`.
  Future<File?> capturedFile({bool? allowRecord}) async {
    File? capturedPath;
    if(kIsWeb){
      throw "Camera is not supported for web";
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CameraScreen(
                allowRecord: allowRecord ?? false,
              )),
    ).then((path) async {
      if (path != null) {
        capturedPath = File(path);
        debugPrint(
            " after compress ${(await capturedPath?.length() ?? 0) / 1024} kb");
      }
    }).catchError((e) {
      capturedPath = null;
    });

    return capturedPath;
  }

  /// Opens the system file picker to select a document.
  ///
  /// Returns the selected file's path if successful, otherwise `null`.
  Future<File?> picFile() {
    assert(
        !kIsWeb &&
            (mediaType == MediaType.document || mediaType == MediaType.audio),
        'Only audio and documents are supported as file');
    return PickerProMaxUltra().picFile(mediaType: mediaType);
  }
}

/// An extension for determining the type of a file.
extension FileTypeChecker on File {
  /// Determines the media type of the file based on its extension.
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

  /// Returns the detected [MediaType] of the file.
  MediaType get fileType => _getFileType();

  /// Returns the name of the file (without its path).
  String get fileName => path.split("/").last;
}
