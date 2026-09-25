import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ai_caption_app/main.dart';
import 'package:ai_caption_app/providers/caption_provider.dart';
import 'package:ai_caption_app/services/ai_caption_service.dart';
import 'package:ai_caption_app/services/image_picker_service.dart';

void main() {
  testWidgets('app shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CaptionProvider(
          aiCaptionService: MockAiCaptionService(),
          imagePickerService: ImagePickerService(),
        ),
        child: const Image2CaptionApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Bottom nav should be visible.
    expect(find.text('Home'), findsOneWidget);
  });
}
