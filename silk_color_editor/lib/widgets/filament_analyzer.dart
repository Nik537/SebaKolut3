import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/editor_state.dart';
import '../services/gemini_color_service.dart';

class FilamentAnalyzer extends StatefulWidget {
  const FilamentAnalyzer({super.key});

  @override
  State<FilamentAnalyzer> createState() => _FilamentAnalyzerState();
}

class _FilamentAnalyzerState extends State<FilamentAnalyzer> {
  final TextEditingController _apiKeyController = TextEditingController();
  final List<Uint8List> _selectedImages = [];
  bool _isDragging = false;
  bool _isAnalyzing = false;
  String? _error;
  String? _detectedHex;

  bool get _apiKeySet => geminiColorService.isInitialized;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _setApiKey() {
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) {
      geminiColorService.initialize(key);
      setState(() {
        _error = null;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final newImages = <Uint8List>[];
        for (final file in result.files) {
          if (file.bytes != null) {
            newImages.add(file.bytes!);
          }
        }
        _addImages(newImages);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick images: $e';
      });
    }
  }

  void _addImages(List<Uint8List> images) {
    setState(() {
      final remaining = 10 - _selectedImages.length;
      _selectedImages.addAll(images.take(remaining));
      _error = null;
      _detectedHex = null;
    });
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    final newImages = <Uint8List>[];
    for (final file in details.files) {
      try {
        final bytes = await file.readAsBytes();
        newImages.add(bytes);
      } catch (e) {
        debugPrint('Error reading dropped file: $e');
      }
    }
    _addImages(newImages);
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _detectedHex = null;
    });
  }

  void _clearImages() {
    setState(() {
      _selectedImages.clear();
      _detectedHex = null;
      _error = null;
    });
  }

  Future<void> _analyzeImages() async {
    if (_selectedImages.isEmpty) {
      setState(() {
        _error = 'Please add at least one image';
      });
      return;
    }

    if (!geminiColorService.isInitialized) {
      setState(() {
        _error = 'Please set your Gemini API key first';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _detectedHex = null;
    });

    try {
      final hex = await geminiColorService.analyzeFilamentColor(_selectedImages);
      if (hex != null) {
        setState(() {
          _detectedHex = hex;
        });
      } else {
        setState(() {
          _error = 'Could not detect color from images';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _applyColor(BuildContext context) {
    if (_detectedHex == null) return;

    final hex = _detectedHex!.replaceAll('#', '');
    if (hex.length != 6) return;

    final color = Color(int.parse('FF$hex', radix: 16));
    final hsv = HSVColor.fromColor(color);

    final state = context.read<EditorState>();

    // Set hue (-180 to 180 range)
    double hue = hsv.hue;
    if (hue > 180) hue -= 360;
    state.setHue(hue);

    // Set saturation
    state.setSaturation(hsv.saturation);

    // Set brightness (map 0-1 to 0-2)
    state.setBrightness(hsv.value * 2);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied color $_detectedHex'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Analyze Filament Color',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // API Key section
                    if (!_apiKeySet) ...[
                      const Text(
                        'Gemini API Key',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _apiKeyController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: 'Enter your Gemini API key',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _setApiKey,
                            child: const Text('Set'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get your API key from Google AI Studio',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Divider(height: 24),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          const Text('API key configured'),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Drop zone
                    DropTarget(
                      onDragDone: _handleDrop,
                      onDragEntered: (_) => setState(() => _isDragging = true),
                      onDragExited: (_) => setState(() => _isDragging = false),
                      child: GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: _isDragging ? Colors.blue[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isDragging ? Colors.blue : Colors.grey[300]!,
                              width: _isDragging ? 2 : 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 40,
                                  color: _isDragging ? Colors.blue : Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isDragging
                                      ? 'Drop images here'
                                      : 'Drop images here or click to browse',
                                  style: TextStyle(
                                    color: _isDragging ? Colors.blue : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${_selectedImages.length}/10 images',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Image previews
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Selected Images',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          TextButton(
                            onPressed: _clearImages,
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      _selectedImages[index],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Error message
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red[700], fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Result
                    if (_detectedHex != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color(int.parse('FF${_detectedHex!.replaceAll('#', '')}', radix: 16)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Detected Color',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    _detectedHex!,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isAnalyzing ? null : _analyzeImages,
                            icon: _isAnalyzing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Color'),
                          ),
                        ),
                        if (_detectedHex != null) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _applyColor(context),
                            icon: const Icon(Icons.check),
                            label: const Text('Apply'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
