import 'dart:io';

import 'document_platform_interface.dart';

/// A simple wrapper class to handle document picking across platforms.
class DocumentPicker {
  /// Picks one or more documents using the platform implementation.
  ///
  /// Returns a list of file paths or URIs depending on the platform.
  Future<File?> picFile() {
    return DocumentPlatform.instance.getDoc();
  }
}
