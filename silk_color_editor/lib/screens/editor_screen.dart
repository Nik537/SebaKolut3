import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/editor_state.dart';
import '../widgets/image_preview.dart';
import '../widgets/hsb_sliders.dart';
import '../widgets/export_button.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  @override
  void initState() {
    super.initState();
    // Load images when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorState>().loadImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SILK Color Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: const [
          ExportButton(),
          SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout: side panel on wide screens, bottom panel on narrow
          final isWide = constraints.maxWidth > 600;

          if (isWide) {
            return Row(
              children: [
                // Preview area (expandable)
                const Expanded(
                  flex: 3,
                  child: ImagePreview(),
                ),
                // Controls panel (fixed width)
                SizedBox(
                  width: 280,
                  child: const HSBSliders(),
                ),
              ],
            );
          } else {
            // Narrow layout: vertical
            return Column(
              children: [
                // Preview area
                const Expanded(
                  flex: 2,
                  child: ImagePreview(),
                ),
                // Controls panel
                SizedBox(
                  height: 300,
                  child: const HSBSliders(),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
