import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';

class TracingMapPage extends StatefulWidget {
  const TracingMapPage({super.key});

  @override
  State<TracingMapPage> createState() => _TracingMapPageState();
}

class _TracingMapPageState extends State<TracingMapPage> {
  final MapController _mapController = MapController();

  bool _isLoading = true;
  String? _errorMessage;

  List<DistrictPolygon> _districtPolygons = [];
  RegionTraceData? _selectedRegion;

  final Map<String, RegionTraceData> _hardcodedRegionData = {
    'Genteng': RegionTraceData(
      name: 'Genteng',
      patientCount: 12,
      riskLevel: RiskLevel.stable,
    ),
    'Simokerto': RegionTraceData(
      name: 'Simokerto',
      patientCount: 24,
      riskLevel: RiskLevel.warning,
    ),
    'Semampir': RegionTraceData(
      name: 'Semampir',
      patientCount: 35,
      riskLevel: RiskLevel.warning,
    ),
    'Kenjeran': RegionTraceData(
      name: 'Kenjeran',
      patientCount: 67,
      riskLevel: RiskLevel.high,
    ),
    'Bulak': RegionTraceData(
      name: 'Bulak',
      patientCount: 8,
      riskLevel: RiskLevel.stable,
    ),
    'Wonokromo': RegionTraceData(
      name: 'Wonokromo',
      patientCount: 72,
      riskLevel: RiskLevel.high,
    ),
    'Gubeng': RegionTraceData(
      name: 'Gubeng',
      patientCount: 41,
      riskLevel: RiskLevel.warning,
    ),
    'Tambaksari': RegionTraceData(
      name: 'Tambaksari',
      patientCount: 58,
      riskLevel: RiskLevel.high,
    ),
    'Rungkut': RegionTraceData(
      name: 'Rungkut',
      patientCount: 18,
      riskLevel: RiskLevel.stable,
    ),
    'Tegalsari': RegionTraceData(
      name: 'Tegalsari',
      patientCount: 29,
      riskLevel: RiskLevel.warning,
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadGeoJson() async {
    try {
      final rawGeoJson = await rootBundle.loadString(
        'assets/geojson/surabaya_kecamatan.json',
      );

      final decoded = jsonDecode(rawGeoJson) as Map<String, dynamic>;
      final features = decoded['features'] as List<dynamic>;

      final List<DistrictPolygon> loadedPolygons = [];

      for (final feature in features) {
        final featureMap = feature as Map<String, dynamic>;

        final properties = featureMap['properties'] as Map<String, dynamic>;
        final geometry = featureMap['geometry'] as Map<String, dynamic>;

        final districtName = properties['name']?.toString() ?? 'Unknown';
        final geometryType = geometry['type']?.toString();
        final coordinates = geometry['coordinates'];

        final traceData =
            _hardcodedRegionData[districtName] ??
            RegionTraceData(
              name: districtName,
              patientCount: 0,
              riskLevel: RiskLevel.stable,
            );

        if (geometryType == 'Polygon') {
          final polygonPoints = _parsePolygonCoordinates(coordinates);

          if (polygonPoints.isNotEmpty) {
            loadedPolygons.add(
              DistrictPolygon(
                name: districtName,
                points: polygonPoints,
                traceData: traceData,
              ),
            );
          }
        }

        if (geometryType == 'MultiPolygon') {
          final multiPolygon = coordinates as List<dynamic>;

          for (final polygon in multiPolygon) {
            final polygonPoints = _parsePolygonCoordinates(polygon);

            if (polygonPoints.isNotEmpty) {
              loadedPolygons.add(
                DistrictPolygon(
                  name: districtName,
                  points: polygonPoints,
                  traceData: traceData,
                ),
              );
            }
          }
        }
      }

      setState(() {
        _districtPolygons = loadedPolygons;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  List<LatLng> _parsePolygonCoordinates(dynamic coordinates) {
    final rings = coordinates as List<dynamic>;

    if (rings.isEmpty) return [];

    // GeoJSON polygon:
    // coordinates[0] = outer boundary
    // coordinates[1..n] = holes, sementara kita abaikan dulu
    final outerRing = rings.first as List<dynamic>;

    return outerRing.map((point) {
      final coordinate = point as List<dynamic>;

      final longitude = (coordinate[0] as num).toDouble();
      final latitude = (coordinate[1] as num).toDouble();

      // GeoJSON = [longitude, latitude]
      // flutter_map = LatLng(latitude, longitude)
      return LatLng(latitude, longitude);
    }).toList();
  }

  LatLng? _calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return null;
    double totalLatitude = 0;
    double totalLongitude = 0;
    for (final point in points) {
      totalLatitude += point.latitude;
      totalLongitude += point.longitude;
    }
    final lat = totalLatitude / points.length;
    final lng = totalLongitude / points.length;
    if (!lat.isFinite || !lng.isFinite) return null;
    return LatLng(lat, lng);
  }

  Color _fillColorByRisk(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.high:
        return Colors.red.withOpacity(0.45);
      case RiskLevel.warning:
        return Colors.orange.withOpacity(0.45);
      case RiskLevel.stable:
        return Colors.green.withOpacity(0.35);
    }
  }

  Color _borderColorByRisk(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.high:
        return Colors.red.shade800;
      case RiskLevel.warning:
        return Colors.orange.shade800;
      case RiskLevel.stable:
        return Colors.green.shade800;
    }
  }

  Color _bubbleColorByRisk(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.high:
        return Colors.red.shade700;
      case RiskLevel.warning:
        return Colors.orange.shade700;
      case RiskLevel.stable:
        return Colors.green.shade700;
    }
  }

  String _riskLabel(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.high:
        return 'Risiko Tinggi';
      case RiskLevel.warning:
        return 'Peringatan';
      case RiskLevel.stable:
        return 'Stabil';
    }
  }

  List<Polygon> _buildPolygons() {
    return _districtPolygons.map((district) {
      return Polygon(
        points: district.points,
        color: _fillColorByRisk(district.traceData.riskLevel),
        borderColor: _borderColorByRisk(district.traceData.riskLevel),
        borderStrokeWidth: 1.4,
      );
    }).toList();
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final district in _districtPolygons) {
      if (district.traceData.patientCount == 0) continue;
      final center = _calculateCenter(district.points);
      if (center == null) continue;
      final traceData = district.traceData;
      markers.add(Marker(
        point: center,
        width: 46,
        height: 46,
        child: GestureDetector(
          onTap: () {
            if (!mounted) return;
            setState(() => _selectedRegion = traceData);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _mapController.move(center, 12.5);
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: _bubbleColorByRisk(traceData.riskLevel),
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
              traceData.patientCount.toString(),
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
    final totalPatients = _hardcodedRegionData.values.fold<int>(
      0,
      (total, item) => total + item.patientCount,
    );

    final highRiskCount = _hardcodedRegionData.values
        .where((item) => item.riskLevel == RiskLevel.high)
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
                color: _bubbleColorByRisk(region.riskLevel),
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
          'Gagal memuat GeoJSON:\n$_errorMessage',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

enum RiskLevel { stable, warning, high }

class RegionTraceData {
  final String name;
  final int patientCount;
  final RiskLevel riskLevel;

  const RegionTraceData({
    required this.name,
    required this.patientCount,
    required this.riskLevel,
  });
}

class DistrictPolygon {
  final String name;
  final List<LatLng> points;
  final RegionTraceData traceData;

  const DistrictPolygon({
    required this.name,
    required this.points,
    required this.traceData,
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
