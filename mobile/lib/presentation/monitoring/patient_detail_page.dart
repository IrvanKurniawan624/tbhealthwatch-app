import 'package:flutter/material.dart';
import '../../data/models/patient_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';
import 'edit_patient_page.dart'; // <-- Pastikan import ini ada

class PatientDetailPage extends StatelessWidget {
  final Patient patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(showBackButton: true), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderInfo(context), // Menambahkan context agar bisa pindah halaman
            const SizedBox(height: 32),
            _buildTreatmentTarget(),
            const SizedBox(height: 24),
            _buildStatsAndAction(),
            const SizedBox(height: 32),
            _buildCalendarSection(),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  // =======================================================================
  // 1. KOMPONEN: HEADER INFO PASIEN
  // =======================================================================
  Widget _buildHeaderInfo(BuildContext context) {
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
        _buildInfoRow("Patient ID:", patient.id, isHighlight: true),
        const SizedBox(height: 4),
        _buildInfoRow("No Telp:", "08123323712"),
        const SizedBox(height: 4),
        _buildInfoRow("Wilayah:", "Sukolilo"),
        const SizedBox(height: 4),
        _buildInfoRow("Tanggal Lahir:", "17 Agustus 1989"),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            // --- SEKARANG TOMBOLNYA SUDAH BISA DIPENCET ---
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPatientPage(patient: patient),
                ),
              );
            },
            // ----------------------------------------------
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
  Widget _buildTreatmentTarget() {
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
                const CircularProgressIndicator(
                  value: 0.84,
                  strokeWidth: 16,
                  backgroundColor: Color(0xFFEBF5FF),
                  color: Color(0xFF0052CC),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "84%",
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    Text(
                      "TARGET 95%",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0052CC)),
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
  Widget _buildStatsAndAction() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("DOSIS DIAMBIL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                SizedBox(height: 4),
                Text("25/30", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("STREAK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                SizedBox(height: 4),
                Text("2 Days", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
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
  Widget _buildCalendarSection() {
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
              const Text("Oktober 2023", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF045D5D))),
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
          _buildCalendarGrid(),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: const [
                  Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text("9 Hari Patuh", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.circle, size: 8, color: Color(0xFFEF4444)),
                  SizedBox(width: 4),
                  Text("2 Hari Terlewat", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final List<String> days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    final List<Map<String, dynamic>> dates = [
      {'date': '27', 'status': 0}, {'date': '28', 'status': 0}, {'date': '29', 'status': 0}, {'date': '30', 'status': 0},
      {'date': '1', 'status': 2}, {'date': '2', 'status': 2}, {'date': '3', 'status': 3},
      {'date': '4', 'status': 2}, {'date': '5', 'status': 2}, {'date': '6', 'status': 2}, {'date': '7', 'status': 2},
      {'date': '8', 'status': 3}, {'date': '9', 'status': 2}, {'date': '10', 'status': 2},
      {'date': '11', 'status': 4}, {'date': '12', 'status': 1}, {'date': '13', 'status': 1}, {'date': '14', 'status': 1},
      {'date': '15', 'status': 1}, {'date': '16', 'status': 1}, {'date': '17', 'status': 1},
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((day) => SizedBox(
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
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final dateData = dates[index];
            return _buildDateItem(dateData['date'], dateData['status']);
          },
        ),
      ],
    );
  }

  Widget _buildDateItem(String date, int status) {
    Color bgColor = Colors.transparent;
    Color textColor = Colors.black87;
    Widget? badge;

    if (status == 0) {
      textColor = Colors.grey[300]!;
    } else if (status == 2) {
      bgColor = const Color(0xFFEBF5FF);
      textColor = const Color(0xFF045D5D);
      badge = const Icon(Icons.check_circle, size: 10, color: Color(0xFF10B981));
    } else if (status == 3) {
      bgColor = const Color(0xFFFFE4E6);
      textColor = const Color(0xFFEF4444);
      badge = const Icon(Icons.cancel, size: 10, color: Color(0xFFEF4444));
    } else if (status == 4) {
      bgColor = const Color(0xFF045D5D);
      textColor = Colors.white;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bgColor,
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
        SizedBox(height: 10, child: badge),
      ],
    );
  }
}
