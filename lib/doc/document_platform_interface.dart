import 'dart:io';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../media_picker_widget.dart';
import 'document_method_channel.dart';

/// The interface that all platform-specific implementations of the document picker must extend.
///
/// This class should not be implemented directly. Instead, extend this class
/// and provide a concrete implementation of [getDoc].
abstract class DocumentPlatform extends PlatformInterface {
  /// Constructs a [DocumentPlatform].
  DocumentPlatform() : super(token: _token);

  static final Object _token = Object();

  static DocumentPlatform _instance = DocumentMethodChannel();

  /// The default instance of [DocumentPlatform] to use.
  ///
  /// Defaults to [DocumentMethodChannel], which uses method channels to communicate with the native platform.
  static DocumentPlatform get instance => _instance;

  /// Sets the default instance of [DocumentPlatform].
  ///
  /// Platform-specific plugins should call this method to register their implementation.
  static set instance(DocumentPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Picks a document and returns its path as a [String].
  ///
  /// Must be implemented by the platform-specific class.
  Future<File?> getDoc({required int limit, required MediaType mediaType}) {
    throw UnimplementedError('getDoc() has not been implemented.');
  }

  Future<String?> compressFile({required String inputPath}) {
    throw UnimplementedError('compressFile() has not been implemented.');
  }
}
