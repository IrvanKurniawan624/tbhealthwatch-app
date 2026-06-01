import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/adherence_model.dart';
import '../../data/repositories/api_patient_repository.dart';
import '../../data/repositories/api_adherence_repository.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';
import 'edit_patient_page.dart';

class PatientDetailPage extends StatefulWidget {
  final Patient patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  final _patientRepo = ApiPatientRepository(ApiClient());
  final _adherenceRepo = ApiAdherenceRepository(ApiClient());

  _DetailBundle? _bundle;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _confirmDelete(BuildContext context, Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pasien'),
        content: Text('Yakin ingin menghapus data "${patient.name}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _patientRepo.delete(patient.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pasien berhasil dihapus')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        _patientRepo.getById(widget.patient.id),
        _adherenceRepo.getSummary(widget.patient.id),
        _adherenceRepo.getCalendar(widget.patient.id, now.year, now.month),
      ]);
      if (mounted) {
        setState(() {
          _bundle = _DetailBundle(
            patient: results[0] as Patient,
            summary: results[1] as AdherenceSummary,
            calendar: results[2] as AdherenceCalendar,
          );
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text('Gagal memuat data: $_error'));
    } else {
      body = _buildContent(_bundle!);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(showBackButton: true),
      body: body,
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  Widget _buildContent(_DetailBundle bundle) {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderInfo(context, bundle),
            const SizedBox(height: 32),
            _buildTreatmentTarget(bundle),
            const SizedBox(height: 24),
            _buildStatsAndAction(bundle),
            const SizedBox(height: 32),
            _buildCalendarSection(bundle),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context, _DetailBundle bundle) {
    final patient = bundle.patient;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ACTIVE MONITORING",
          style: TextStyle(color: Color(0xFF0052CC), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFEBF5FF), borderRadius: BorderRadius.circular(20)),
          child: Text(
            patient.status,
            style: const TextStyle(color: Color(0xFF0052CC), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          patient.name,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 12),
        _buildInfoRow("Patient ID:", patient.nik ?? patient.id, isHighlight: true),
        const SizedBox(height: 4),
        _buildInfoRow("No Telp:", patient.phone ?? '-'),
        const SizedBox(height: 4),
        _buildInfoRow("Wilayah:", patient.regionName ?? '-'),
        const SizedBox(height: 4),
        _buildInfoRow("Tanggal Lahir:", patient.dob ?? '-'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => EditPatientPage(patient: patient)),
                );
                if (updated == true) await _loadAll();
              },
              icon: const Icon(Icons.edit_document, size: 16, color: Colors.white),
              label: const Text("EDIT DATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, patient),
              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
              label: const Text("HAPUS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? const Color(0xFF0052CC) : Colors.black87,
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentTarget(_DetailBundle bundle) {
    final summary = bundle.summary;
    final patient = bundle.patient;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Target Pengobatan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(
          "Presentase Kepatuhan Obat Untuk ${patient.phase.toLowerCase().replaceAll('phase ', 'Phase ')}",
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: summary.percentage / 100,
                  strokeWidth: 16,
                  backgroundColor: const Color(0xFFEBF5FF),
                  color: const Color(0xFF0052CC),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${summary.percentage.toStringAsFixed(0)}%",
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    Text(
                      "TARGET ${summary.target}%",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0052CC)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsAndAction(_DetailBundle bundle) {
    final summary = bundle.summary;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final alreadyLogged = bundle.calendar.days
        .where((d) => d.date == todayStr)
        .any((d) => d.status == 'taken');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("DOSIS DIAMBIL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  "${summary.dosesTaken}/${summary.dosesTotal}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("STREAK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  "${summary.streakDays} Days",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: alreadyLogged
                ? null
                : () async {
                    try {
                      await _adherenceRepo.log(widget.patient.id, todayStr, 'taken');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Obat berhasil dicatat')),
                        );
                        await _loadAll();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal mencatat: $e')),
                        );
                      }
                    }
                  },
            icon: Icon(
              alreadyLogged ? Icons.check_circle : Icons.add_circle,
              color: Colors.white,
            ),
            label: Text(
              alreadyLogged ? "Sudah Dicatat Hari Ini" : "Catat Obat Sekarang",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: alreadyLogged ? Colors.green[600] : const Color(0xFF0052CC),
              disabledBackgroundColor: Colors.green[600],
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection(_DetailBundle bundle) {
    final calendar = bundle.calendar;
    final monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final monthLabel = '${monthNames[calendar.month - 1]} ${calendar.year}';
    final takenCount = calendar.days.where((d) => d.status == 'taken').length;
    final missedCount = calendar.days.where((d) => d.status == 'missed').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(monthLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF045D5D))),
              Row(
                children: const [
                  Icon(Icons.chevron_left, color: Color(0xFF045D5D)),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Color(0xFF045D5D)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCalendarGrid(bundle),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text("$takenCount Hari Patuh",
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  Text("$missedCount Hari Terlewat",
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(_DetailBundle bundle) {
    const dayHeaders = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    final days = bundle.calendar.days;
    // Monday=1 → offset 0, Sunday=7 → offset 6
    final offset = DateTime(bundle.calendar.year, bundle.calendar.month, 1).weekday - 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayHeaders
              .map((d) => SizedBox(
                    width: 30,
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: offset + days.length,
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox.shrink();
            final day = days[index - offset];
            final parts = day.date.split('-');
            final dayNum = parts.length >= 3 ? parts[2] : day.date;
            return _buildDateItem(dayNum, day.status);
          },
        ),
      ],
    );
  }

  ({Color bg, IconData? icon, Color? iconColor}) _statusStyle(String status) {
    switch (status) {
      case 'taken':
        return (bg: const Color(0xFFEBF5FF), icon: Icons.check, iconColor: const Color(0xFF0052CC));
      case 'missed':
        return (bg: const Color(0xFFFFE4E6), icon: Icons.close, iconColor: Colors.red);
      case 'partial':
        return (bg: const Color(0xFFFFF7E6), icon: Icons.remove, iconColor: Colors.orange);
      case 'pending':
        return (bg: const Color(0xFFF3F4F6), icon: null, iconColor: null);
      default:
        return (bg: Colors.transparent, icon: null, iconColor: null);
    }
  }

  Widget _buildDateItem(String date, String status) {
    final style = _statusStyle(status);
    final isGreyed = status == 'outside_month' || status == 'upcoming';
    final textColor = isGreyed ? Colors.grey[400]! : Colors.black87;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: style.bg, shape: BoxShape.circle),
          child: Center(
            child: Text(date, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 10,
          child: style.icon != null ? Icon(style.icon, size: 10, color: style.iconColor) : null,
        ),
      ],
    );
  }
}

class _DetailBundle {
  final Patient patient;
  final AdherenceSummary summary;
  final AdherenceCalendar calendar;

  _DetailBundle({required this.patient, required this.summary, required this.calendar});
}
