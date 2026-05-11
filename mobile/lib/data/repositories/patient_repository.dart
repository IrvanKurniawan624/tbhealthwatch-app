import '../models/patient_model.dart';

abstract class IPatientRepository {
  Future<List<Patient>> getMonitoringPatients();
}