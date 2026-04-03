import 'package:flutter_test/flutter_test.dart';
import 'package:edunova/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const EduNovaApp());

    // 只测试 app 能打开
    expect(find.text('EduNova Login'), findsOneWidget);
  });
}