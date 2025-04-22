import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picker_pro_max_ultra/picker_pro_max_ultra_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelPickerProMaxUltra platform = MethodChannelPickerProMaxUltra();
  const MethodChannel channel = MethodChannel('picker_pro_max_ultra');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {

  });
}
