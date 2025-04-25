import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picker_pro_max_ultra/media_picker_widget.dart';
import 'package:picker_pro_max_ultra/picker_pro_max_ultra.dart';
import 'package:picker_pro_max_ultra/picker_pro_max_ultra_platform_interface.dart';
import 'package:picker_pro_max_ultra/picker_pro_max_ultra_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPickerProMaxUltraPlatform
    with MockPlatformInterfaceMixin
    implements PickerProMaxUltraPlatform {

  @override
  Future<String?> compressFile({required String inputPath}) {
    // TODO: implement compressFile
    throw UnimplementedError();
  }

  @override
  Future<File?> getDoc({required int limit, required MediaType mediaType}) {
    // TODO: implement getDoc
    throw UnimplementedError();
  }
}

void main() {
  final PickerProMaxUltraPlatform initialPlatform = PickerProMaxUltraPlatform.instance;

  test('$MethodChannelPickerProMaxUltra is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPickerProMaxUltra>());
  });

  test('getPlatformVersion', () async {
    PickerProMaxUltra pickerProMaxUltraPlugin = PickerProMaxUltra();
    MockPickerProMaxUltraPlatform fakePlatform = MockPickerProMaxUltraPlatform();
    PickerProMaxUltraPlatform.instance = fakePlatform;


  });
}
