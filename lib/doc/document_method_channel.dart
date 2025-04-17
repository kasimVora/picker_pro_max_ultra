import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../media_picker_widget.dart';
import 'document_platform_interface.dart';

/// An implementation of [DocumentPlatform] that uses method channels.
class DocumentMethodChannel extends DocumentPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('untitled2');

  @override
  Future<File?> getDoc(
      {required int limit, required MediaType mediaType}) async {
    String? version;
    version = (await methodChannel.invokeMethod<List>(
            'getDoc', {'limit': limit, 'mediaType': mediaType.name}))
        ?.firstOrNull;
    return version != null ? File(version) : null;
  }

  @override
  Future<String?> compressFile({
    required String inputPath,
  }) async {
    final file = inputPath.split('/').last;
    final dir = inputPath.substring(0, inputPath.lastIndexOf('/'));
    String outputPath = "";
    final nameParts = file.split('.');
    if (nameParts.length < 2) return inputPath; // fallback

    final name = nameParts.sublist(0, nameParts.length - 1).join('.');
    final ext = nameParts.last;

    outputPath = '$dir/${name}_compressed.$ext';
    if (outputPath.contains(".temp")) {
      outputPath = outputPath.replaceAll(".temp", ".mp4");
    }

    return await methodChannel.invokeMethod<String?>('compressFile', {
      'inputPath': inputPath,
      'outputPath': outputPath,
    });
  }
}
