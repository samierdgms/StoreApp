import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:storeappp/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {

    await tester.pumpWidget(const MyApp(isMaintenance: false,));


    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
