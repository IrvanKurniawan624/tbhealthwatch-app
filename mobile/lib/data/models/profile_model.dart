class Profile {
  final String name;           // maps to backend's fullName
  final String role;           // maps to backend's specialization
  final String facilityName;
  final String facilityRole;
  final String assignmentLocation;
  final String? wilayah;       // maps to backend's regionName
  final String? regionId;      // UUID — needed for PUT /profile/me
  final String email;
  final String phone;
  final String address;

  Profile({
    required this.name,
    required this.role,
    required this.facilityName,
    required this.facilityRole,
    required this.assignmentLocation,
    this.wilayah,
    this.regionId,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['fullName'] as String? ?? '',
      role: json['specialization'] as String? ?? '',
      facilityName: json['facilityName'] as String? ?? '',
      facilityRole: json['facilityRole'] as String? ?? '',
      assignmentLocation: json['assignmentLocation'] as String? ?? '',
      wilayah: json['regionName'] as String?,
      regionId: json['regionId']?.toString(),
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  // Sends the keys that UpdateProfileDto expects on the backend
  Map<String, dynamic> toJson() {
    return {
      'fullName': name,
      'specialization': role,
      'facilityName': facilityName,
      'facilityRole': facilityRole,
      'assignmentLocation': assignmentLocation,
      if (regionId != null) 'regionId': regionId,
      'phone': phone,
      'address': address,
    };
  }
}
