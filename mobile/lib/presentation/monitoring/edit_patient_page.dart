import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../data/models/patient_model.dart';
import '../../data/repositories/api_patient_repository.dart';

// ============================================================================
// 1. HALAMAN EDIT PASIEN
// Halaman ini digunakan untuk memperbarui informasi detail pasien.
// ============================================================================
class EditPatientPage extends StatefulWidget {
  final Patient patient;

  const EditPatientPage({super.key, required this.patient});

  @override
  State<EditPatientPage> createState() => _EditPatientPageState();
}

class _EditPatientPageState extends State<EditPatientPage> {
  // --- Controller untuk menangkap inputan ---
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _wilayahController;
  late TextEditingController _phoneController;
  late TextEditingController _idController;

  String _selectedPhase = '2'; // Default sesuai figma

  final _repo = ApiPatientRepository(ApiClient());
  bool _isSaving = false;
  List<Map<String, dynamic>> _regions = [];
  String? _selectedRegionId;

  @override
  void initState() {
    super.initState();
    // Pre-fill from the patient passed in
    _nameController = TextEditingController(text: widget.patient.name);
    _dobController = TextEditingController(text: widget.patient.dob ?? '');
    _wilayahController = TextEditingController(text: widget.patient.regionName ?? '');
    _phoneController = TextEditingController(text: widget.patient.phone ?? '');
    // ID menggunakan data asli yang dioper dari halaman sebelumnya
    _idController = TextEditingController(text: widget.patient.id);
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      final data = await ApiClient().get('/regions') as List;
      if (mounted) {
        setState(() {
          _regions = data.cast<Map<String, dynamic>>();
          // Pre-select region matching the patient's regionName
          final match = _regions.firstWhere(
            (r) => r['name'] == widget.patient.regionName,
            orElse: () => {},
          );
          _selectedRegionId = match['id'] as String?;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _wilayahController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0052CC)),
          onPressed: () => Navigator.pop(context), // Kembali ke halaman sebelumnya
        ),
        // Garis progress bar di bawah App Bar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Row(
            children: [
              Expanded(child: Container(color: Colors.grey[200], height: 2.0)),
              Expanded(child: Container(color: const Color(0xFF0052CC), height: 2.0)),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Edit Data Pasien baru",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            const Text(
              "Informasi data",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1, color: Colors.black12),
            const SizedBox(height: 12),

            // --- Form Inputs ---
            _buildLabel("Name"),
            _buildTextField(_nameController),

            _buildLabel("Tanggal lahir"),
            _buildTextField(_dobController),

            _buildLabel("Wilayah"),
            _buildRegionDropdown(),

            _buildLabel("Nomor Telefon"),
            _buildTextField(_phoneController),

            _buildLabel("Id"),
            _buildTextField(_idController, isEnabled: false), // Kotak ID abu-abu

            _buildLabel("Phase"),
            _buildDropdown(),

            const SizedBox(height: 48),

            // --- Tombol Edit ---
            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setState(() => _isSaving = true);
                          try {
                            await _repo.update(widget.patient.id, {
                              'fullName': _nameController.text.trim(),
                              if (_dobController.text.trim().isNotEmpty)
                                'dob': _dobController.text.trim(),
                              'phone': _phoneController.text.trim(),
                              if (_selectedRegionId != null) 'regionId': _selectedRegionId,
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Data pasien berhasil diperbarui')),
                              );
                              Navigator.pop(context, true);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal menyimpan: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text("EDIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24), // Spasi bawah agar tidak mentok
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET BANTUAN
  // ===========================================================================

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {bool isEnabled = true}) {
    return TextField(
      controller: controller,
      enabled: isEnabled,
      style: TextStyle(fontSize: 14, color: isEnabled ? Colors.black87 : Colors.black54),
      decoration: InputDecoration(
        filled: true,
        fillColor: isEnabled ? Colors.white : Colors.grey[300], // Warna abu-abu kalau disable
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF0052CC)),
        ),
      ),
    );
  }

  Widget _buildRegionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRegionId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          hint: Text(
            _wilayahController.text.isNotEmpty ? _wilayahController.text : 'Pilih wilayah',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          items: _regions.map((r) => DropdownMenuItem<String>(
            value: r['id'] as String,
            child: Text(r['name'] as String, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          )).toList(),
          onChanged: (val) => setState(() => _selectedRegionId = val),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPhase,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: ['1', '2', '3'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedPhase = newValue!;
            });
          },
        ),
      ),
    );
  }
}
