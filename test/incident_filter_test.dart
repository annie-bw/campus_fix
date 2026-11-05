import 'package:campus_fix/core/constants.dart';
import 'package:campus_fix/models/incident.dart';
import 'package:campus_fix/providers/incident_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Incident _incident(
  String id, {
  required IncidentStatus status,
  required IncidentCategory category,
  required String reporter,
  required int hoursAgo,
  String title = 'Untitled issue',
  String location = 'Block A',
}) {
  final at = DateTime(2026, 11, 3, 12).subtract(Duration(hours: hoursAgo));
  return Incident(
    id: id,
    reference: 'CF-$id',
    title: title,
    description: 'A description long enough.',
    category: category,
    location: location,
    status: status,
    reporterId: reporter,
    reporterName: 'Name $reporter',
    createdAt: at,
    updatedAt: at,
    history: const [],
  );
}

void main() {
  final all = [
    _incident(
      '1',
      status: IncidentStatus.submitted,
      category: IncidentCategory.water,
      reporter: 'me',
      hoursAgo: 1,
      title: 'Leaking tap in washroom',
      location: 'Social Commons',
    ),
    _incident(
      '2',
      status: IncidentStatus.inProgress,
      category: IncidentCategory.electricity,
      reporter: 'other',
      hoursAgo: 5,
      title: 'No power in Lab 3',
      location: 'Main Building',
    ),
    _incident(
      '3',
      status: IncidentStatus.resolved,
      category: IncidentCategory.furniture,
      reporter: 'me',
      hoursAgo: 48,
      title: 'Wobbly desks in Room 12',
    ),
    _incident(
      '4',
      status: IncidentStatus.submitted,
      category: IncidentCategory.safety,
      reporter: 'other',
      hoursAgo: 24,
      title: 'Dark path to the hostels',
    ),
  ];

  test('default filter returns everything newest first', () {
    final out = const IncidentFilter().apply(all, uid: 'me');
    expect(out.map((i) => i.id), ['1', '2', '4', '3']);
  });

  test('status filter', () {
    final out = const IncidentFilter(status: IncidentStatus.submitted).apply(all);
    expect(out.map((i) => i.id), ['1', '4']);
  });

  test('category filter is an OR across selected categories', () {
    final out = const IncidentFilter(
      categories: {IncidentCategory.water, IncidentCategory.safety},
    ).apply(all);
    expect(out.map((i) => i.id).toSet(), {'1', '4'});
  });

  test('only mine uses the signed-in uid', () {
    final out = const IncidentFilter(onlyMine: true).apply(all, uid: 'me');
    expect(out.map((i) => i.id), ['1', '3']);
  });

  test('search matches title, location and reference (case-insensitive)', () {
    expect(const IncidentFilter(query: 'lab').apply(all).single.id, '2');
    expect(const IncidentFilter(query: 'SOCIAL').apply(all).single.id, '1');
    expect(const IncidentFilter(query: 'cf-3').apply(all).single.id, '3');
  });

  test('oldest first sort', () {
    final out = const IncidentFilter(newestFirst: false).apply(all);
    expect(out.first.id, '3');
  });

  test('filters combine', () {
    final out = const IncidentFilter(status: IncidentStatus.submitted, onlyMine: true).apply(all, uid: 'me');
    expect(out.map((i) => i.id), ['1']);
  });

  test('activeCount counts each applied option', () {
    const f = IncidentFilter(
      status: IncidentStatus.resolved,
      categories: {IncidentCategory.water, IncidentCategory.safety},
      onlyMine: true,
    );
    expect(f.activeCount, 4);
    expect(const IncidentFilter().activeCount, 0);
  });

  test('only Submitted reports are editable', () {
    expect(all[0].isEditable, isTrue);
    expect(all[1].isEditable, isFalse);
    expect(all[2].isEditable, isFalse);
  });
}
