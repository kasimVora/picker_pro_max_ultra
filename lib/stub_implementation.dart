import 'dart:io';

import 'media_picker_widget.dart';
import 'picker_pro_max_ultra_platform_interface.dart';

/// A placeholder implementation for web platform when compiled for non-web environments.
///
/// This class throws [UnsupportedError] or [UnimplementedError] for all methods,
/// since web functionality is only available on web platforms.
class WebImplementation implements PickerProMaxUltraPlatform {
  /// Creates a [WebImplementation] instance with [maxLimit] and [mediaType].
  const WebImplementation({
    this.maxLimit = 1,
    this.mediaType = MediaType.image,
  });

  /// The maximum number of files allowed for selection.
  final int maxLimit;

  /// The type of media to be picked.
  final MediaType mediaType;

  /// Unsupported on non-web platforms. Throws [UnsupportedError].
  Future<List<String>?> pickMultipleImages() async {
    throw UnsupportedError('Web picker is only supported on the web platform.');
  }

  /// Not implemented. Throws [UnimplementedError].
  @override
  Future<String?> compressFile({required String inputPath}) {
    throw UnimplementedError();
  }

  /// Not implemented. Throws [UnimplementedError].
  @override
  Future<File?> getDoc({required int limit, required MediaType mediaType}) {
    throw UnimplementedError();
  }
}
