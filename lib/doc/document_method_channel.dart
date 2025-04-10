import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'document_platform_interface.dart';

/// An implementation of [DocumentPlatform] that uses method channels.
class DocumentMethodChannel extends DocumentPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('untitled2');

  @override
  Future<File?> getDoc({required int limit}) async {
    String? version;
    version =
        (await methodChannel.invokeMethod<List>('getDoc', {'limit': limit}))
            ?.firstOrNull;
    return version != null ? File(version) : null;
  }
}
