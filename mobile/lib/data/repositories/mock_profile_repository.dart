import '../models/profile_model.dart';
import 'profile_repository.dart';

class MockProfileRepository implements IProfileRepository {
  @override
  Future<void> updateProfileData(Profile profile) async {}

  @override
  Future<Profile> getProfileData() async {
    // Simulasi loading jaringan 1.5 detik
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Data dummy sesuai desain Figma
    return Profile(
      name: "Dr. Siti Aminah",
      role: "Epidemiology Specialist",
      facilityName: "Fasilitas Kesehatan",
      facilityRole: "Koordinator Pemantauan Wilayah Gubeng, Surabaya Timur",
      assignmentLocation: "RSUD Dr. Soetomo,\nSurabaya",
      email: "siti.aminah@gmail.com",
      phone: "+62 811 3452 900",
      address: "Jl. Arief Rahman Hakim\nNo.99, Sukolilo, Surabaya",
    );
  }
}
