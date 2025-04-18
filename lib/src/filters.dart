import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'enums.dart';

class Filters  {

  Future<ui.Image> decodeImage(Uint8List data) async {
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<File> onFilterApplied(FilterType selectedFilter, File capturedImageFile) async {
    final uiImage = await loadUiImage(capturedImageFile); // Step 1

    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba); // Step 2
    final pixels = byteData!.buffer.asUint8List();

    applyFilter(pixels, selectedFilter); // Step 3

    // Step 4: Convert modified pixels back to ui.Image
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      uiImage.width,
      uiImage.height,
      ui.PixelFormat.rgba8888,
          (ui.Image img) {
        completer.complete(img);
      },
    );
    final filteredImage = await completer.future;

    // Step 5: Convert to PNG bytes
    final pngBytes = await filteredImage.toByteData(format: ui.ImageByteFormat.png);

    // Step 6: Save image
    final fileName = 'filtered_${DateTime.now().millisecondsSinceEpoch}.png';
    return await saveFilteredImage(pngBytes!.buffer.asUint8List(), fileName);
  }


  Future<ui.Image> loadUiImage(File file) async {
    final bytes = await file.readAsBytes();
    return decodeImageFromList(bytes);
  }





  // Save filtered image
  Future<File> saveFilteredImage(Uint8List bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final file = File(path);
    return await file.writeAsBytes(bytes);
  }


  static const Map<FilterType, String> filterNames = {
    FilterType.normal: "Normal",
    FilterType.sepia: "Sepia",
    FilterType.gray: "Gray",
    FilterType.blue: "Blue",
    FilterType.red: "Red",
    FilterType.green: "Green",
    FilterType.invert: "Invert",
    FilterType.warm: "Warm",
    FilterType.cool: "Cool",
    FilterType.vintage: "Vintage",
    FilterType.faded: "Faded",
    FilterType.bright: "Bright",
    FilterType.dark: "Dark",
    FilterType.highContrast: "High Contrast",
    FilterType.lowContrast: "Low Contrast",
    FilterType.cyan: "Cyan",
    FilterType.yellow: "Yellow",
    FilterType.ocean: "Ocean",
    FilterType.pink: "Pink",
  };

  static final Map<FilterType, Color> filterColors = {
    FilterType.normal: Colors.transparent,
    FilterType.sepia: const Color(0xFF704214),
    FilterType.blue: Colors.blueAccent,
    FilterType.gray: Colors.grey,
    FilterType.red: Colors.red,
    FilterType.green: Colors.green,
    FilterType.invert: Colors.purple,
    FilterType.warm: Colors.orange,
    FilterType.cool: Colors.cyan,
    FilterType.vintage: Colors.brown,
    FilterType.faded: Colors.lightBlueAccent,
    FilterType.bright: Colors.yellow,
    FilterType.dark: Colors.black,
    FilterType.highContrast: Colors.white,
    FilterType.lowContrast: Colors.grey.shade300,
    FilterType.cyan: Colors.cyan,
    FilterType.yellow: Colors.yellow,
    FilterType.ocean: Colors.teal,
    FilterType.pink: Colors.pink,
  };

  // Apply filter to view only for camera preview
// Apply filter to view only for camera preview
  static ColorFilter applyFilterColor(FilterType filterType) {
    ColorFilter _currentFilter;
    switch (filterType) {
      case FilterType.normal:
        _currentFilter = ColorFilter.mode(Colors.transparent, BlendMode.multiply);
        break;
      case FilterType.sepia:
        _currentFilter = ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0,     0,     0,     1, 0,
        ]);
        break;
      case FilterType.gray:
        _currentFilter = ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);
        break;
      case FilterType.blue:
        _currentFilter = ColorFilter.matrix([
          0.6, 0.1,   0.2,   0, 0,  // Red
          0.1,   0.6, 0.2,   0, 0,  // Green
          0.2,   0.2,   1.2, 0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.red:
        _currentFilter = ColorFilter.matrix([
          0.9, 0.1, 0.4, 0, 0,  // Red boost, slight blend from G and B
          0.1, 0.5, 0.1, 0, 0,  // Green dimmed and blended
          0.0, 0.1, 0.5, 0, 0,  // Blue dimmed with minimal red influence
          0, 0, 0, 1, 0         // Alpha unchanged
        ]);
        break;
      case FilterType.green:
        _currentFilter = ColorFilter.matrix([
          0.5, 0,   0,   0, 0,  // Red
          0,   1.5, 0,   0, 0,  // Green
          0,   0,   0.5, 0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.invert:
        _currentFilter = ColorFilter.matrix([
          -1, 0, 0, 0, 255, // Red
          0, -1, 0, 0, 255, // Green
          0, 0, -1, 0, 255, // Blue
          0, 0, 0, 1, 0,    // Alpha
        ]);
        break;
      case FilterType.warm:
        _currentFilter = ColorFilter.matrix([
          1.2, 0,   0,   0, 0,  // Red
          0,   1.1, 0,   0, 0,  // Green
          0,   0,   1,   0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.cool:
        _currentFilter = ColorFilter.matrix([
          1,   0,   0,   0, 0,  // Red
          0,   1,   0,   0, 0,  // Green
          0,   0,   1.5, 0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.vintage:
        _currentFilter = ColorFilter.matrix([
          0.9, 0.6, 0.3, 0, 0,  // Red
          0.7, 0.9, 0.2, 0, 0,  // Green
          0.3, 0.5, 0.7, 0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.faded:
        _currentFilter = ColorFilter.matrix([
          0.8, 0.8, 0.8, 0, 0,  // Red
          0.8, 0.8, 0.8, 0, 0,  // Green
          0.8, 0.8, 0.8, 0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.bright:
        _currentFilter = ColorFilter.matrix([
          1.3, 0,   0,   0, 0,  // Red
          0,   1.3, 0,   0, 0,  // Green
          0,   0,   1.3, 0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.dark:
        _currentFilter = ColorFilter.matrix([
          0.7, 0,   0,   0, 0,  // Red
          0,   0.7, 0,   0, 0,  // Green
          0,   0,   0.7, 0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.highContrast:
        _currentFilter = ColorFilter.matrix([
          1.8, 0,   0,   0, 0,  // Red
          0,   1.8, 0,   0, 0,  // Green
          0,   0,   1.8, 0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.lowContrast:
        _currentFilter = ColorFilter.matrix([
          0.7, 0,   0,   0, 0,  // Red
          0,   0.7, 0,   0, 0,  // Green
          0,   0,   0.7, 0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.cyan:
        _currentFilter = ColorFilter.matrix([
          0,   1,   1,   0, 0,  // Red
          0,   1,   1,   0, 0,  // Green
          0,   1,   1,   0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.magenta:
        _currentFilter = ColorFilter.matrix([
          1,   0,   1,   0, 0,  // Red
          0,   1,   1,   0, 0,  // Green
          0,   0,   1,   0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.yellow:
        _currentFilter = ColorFilter.matrix([
          1,   1,   0,   0, 0,  // Red
          1,   1,   0,   0, 0,  // Green
          0,   0,   1,   0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.ocean:
        _currentFilter = ColorFilter.matrix([
          0.5, 0,   0,   0, 0,  // Red
          0,   1.5, 0,   0, 0,  // Green
          0,   0,   1.8, 0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      case FilterType.pink:
        _currentFilter = ColorFilter.matrix([
          1.2, 0,   0,   0, 0,  // Red
          0,   0.7, 0,   0, 0,  // Green
          0,   0,   1.5, 0, 0,  // Blue
          0,   0,   0,   1, 0,  // Alpha
        ]);
        break;
      default:
        _currentFilter = ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
    return _currentFilter;
  }

  // Apply filter to original image by pixel
  void applyFilter(Uint8List pixels, FilterType type) {
    for (int i = 0; i < pixels.length; i += 4) {
      int r = pixels[i];
      int g = pixels[i + 1];
      int b = pixels[i + 2];

      switch (type) {
        case FilterType.normal:
          break;

        case FilterType.sepia:
          final tr = (0.393 * r + 0.769 * g + 0.189 * b).clamp(0, 255).round();
          final tg = (0.349 * r + 0.686 * g + 0.168 * b).clamp(0, 255).round();
          final tb = (0.272 * r + 0.534 * g + 0.131 * b).clamp(0, 255).round();
          r = tr;
          g = tg;
          b = tb;
          break;

        case FilterType.gray:
          final gray = (0.3 * r + 0.59 * g + 0.11 * b).round();
          r = g = b = gray;
          break;

        case FilterType.blue:
          b = (b * 1.5).clamp(0, 255).round();
          break;

        case FilterType.red:
          r = (r * 1.5).clamp(0, 255).round();
          break;

        case FilterType.green:
          g = (g * 1.5).clamp(0, 255).round();
          break;

        case FilterType.invert:
          r = 255 - r;
          g = 255 - g;
          b = 255 - b;
          break;

        case FilterType.warm:
          r = (r + 30).clamp(0, 255);
          b = (b - 20).clamp(0, 255);
          break;

        case FilterType.cool:
          b = (b + 30).clamp(0, 255);
          r = (r - 20).clamp(0, 255);
          break;

        case FilterType.vintage:
          final gray = (0.3 * r + 0.59 * g + 0.11 * b).round();
          r = (gray + 30).clamp(0, 255);
          g = (gray + 15).clamp(0, 255);
          b = (gray).clamp(0, 255);
          break;

        case FilterType.faded:
          r = (r * 0.7 + 50).clamp(0, 255).round();
          g = (g * 0.7 + 50).clamp(0, 255).round();
          b = (b * 0.7 + 50).clamp(0, 255).round();
          break;

        case FilterType.bright:
          r = (r + 40).clamp(0, 255);
          g = (g + 40).clamp(0, 255);
          b = (b + 40).clamp(0, 255);
          break;

        case FilterType.dark:
          r = (r - 40).clamp(0, 255);
          g = (g - 40).clamp(0, 255);
          b = (b - 40).clamp(0, 255);
          break;

        case FilterType.highContrast:
          r = r > 128 ? 255 : 0;
          g = g > 128 ? 255 : 0;
          b = b > 128 ? 255 : 0;
          break;

        case FilterType.lowContrast:
          r = (r * 0.5 + 64).round();
          g = (g * 0.5 + 64).round();
          b = (b * 0.5 + 64).round();
          break;

        case FilterType.cyan:
          r = (r * 0.5).round();
          g = (g + 40).clamp(0, 255);
          b = (b + 40).clamp(0, 255);
          break;

        case FilterType.magenta:
          g = (g * 0.5).round();
          r = (r + 40).clamp(0, 255);
          b = (b + 40).clamp(0, 255);
          break;

        case FilterType.yellow:
          b = (b * 0.5).round();
          r = (r + 40).clamp(0, 255);
          g = (g + 40).clamp(0, 255);
          break;

        case FilterType.ocean:
          r = (r * 0.5).round();
          g = (g + 30).clamp(0, 255);
          b = (b + 60).clamp(0, 255);
          break;

        case FilterType.pink:
          g = (g * 0.7).round();
          r = (r + 40).clamp(0, 255);
          b = (b + 40).clamp(0, 255);
          break;
      }

      pixels[i] = r;
      pixels[i + 1] = g;
      pixels[i + 2] = b;
    }
  }

}


