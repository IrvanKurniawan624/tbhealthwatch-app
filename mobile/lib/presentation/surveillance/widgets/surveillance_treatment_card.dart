import 'package:flutter/material.dart';

import '../surveillance_page.dart';

class SurveillanceTreatmentCard extends StatelessWidget {
  const SurveillanceTreatmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 28),
        decoration: BoxDecoration(
          color: SurveillancePage.deepBlue,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: SurveillancePage.deepBlue.withOpacity(0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -38,
              child: Icon(
                Icons.show_chart_rounded,
                color: Colors.white.withOpacity(0.10),
                size: 150,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BlueIconBox(),
                    Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '98%',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'KEPATUHAN',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 2,
                            color: Color(0xFFD8E6FF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 48),
                Text(
                  'Keberhasilan Pengobatan',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 11),
                Text(
                  'Kepatuhan pengobatan di seluruh Surabaya tetap sangat tinggi bulan ini.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.42,
                    color: Color(0xFFD8E6FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BlueIconBox extends StatelessWidget {
  const _BlueIconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 51,
      height: 51,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.link_rounded, color: Colors.white),
    );
  }
}
