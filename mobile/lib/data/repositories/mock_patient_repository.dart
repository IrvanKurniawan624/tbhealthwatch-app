import '../models/patient_model.dart';
import 'patient_repository.dart';

class MockPatientRepository implements IPatientRepository {
  @override
  Future<List<Patient>> getMonitoringPatients({
    String? search,
    int? page,
    int? pageSize,
    String? phase,
    String? status,
    String? sortBy,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
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
        status: "STABLE",
        location: "Tegalsari, Surabaya",
        phase: "PHASE 2 PERAWATAN",
        currentMonth: 4,
        totalMonths: 6,
      ),
    ];
  }
}