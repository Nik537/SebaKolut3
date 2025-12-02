import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/hsb_utils.dart';

class EditorState extends ChangeNotifier {
  double _hue = 0; // -180 to 180
  double _saturation = 0; // 0 to 1 (colorization intensity: 0 = original, 1 = full color)
  double _brightness = 1.0; // 0 to 2

  bool _isExporting = false;
  Uint8List? _baseImageBytes;
  Uint8List? _overlayImageBytes;

  double get hue => _hue;
  double get saturation => _saturation;
  double get brightness => _brightness;
  bool get isExporting => _isExporting;
  Uint8List? get baseImageBytes => _baseImageBytes;
  Uint8List? get overlayImageBytes => _overlayImageBytes;

  void setHue(double value) {
    _hue = value.clamp(-180.0, 180.0);
    notifyListeners();
  }

  void setSaturation(double value) {
    _saturation = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setBrightness(double value) {
    _brightness = value.clamp(0.0, 2.0);
    notifyListeners();
  }

  void resetToDefaults() {
    _hue = 0;
    _saturation = 0; // No colorization by default
    _brightness = 1.0;
    notifyListeners();
  }

  void setExporting(bool value) {
    _isExporting = value;
    notifyListeners();
  }

  /// Get ColorFilter for real-time preview
  ColorFilter get previewColorFilter {
    // Convert hue from -180..180 to 0..360
    final targetHue = _hue < 0 ? _hue + 360 : _hue;

    // Use colorization matrix for proper tinting
    final matrix = buildColorizationMatrix(
      targetHue: targetHue,
      colorIntensity: _saturation.clamp(0.0, 1.0), // 0-1 range for colorization
      brightness: _brightness,
    );
    return ColorFilter.matrix(matrix);
  }

  /// Load images from assets
  Future<void> loadImages() async {
    _baseImageBytes = await _loadAsset('assets/images/SILK Template.png');
    _overlayImageBytes = await _loadAsset('assets/images/Carton.png');
    notifyListeners();
  }

  Future<Uint8List> _loadAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }
}
