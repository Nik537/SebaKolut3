import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../utils/hsb_utils.dart';

class ProcessingParams {
  final Uint8List sourceBytes;
  final double hue;
  final double saturation;
  final double brightness;

  ProcessingParams({
    required this.sourceBytes,
    required this.hue,
    required this.saturation,
    required this.brightness,
  });
}

class HSBProcessor {
  /// Process image with HSB adjustments in a background isolate
  static Future<Uint8List> processImage(ProcessingParams params) async {
    return compute(_processImageIsolate, params);
  }

  static Uint8List _processImageIsolate(ProcessingParams params) {
    final source = img.decodeImage(params.sourceBytes);
    if (source == null) {
      throw Exception('Failed to decode image');
    }

    final result = img.Image.from(source);

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);

        // Get RGB values (0-1 range)
        final r = pixel.r.toDouble() / 255.0;
        final g = pixel.g.toDouble() / 255.0;
        final b = pixel.b.toDouble() / 255.0;
        final a = pixel.a.toInt();

        // Skip fully transparent pixels
        if (a == 0) continue;

        // Convert RGB to HSB
        final hsb = rgbToHsb(r, g, b);

        // Apply hue shift
        double newHue = (hsb.hue + params.hue) % 360;
        if (newHue < 0) newHue += 360;

        // Apply saturation factor
        double newSaturation = (hsb.saturation * params.saturation).clamp(0.0, 1.0);

        // Apply brightness factor
        double newBrightness = (hsb.brightness * params.brightness).clamp(0.0, 1.0);

        // Convert back to RGB
        final newRgb = hsbToRgb(newHue, newSaturation, newBrightness);

        result.setPixel(
          x,
          y,
          img.ColorRgba8(
            (newRgb.r * 255).round().clamp(0, 255),
            (newRgb.g * 255).round().clamp(0, 255),
            (newRgb.b * 255).round().clamp(0, 255),
            a,
          ),
        );
      }
    }

    return Uint8List.fromList(img.encodePng(result));
  }
}
