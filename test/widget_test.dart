import 'package:campus_fix/core/constants.dart';
import 'package:campus_fix/models/incident.dart';
import 'package:campus_fix/widgets/category_tile.dart';
import 'package:campus_fix/widgets/report_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('CategoryPicker shows an error until a category is chosen', (tester) async {
    final formKey = GlobalKey<FormState>();
    IncidentCategory? picked;

    await tester.pumpWidget(
      _wrap(
        Form(
          key: formKey,
          child: CategoryPicker(onChanged: (c) => picked = c),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Please choose a category'), findsOneWidget);

    await tester.tap(find.text('Water'));
    await tester.pump();
    expect(picked, IncidentCategory.water);
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(find.text('Please choose a category'), findsNothing);
  });

  testWidgets('ReportCard shows title, status and reporter for staff', (tester) async {
    final incident = Incident(
      id: 'abc',
      reference: 'CF-ABC123',
      title: 'Exposed wiring by stairs',
      description: 'Bare wires next to the stairwell handrail.',
      category: IncidentCategory.safety,
      location: 'Block A',
      status: IncidentStatus.inProgress,
      reporterId: 'u1',
      reporterName: 'Kevin Nshuti',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      updatedAt: DateTime.now(),
      history: const [],
    );
    var tapped = false;

    await tester.pumpWidget(
      _wrap(ReportCard(incident: incident, showReporter: true, onTap: () => tapped = true)),
    );

    expect(find.text('Exposed wiring by stairs'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.textContaining('by Kevin Nshuti'), findsOneWidget);

    await tester.tap(find.byType(ReportCard));
    expect(tapped, isTrue);
  });
}
