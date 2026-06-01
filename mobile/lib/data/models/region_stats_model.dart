class RegionStats {
  final String id;
  final String name;
  final int patientCount;
  final String riskLevel;

  const RegionStats({
    required this.id,
    required this.name,
    required this.patientCount,
    required this.riskLevel,
  });

  factory RegionStats.fromJson(Map<String, dynamic> json) {
    return RegionStats(
      id: json['id'] as String,
      name: json['name'] as String,
      patientCount: json['patientCount'] as int,
      riskLevel: json['riskLevel'] as String,
    );
  }
}
