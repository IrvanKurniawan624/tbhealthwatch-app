import '../models/patient_model.dart';

abstract class IPatientRepository {
  Future<List<Patient>> getMonitoringPatients({
    String? search,
    int? page,
    int? pageSize,
    String? phase,
    String? status,
    String? sortBy,
  });
}