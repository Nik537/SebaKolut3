import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/editor_state.dart';

class ColorPickerSection extends StatefulWidget {
  const ColorPickerSection({super.key});

  @override
  State<ColorPickerSection> createState() => _ColorPickerSectionState();
}

class _ColorPickerSectionState extends State<ColorPickerSection> {
  late TextEditingController _hexController;
  Color _currentColor = const Color(0xFFAAAAAA); // Default gray (no tint)

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: 'AAAAAA');
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _applyColorToState(Color color, EditorState state) {
    // Convert color to HSV
    final hsv = HSVColor.fromColor(color);

    // Set hue (-180 to 180 range, color wheel is 0-360)
    double hue = hsv.hue;
    if (hue > 180) hue -= 360;
    state.setHue(hue);

    // Set saturation (0-1 for colorization intensity)
    // Use the HSV saturation directly as colorization intensity
    state.setSaturation(hsv.saturation);

    // Set brightness/value (1.0 = normal, use value to scale)
    // Map HSV value 0-1 to brightness 0-2 (so value=1 gives brightness=2 for full color)
    state.setBrightness(hsv.value * 2);

    setState(() {
      _currentColor = color;
      _hexController.text = _colorToHex(color);
    });
  }

  String _colorToHex(Color color) {
    // In Flutter 3.x, color.r/g/b are 0.0-1.0, need to multiply by 255
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return _currentColor;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorState>(
      builder: (context, state, _) {
        // Update current color based on state
        final hue = state.hue < 0 ? state.hue + 360 : state.hue;
        final saturation = (state.saturation / 2).clamp(0.0, 1.0);
        final brightness = (state.brightness / 2).clamp(0.0, 1.0);
        _currentColor = HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();

        // Update hex controller to reflect current color after frame completes
        final hexValue = _colorToHex(_currentColor);
        if (_hexController.text != hexValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _hexController.text != hexValue) {
              _hexController.text = hexValue;
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Color',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Color preview swatch
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[400]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Hex input
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _hexController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        prefixText: '#',
                        prefixStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        isDense: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                        LengthLimitingTextInputFormatter(6),
                        UpperCaseTextFormatter(),
                      ],
                      onSubmitted: (value) {
                        if (value.length == 6) {
                          final color = _hexToColor(value);
                          _applyColorToState(color, state);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
