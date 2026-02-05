import 'package:flutter/material.dart';
import 'package:campusapp/shared/widgets/custom_button.dart';
import 'package:campusapp/features/events/domain/models/event_model.dart';
import 'package:campusapp/features/admin/data/repositories/admin_event_repository.dart';
import 'package:intl/intl.dart';

class AdminEditEventScreen extends StatefulWidget {
  final String eventId;

  const AdminEditEventScreen({super.key, required this.eventId});

  @override
  State<AdminEditEventScreen> createState() => _AdminEditEventScreenState();
}

class _AdminEditEventScreenState extends State<AdminEditEventScreen> {
  final AdminEventRepository _eventRepository = AdminEventRepository();
  final _formKey = GlobalKey<FormState>();

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
  EventModel? _event;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedKategori;
  String? _selectedStatus;
  DateTime? _selectedTanggal;
  DateTime? _selectedBatasDaftar;

  // Dropdown options
  final List<String> _kategoriOptions = [
    'Seminar',
    'Workshop',
    'Pelatihan',
    'Lomba',
    'Webinar',
    'Lainnya'
  ];

  final List<String> _statusOptions = [
    'pending',
    'active',
    'cancelled',
    'completed'
  ];

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  // =======================
  // LOAD EVENT
  // =======================
  Future<void> _loadEvent() async {
    try {
      final event = await _eventRepository.getEventById(widget.eventId);

      if (event == null) {
        _showError('Event tidak ditemukan');
        Navigator.pop(context);
        return;
      }

      setState(() {
        _event = event;
        _selectedKategori = event.kategori;
        _selectedStatus = event.status;
        _selectedTanggal = event.tanggal;
        _selectedBatasDaftar = event.batasDaftar;

        // Set controller values
        _judulController.text = event.judul;
        _deskripsiController.text = event.deskripsi;
        _lokasiController.text = event.lokasi;
        _linkOnlineController.text = event.linkOnline;
        _kuotaController.text = event.kuota.toString();
        _skkmController.text = event.skkm.toString();
        _hargaOnlineController.text = event.hargaOnline.toString();
        _hargaOfflineController.text = event.hargaOffline.toString();
        _jamMulaiController.text = event.jamMulai;
        _jamSelesaiController.text = event.jamSelesai;

        _isLoading = false;
      });
    } catch (e) {
      _showError('Gagal memuat data event: $e');
      Navigator.pop(context);
    }
  }

  // =======================
  // UPDATE EVENT
  // =======================
  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate() || _event == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedEvent = _event!.copyWith(
        judul: _judulController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        kategori: _selectedKategori ?? _event!.kategori,
        lokasi: _lokasiController.text.trim(),
        linkOnline: _linkOnlineController.text.trim(),
        tanggal: _selectedTanggal ?? _event!.tanggal,
        batasDaftar: _selectedBatasDaftar ?? _event!.batasDaftar,
        jamMulai: _jamMulaiController.text.trim(),
        jamSelesai: _jamSelesaiController.text.trim(),
        kuota: int.tryParse(_kuotaController.text) ?? _event!.kuota,
        skkm: int.tryParse(_skkmController.text) ?? _event!.skkm,
        hargaOnline: int.tryParse(_hargaOnlineController.text) ?? _event!.hargaOnline,
        hargaOffline: int.tryParse(_hargaOfflineController.text) ?? _event!.hargaOffline,
        status: _selectedStatus ?? _event!.status,
        updatedAt: DateTime.now(),
      );

      await _eventRepository.updateEvent(updatedEvent);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Gagal memperbarui event: $e');
    }
  }

  // =======================
  // DATE PICKERS
  // =======================
  Future<void> _selectTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggal ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedTanggal = picked);
    }
  }

  Future<void> _selectBatasDaftar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBatasDaftar ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedBatasDaftar = picked);
    }
  }

  // =======================
  // SHOW DIALOGS
  // =======================
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =======================
  // DISPOSE
  // =======================
  @override
  void dispose() {
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

  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _updateEvent,
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Judul Event
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul Event',
                  border: OutlineInputBorder(),
                ),
                validator: (harga) => harga == null || harga.isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Kategori dan Status
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        hintText: _selectedKategori ?? 'Pilih kategori',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      onTap: _showKategoriDialog,
                      validator: (_) => _selectedKategori == null ? 'Pilih kategori' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        hintText: _selectedStatus ?? 'Pilih status',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      onTap: _showStatusDialog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Deskripsi
              TextFormField(
                controller: _deskripsiController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Tanggal dan Batas Daftar
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectTanggal,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Tanggal Event',
                            hintText: _selectedTanggal == null
                                ? 'Pilih tanggal'
                                : DateFormat('dd/MM/yyyy').format(_selectedTanggal!),
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          validator: (_) => _selectedTanggal == null ? 'Pilih tanggal event' : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectBatasDaftar,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Batas Daftar',
                            hintText: _selectedBatasDaftar == null
                                ? 'Pilih batas daftar'
                                : DateFormat('dd/MM/yyyy').format(_selectedBatasDaftar!),
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          validator: (_) => _selectedBatasDaftar == null ? 'Pilih batas daftar' : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Jam Mulai dan Selesai
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _jamMulaiController,
                      decoration: const InputDecoration(
                        labelText: 'Jam Mulai',
                        hintText: 'Contoh: 09.00',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Jam mulai wajib diisi';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _jamSelesaiController,
                      decoration: const InputDecoration(
                        labelText: 'Jam Selesai',
                        hintText: 'Contoh: 12.00',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Jam selesai wajib diisi';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lokasi
              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Lokasi wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Link Online
              TextFormField(
                controller: _linkOnlineController,
                decoration: const InputDecoration(
                  labelText: 'Link Online (Opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Kuota dan SKKM
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _kuotaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kuota',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Kuota wajib diisi';
                        final kuota = int.tryParse(v);
                        if (kuota == null || kuota <= 0) return 'Kuota harus > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _skkmController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Poin SKKM',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Poin SKKM wajib diisi';
                        final skkm = int.tryParse(v);
                        if (skkm == null || skkm < 0) return 'Poin SKKM harus >= 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Harga Online dan Offline
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hargaOnlineController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Online (Rp)',
                        hintText: '0 untuk gratis',
                        border: OutlineInputBorder(),
                      ),
                      validator: (harga) {
                        if (harga == null || harga.isEmpty) return 'Harga online wajib diisi';
                        final hargaValue = int.tryParse(harga);
                        if (hargaValue == null || hargaValue < 0) return 'Harga tidak valid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _hargaOfflineController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Offline (Rp)',
                        hintText: '0 untuk gratis',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Harga offline wajib diisi';
                        final harga = int.tryParse(v);
                        if (harga == null || harga < 0) return 'Harga tidak valid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              CustomButton(
                onPressed: _isSaving ? null : _updateEvent,
                isLoading: _isSaving,
                text: 'Simpan Perubahan',
                backgroundColor: Colors.blue,
                textColor: Colors.white,
              ),
              const SizedBox(height: 16),

              // Cancel Button
              OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Danger Zone
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zona Berbahaya',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tindakan ini tidak dapat dibatalkan. Event yang dihapus tidak dapat dikembalikan.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showDeleteConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.red.shade300),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Hapus Event'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =======================
  // DELETE EVENT
  // =======================
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Event'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus event ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent() async {
    setState(() => _isSaving = true);

    try {
      await _eventRepository.deleteEvent(widget.eventId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event berhasil dihapus!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Gagal menghapus event: $e');
    }
  }
}