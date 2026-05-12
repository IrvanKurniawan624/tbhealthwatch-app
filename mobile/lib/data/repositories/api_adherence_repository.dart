import '../models/adherence_model.dart';
import '../../core/api_client.dart';

class ApiAdherenceRepository {
  final ApiClient _client;

  ApiAdherenceRepository(this._client);

  Future<AdherenceSummary> getSummary(String patientId) async {
    final data = await _client
        .get('/patients/$patientId/adherence/summary') as Map<String, dynamic>;
    return AdherenceSummary.fromJson(data);
  }

  Future<AdherenceCalendar> getCalendar(
      String patientId, int year, int month) async {
    final data = await _client.get(
            '/patients/$patientId/adherence/calendar?year=$year&month=$month')
        as Map<String, dynamic>;
    return AdherenceCalendar.fromJson(data);
  }

  Future<void> log(String patientId, String logDate, String status,
      {String? notes}) async {
    await _client.post('/patients/$patientId/adherence/log', {
      'logDate': logDate,
      'status': status,
      if (notes != null) 'notes': notes,
    });
  }
}
