import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
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
  String _selectedPhase = 'all';
  String _selectedStatus = 'all';
  String _selectedSortBy = 'registered_newest';
  int _page = 1;
  static const int _pageSize = 15;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _pageInputController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadPatients(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageInputController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPatients({bool reset = false}) async {
    print("MonitoringPage: _loadPatients(reset: $reset) page=$_page, pageSize=$_pageSize");
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
      }
    });

    try {
      final newPatients = await _repository.getMonitoringPatients(
        search: _searchQuery,
        page: _page,
        pageSize: _pageSize,
        phase: _selectedPhase,
        status: _selectedStatus,
        sortBy: _selectedSortBy,
      );

      print("MonitoringPage: fetched ${newPatients.length} patients");

      if (mounted) {
        setState(() {
          _patients = newPatients;
          _hasMore = newPatients.length >= _pageSize;
          print("MonitoringPage: updated state, patients.length=${_patients.length}, hasMore=$_hasMore");
          _loading = false;
          _pageInputController.text = '$_page';
        });
      }
    } catch (e) {
      print("MonitoringPage: error loading patients: $e");
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _prevPage() {
    if (_page > 1 && !_loading) {
      setState(() {
        _page--;
      });
      _loadPatients();
      _scrollToTop();
    }
  }

  void _nextPage() {
    if (_hasMore && !_loading) {
      setState(() {
        _page++;
      });
      _loadPatients();
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _loadPatients(reset: true);
    });
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePatientPage()),
    );
    if (result == true) _loadPatients(reset: true);
  }

  Future<void> _openDetail(Patient patient) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PatientDetailPage(patient: patient)),
    );
    if (result == true) _loadPatients(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: () => _loadPatients(reset: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar()),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_patients.isEmpty)
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
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      return PatientCard(
                        patient: _patients[i],
                        onTap: () => _openDetail(_patients[i]),
                      );
                    },
                    childCount: _patients.length,
                  ),
                ),
              ),
              if (!_loading && _patients.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildPaginationControls(),
                ),
            ],
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
    final bool hasActiveFilters = _selectedPhase != 'all' || _selectedStatus != 'all' || _selectedSortBy != 'registered_newest';

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
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: _onSearchChanged,
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
              ),
              const SizedBox(width: 12),
              Material(
                color: hasActiveFilters ? const Color(0xFFEBF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _showFilterBottomSheet,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: hasActiveFilters ? const Color(0xFF0052CC) : const Color(0xFFE5E7EB),
                        width: hasActiveFilters ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune,
                          color: hasActiveFilters ? const Color(0xFF0052CC) : Colors.grey[700],
                        ),
                        if (hasActiveFilters)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD32F2F),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedPhase != 'all')
                    _buildFilterChip(
                      label: _selectedPhase == 'phase1' ? 'Fase 1' : 'Fase 2',
                      onDeleted: () {
                        setState(() {
                          _selectedPhase = 'all';
                        });
                        _loadPatients(reset: true);
                      },
                    ),
                  if (_selectedStatus != 'all')
                    _buildFilterChip(
                      label: _selectedStatus == 'active' ? 'Aktif' : 'Stabil',
                      onDeleted: () {
                        setState(() {
                          _selectedStatus = 'all';
                        });
                        _loadPatients(reset: true);
                      },
                    ),
                  if (_selectedSortBy != 'registered_newest')
                    _buildFilterChip(
                      label: _getSortLabel(_selectedSortBy),
                      onDeleted: () {
                        setState(() {
                          _selectedSortBy = 'registered_newest';
                        });
                        _loadPatients(reset: true);
                      },
                    ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedPhase = 'all';
                        _selectedStatus = 'all';
                        _selectedSortBy = 'registered_newest';
                      });
                      _loadPatients(reset: true);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Hapus Semua',
                      style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _jumpToPage(int targetPage) {
    if (targetPage < 1 || _loading) return;
    setState(() {
      _page = targetPage;
    });
    _loadPatients();
    _scrollToTop();
  }

  void _submitCustomPage() {
    final text = _pageInputController.text.trim();
    if (text.isEmpty) return;
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 1) {
      _pageInputController.text = '$_page';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nomor halaman yang valid (minimal 1)'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _jumpToPage(parsed);
  }

  Widget _buildPageChip(int p) {
    final bool isCurrent = p == _page;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: isCurrent ? const Color(0xFF0052CC) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isCurrent || _loading ? null : () => _jumpToPage(p),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: isCurrent ? const Color(0xFF0052CC) : const Color(0xFFE5E7EB),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$p',
              style: TextStyle(
                color: isCurrent ? Colors.white : const Color(0xFF1F2937),
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPageButtons() {
    final List<Widget> buttons = [];
    
    // Always show Page 1
    buttons.add(_buildPageChip(1));
    
    // Show ellipsis if page is far from 1
    if (_page > 3) {
      buttons.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            '...',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    
    // Show _page - 2, _page - 1
    for (int p = _page - 2; p < _page; p++) {
      if (p > 1) {
        buttons.add(_buildPageChip(p));
      }
    }
    
    // Show current page if it is not page 1
    if (_page > 1) {
      buttons.add(_buildPageChip(_page));
    }
    
    // Show _page + 1, _page + 2 if we have more pages
    if (_hasMore) {
      buttons.add(_buildPageChip(_page + 1));
      buttons.add(_buildPageChip(_page + 2));
      
      // Show trailing ellipsis
      buttons.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            '...',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    
    return buttons;
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                color: _page > 1 ? Colors.white : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _page > 1 && !_loading ? _prevPage : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _page > 1 ? const Color(0xFFE5E7EB) : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: _page > 1 ? const Color(0xFF1F2937) : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildPageButtons(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: _hasMore ? Colors.white : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _hasMore && !_loading ? _nextPage : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _hasMore ? const Color(0xFFE5E7EB) : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: _hasMore ? const Color(0xFF1F2937) : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Ke Halaman:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                height: 36,
                child: TextField(
                  controller: _pageInputController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF0052CC)),
                    ),
                  ),
                  onSubmitted: (_) => _submitCustomPage(),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: const Color(0xFF0052CC),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _loading ? null : _submitCustomPage,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _FilterBottomSheet(
          initialPhase: _selectedPhase,
          initialStatus: _selectedStatus,
          initialSortBy: _selectedSortBy,
          onApply: (phase, status, sortBy) {
            setState(() {
              _selectedPhase = phase;
              _selectedStatus = status;
              _selectedSortBy = sortBy;
            });
            _loadPatients(reset: true);
          },
        );
      },
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'name_desc':
        return 'Nama Z-A';
      case 'registered_newest':
        return 'Terbaru';
      case 'registered_oldest':
        return 'Terlama';
      default:
        return 'Nama A-Z';
    }
  }

  Widget _buildFilterChip({required String label, required VoidCallback onDeleted}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF0052CC), fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFFEBF5FF),
        deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF0052CC)),
        onDeleted: onDeleted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide.none,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    ? (patient.currentMonth - 1) / patient.totalMonths
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

class _FilterBottomSheet extends StatefulWidget {
  final String initialPhase;
  final String initialStatus;
  final String initialSortBy;
  final Function(String phase, String status, String sortBy) onApply;

  const _FilterBottomSheet({
    required this.initialPhase,
    required this.initialStatus,
    required this.initialSortBy,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String _phase;
  late String _status;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _phase = widget.initialPhase;
    _status = widget.initialStatus;
    _sortBy = widget.initialSortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 8,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter & Urutkan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Fase Pengobatan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSelectionChip('Semua', 'all', _phase, (val) => setState(() => _phase = val)),
              const SizedBox(width: 8),
              _buildSelectionChip('Fase 1', 'phase1', _phase, (val) => setState(() => _phase = val)),
              const SizedBox(width: 8),
              _buildSelectionChip('Fase 2', 'phase2', _phase, (val) => setState(() => _phase = val)),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Status Pasien',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSelectionChip('Semua', 'all', _status, (val) => setState(() => _status = val)),
              const SizedBox(width: 8),
              _buildSelectionChip('Aktif', 'active', _status, (val) => setState(() => _status = val)),
              const SizedBox(width: 8),
              _buildSelectionChip('Stabil', 'stable', _status, (val) => setState(() => _status = val)),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Urutkan Berdasarkan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSelectionChip('Nama A-Z', 'name_asc', _sortBy, (val) => setState(() => _sortBy = val)),
              _buildSelectionChip('Nama Z-A', 'name_desc', _sortBy, (val) => setState(() => _sortBy = val)),
              _buildSelectionChip('Pendaftaran Terbaru', 'registered_newest', _sortBy, (val) => setState(() => _sortBy = val)),
              _buildSelectionChip('Pendaftaran Terlama', 'registered_oldest', _sortBy, (val) => setState(() => _sortBy = val)),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _phase = 'all';
                      _status = 'all';
                      _sortBy = 'registered_newest';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Atur Ulang',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_phase, _status, _sortBy);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Terapkan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionChip(
    String label,
    String value,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
    final bool isSelected = value == currentValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052CC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0052CC) : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0052CC).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
