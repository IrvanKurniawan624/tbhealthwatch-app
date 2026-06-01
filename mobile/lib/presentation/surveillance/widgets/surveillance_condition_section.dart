import 'package:flutter/material.dart';

import '../surveillance_page.dart';
import 'surveillance_mini_metric_card.dart';
import 'surveillance_pill_label.dart';

class SurveillanceConditionSection extends StatelessWidget {
  final VoidCallback onOpenTracing;
  final String topRegionName;
  final double complianceRate;
  final int highRiskCount;

  const SurveillanceConditionSection({
    super.key,
    required this.onOpenTracing,
    required this.topRegionName,
    required this.complianceRate,
    required this.highRiskCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kondisi Saat Ini',
            style: TextStyle(
              fontSize: 29,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: SurveillancePage.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ringkasan kondisi wilayah dan peringatan\nsurveillance TB terbaru.',
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: SurveillancePage.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F8),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE5E7EF)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -28,
                  child: Icon(
                    Icons.health_and_safety_outlined,
                    size: 120,
                    color: Colors.grey.withOpacity(0.16),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SurveillancePillLabel(
                      text: 'PERINGATAN LONJAKAN',
                      color: Color(0xFFFFD8A8),
                      textColor: Color(0xFF6B4100),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      topRegionName.isNotEmpty
                          ? 'Wilayah $topRegionName'
                          : 'Tidak Ada Wilayah Berisiko',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: SurveillancePage.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Terjadi lonjakan kasus dalam periode terakhir. Diperlukan tindakan cepat untuk pelacakan kontak.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF555B66),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    InkWell(
                      onTap: onOpenTracing,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Lakukan Pelacakan  →',
                          style: TextStyle(
                            fontSize: 15,
                            color: SurveillancePage.deepBlue,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SurveillanceMiniMetricCard(
                  title: 'Kepatuhan',
                  value: '${complianceRate.toStringAsFixed(0)}%',
                  icon: Icons.verified_outlined,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SurveillanceMiniMetricCard(
                  title: 'Wilayah Risiko',
                  value: '$highRiskCount',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
