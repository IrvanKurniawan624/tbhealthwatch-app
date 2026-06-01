class SurveillanceSummary {
  final int totalActive;
  final int newCasesThisMonth;
  final int highRiskCount;
  final double complianceRate;
  final List<SurveillanceRegionSummary> topRegions;
  final List<SurveillanceAlert> alerts;

  const SurveillanceSummary({
    required this.totalActive,
    required this.newCasesThisMonth,
    required this.highRiskCount,
    required this.complianceRate,
    required this.topRegions,
    required this.alerts,
  });

  factory SurveillanceSummary.fromJson(Map<String, dynamic> json) {
    return SurveillanceSummary(
      totalActive: json['totalActive'] as int,
      newCasesThisMonth: json['newCasesThisMonth'] as int,
      highRiskCount: json['highRiskCount'] as int,
      complianceRate: (json['complianceRate'] as num).toDouble(),
      topRegions: (json['topRegions'] as List<dynamic>)
          .map((e) => SurveillanceRegionSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      alerts: (json['alerts'] as List<dynamic>)
          .map((e) => SurveillanceAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SurveillanceRegionSummary {
  final String name;
  final int patientCount;
  final String riskLevel;

  const SurveillanceRegionSummary({
    required this.name,
    required this.patientCount,
    required this.riskLevel,
  });

  factory SurveillanceRegionSummary.fromJson(Map<String, dynamic> json) {
    return SurveillanceRegionSummary(
      name: json['name'] as String,
      patientCount: json['patientCount'] as int,
      riskLevel: json['riskLevel'] as String,
    );
  }
}

class SurveillanceAlert {
  final String title;
  final String description;
  final String type;

  const SurveillanceAlert({
    required this.title,
    required this.description,
    required this.type,
  });

  factory SurveillanceAlert.fromJson(Map<String, dynamic> json) {
    return SurveillanceAlert(
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
    );
  }
}
