class Patient {
  final String id;
  final String name;
  final String status;
  final String location;
  final String phase;
  final int currentMonth;
  final int totalMonths;
  // Detail fields — null when constructed from list endpoint
  final String? nik;
  final String? phone;
  final String? address;
  final String? dob;
  final String? regionName;
  final String? photoUrl;

  Patient({
    required this.id,
    required this.name,
    required this.status,
    required this.location,
    required this.phase,
    required this.currentMonth,
    required this.totalMonths,
    this.nik,
    this.phone,
    this.address,
    this.dob,
    this.regionName,
    this.photoUrl,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      location: json['location'] as String,
      phase: json['phase'] as String,
      currentMonth: json['currentMonth'] as int,
      totalMonths: json['totalMonths'] as int,
      nik: json['nik'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      dob: json['dob'] as String?,
      regionName: json['regionName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
