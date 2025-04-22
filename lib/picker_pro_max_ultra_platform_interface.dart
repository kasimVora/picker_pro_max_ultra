import 'dart:io';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'media_picker_widget.dart';
import 'picker_pro_max_ultra_method_channel.dart';

/// PickerProMaxUltraPlatform
///
abstract class PickerProMaxUltraPlatform extends PlatformInterface {
  /// Constructs a PickerProMaxUltraPlatform.
  PickerProMaxUltraPlatform() : super(token: _token);

  static final Object _token = Object();

  static PickerProMaxUltraPlatform _instance = MethodChannelPickerProMaxUltra();

  /// The default instance of [PickerProMaxUltraPlatform] to use.
  ///
  /// Defaults to [MethodChannelPickerProMaxUltra].
  static PickerProMaxUltraPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PickerProMaxUltraPlatform] when
  /// they register themselves.
  static set instance(PickerProMaxUltraPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Picks a document and returns its path as a [String].
  ///
  /// Must be implemented by the platform-specific class.
  Future<File?> getDoc({required int limit, required MediaType mediaType}) {
    throw UnimplementedError('getDoc() has not been implemented.');
  }

  /// compressFile
  Future<String?> compressFile({required String inputPath}) {
    throw UnimplementedError('compressFile() has not been implemented.');
  }
}
