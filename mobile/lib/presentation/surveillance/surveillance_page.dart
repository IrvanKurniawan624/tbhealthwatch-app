import 'package:flutter/material.dart';

import '../tracing/tracing_map_page.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';
import 'widgets/surveillance_alerts_section.dart';
import 'widgets/surveillance_case_card.dart';
import 'widgets/surveillance_condition_section.dart';
import 'widgets/surveillance_summary_card.dart';
import 'widgets/surveillance_treatment_card.dart';

class SurveillancePage extends StatelessWidget {
  const SurveillancePage({super.key});

  static const Color primaryBlue = Color(0xFF0052CC);
  static const Color deepBlue = Color(0xFF0047B3);
  static const Color textDark = Color(0xFF20242A);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color softBackground = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _HeroMapSection(onOpenTracing: () => _openTracing(context)),
            SurveillanceConditionSection(onOpenTracing: () => _openTracing(context)),
            const SurveillanceTreatmentCard(),
            SurveillanceAlertsSection(onOpenTracing: () => _openTracing(context)),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  void _openTracing(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TracingMapPage()),
    );
  }
}

class _HeroMapSection extends StatelessWidget {
  final VoidCallback onOpenTracing;

  const _HeroMapSection({required this.onOpenTracing});

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
        const Positioned(
          top: 22,
          left: 22,
          right: 22,
          child: Row(
            children: [
              Expanded(
                child: SurveillanceSummaryCard(
                  label: 'TOTAL AKTIF',
                  value: '1,284',
                  icon: Icons.groups_2_outlined,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SurveillanceSummaryCard(
                  label: 'KASUS BARU',
                  value: '42',
                  trailing: 'Stabil',
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
          child: SurveillanceCaseCard(onOpenTracing: onOpenTracing),
        ),
      ],
    );
  }
}
