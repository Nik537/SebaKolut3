import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/editor_state.dart';

class ImagePreview extends StatelessWidget {
  const ImagePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorState>(
      builder: (context, state, _) {
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Base image with HSB filter
                  ColorFiltered(
                    colorFilter: state.previewColorFilter,
                    child: Image.asset(
                      'assets/images/SILK Template.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Overlay (unchanged)
                  Image.asset(
                    'assets/images/Carton.png',
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
