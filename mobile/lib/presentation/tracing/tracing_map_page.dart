import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../data/models/region_stats_model.dart';
import '../../data/repositories/api_surveillance_repository.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';

class TracingMapPage extends StatefulWidget {
  const TracingMapPage({super.key});

  @override
  State<TracingMapPage> createState() => _TracingMapPageState();
}

class _TracingMapPageState extends State<TracingMapPage> {
  final MapController _mapController = MapController();
  final _repo = ApiSurveillanceRepository(ApiClient());

  bool _isLoading = true;
  String? _errorMessage;

  List<_DistrictPolygon> _districtPolygons = [];
  RegionStats? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        rootBundle.loadString('assets/geojson/surabaya_kecamatan.json'),
        _repo.getRegionStats(),
      ]);

      final rawGeoJson = results[0] as String;
      final regionStats = results[1] as List<RegionStats>;

      final statsMap = {for (final r in regionStats) r.name.toUpperCase(): r};

      final decoded = jsonDecode(rawGeoJson) as Map<String, dynamic>;
      final features = decoded['features'] as List<dynamic>;

      final List<_DistrictPolygon> loaded = [];

      for (final feature in features) {
        final featureMap = feature as Map<String, dynamic>;
        final properties = featureMap['properties'] as Map<String, dynamic>;
        final geometry = featureMap['geometry'] as Map<String, dynamic>;

        final rawName = properties['name']?.toString() ?? 'Unknown';
        final geometryType = geometry['type']?.toString();
        final coordinates = geometry['coordinates'];

        final stats = statsMap[rawName.toUpperCase()] ??
            RegionStats(
              id: '',
              name: rawName,
              patientCount: 0,
              riskLevel: 'stable',
            );

        void addPolygon(dynamic coords) {
          final points = _parsePolygon(coords);
          if (points.isNotEmpty) {
            loaded.add(_DistrictPolygon(name: rawName, points: points, stats: stats));
          }
        }

        if (geometryType == 'Polygon') {
          addPolygon(coordinates);
        } else if (geometryType == 'MultiPolygon') {
          for (final poly in coordinates as List<dynamic>) {
            addPolygon(poly);
          }
        }
      }

      if (mounted) {
        setState(() {
          _districtPolygons = loaded;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<LatLng> _parsePolygon(dynamic coordinates) {
    final rings = coordinates as List<dynamic>;
    if (rings.isEmpty) return [];
    final outer = rings.first as List<dynamic>;
    return outer.map((point) {
      final coord = point as List<dynamic>;
      return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
    }).toList();
  }

  LatLng? _calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return null;
    double lat = 0, lng = 0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    final avgLat = lat / points.length;
    final avgLng = lng / points.length;
    if (!avgLat.isFinite || !avgLng.isFinite) return null;
    return LatLng(avgLat, avgLng);
  }

  Color _fillColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return Colors.red.withOpacity(0.45);
      case 'warning':
        return Colors.orange.withOpacity(0.45);
      default:
        return Colors.green.withOpacity(0.35);
    }
  }

  Color _borderColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return Colors.red.shade800;
      case 'warning':
        return Colors.orange.shade800;
      default:
        return Colors.green.shade800;
    }
  }

  Color _bubbleColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return Colors.red.shade700;
      case 'warning':
        return Colors.orange.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  String _riskLabel(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return 'Risiko Tinggi';
      case 'warning':
        return 'Peringatan';
      default:
        return 'Stabil';
    }
  }

  List<Polygon> _buildPolygons() {
    return _districtPolygons.map((d) {
      return Polygon(
        points: d.points,
        color: _fillColor(d.stats.riskLevel),
        borderColor: _borderColor(d.stats.riskLevel),
        borderStrokeWidth: 1.4,
      );
    }).toList();
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final district in _districtPolygons) {
      if (district.stats.patientCount == 0) continue;
      final center = _calculateCenter(district.points);
      if (center == null) continue;
      final stats = district.stats;
      markers.add(Marker(
        point: center,
        width: 46,
        height: 46,
        child: GestureDetector(
          onTap: () {
            if (!mounted) return;
            setState(() => _selectedRegion = stats);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _mapController.move(center, 12.5);
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: _bubbleColor(stats.riskLevel),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              stats.patientCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            _buildErrorView()
          else
            _buildMap(),

          if (!_isLoading && _errorMessage == null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildTopSummaryCard(),
            ),

          if (!_isLoading && _errorMessage == null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _selectedRegion == null
                  ? _buildLegendCard()
                  : _buildSelectedRegionCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(-7.2575, 112.7521),
        initialZoom: 11,
        minZoom: 10,
        maxZoom: 17,
        cameraConstraint: CameraConstraint.containCenter(
          bounds: LatLngBounds(
            const LatLng(-8.0, 112.0),
            const LatLng(-6.8, 113.5),
          ),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.tbc_app',
        ),
        PolygonLayer(polygons: _buildPolygons()),
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }

  Widget _buildTopSummaryCard() {
    final totalPatients = _districtPolygons.fold<int>(
      0,
      (sum, d) => sum + d.stats.patientCount,
    );
    final highRiskCount = _districtPolygons
        .where((d) => d.stats.riskLevel == 'high')
        .map((d) => d.stats.name)
        .toSet()
        .length;

    return Card(
      elevation: 4,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF0052CC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_tree_outlined,
                color: Color(0xFF0052CC),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tracing Wilayah Surabaya',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$totalPatients pasien tercatat • $highRiskCount wilayah risiko tinggi',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _LegendItem(color: Colors.green, label: 'Stabil'),
            _LegendItem(color: Colors.orange, label: 'Peringatan'),
            _LegendItem(color: Colors.red, label: 'Risiko Tinggi'),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedRegionCard() {
    final region = _selectedRegion!;
    return Card(
      elevation: 5,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _bubbleColor(region.riskLevel),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                region.patientCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${region.patientCount} pasien • ${_riskLabel(region.riskLevel)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                if (mounted) setState(() => _selectedRegion = null);
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Gagal memuat data:\n$_errorMessage',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

class _DistrictPolygon {
  final String name;
  final List<LatLng> points;
  final RegionStats stats;

  const _DistrictPolygon({
    required this.name,
    required this.points,
    required this.stats,
  });
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
