import 'package:flutter/material.dart';

import '../surveillance_page.dart';
import 'surveillance_sheet_widgets.dart';

class SurveillanceAlertsSection extends StatelessWidget {
  final VoidCallback onOpenTracing;

  const SurveillanceAlertsSection({
    super.key,
    required this.onOpenTracing,
  });

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.notifications_active_outlined, color: SurveillancePage.deepBlue, size: 22),
              ],
            ),
            const SizedBox(height: 24),
            SurveillanceAlertItem(
              iconBackground: const Color(0xFFFFD8A8),
              icon: Icons.priority_high_rounded,
              title: 'Klaster Terdeteksi',
              description: 'Klaster baru sebanyak 15 pasien gejala teridentifikasi di area Pasar Wonokromo.',
              time: '14 menit yang lalu',
              onTap: onOpenTracing,
            ),
            const SizedBox(height: 22),
            SurveillanceAlertItem(
              iconBackground: const Color(0xFFDDE6FF),
              icon: Icons.person_add_alt_1_outlined,
              title: 'Pasien Baru',
              description: 'Terdapat pasien baru di wilayah Gubeng.',
              time: '2 jam yang lalu',
              onTap: () {},
            ),
            const SizedBox(height: 22),
            SurveillanceAlertItem(
              iconBackground: const Color(0xFFE0E2E6),
              icon: Icons.access_time_rounded,
              title: 'Update Wilayah Terdampak',
              description: 'Saat ini Wonokromo menjadi wilayah yang paling terdampak.',
              time: '4 jam yang lalu',
              onTap: onOpenTracing,
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => _showAllAlertsSheet(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SurveillancePage.textDark,
                  side: const BorderSide(color: Color(0xFFC7CCD6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                child: const Text('Lihat Semua'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllAlertsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SurveillanceSheetHeader(
                title: 'Semua Peringatan',
                subtitle: 'Daftar alert surveillance terbaru.',
              ),
              const SizedBox(height: 18),
              SurveillanceFilterTile(
                title: 'Klaster Terdeteksi',
                subtitle: 'Pasar Wonokromo • 14 menit lalu',
                icon: Icons.priority_high_rounded,
                onTap: () {
                  Navigator.pop(context);
                  onOpenTracing();
                },
              ),
              SurveillanceFilterTile(
                title: 'Pasien Baru',
                subtitle: 'Wilayah Gubeng • 2 jam lalu',
                icon: Icons.person_add_alt_1_outlined,
                onTap: () => Navigator.pop(context),
              ),
              SurveillanceFilterTile(
                title: 'Update Wilayah',
                subtitle: 'Wonokromo menjadi wilayah paling terdampak',
                icon: Icons.access_time_rounded,
                onTap: () {
                  Navigator.pop(context);
                  onOpenTracing();
                },
              ),
            ],
          ),
        );
      },
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
