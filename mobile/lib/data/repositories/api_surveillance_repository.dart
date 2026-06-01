import '../../core/api_client.dart';
import '../models/region_stats_model.dart';
import '../models/surveillance_model.dart';

class ApiSurveillanceRepository {
  final ApiClient _client;

  ApiSurveillanceRepository(this._client);

  Future<SurveillanceSummary> getSummary() async {
    final json = await _client.get('/surveillance/summary') as Map<String, dynamic>;
    return SurveillanceSummary.fromJson(json);
  }

  Future<List<RegionStats>> getRegionStats() async {
    final list = await _client.get('/regions/stats') as List;
    return list
        .map((e) => RegionStats.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
