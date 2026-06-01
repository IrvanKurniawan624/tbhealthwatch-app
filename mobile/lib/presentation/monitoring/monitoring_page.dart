import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../data/models/patient_model.dart';
import '../../data/repositories/api_patient_repository.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';
import 'patient_detail_page.dart';
import 'create_patient_page.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  final _repository = ApiPatientRepository(ApiClient());

  List<Patient> _patients = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    try {
      final patients = await _repository.getMonitoringPatients();
      if (mounted) setState(() { _patients = patients; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Patient> get _filtered {
    if (_searchQuery.isEmpty) return _patients;
    final q = _searchQuery.toLowerCase();
    return _patients.where((p) =>
      p.name.toLowerCase().contains(q) ||
      (p.nik ?? '').toLowerCase().contains(q) ||
      p.location.toLowerCase().contains(q),
    ).toList();
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePatientPage()),
    );
    if (result == true) _loadPatients();
  }

  Future<void> _openDetail(Patient patient) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PatientDetailPage(patient: patient)),
    );
    if (result == true) _loadPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadPatients,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar()),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'Tidak ada pasien yang cocok.'
                        : 'Belum ada data pasien.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => PatientCard(
                      patient: _filtered[i],
                      onTap: () => _openDetail(_filtered[i]),
                    ),
                    childCount: _filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: const Color(0xFF0052CC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Monitoring",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari nama, NIK, atau wilayah...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF0052CC)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const PatientCard({super.key, required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isStable = patient.status.toUpperCase().contains("STABIL") ||
        patient.status.toUpperCase().contains("STABLE");

    return InkWell(
      onTap: onTap,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FF),
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
            Text(patient.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              "ID: ${patient.nik ?? patient.id}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    patient.location.isNotEmpty ? patient.location : '-',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(patient.phase, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(
                  "BULAN ${patient.currentMonth} DARI ${patient.totalMonths}",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: patient.totalMonths > 0
                    ? patient.currentMonth / patient.totalMonths
                    : 0,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                color: const Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
