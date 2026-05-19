import 'package:flutter/material.dart';

import '../surveillance_page.dart';
import 'surveillance_impacted_area_row.dart';
import 'surveillance_sheet_widgets.dart';

class SurveillanceCaseCard extends StatelessWidget {
  final VoidCallback onOpenTracing;

  const SurveillanceCaseCard({
    super.key,
    required this.onOpenTracing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Case Surveillance',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: SurveillancePage.textDark,
                  ),
                ),
              ),
              TextButton(
                onPressed: onOpenTracing,
                style: TextButton.styleFrom(
                  foregroundColor: SurveillancePage.deepBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'Lihat Detail',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showSearchSheet(context),
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4E7EE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: Color(0xFF767B86), size: 25),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cari Wilayah atau Pasien',
                      style: TextStyle(
                        color: Color(0xFF6F7480),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.tune_rounded, color: Color(0xFF9AA1AD), size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Wilayah Paling Terdampak',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555B66),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Hari ini',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A9099),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SurveillanceImpactedAreaRow(
            color: Colors.red,
            region: 'Wilayah Wonokromo',
            cases: '15 Active Cases',
            riskText: 'Tinggi',
            onTap: onOpenTracing,
          ),
          const SizedBox(height: 14),
          SurveillanceImpactedAreaRow(
            color: Colors.orange,
            region: 'Wilayah Gubeng',
            cases: '5 Active Cases',
            riskText: 'Waspada',
            onTap: onOpenTracing,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _showRegionFilterSheet(context),
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Filter Wilayah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SurveillancePage.deepBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRegionFilterSheet(BuildContext context) {
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
                title: 'Filter Wilayah',
                subtitle: 'Pilih kategori wilayah yang ingin ditampilkan.',
              ),
              const SizedBox(height: 18),
              SurveillanceFilterTile(
                title: 'Semua Wilayah',
                subtitle: 'Tampilkan seluruh wilayah Surabaya',
                icon: Icons.public,
                onTap: () => Navigator.pop(context),
              ),
              SurveillanceFilterTile(
                title: 'Risiko Tinggi',
                subtitle: 'Wilayah dengan lonjakan kasus',
                icon: Icons.warning_amber_rounded,
                onTap: () => Navigator.pop(context),
              ),
              SurveillanceFilterTile(
                title: 'Peringatan',
                subtitle: 'Wilayah dengan tren meningkat',
                icon: Icons.error_outline,
                onTap: () => Navigator.pop(context),
              ),
              SurveillanceFilterTile(
                title: 'Stabil',
                subtitle: 'Wilayah dengan kondisi terkendali',
                icon: Icons.check_circle_outline,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            6,
            24,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SurveillanceSheetHeader(
                title: 'Cari Wilayah atau Pasien',
                subtitle: 'Fitur ini masih hardcode untuk tahap awal.',
              ),
              const SizedBox(height: 18),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Contoh: Wonokromo',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SurveillanceFilterTile(
                title: 'Wilayah Wonokromo',
                subtitle: '15 kasus aktif • Risiko tinggi',
                icon: Icons.location_on_outlined,
                onTap: () {
                  Navigator.pop(context);
                  onOpenTracing();
                },
              ),
              SurveillanceFilterTile(
                title: 'Wilayah Gubeng',
                subtitle: '5 kasus aktif • Peringatan',
                icon: Icons.location_on_outlined,
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
