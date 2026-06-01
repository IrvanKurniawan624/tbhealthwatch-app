import 'package:flutter/material.dart';

import '../../../data/models/surveillance_model.dart';
import '../surveillance_page.dart';

class SurveillanceAlertsSection extends StatelessWidget {
  final VoidCallback onOpenTracing;
  final List<SurveillanceAlert> alerts;

  const SurveillanceAlertsSection({
    super.key,
    required this.onOpenTracing,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    final displayAlerts = alerts.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE8EAF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Peringatan Terbaru',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: SurveillancePage.textDark,
                    ),
                  ),
                ),
                Icon(Icons.notifications_active_outlined,
                    color: SurveillancePage.deepBlue, size: 22),
              ],
            ),
            const SizedBox(height: 24),
            if (displayAlerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Tidak ada peringatan saat ini.',
                  style: TextStyle(color: Color(0xFF8A9099)),
                ),
              )
            else
              ...List.generate(displayAlerts.length, (i) {
                final alert = displayAlerts[i];
                final isHigh = alert.type == 'high';
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: i < displayAlerts.length - 1 ? 22 : 0),
                  child: SurveillanceAlertItem(
                    iconBackground: isHigh
                        ? const Color(0xFFFFD8A8)
                        : const Color(0xFFDDE6FF),
                    icon: isHigh
                        ? Icons.priority_high_rounded
                        : Icons.warning_amber_outlined,
                    title: alert.title,
                    description: alert.description,
                    time: 'Baru saja',
                    onTap: onOpenTracing,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class SurveillanceAlertItem extends StatelessWidget {
  final Color iconBackground;
  final IconData icon;
  final String title;
  final String description;
  final String time;
  final VoidCallback onTap;

  const SurveillanceAlertItem({
    super.key,
    required this.iconBackground,
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF1F2937)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          color: SurveillancePage.textDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Color(0xFF555B66),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A9099),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B6C1)),
            ],
          ),
        ),
      ),
    );
  }
}
