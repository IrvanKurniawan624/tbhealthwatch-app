import 'package:flutter_test/flutter_test.dart';
import 'package:projekakhir/data/models/adherence_model.dart';

void main() {
  test('AdherenceSummary.fromJson parses correctly', () {
    final json = {
      'percentage': 84.0,
      'target': 95,
      'dosesTaken': 25,
      'dosesTotal': 30,
      'streakDays': 3,
      'currentPhase': 'phase_2',
    };
    final s = AdherenceSummary.fromJson(json);
    expect(s.percentage, 84.0);
    expect(s.target, 95);
    expect(s.streakDays, 3);
    expect(s.currentPhase, 'phase_2');
  });

  test('AdherenceCalendar.fromJson parses days list', () {
    final json = {
      'year': 2024,
      'month': 10,
      'days': [
        {'date': '2024-10-01', 'status': 'taken'},
        {'date': '2024-10-02', 'status': 'missed'},
      ],
    };
    final c = AdherenceCalendar.fromJson(json);
    expect(c.days.length, 2);
    expect(c.days[0].status, 'taken');
    expect(c.days[1].date, '2024-10-02');
  });
}
