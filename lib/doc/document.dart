import 'dart:io';

import 'package:picker_pro_max_ultra/media_picker_widget.dart';

import 'document_platform_interface.dart';

/// A simple wrapper class to handle document picking across platforms.
class DocumentPicker {
  /// Picks one or more documents using the platform implementation.
  ///
  /// Returns a list of file paths or URIs depending on the platform.
  Future<File?> picFile({required MediaType mediaType}) {
    return DocumentPlatform.instance.getDoc(limit: 1, mediaType: mediaType);
  }

  Future<String?> compressFile({required String inputPath}) {
    return DocumentPlatform.instance.compressFile(inputPath: inputPath);
  }
}
