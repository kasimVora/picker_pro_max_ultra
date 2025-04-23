import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as html;

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
    final input = html.HTMLInputElement();

    input.type = 'file';
    input.multiple = maxLimit > 0;

    // Accept types based on MediaType
    input.accept = switch (mediaType) {
      MediaType.audio => [
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
        ].join(','),
      MediaType.document => [
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
        ].join(','),
      MediaType.video => 'video/*',
      _ => 'image/*',
    };

    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.length > 0) {
        final List<XFile> xFiles = [];

        for (int i = 0; i < files.length && i < maxLimit; i++) {
          final reader = html.FileReader();
          final readCompleter = Completer<XFile>();
          reader.readAsArrayBuffer(files.item(i) as html.Blob);
          reader.onLoadEnd.listen((_) {
            final data = reader.result as ByteBuffer;
            final xFile = XFile.fromData(
              Uint8List.view(data),
              name: files.item(i)?.name ?? "Undefined",
              mimeType: files.item(i)?.type ?? "Undefined",
              lastModified: files.item(i)?.lastModified != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      files.item(i)!.lastModified)
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
