import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/editor_state.dart';

class HSBSliders extends StatefulWidget {
  const HSBSliders({super.key});

  @override
  State<HSBSliders> createState() => _HSBSlidersState();
}

class _HSBSlidersState extends State<HSBSliders> {
  late TextEditingController _hueController;
  late TextEditingController _saturationController;
  late TextEditingController _brightnessController;

  @override
  void initState() {
    super.initState();
    _hueController = TextEditingController();
    _saturationController = TextEditingController();
    _brightnessController = TextEditingController();
  }

  @override
  void dispose() {
    _hueController.dispose();
    _saturationController.dispose();
    _brightnessController.dispose();
    super.dispose();
  }

  void _updateControllerIfNeeded(TextEditingController controller, String newValue) {
    if (controller.text != newValue && !controller.text.endsWith('.')) {
      final selection = controller.selection;
      controller.text = newValue;
      // Try to preserve cursor position
      if (selection.isValid && selection.end <= newValue.length) {
        controller.selection = selection;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorState>(
      builder: (context, state, _) {
        // Update controllers when state changes (but not during editing)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_hueController.text.contains(RegExp(r'[0-9]')) ||
              double.tryParse(_hueController.text) != state.hue) {
            _updateControllerIfNeeded(_hueController, state.hue.toStringAsFixed(0));
          }
          if (!_saturationController.text.contains(RegExp(r'[0-9]')) ||
              double.tryParse(_saturationController.text) != (state.saturation * 100)) {
            _updateControllerIfNeeded(_saturationController, (state.saturation * 100).toStringAsFixed(0));
          }
          if (!_brightnessController.text.contains(RegExp(r'[0-9]')) ||
              double.tryParse(_brightnessController.text) != (state.brightness * 100)) {
            _updateControllerIfNeeded(_brightnessController, (state.brightness * 100).toStringAsFixed(0));
          }
        });

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjustments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Hue slider
              _buildSliderSection(
                label: 'Hue',
                value: state.hue,
                min: -180,
                max: 180,
                suffix: '°',
                controller: _hueController,
                onChanged: state.setHue,
                onTextSubmitted: (text) {
                  final parsed = double.tryParse(text);
                  if (parsed != null) {
                    state.setHue(parsed.clamp(-180, 180));
                  }
                },
                activeColor: Colors.purple,
              ),
              const SizedBox(height: 20),

              // Saturation slider
              _buildSliderSection(
                label: 'Saturation',
                value: state.saturation,
                min: 0,
                max: 2,
                suffix: '%',
                isPercentage: true,
                controller: _saturationController,
                onChanged: state.setSaturation,
                onTextSubmitted: (text) {
                  final parsed = double.tryParse(text);
                  if (parsed != null) {
                    state.setSaturation((parsed / 100).clamp(0, 2));
                  }
                },
                activeColor: Colors.blue,
              ),
              const SizedBox(height: 20),

              // Brightness slider
              _buildSliderSection(
                label: 'Brightness',
                value: state.brightness,
                min: 0,
                max: 2,
                suffix: '%',
                isPercentage: true,
                controller: _brightnessController,
                onChanged: state.setBrightness,
                onTextSubmitted: (text) {
                  final parsed = double.tryParse(text);
                  if (parsed != null) {
                    state.setBrightness((parsed / 100).clamp(0, 2));
                  }
                },
                activeColor: Colors.orange,
              ),

              const Spacer(),

              // Reset button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<EditorState>().resetToDefaults();
                    _hueController.text = '0';
                    _saturationController.text = '100';
                    _brightnessController.text = '100';
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset to Defaults'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliderSection({
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required TextEditingController controller,
    required ValueChanged<double> onChanged,
    required ValueChanged<String> onTextSubmitted,
    required Color activeColor,
    bool isPercentage = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(
              width: 80,
              height: 32,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  suffixText: suffix,
                  suffixStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: activeColor),
                  ),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: false),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
                onSubmitted: onTextSubmitted,
                onEditingComplete: () {
                  onTextSubmitted(controller.text);
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: activeColor,
            thumbColor: activeColor,
            inactiveTrackColor: activeColor.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (newValue) {
              onChanged(newValue);
              if (isPercentage) {
                controller.text = (newValue * 100).toStringAsFixed(0);
              } else {
                controller.text = newValue.toStringAsFixed(0);
              }
            },
          ),
        ),
      ],
    );
  }
}
