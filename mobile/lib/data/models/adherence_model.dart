class AdherenceSummary {
  final double percentage;
  final int target;
  final int dosesTaken;
  final int dosesTotal;
  final int streakDays;
  final String currentPhase;

  const AdherenceSummary({
    required this.percentage,
    required this.target,
    required this.dosesTaken,
    required this.dosesTotal,
    required this.streakDays,
    required this.currentPhase,
  });

  factory AdherenceSummary.fromJson(Map<String, dynamic> json) {
    return AdherenceSummary(
      percentage: (json['percentage'] as num).toDouble(),
      target: json['target'] as int,
      dosesTaken: json['dosesTaken'] as int,
      dosesTotal: json['dosesTotal'] as int,
      streakDays: json['streakDays'] as int,
      currentPhase: json['currentPhase'] as String,
    );
  }

  factory AdherenceSummary.empty() => const AdherenceSummary(
        percentage: 0,
        target: 95,
        dosesTaken: 0,
        dosesTotal: 0,
        streakDays: 0,
        currentPhase: 'phase_1',
      );
}

class AdherenceDay {
  final String date;
  final String status;

  const AdherenceDay({required this.date, required this.status});

  factory AdherenceDay.fromJson(Map<String, dynamic> json) {
    return AdherenceDay(
      date: json['date'] as String,
      status: json['status'] as String,
    );
  }
}

class AdherenceCalendar {
  final int year;
  final int month;
  final List<AdherenceDay> days;

  const AdherenceCalendar({
    required this.year,
    required this.month,
    required this.days,
  });

  factory AdherenceCalendar.fromJson(Map<String, dynamic> json) {
    return AdherenceCalendar(
      year: json['year'] as int,
      month: json['month'] as int,
      days: (json['days'] as List)
          .map((d) => AdherenceDay.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  factory AdherenceCalendar.empty(int year, int month) =>
      AdherenceCalendar(year: year, month: month, days: []);
}
