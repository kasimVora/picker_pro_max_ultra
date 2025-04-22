import 'dart:io';

import 'package:picker_pro_max_ultra/media_picker_widget.dart';

import 'picker_pro_max_ultra_platform_interface.dart';

/// A simple wrapper class to handle document picking across platforms.
class PickerProMaxUltra {
  /// Picks one or more documents using the platform implementation.
  ///
  /// Returns a list of file paths or URIs depending on the platform.
  Future<File?> picFile({required MediaType mediaType}) {
    return PickerProMaxUltraPlatform.instance
        .getDoc(limit: 1, mediaType: mediaType);
  }

  /// Compresses a media file at the given [inputPath] using platform-specific logic.
  ///
  /// Returns the path of the compressed file, or `null` if compression failed.
  Future<String?> compressFile({required String inputPath}) {
    return PickerProMaxUltraPlatform.instance
        .compressFile(inputPath: inputPath);
  }
}
