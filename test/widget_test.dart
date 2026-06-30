import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:water_tasks/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WaterTasksApp());
    await tester.pump();

    expect(find.text('Water Tasks'), findsOneWidget);
    expect(find.text('New List'), findsOneWidget);
  });
}
