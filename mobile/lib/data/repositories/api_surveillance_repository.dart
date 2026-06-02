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

  Future<List<RegionStats>> getRegionStats({String? search, int? page, int? pageSize}) async {
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

    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final list = await _client.get('/regions/stats$queryString') as List;
    return list
        .map((e) => RegionStats.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
