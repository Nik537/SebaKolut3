import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/editor_state.dart';
import 'screens/editor_screen.dart';

void main() {
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
