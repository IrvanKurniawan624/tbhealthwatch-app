import '../models/patient_model.dart';
import 'patient_repository.dart';
import '../../core/api_client.dart';

class ApiPatientRepository implements IPatientRepository {
  final ApiClient _client;

  ApiPatientRepository(this._client);

  @override
  Future<List<Patient>> getMonitoringPatients({
    String? search,
    int? page,
    int? pageSize,
    String? phase,
    String? status,
    String? sortBy,
  }) async {
    final queryParams = <String>[];
    if (search != null && search.isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search)}');
    }
    if (page != null) {
      queryParams.add('page=$page');
    }
    if (pageSize != null) {
      queryParams.add('pageSize=$pageSize');
    }
    if (phase != null && phase.isNotEmpty) {
      queryParams.add('phase=$phase');
    }
    if (status != null && status.isNotEmpty) {
      queryParams.add('status=$status');
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams.add('sortBy=$sortBy');
    }

    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final data = await _client.get('/patients$queryString') as List;
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

  Future<void> delete(String id) async {
    await _client.delete('/patients/$id');
  }
}
