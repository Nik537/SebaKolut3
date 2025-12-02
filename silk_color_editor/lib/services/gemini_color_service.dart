import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiColorService {
  GenerativeModel? _model;

  void initialize(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-3-pro-preview',
      apiKey: apiKey,
    );
  }

  bool get isInitialized => _model != null;

  Future<String?> analyzeFilamentColor(List<Uint8List> images) async {
    if (_model == null) {
      throw Exception('Gemini API not initialized. Please set your API key.');
    }

    if (images.isEmpty) {
      throw Exception('No images provided');
    }

    if (images.length > 10) {
      throw Exception('Maximum 10 images allowed');
    }

    final prompt = '''Analyze these images of 3D printing filament spools or samples.

Your task is to determine the exact color of the filament material itself (not the spool, packaging, or background).

Please:
1. Look at the filament material in each image
2. Consider lighting conditions and try to determine the true color
3. If multiple images show the same filament, use them to get a more accurate reading
4. Return ONLY a single hex color code that best represents the filament color

Important:
- Focus on the actual filament thread/material, not the spool or packaging
- If the filament appears metallic or has special effects (silk, glitter, etc), estimate the base color
- Account for lighting - indoor lighting may make colors appear warmer/cooler

Respond with ONLY the hex code in format: #RRGGBB
No explanation, no other text, just the hex code.''';

    final content = <Content>[
      Content.multi([
        TextPart(prompt),
        ...images.map((imageBytes) => DataPart('image/jpeg', imageBytes)),
      ]),
    ];

    try {
      final response = await _model!.generateContent(content);
      final text = response.text?.trim();

      if (text == null || text.isEmpty) {
        return null;
      }

      // Extract hex code from response (in case there's extra text)
      final hexPattern = RegExp(r'#[0-9A-Fa-f]{6}');
      final match = hexPattern.firstMatch(text);

      if (match != null) {
        return match.group(0)!.toUpperCase();
      }

      return null;
    } catch (e) {
      throw Exception('Failed to analyze images: $e');
    }
  }
}

// Singleton instance
final geminiColorService = GeminiColorService();
