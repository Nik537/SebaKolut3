import 'dart:math' as math;

class HSBColor {
  final double hue; // 0-360
  final double saturation; // 0-1
  final double brightness; // 0-1

  const HSBColor(this.hue, this.saturation, this.brightness);
}

class RGBColor {
  final double r, g, b; // 0-1

  const RGBColor(this.r, this.g, this.b);
}

/// Convert RGB (0-1) to HSB
HSBColor rgbToHsb(double r, double g, double b) {
  final maxVal = math.max(r, math.max(g, b));
  final minVal = math.min(r, math.min(g, b));
  final delta = maxVal - minVal;

  // Brightness
  final brightness = maxVal;

  // Saturation
  final saturation = maxVal == 0 ? 0.0 : delta / maxVal;

  // Hue
  double hue = 0;
  if (delta != 0) {
    if (maxVal == r) {
      hue = 60 * (((g - b) / delta) % 6);
    } else if (maxVal == g) {
      hue = 60 * (((b - r) / delta) + 2);
    } else {
      hue = 60 * (((r - g) / delta) + 4);
    }
  }
  if (hue < 0) hue += 360;

  return HSBColor(hue, saturation, brightness);
}

/// Convert HSB to RGB (0-1)
RGBColor hsbToRgb(double h, double s, double v) {
  final c = v * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = v - c;

  double r, g, b;

  if (h < 60) {
    r = c;
    g = x;
    b = 0;
  } else if (h < 120) {
    r = x;
    g = c;
    b = 0;
  } else if (h < 180) {
    r = 0;
    g = c;
    b = x;
  } else if (h < 240) {
    r = 0;
    g = x;
    b = c;
  } else if (h < 300) {
    r = x;
    g = 0;
    b = c;
  } else {
    r = c;
    g = 0;
    b = x;
  }

  return RGBColor(r + m, g + m, b + m);
}

/// Build a 5x4 color matrix for saturation adjustment
List<double> buildSaturationMatrix(double saturation) {
  final s = saturation;
  final sr = (1 - s) * 0.3086;
  final sg = (1 - s) * 0.6094;
  final sb = (1 - s) * 0.0820;

  return [
    sr + s, sg, sb, 0, 0,
    sr, sg + s, sb, 0, 0,
    sr, sg, sb + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// Build a 5x4 color matrix for brightness adjustment
List<double> buildBrightnessMatrix(double brightness) {
  return [
    brightness, 0, 0, 0, 0,
    0, brightness, 0, 0, 0,
    0, 0, brightness, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// Build a 5x4 color matrix for hue rotation (approximate)
List<double> buildHueRotationMatrix(double degrees) {
  final radians = degrees * math.pi / 180;
  final cos = math.cos(radians);
  final sin = math.sin(radians);

  // Hue rotation matrix using YIQ color space approximation
  const lumR = 0.213;
  const lumG = 0.715;
  const lumB = 0.072;

  return [
    lumR + cos * (1 - lumR) + sin * (-lumR),
    lumG + cos * (-lumG) + sin * (-lumG),
    lumB + cos * (-lumB) + sin * (1 - lumB),
    0,
    0,
    lumR + cos * (-lumR) + sin * 0.143,
    lumG + cos * (1 - lumG) + sin * 0.140,
    lumB + cos * (-lumB) + sin * (-0.283),
    0,
    0,
    lumR + cos * (-lumR) + sin * (-(1 - lumR)),
    lumG + cos * (-lumG) + sin * lumG,
    lumB + cos * (1 - lumB) + sin * lumB,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

/// Multiply two 5x4 color matrices
List<double> multiplyColorMatrices(List<double> a, List<double> b) {
  final result = List<double>.filled(20, 0);

  for (int row = 0; row < 4; row++) {
    for (int col = 0; col < 5; col++) {
      double sum = 0;
      for (int i = 0; i < 4; i++) {
        sum += a[row * 5 + i] * b[i * 5 + col];
      }
      if (col == 4) {
        sum += a[row * 5 + 4];
      }
      result[row * 5 + col] = sum;
    }
  }

  return result;
}

/// Combine hue, saturation, and brightness into a single color matrix
List<double> buildCombinedHSBMatrix({
  required double hue,
  required double saturation,
  required double brightness,
}) {
  var matrix = buildHueRotationMatrix(hue);
  matrix = multiplyColorMatrices(matrix, buildSaturationMatrix(saturation));
  matrix = multiplyColorMatrices(matrix, buildBrightnessMatrix(brightness));
  return matrix;
}
