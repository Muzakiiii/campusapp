import 'dart:io';
import 'dart:typed_data';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:campusapp/features/events/data/repositories/event_repository.dart';

class AdminCreateEventScreen extends StatefulWidget {
  const AdminCreateEventScreen({super.key});

  @override
  State<AdminCreateEventScreen> createState() => _AdminCreateEventScreenState();
}

class _AdminCreateEventScreenState extends State<AdminCreateEventScreen> {
  final _scrollController = ScrollController();
  final EventRepository _eventRepository = EventRepository();

  // Controllers
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _linkOnlineController = TextEditingController();
  final _kuotaController = TextEditingController();
  final _skkmController = TextEditingController();
  final _hargaOnlineController = TextEditingController();
  final _hargaOfflineController = TextEditingController();
  final _jamMulaiController = TextEditingController();
  final _jamSelesaiController = TextEditingController();

  // State variables
  String _selectedKategori = 'Seminar';
  String _selectedStatus = 'pending';
  DateTime? _selectedTanggal;
  DateTime? _selectedBatasDaftar;
  
  // Image picker
  File? _posterFile;
  Uint8List? _posterBytes;
  String? _posterFileName;

  bool _isSaving = false;

  // Error flags
  bool _errJudul = false;
  bool _errDeskripsi = false;
  bool _errTanggal = false;
  bool _errBatasDaftar = false;
  bool _errJamMulai = false;
  bool _errJamSelesai = false;
  bool _errLokasi = false;
  bool _errKuota = false;
  bool _errSKKM = false;

  // Options
  final List<String> _kategoriOptions = [
    'Seminar',
    'Workshop',
    'Webinar',
    'Pelatihan',
    'Lomba',
    'Lainnya'
  ];

  final List<String> _statusOptions = [
    'pending',
    'active',
    'cancelled',
    'completed'
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _judulController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    _linkOnlineController.dispose();
    _kuotaController.dispose();
    _skkmController.dispose();
    _hargaOnlineController.dispose();
    _hargaOfflineController.dispose();
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
    super.dispose();
  }

  // ================= PICK POSTER =================
  Future<void> _pickPoster() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (picked == null) return;

      if (kIsWeb) {
        // Untuk web
        final bytes = await picked.readAsBytes();
        setState(() {
          _posterBytes = bytes;
          _posterFile = null;
          _posterFileName = picked.name;
        });
      } else {
        // Untuk mobile
        final file = File(picked.path);
        final bytes = await file.readAsBytes();
        setState(() {
          _posterFile = file;
          _posterBytes = bytes;
          _posterFileName = picked.name;
        });
      }
      
      print('📸 Gambar dipilih: $_posterFileName (${_posterBytes?.length ?? 0} bytes)');
    } catch (e) {
      _showError('Gagal memilih gambar: $e');
    }
  }

  // ================= VALIDASI FORM =================
  bool _validateForm() {
    setState(() {
      _errJudul = _judulController.text.isEmpty;
      _errDeskripsi = _deskripsiController.text.isEmpty;
      _errTanggal = _selectedTanggal == null;
      _errBatasDaftar = _selectedBatasDaftar == null;
      _errJamMulai = _jamMulaiController.text.isEmpty;
      _errJamSelesai = _jamSelesaiController.text.isEmpty;
      _errLokasi = _lokasiController.text.isEmpty;
      _errKuota = _kuotaController.text.isEmpty;
      _errSKKM = _skkmController.text.isEmpty;
    });

    if (_errJudul ||
        _errDeskripsi ||
        _errTanggal ||
        _errBatasDaftar ||
        _errJamMulai ||
        _errJamSelesai ||
        _errLokasi ||
        _errKuota ||
        _errSKKM) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return false;
    }
    return true;
  }

  // ================= BUAT EVENT DENGAN CLOUDINARY =================
  Future<void> _createEvent() async {
    if (!_validateForm()) {
      _showError('Lengkapi semua field wajib');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Validasi waktu format "09.00"
      if (!_isValidTimeFormat(_jamMulaiController.text) ||
          !_isValidTimeFormat(_jamSelesaiController.text)) {
        _showError('Format jam harus HH.mm (contoh: 09.00 atau 14.30)');
        setState(() => _isSaving = false);
        return;
      }

      // Validasi tanggal
      if (_selectedTanggal!.isBefore(DateTime.now())) {
        _showError('Tanggal event tidak boleh di masa lalu');
        setState(() => _isSaving = false);
        return;
      }

      if (_selectedBatasDaftar!.isAfter(_selectedTanggal!)) {
        _showError('Batas daftar tidak boleh setelah tanggal event');
        setState(() => _isSaving = false);
        return;
      }

      // Validasi kuota
      final kuota = int.tryParse(_kuotaController.text) ?? 0;
      if (kuota <= 0) {
        _showError('Kuota harus lebih dari 0');
        setState(() => _isSaving = false);
        return;
      }

      // Validasi harga
      final hargaOnline = int.tryParse(_hargaOnlineController.text) ?? 0;
      final hargaOffline = int.tryParse(_hargaOfflineController.text) ?? 0;
      if (hargaOnline < 0 || hargaOffline < 0) {
        _showError('Harga tidak boleh negatif');
        setState(() => _isSaving = false);
        return;
      }

      print('🔄 Membuat event dengan gambar...');
      
      // Siapkan data event
      final eventData = {
        'judul': _judulController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'kategori': _selectedKategori,
        'lokasi': _lokasiController.text.trim(),
        'linkOnline': _linkOnlineController.text.trim(),
        'tanggal': _selectedTanggal!,
        'batasDaftar': _selectedBatasDaftar!,
        'jamMulai': _jamMulaiController.text.trim(),
        'jamSelesai': _jamSelesaiController.text.trim(),
        'kuota': kuota,
        'skkm': int.tryParse(_skkmController.text) ?? 0,
        'hargaOnline': hargaOnline,
        'hargaOffline': hargaOffline,
        'status': _selectedStatus,
      };

      // Gunakan repository untuk create event dengan gambar
      await _eventRepository.createEventWithImage(
        eventData: eventData,
        imageBytes: _posterBytes,
      );

      _showSuccess('✅ Event berhasil dibuat dengan gambar!');
      
      // Clear form
      _clearForm();
      
      // Delay dan kembali
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context);
      
    } catch (e) {
      print('❌ Error creating event: $e');
      _showError('Gagal menyimpan event: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ================= CLEAR FORM =================
  void _clearForm() {
    _judulController.clear();
    _deskripsiController.clear();
    _lokasiController.clear();
    _linkOnlineController.clear();
    _kuotaController.clear();
    _skkmController.clear();
    _hargaOnlineController.clear();
    _hargaOfflineController.clear();
    _jamMulaiController.clear();
    _jamSelesaiController.clear();
    
    setState(() {
      _selectedKategori = 'Seminar';
      _selectedStatus = 'pending';
      _selectedTanggal = null;
      _selectedBatasDaftar = null;
      _posterFile = null;
      _posterBytes = null;
      _posterFileName = null;
      
      // Reset error flags
      _errJudul = _errDeskripsi = _errTanggal = _errBatasDaftar = false;
      _errJamMulai = _errJamSelesai = _errLokasi = _errKuota = _errSKKM = false;
    });
  }

  // ================= PICKER TANGGAL =================
  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggal ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedTanggal = picked);
    }
  }

  Future<void> _pickBatasDaftar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBatasDaftar ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedBatasDaftar = picked);
    }
  }

  // ================= VALIDASI WAKTU =================
  bool _isValidTimeFormat(String time) {
    // Format HH.mm (contoh: 09.00, 14.30, 23.59)
    final timePattern = RegExp(r'^([0-1]?[0-9]|2[0-3])\.([0-5][0-9])$');
    return timePattern.hasMatch(time);
  }

  // ================= DIALOGS =================
  void _showKategoriDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Kategori'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _kategoriOptions.length,
            itemBuilder: (context, index) {
              final kategori = _kategoriOptions[index];
              return ListTile(
                title: Text(kategori),
                onTap: () {
                  setState(() => _selectedKategori = kategori);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Status'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _statusOptions.length,
            itemBuilder: (context, index) {
              final status = _statusOptions[index];
              return ListTile(
                title: Text(status),
                onTap: () {
                  setState(() => _selectedStatus = status);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Buat Event Baru',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Section 1: Poster
            _buildPosterSection(),
            const SizedBox(height: 20),

            // Section 2: Informasi Dasar
            _buildSectionCard(
              title: 'Informasi Dasar',
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Judul Event*',
                    controller: _judulController,
                    error: _errJudul,
                    hint: 'Contoh: Seminar Nasional AI',
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField(
                    label: 'Kategori*',
                    value: _selectedKategori,
                    onTap: _showKategoriDialog,
                    error: _selectedKategori.isEmpty,
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField(
                    label: 'Status',
                    value: _selectedStatus,
                    onTap: _showStatusDialog,
                  ),
                  const SizedBox(height: 12),
                  _buildTextArea(
                    label: 'Deskripsi*',
                    controller: _deskripsiController,
                    error: _errDeskripsi,
                    hint: 'Jelaskan detail event...',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 3: Waktu
            _buildSectionCard(
              title: 'Waktu Pelaksanaan',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Tanggal Event*',
                          date: _selectedTanggal,
                          onTap: _pickTanggal,
                          error: _errTanggal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          label: 'Batas Daftar*',
                          date: _selectedBatasDaftar,
                          onTap: _pickBatasDaftar,
                          error: _errBatasDaftar,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Jam Mulai*',
                          controller: _jamMulaiController,
                          error: _errJamMulai,
                          hint: 'Format: 09.00',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: 'Jam Selesai*',
                          controller: _jamSelesaiController,
                          error: _errJamSelesai,
                          hint: 'Format: 12.00',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 4: Lokasi
            _buildSectionCard(
              title: 'Tempat Acara',
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Lokasi*',
                    controller: _lokasiController,
                    error: _errLokasi,
                    hint: 'Contoh: Aula Kampus',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Link Online (Opsional)',
                    controller: _linkOnlineController,
                    hint: 'Contoh: https://zoom.us/j/123',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 5: Kuota & SKKM
            _buildSectionCard(
              title: 'Kuota & Poin',
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Kuota Peserta*',
                    controller: _kuotaController,
                    keyboardType: TextInputType.number,
                    error: _errKuota,
                    hint: 'Contoh: 75',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Poin SKKM*',
                    controller: _skkmController,
                    keyboardType: TextInputType.number,
                    error: _errSKKM,
                    hint: 'Contoh: 2',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 6: Harga
            _buildSectionCard(
              title: 'Harga Partisipasi',
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Harga Online (Rp)',
                    controller: _hargaOnlineController,
                    keyboardType: TextInputType.number,
                    hint: '0 untuk gratis',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Harga Offline (Rp)',
                    controller: _hargaOfflineController,
                    keyboardType: TextInputType.number,
                    hint: '0 untuk gratis',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _createEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'BUAT EVENT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ================= WIDGET BUILDERS =================
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPosterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Poster Event',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload gambar menarik untuk event Anda',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickPoster,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
              ),
              child: _posterBytes != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.memory(_posterBytes!, fit: BoxFit.cover)
                              : _posterFile != null
                                  ? Image.file(_posterFile!, fit: BoxFit.cover)
                                  : Container(),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (_posterFileName != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                _posterFileName!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('Klik untuk upload poster'),
                        const SizedBox(height: 4),
                        Text(
                          'Format: JPG, PNG. Maks: 5MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          if (_posterBytes != null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _posterFile = null;
                        _posterBytes = null;
                        _posterFileName = null;
                      });
                    },
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Hapus Gambar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool error = false,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: error ? Colors.red : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: error ? Colors.red : Colors.grey.shade400,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: error ? Colors.red : Colors.grey.shade400,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: error ? Colors.red : Colors.blue,
              ),
            ),
            errorText: error ? 'Field ini wajib diisi' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required String label,
    required TextEditingController controller,
    bool error = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: error ? Colors.red : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: error ? Colors.red : Colors.grey.shade400,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: error ? Colors.red : Colors.grey.shade400,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: error ? Colors.red : Colors.blue,
              ),
            ),
            errorText: error ? 'Field ini wajib diisi' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool error = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: error ? Colors.red : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: error ? Colors.red : Colors.grey.shade400,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: value.isEmpty ? Colors.grey.shade500 : Colors.black,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    DateTime? date,
    required VoidCallback onTap,
    bool error = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: error ? Colors.red : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: error ? Colors.red : Colors.grey.shade400,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date == null
                      ? 'Pilih tanggal'
                      : DateFormat('dd/MM/yyyy').format(date),
                  style: TextStyle(
                    color: date == null ? Colors.grey.shade500 : Colors.black,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}