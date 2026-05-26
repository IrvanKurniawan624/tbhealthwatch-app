import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_client.dart';
import '../../data/repositories/api_patient_repository.dart';

// ─────────────────────────────────────────────
// COLOR CONSTANTS
// ─────────────────────────────────────────────

class TBColors {
  static const primary = Color(0xFF1565C0);
  static const background = Color(0xFFF5F7FA);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFFADB5BD);
  static const divider = Color(0xFFE5E7EB);
  static const inputBorder = Color(0xFFCED4DA);
  static const inputFocused = Color(0xFF1565C0);
  static const disabledBg = Color(0xFFE9ECEF);
  static const disabledText = Color(0xFF9CA3AF);
  static const progressActive = Color(0xFF1565C0);
  static const progressInactive = Color(0xFFDEE2E6);
  static const backArrow = Color(0xFF1565C0);
}

// ─────────────────────────────────────────────
// CREATE PATIENT PAGE (Updated from InputPasienScreen)
// ─────────────────────────────────────────────

class CreatePatientPage extends StatefulWidget {
  const CreatePatientPage({super.key});

  @override
  State<CreatePatientPage> createState() => _CreatePatientPageState();
}

class _CreatePatientPageState extends State<CreatePatientPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _namaController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _nikController = TextEditingController();
  final _nomorTelefonController = TextEditingController();

  // For Region Dropdown (Matching Backend Requirement)
  final _repo = ApiPatientRepository(ApiClient());
  List<Map<String, dynamic>> _regions = [];
  String? _selectedRegionId;

  // Auto-generated ID (visual only as per user design)
  final String _generatedId = 'TB-2024-1999999';

  // Phase dropdown
  int _selectedPhase = 1;
  final List<int> _phaseOptions = [1, 2];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      final data = await ApiClient().get('/regions') as List;
      if (mounted) {
        setState(() {
          _regions = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tanggalLahirController.dispose();
    _nikController.dispose();
    _nomorTelefonController.dispose();
    super.dispose();
  }

  // ── DATE PICKER ──────────────────────────────
  Future<void> _pickTanggalLahir() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: TBColors.primary,
              onSurface: TBColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tanggalLahirController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // ── SUBMIT ───────────────────────────────────
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _repo.create({
        'fullName': _namaController.text.trim(),
        'nik': _nikController.text.trim(),
        if (_tanggalLahirController.text.isNotEmpty)
          'dob': _tanggalLahirController.text,
        'phone': _nomorTelefonController.text.trim(),
        if (_selectedRegionId != null) 'regionId': _selectedRegionId,
        'treatmentPhase': _selectedPhase,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data pasien berhasil disimpan!'),
          backgroundColor: TBColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageTitle(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Informasi data'),
                    const SizedBox(height: 20),

                    // Name
                    _buildLabel('Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _namaController,
                      hint: 'Masukkan nama',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),

                    // Tanggal Lahir
                    _buildLabel('Tanggal Lahir'),
                    const SizedBox(height: 8),
                    _buildDateField(),
                    const SizedBox(height: 20),

                    // Wilayah (Changed to Dropdown for API Integration)
                    _buildLabel('Wilayah'),
                    const SizedBox(height: 8),
                    _buildRegionDropdown(),
                    const SizedBox(height: 20),

                    // Nomor Telefon
                    _buildLabel('Nomor Telefon'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nomorTelefonController,
                      hint: 'Nomor telefon anda...',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nomor wajib diisi';
                        if (v.length < 9) return 'Nomor tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // NIK / ID
                    _buildLabel('NIK'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nikController,
                      hint: 'Masukkan 16 digit NIK',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'NIK wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),

                    // Generated ID (Visual only as per design)
                    _buildLabel('Generated Id'),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(_generatedId),
                    const SizedBox(height: 20),

                    // Phase dropdown
                    _buildLabel('Phase'),
                    const SizedBox(height: 8),
                    _buildPhaseDropdown(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // ── TOP BAR with progress ────────────────────
  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: TBColors.backArrow, size: 24),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
          // Progress bar — step 1 of 2
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 3,
                  color: TBColors.progressActive,
                ),
              ),
              Expanded(
                child: Container(
                  height: 3,
                  color: TBColors.progressInactive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PAGE TITLE ───────────────────────────────
  Widget _buildPageTitle() {
    return const Text(
      'Input Data Pasien baru',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: TBColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  // ── SECTION HEADER ───────────────────────────
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: TBColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: TBColors.divider),
      ],
    );
  }

  // ── FIELD LABEL ──────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: TBColors.textPrimary,
      ),
    );
  }

  // ── TEXT FIELD ───────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: TBColors.textPrimary,
      ),
      decoration: _inputDecoration(hint),
    );
  }

  // ── DATE FIELD ───────────────────────────────
  Widget _buildDateField() {
    return TextFormField(
      controller: _tanggalLahirController,
      readOnly: true,
      onTap: _pickTanggalLahir,
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Tanggal lahir wajib diisi' : null,
      style: const TextStyle(fontSize: 15, color: TBColors.textPrimary),
      decoration: _inputDecoration('Masukkan Lahir').copyWith(
        suffixIcon: const Icon(Icons.calendar_today_outlined,
            size: 18, color: TBColors.textSecondary),
      ),
    );
  }

  // ── READ-ONLY FIELD (ID) ─────────────────────
  Widget _buildReadOnlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: TBColors.disabledBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TBColors.inputBorder),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          color: TBColors.disabledText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── REGION DROPDOWN ──────────────────────────
  Widget _buildRegionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TBColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRegionId,
          isExpanded: true,
          hint: const Text('Pilih wilayah', style: TextStyle(fontSize: 15, color: TBColors.textHint)),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: TBColors.textSecondary),
          style: const TextStyle(
            fontSize: 15,
            color: TBColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          items: _regions.map((r) {
            return DropdownMenuItem<String>(
              value: r['id'] as String,
              child: Text(r['name'] as String),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedRegionId = val);
          },
        ),
      ),
    );
  }

  // ── PHASE DROPDOWN ───────────────────────────
  Widget _buildPhaseDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TBColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedPhase,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: TBColors.textSecondary),
          style: const TextStyle(
            fontSize: 15,
            color: TBColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          items: _phaseOptions.map((phase) {
            return DropdownMenuItem<int>(
              value: phase,
              child: Text('$phase'),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedPhase = val);
          },
        ),
      ),
    );
  }

  // ── SUBMIT BUTTON ────────────────────────────
  Widget _buildSubmitButton() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: TBColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: TBColors.primary.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'INPUT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  // ── INPUT DECORATION HELPER ──────────────────
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(fontSize: 15, color: TBColors.textHint),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: TBColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: TBColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: TBColors.inputFocused, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
    );
  }
}
