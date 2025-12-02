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

/// Build a colorization matrix that tints an image with a target color
/// while applying brightness, highlights, and shadows adjustments.
///
/// targetHue: 0-360 (color wheel position)
/// colorIntensity: 0-1 (0 = original colors, 1 = fully colorized)
/// brightness: 0-2 (1 = normal, 0 = black, 2 = 2x bright)
/// highlights: -1 to 1 (adjusts bright areas, +1 = white)
/// shadows: -1 to 1 (adjusts dark areas, +1 = lift, -1 = crush)
List<double> buildColorizationMatrix({
  required double targetHue,
  required double colorIntensity,
  required double brightness,
  double highlights = 0,
  double shadows = 0,
}) {
  // Luminance weights (standard Rec. 709)
  const lr = 0.2126;
  const lg = 0.7152;
  const lb = 0.0722;

  // Convert target hue to RGB (at full saturation and value)
  final targetRgb = hsbToRgb(targetHue, 1.0, 1.0);
  final tr = targetRgb.r;
  final tg = targetRgb.g;
  final tb = targetRgb.b;

  // Clamp intensity to 0-1
  final double s = colorIntensity.clamp(0.0, 1.0);
  final double ns = 1.0 - s;

  // Build base colorization matrix
  // Strategy: Blend between original pixel colors and colorized version
  var baseMatrix = <double>[
    // R row: blend original R with colorized R
    ns + s * tr * lr, s * tr * lg, s * tr * lb, 0.0, 0.0,
    // G row: blend original G with colorized G
    s * tg * lr, ns + s * tg * lg, s * tg * lb, 0.0, 0.0,
    // B row: blend original B with colorized B
    s * tb * lr, s * tb * lg, ns + s * tb * lb, 0.0, 0.0,
    // Alpha row: unchanged
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  // Apply brightness as a multiplier to the matrix coefficients
  // brightness = 1.0 means no change, 0 = black, 2 = 2x bright
  final double b = brightness.clamp(0.0, 2.0);

  // Highlights: At max (+1), produce pure white (#ffffff)
  // At min (-1), darken the image significantly
  // We achieve white by: setting high offset + reducing contrast
  // At highlights = 1: offset = 1.0 (full white), slope reduced
  // At highlights = -1: offset = -0.5 (darken), slope increased
  final double h = highlights.clamp(-1.0, 1.0);

  // Shadows: At max (+1), lift blacks significantly (towards white)
  // At min (-1), crush to pure black (#000000)
  // We achieve black by: negative offset + increased contrast
  // At shadows = 1: lift blacks with positive offset
  // At shadows = -1: negative offset to crush blacks
  final double sh = shadows.clamp(-1.0, 1.0);

  // For highlights and shadows, we use a simpler, more direct approach:
  // The color matrix formula is: output = input * slope + offset
  //
  // Highlights at +1 (100%): We want pure white (#ffffff)
  //   - Set slope to 0 (ignore input) and offset to 1.0 (full white)
  // Highlights at -1 (-100%): Darken the image
  //   - Reduce slope to darken
  //
  // Shadows at -1 (-100%): We want pure black (#000000)
  //   - Set slope high and offset to -1.0 (crush to black)
  // Shadows at +1 (100%): Lift shadows (brighten darks)
  //   - Add positive offset

  // Highlights: interpolate between normal (slope=1, offset=0) and white (slope=0, offset=1)
  double highlightSlope = 1.0;
  double highlightOffset = 0.0;
  if (h > 0) {
    // At h=1: slope=0, offset=1 (pure white)
    highlightSlope = 1.0 - h;
    highlightOffset = h;
  } else if (h < 0) {
    // At h=-1: darken by reducing slope
    highlightSlope = 1.0 + (h * 0.5); // At -1: slope = 0.5
    highlightOffset = 0.0;
  }

  // Shadows: interpolate between normal and black
  double shadowSlope = 1.0;
  double shadowOffset = 0.0;
  if (sh < 0) {
    // At sh=-1: slope stays 1, offset=-1 (push everything to black)
    shadowOffset = sh; // At -1: offset = -1.0
  } else if (sh > 0) {
    // At sh=1: lift blacks by adding offset
    shadowOffset = sh * 0.5; // At +1: offset = 0.5
  }

  // Combine: apply brightness first, then highlights/shadows adjustments
  final double totalSlope = b * highlightSlope * shadowSlope;
  final double totalOffset = highlightOffset + shadowOffset;

  // Apply to matrix
  // Note: Flutter's ColorFilter.matrix expects offset values in 0-255 range
  for (int row = 0; row < 3; row++) {
    // Multiply each coefficient by total slope
    for (int col = 0; col < 3; col++) {
      baseMatrix[row * 5 + col] = baseMatrix[row * 5 + col] * totalSlope;
    }
    // Add offset for highlights/shadows (multiply by 255 for Flutter's expected range)
    baseMatrix[row * 5 + 4] = totalOffset * 255.0;
  }

  return baseMatrix;
}
