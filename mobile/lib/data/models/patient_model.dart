class Patient {
  final String id;
  final String name;
  final String status;
  final String location;
  final String phase;
  final int currentMonth;
  final int totalMonths;

  Patient({
    required this.id,
    required this.name,
    required this.status,
    required this.location,
    required this.phase,
    required this.currentMonth,
    required this.totalMonths,
  });
}
