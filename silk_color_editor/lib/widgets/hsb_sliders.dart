import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/editor_state.dart';

class HSBSliders extends StatelessWidget {
  const HSBSliders({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorState>(
      builder: (context, state, _) {
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
                displayValue: '${state.hue.toStringAsFixed(0)}°',
                onChanged: state.setHue,
                activeColor: Colors.purple,
              ),
              const SizedBox(height: 20),

              // Saturation slider
              _buildSliderSection(
                label: 'Saturation',
                value: state.saturation,
                min: 0,
                max: 2,
                displayValue: '${(state.saturation * 100).toStringAsFixed(0)}%',
                onChanged: state.setSaturation,
                activeColor: Colors.blue,
              ),
              const SizedBox(height: 20),

              // Brightness slider
              _buildSliderSection(
                label: 'Brightness',
                value: state.brightness,
                min: 0,
                max: 2,
                displayValue: '${(state.brightness * 100).toStringAsFixed(0)}%',
                onChanged: state.setBrightness,
                activeColor: Colors.orange,
              ),

              const Spacer(),

              // Reset button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: state.resetToDefaults,
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
    required String displayValue,
    required ValueChanged<double> onChanged,
    required Color activeColor,
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
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
