import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../data/models/surveillance_model.dart';
import '../../data/repositories/api_surveillance_repository.dart';
import '../tracing/tracing_map_page.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';
import 'widgets/surveillance_alerts_section.dart';
import 'widgets/surveillance_case_card.dart';
import 'widgets/surveillance_condition_section.dart';
import 'widgets/surveillance_summary_card.dart';
import 'widgets/surveillance_treatment_card.dart';

class SurveillancePage extends StatefulWidget {
  const SurveillancePage({super.key});

  static const Color primaryBlue = Color(0xFF0052CC);
  static const Color deepBlue = Color(0xFF0047B3);
  static const Color textDark = Color(0xFF20242A);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color softBackground = Color(0xFFF4F6FA);

  @override
  State<SurveillancePage> createState() => _SurveillancePageState();
}

class _SurveillancePageState extends State<SurveillancePage> {
  final _repo = ApiSurveillanceRepository(ApiClient());

  SurveillanceSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() { _loading = true; _error = null; });
    try {
      final summary = await _repo.getSummary();
      if (mounted) setState(() { _summary = summary; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openTracing(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TracingMapPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadSummary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _HeroMapSection(
                          onOpenTracing: () => _openTracing(context),
                          totalActive: _summary!.totalActive,
                          newCasesThisMonth: _summary!.newCasesThisMonth,
                          topRegions: _summary!.topRegions,
                        ),
                        SurveillanceConditionSection(
                          onOpenTracing: () => _openTracing(context),
                          topRegionName: _summary!.topRegions.isNotEmpty
                              ? _summary!.topRegions.first.name
                              : '',
                          complianceRate: _summary!.complianceRate,
                          highRiskCount: _summary!.highRiskCount,
                        ),
                        SurveillanceTreatmentCard(
                          complianceRate: _summary!.complianceRate,
                        ),
                        SurveillanceAlertsSection(
                          onOpenTracing: () => _openTracing(context),
                          alerts: _summary!.alerts,
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gagal memuat data:\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSummary,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMapSection extends StatelessWidget {
  final VoidCallback onOpenTracing;
  final int totalActive;
  final int newCasesThisMonth;
  final List<SurveillanceRegionSummary> topRegions;

  const _HeroMapSection({
    required this.onOpenTracing,
    required this.totalActive,
    required this.newCasesThisMonth,
    required this.topRegions,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 640,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/surabaya_map_preview.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 640,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.16),
                Colors.white.withOpacity(0.72),
              ],
            ),
          ),
        ),
        Positioned(
          top: 22,
          left: 22,
          right: 22,
          child: Row(
            children: [
              Expanded(
                child: SurveillanceSummaryCard(
                  label: 'TOTAL AKTIF',
                  value: '$totalActive',
                  icon: Icons.groups_2_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SurveillanceSummaryCard(
                  label: 'KASUS BARU',
                  value: '$newCasesThisMonth',
                  trailing: newCasesThisMonth == 0 ? 'Stabil' : null,
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 186,
          left: 22,
          right: 22,
          child: SurveillanceCaseCard(
            onOpenTracing: onOpenTracing,
            topRegions: topRegions,
          ),
        ),
      ],
    );
  }
}
