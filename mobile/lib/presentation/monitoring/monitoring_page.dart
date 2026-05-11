import 'package:flutter/material.dart';
import '../../data/models/patient_model.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/mock_patient_repository.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';
import 'patient_detail_page.dart'; // <-- Import halaman detail yang baru dibuat

// ============================================================================
// 1. HALAMAN UTAMA MONITORING (ROOT PAGE)
// Halaman ini bertugas mengambil data pasien dari repository dan merakit UI.
// ============================================================================
class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  // ----------------------------------------------------------------------
  // ⚠️ TEMPAT MENGUBAH KE BACKEND ASLI NANTI
  // Untuk saat ini pakai MockPatientRepository (Dummy Data).
  // ----------------------------------------------------------------------
  final IPatientRepository _repository = MockPatientRepository();
  late Future<List<Patient>> _patientsFuture;

  @override
  void initState() {
    super.initState();
    _patientsFuture = _repository.getMonitoringPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Background abu-abu terang
      appBar: const CustomAppBar(), // <-- Memanggil Global App Bar
      body: FutureBuilder<List<Patient>>(
        future: _patientsFuture,
        builder: (context, snapshot) {
          // Menampilkan loading saat data sedang diambil
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          // Menampilkan pesan error jika gagal mengambil data
          else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } 
          // Jika data berhasil diambil, tampilkan daftar pasien
          else if (snapshot.hasData) {
            final patients = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Halaman
                  const Text(
                    "Monitoring",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Melakukan perulangan (mapping) data pasien menjadi komponen kartu
                  ...patients.map((patient) => PatientCard(patient: patient)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      // MENGGUNAKAN GLOBAL BOTTOM NAV (Index 2 untuk Monitoring)
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2), 
    );
  }
}

// ============================================================================
// 2. KOMPONEN: KARTU PASIEN (PATIENT CARD)
// Berisi detail individu pasien seperti status, ID, lokasi, dan progress bar.
// Dipisah menjadi class agar bisa digunakan ulang dan kodenya lebih bersih.
// ============================================================================
class PatientCard extends StatelessWidget {
  final Patient patient;

  const PatientCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    // Menentukan warna badge berdasarkan kata kunci status (STABIL / STABLE)
    bool isStable = patient.status.toUpperCase().contains("STABIL") || 
                    patient.status.toUpperCase().contains("STABLE");

    // BUNGKUS DENGAN INKWELL AGAR BISA DIKLIK DAN PINDAH HALAMAN
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailPage(patient: patient),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN ATAS: Avatar & Badge Status ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FF), // Biru sangat muda
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline, color: Color(0xFF0052CC)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isStable ? const Color(0xFFEBF5FF) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    patient.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isStable ? const Color(0xFF0052CC) : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // --- BAGIAN TENGAH: Nama, ID, & Lokasi ---
            Text(
              patient.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "ID: ${patient.id}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  patient.location,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // --- BAGIAN BAWAH: Progress Bar Fase Perawatan ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  patient.phase,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                Text(
                  "MONTH ${patient.currentMonth} OF ${patient.totalMonths}",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: patient.currentMonth / patient.totalMonths, // Menghitung rasio progress
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                color: const Color(0xFF2C3E50), // Warna biru gelap sesuai figma
              ),
            ),
          ],
        ),
      ),
    );
  }
}