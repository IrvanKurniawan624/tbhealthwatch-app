import '../models/patient_model.dart';
import 'patient_repository.dart';
import '../../core/api_client.dart';

class ApiPatientRepository implements IPatientRepository {
  final ApiClient _client;

  ApiPatientRepository(this._client);

  @override
  Future<List<Patient>> getMonitoringPatients() async {
    final data = await _client.get('/patients') as List;
    return data
        .map((e) => Patient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Patient> getById(String id) async {
    final data =
        await _client.get('/patients/$id') as Map<String, dynamic>;
    return Patient.fromJson(data);
  }

  Future<Patient> update(String id, Map<String, dynamic> body) async {
    final data =
        await _client.put('/patients/$id', body) as Map<String, dynamic>;
    return Patient.fromJson(data);
  }

  Future<Patient> create(Map<String, dynamic> body) async {
    final data =
        await _client.post('/patients', body) as Map<String, dynamic>;
    return Patient.fromJson(data);
  }
}
