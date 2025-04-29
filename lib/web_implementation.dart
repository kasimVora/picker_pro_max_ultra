import 'dart:async';
import 'dart:html' as html;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'media_picker_widget.dart';
import 'picker_pro_max_ultra_platform_interface.dart';

/// A web implementation of the [PickerProMaxUltraPlatform] interface.
///
/// This handles picking media files (image, video, audio, document)
/// through the browser's file input system.
class WebImplementation extends PickerProMaxUltraPlatform {
  /// Maximum number of files the user can select.
  final int maxLimit;

  /// Type of media to be picked.
  final MediaType mediaType;

  /// Creates an instance of [WebImplementation].
  WebImplementation({
    this.maxLimit = 1,
    this.mediaType = MediaType.image,
  });

  /// Registers the web implementation with the Flutter plugin system.
  static void registerWith(Registrar registrar) {
    PickerProMaxUltraPlatform.instance = WebImplementation();
  }

  /// Opens the browser's file picker for selecting multiple media files.
  ///
  /// Returns a [List] of [String] objects based on the selected files.
  Future<List<String>> pickMultipleImages() async {
    final completer = Completer<List<String>>();
    final input = html.FileUploadInputElement();

    input.multiple = maxLimit > 1;
    input.accept = _getAcceptMimeTypes();

    input.click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete([]);
        return;
      }

      final List<String> fileUrls = [];

      for (var i = 0; i < files.length && i < maxLimit; i++) {
        final file = files[i];
        // Create a blob URL (temporary object URL for browser use)
        final url = html.Url.createObjectUrl(file);
        fileUrls.add(url);
      }

      completer.complete(fileUrls);
    });

    return completer.future;
  }

  /// Returns the accepted MIME types based on [mediaType].
  String _getAcceptMimeTypes() {
    switch (mediaType) {
      case MediaType.audio:
        return [
          '.mp3',
          '.wav',
          '.aac',
          '.m4a',
          '.ogg',
          '.oga',
          '.flac',
          '.wma',
          '.amr',
          '.aiff',
          '.opus',
          '.webm'
        ].join(',');
      case MediaType.document:
        return [
          '.pdf',
          '.doc',
          '.docx',
          '.xls',
          '.xlsx',
          '.ppt',
          '.pptx',
          '.txt',
          '.rtf',
          '.csv'
        ].join(',');
      case MediaType.video:
        return 'video/*';
      case MediaType.image:
      default:
        return 'image/*';
    }
  }
}
