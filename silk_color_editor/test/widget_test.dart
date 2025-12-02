import 'package:flutter_test/flutter_test.dart';
import 'package:silk_color_editor/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SilkColorEditorApp());

    // Verify that the app title is displayed
    expect(find.text('SILK Color Editor'), findsOneWidget);
  });
}
