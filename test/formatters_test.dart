import 'package:campus_fix/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 3, 15, 0);

  test('timeAgo', () {
    expect(Formatters.timeAgo(now.subtract(const Duration(seconds: 20)), now: now), 'Just now');
    expect(Formatters.timeAgo(now.subtract(const Duration(minutes: 40)), now: now), '40 min ago');
    expect(Formatters.timeAgo(now.subtract(const Duration(hours: 5)), now: now), '5 h ago');
    expect(Formatters.timeAgo(now.subtract(const Duration(days: 1)), now: now), '1 day ago');
    expect(Formatters.timeAgo(now.subtract(const Duration(days: 3)), now: now), '3 days ago');
    expect(Formatters.timeAgo(DateTime(2026, 10, 15), now: now), 'Oct 15');
  });

  test('timelineTime', () {
    expect(Formatters.timelineTime(DateTime(2026, 11, 3, 9, 10), now: now), 'Today, 9:10 AM');
    expect(Formatters.timelineTime(DateTime(2026, 11, 2, 14, 30), now: now), 'Yesterday, 2:30 PM');
    expect(Formatters.timelineTime(DateTime(2026, 10, 15, 10, 24), now: now), 'Oct 15, 10:24 AM');
  });

  test('initials and first name', () {
    expect(Formatters.initials('Aline Uwase'), 'AU');
    expect(Formatters.initials('jean'), 'J');
    expect(Formatters.initials('  '), '?');
    expect(Formatters.firstName('Aline Uwase'), 'Aline');
  });
}
