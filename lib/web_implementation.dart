import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
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
  /// Returns a [List] of [XFile] objects based on the selected files.
  Future<List<XFile>> pickMultipleImages() async {
    final completer = Completer<List<XFile>>();
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();

    // Set accepted file types based on mediaType
    if (mediaType == MediaType.audio) {
      uploadInput.accept = [
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
    } else if (mediaType == MediaType.document) {
      uploadInput.accept = [
        '.pdf',
        '.doc',
        '.docx',
        '.xls',
        '.xlsx',
        '.ppt',
        '.pptx',
        '.txt',
        '.rtf',
        '.csv',
      ].join(',');
    } else if (mediaType == MediaType.video) {
      uploadInput.accept = 'video/*';
    } else {
      uploadInput.accept = 'image/*';
    }

    uploadInput.multiple = maxLimit > 0;
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        List<XFile> xFiles = [];

        for (final file in files.take(maxLimit)) {
          final reader = html.FileReader();
          final readCompleter = Completer<XFile>();

          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((event) {
            final data = reader.result as Uint8List;

            final xFile = XFile.fromData(
              data,
              name: file.name,
              mimeType: file.type,
              lastModified: file.lastModified != null
                  ? DateTime.fromMillisecondsSinceEpoch(file.lastModified!)
                  : null,
            );

            readCompleter.complete(xFile);
          });

          xFiles.add(await readCompleter.future);
        }

        completer.complete(xFiles);
      } else {
        completer.complete([]);
      }
    });

    return completer.future;
  }
}
