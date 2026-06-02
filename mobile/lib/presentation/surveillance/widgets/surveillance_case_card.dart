import 'package:flutter/material.dart';

import '../../../data/models/surveillance_model.dart';
import '../surveillance_page.dart';
import 'surveillance_impacted_area_row.dart';
import 'surveillance_sheet_widgets.dart';

class SurveillanceCaseCard extends StatefulWidget {
  final VoidCallback onOpenTracing;
  final List<SurveillanceRegionSummary> topRegions;

  const SurveillanceCaseCard({
    super.key,
    required this.onOpenTracing,
    required this.topRegions,
  });

  @override
  State<SurveillanceCaseCard> createState() => _SurveillanceCaseCardState();
}

class _SurveillanceCaseCardState extends State<SurveillanceCaseCard> {
  // 'all' | 'high' | 'warning' | 'stable'
  String _selectedFilter = 'all';

  List<SurveillanceRegionSummary> get _filteredRegions {
    if (_selectedFilter == 'all') {
      return widget.topRegions.take(2).toList();
    }
    return widget.topRegions
        .where((r) => r.riskLevel == _selectedFilter)
        .take(2)
        .toList();
  }

  String get _filterLabel {
    switch (_selectedFilter) {
      case 'high':
        return 'Risiko Tinggi';
      case 'warning':
        return 'Peringatan';
      case 'stable':
        return 'Stabil';
      default:
        return 'Filter Wilayah';
    }
  }

  void _applyFilter(String filter) {
    setState(() => _selectedFilter = filter);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final displayRegions = _filteredRegions;

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
                onPressed: widget.onOpenTracing,
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
          if (displayRegions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _selectedFilter == 'all'
                    ? 'Belum ada data wilayah.'
                    : 'Tidak ada wilayah dengan filter "$_filterLabel".',
                style: const TextStyle(color: Color(0xFF8A9099)),
              ),
            )
          else
            ...List.generate(displayRegions.length, (i) {
              final region = displayRegions[i];
              final isHigh = region.riskLevel == 'high';
              return Padding(
                padding: EdgeInsets.only(
                    bottom: i < displayRegions.length - 1 ? 14 : 0),
                child: SurveillanceImpactedAreaRow(
                  color: isHigh ? Colors.red : Colors.orange,
                  region: 'Wilayah ${region.name}',
                  cases: '${region.patientCount} Active Cases',
                  riskText: isHigh ? 'Tinggi' : 'Waspada',
                  onTap: widget.onOpenTracing,
                ),
              );
            }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _showRegionFilterSheet(context),
              icon: const Icon(Icons.filter_alt_outlined),
              label: Text(_filterLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedFilter == 'all'
                    ? SurveillancePage.deepBlue
                    : const Color(0xFF003D99),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 16),
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
      builder: (ctx) {
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
                isSelected: _selectedFilter == 'all',
                onTap: () => _applyFilter('all'),
              ),
              SurveillanceFilterTile(
                title: 'Risiko Tinggi',
                subtitle: 'Wilayah dengan lonjakan kasus',
                icon: Icons.warning_amber_rounded,
                isSelected: _selectedFilter == 'high',
                onTap: () => _applyFilter('high'),
              ),
              SurveillanceFilterTile(
                title: 'Peringatan',
                subtitle: 'Wilayah dengan tren meningkat',
                icon: Icons.error_outline,
                isSelected: _selectedFilter == 'warning',
                onTap: () => _applyFilter('warning'),
              ),
              SurveillanceFilterTile(
                title: 'Stabil',
                subtitle: 'Wilayah dengan kondisi terkendali',
                icon: Icons.check_circle_outline,
                isSelected: _selectedFilter == 'stable',
                onTap: () => _applyFilter('stable'),
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
      builder: (ctx) {
        String query = '';
        final maxHeight = MediaQuery.of(ctx).size.height * 0.75;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = query.isEmpty
                ? widget.topRegions.take(5).toList()
                : widget.topRegions
                    .where((r) =>
                        r.name.toLowerCase().contains(query.toLowerCase()))
                    .toList();

            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 6, 24, bottomInset + 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SurveillanceSheetHeader(
                      title: 'Cari Wilayah atau Pasien',
                      subtitle: 'Wilayah dengan pasien aktif.',
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      autofocus: true,
                      onChanged: (v) => setSheetState(() => query = v),
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
                    const SizedBox(height: 8),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Tidak ada wilayah yang cocok.',
                          style: TextStyle(color: Color(0xFF8A9099)),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: filtered.map((region) {
                            String riskLabel;
                            if (region.riskLevel == 'high') {
                              riskLabel = 'Risiko tinggi';
                            } else if (region.riskLevel == 'warning') {
                              riskLabel = 'Peringatan';
                            } else {
                              riskLabel = 'Stabil';
                            }
                            return SurveillanceFilterTile(
                              title: 'Wilayah ${region.name}',
                              subtitle:
                                  '${region.patientCount} kasus aktif • $riskLabel',
                              icon: Icons.location_on_outlined,
                              onTap: () {
                                Navigator.pop(ctx);
                                widget.onOpenTracing();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
