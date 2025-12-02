import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/editor_state.dart';
import 'screens/editor_screen.dart';
import 'services/gemini_color_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Initialize Gemini with API key from .env
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey != null && apiKey.isNotEmpty) {
    geminiColorService.initialize(apiKey);
  }

  runApp(const SilkColorEditorApp());
}

class SilkColorEditorApp extends StatelessWidget {
  const SilkColorEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorState(),
      child: MaterialApp(
        title: 'SILK Color Editor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const EditorScreen(),
      ),
    );
  }
}
