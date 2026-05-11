import '../models/patient_model.dart';
import 'patient_repository.dart';

class MockPatientRepository implements IPatientRepository {
  @override
  Future<List<Patient>> getMonitoringPatients() async {
    // Simulasi loading jaringan 1 detik
    await Future.delayed(const Duration(seconds: 1));

    // Dummy data sesuai desain Figma
    return [
      Patient(
        id: "TB-2023-0988",
        name: "Siti Aminah",
        status: "STABIL",
        location: "Gubeng, Surabaya",
        phase: "PHASE 2 PERAWATAN",
        currentMonth: 5,
        totalMonths: 6,
      ),
      Patient(
        id: "TB-2024-0104",
        name: "Aditya Pratama",
        status: "DALAM PERAWATAN",
        location: "Sawahan, Surabaya",
        phase: "PHASE 2 PERAWATAN",
        currentMonth: 1,
        totalMonths: 6,
      ),
      Patient(
        id: "TB-2023-1122",
        name: "Rina Wulandari",
        status: "STABLE", // Sesuai figma (campuran inggris/indo)
        location: "Tegalsari, Surabaya",
        phase: "PHASE 2 PERAWATAN",
        currentMonth: 4,
        totalMonths: 6,
      ),
    ];
  }
}