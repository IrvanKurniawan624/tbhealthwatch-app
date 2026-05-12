import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/adherence_model.dart';
import '../../data/repositories/api_patient_repository.dart';
import '../../data/repositories/api_adherence_repository.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';
import 'edit_patient_page.dart'; // <-- Pastikan import ini ada

class PatientDetailPage extends StatefulWidget {
  final Patient patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  late Future<_DetailBundle> _future;
  final _patientRepo = ApiPatientRepository(ApiClient());
  final _adherenceRepo = ApiAdherenceRepository(ApiClient());

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  Future<_DetailBundle> _loadAll() async {
    final now = DateTime.now();
    final results = await Future.wait([
      _patientRepo.getById(widget.patient.id),
      _adherenceRepo.getSummary(widget.patient.id),
      _adherenceRepo.getCalendar(widget.patient.id, now.year, now.month),
    ]);
    return _DetailBundle(
      patient: results[0] as Patient,
      summary: results[1] as AdherenceSummary,
      calendar: results[2] as AdherenceCalendar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(showBackButton: true),
      body: FutureBuilder<_DetailBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
          }
          final bundle = snapshot.data!;
          return _buildContent(bundle);
        },
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  Widget _buildContent(_DetailBundle bundle) {
    return SingleChildScrollView(
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
    );
  }

  // =======================================================================
  // 1. KOMPONEN: HEADER INFO PASIEN
  // =======================================================================
  Widget _buildHeaderInfo(BuildContext context, _DetailBundle bundle) {
    final patient = bundle.patient;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ACTIVE MONITORING",
          style: TextStyle(
            color: Color(0xFF0052CC),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF5FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            patient.status,
            style: const TextStyle(
              color: Color(0xFF0052CC),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          patient.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
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
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPatientPage(patient: patient),
                ),
              );
            },
            icon: const Icon(Icons.edit_document, size: 16, color: Colors.white),
            label: const Text("EDIT DATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052CC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
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

  // =======================================================================
  // 2. KOMPONEN: TARGET PENGOBATAN
  // =======================================================================
  Widget _buildTreatmentTarget(_DetailBundle bundle) {
    final summary = bundle.summary;
    final patient = bundle.patient;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Target Pengobatan",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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

  // =======================================================================
  // 3. KOMPONEN: STATISTIK & TOMBOL CATAT
  // =======================================================================
  Widget _buildStatsAndAction(_DetailBundle bundle) {
    final summary = bundle.summary;
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
                Text("${summary.dosesTaken}/${summary.dosesTotal}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("STREAK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text("${summary.streakDays} Days",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final today = DateTime.now();
              final logDate =
                  '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
              try {
                await _adherenceRepo.log(widget.patient.id, logDate, 'taken');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Obat berhasil dicatat')),
                  );
                  setState(() {
                    _future = _loadAll();
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mencatat: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.add_circle, color: Colors.white),
            label: const Text("Catat Obat Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052CC),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // =======================================================================
  // 4. KOMPONEN: KALENDER KEPATUHAN
  // =======================================================================
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
    final List<String> dayHeaders = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    final days = bundle.calendar.days;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayHeaders.map((day) => SizedBox(
            width: 30,
            child: Center(child: Text(day, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
          )).toList(),
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
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
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
      default:
        return (bg: Colors.transparent, icon: null, iconColor: null);
    }
  }

  Widget _buildDateItem(String date, String status) {
    final style = _statusStyle(status);
    final textColor = status == 'none' ? Colors.grey[400]! : Colors.black87;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: style.bg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 10,
          child: style.icon != null
              ? Icon(style.icon, size: 10, color: style.iconColor)
              : null,
        ),
      ],
    );
  }
}

class _DetailBundle {
  final Patient patient;
  final AdherenceSummary summary;
  final AdherenceCalendar calendar;
  _DetailBundle({
    required this.patient,
    required this.summary,
    required this.calendar,
  });
}
