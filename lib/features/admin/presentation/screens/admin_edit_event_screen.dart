import 'package:flutter/material.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/shared/widgets/custom_button.dart';
import 'package:campusapp/features/events/domain/models/event_model.dart';
import 'package:campusapp/features/admin/data/repositories/admin_event_repository.dart';

class AdminEditEventScreen extends StatefulWidget {
  final String eventId;

  const AdminEditEventScreen({super.key, required this.eventId});

  @override
  State<AdminEditEventScreen> createState() =>
      _AdminEditEventScreenState();
}

class _AdminEditEventScreenState
    extends State<AdminEditEventScreen> {
  final AdminEventRepository _eventRepository =
      AdminEventRepository();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _priceController = TextEditingController();
  final _skkmController = TextEditingController();
  final _capacityController = TextEditingController();

  EventModel? _event;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedCategory;
  DateTime? _selectedDate;

  final List<String> _categories = [
    'Teknologi',
    'Kesehatan',
    'Kepemimpinan',
    'Seni & Budaya',
    'Olahraga',
    'Bisnis',
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
      final event =
          await _eventRepository.getEventById(widget.eventId);

      if (event == null) {
        _showError('Event tidak ditemukan');
        Navigator.pop(context);
        return;
      }

      setState(() {
        _event = event;
        _selectedCategory = event.kategori;
        _selectedDate = event.tanggal;

        _titleController.text = event.judul;
        _descriptionController.text = event.deskripsi;
        _locationController.text = event.lokasi;
        _imageUrlController.text = event.posterUrl;
        _dateController.text = event.dateText;
        _timeController.text = event.jamMulai;
        _priceController.text = event.hargaOnline.toStringAsFixed(0);
        _skkmController.text = event.skkm.toString();
        _capacityController.text = event.kuota.toString();

        _isLoading = false;
      });
    } catch (e) {
      _showError('Gagal memuat data event');
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    _skkmController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  // =======================
  // UPDATE EVENT
  // =======================
  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate() ||
        _event == null ||
        _selectedDate == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedEvent = EventModel(
        id: _event!.id,
        judul: _titleController.text.trim(),
        deskripsi: _descriptionController.text.trim(),
        kategori: _selectedCategory ?? _event!.kategori,
        lokasi: _locationController.text.trim(),
        posterUrl: _imageUrlController.text.trim(),

        tanggal: _selectedDate!,
        batasDaftar: _selectedDate!, // sementara samakan

        jamMulai: _timeController.text.trim(),
        jamSelesai: _event!.jamSelesai,

        kuota: int.tryParse(_capacityController.text) ?? 0,
        jumlahPendaftar: _event!.jumlahPendaftar,
        skkm: int.tryParse(_skkmController.text) ?? 0,

        hargaOnline:
            double.tryParse(_priceController.text) ?? 0,
        hargaOffline: _event!.hargaOffline,

        linkOnline: _event!.linkOnline,
        status: _event!.status,

        isBookmarked: _event!.isBookmarked,
      );

      await _eventRepository.updateEvent(updatedEvent);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event berhasil diperbarui!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);

      _showError('Gagal memperbarui event');
    }
  }

  // =======================
  // DATE & TIME
  // =======================
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _selectedDate = picked;
      _dateController.text =
          '${picked.day}/${picked.month}/${picked.year}';
      setState(() {});
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      _timeController.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  // =======================
  // CATEGORY
  // =======================
  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Kategori'),
        content: ListView.builder(
          shrinkWrap: true,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return ListTile(
              title: Text(category),
              onTap: () {
                setState(() => _selectedCategory = category);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
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
      appBar: AppBar(title: const Text('Edit Event')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration:
                    const InputDecoration(labelText: 'Judul Event'),
                validator: (v) =>
                    v == null || v.isEmpty
                        ? 'Judul wajib diisi'
                        : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration:
                    const InputDecoration(labelText: 'Deskripsi'),
                validator: (v) =>
                    v == null || v.isEmpty
                        ? 'Deskripsi wajib diisi'
                        : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  hintText:
                      _selectedCategory ?? 'Pilih kategori',
                  suffixIcon:
                      const Icon(Icons.arrow_drop_down),
                ),
                onTap: _showCategoryDialog,
                validator: (_) =>
                    _selectedCategory == null
                        ? 'Pilih kategori'
                        : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                          labelText: 'Tanggal'),
                      onTap: _selectDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                          labelText: 'Jam Mulai'),
                      onTap: _selectTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration:
                    const InputDecoration(labelText: 'Lokasi'),
                validator: (v) =>
                    v == null || v.isEmpty
                        ? 'Lokasi wajib diisi'
                        : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                    labelText: 'URL Poster'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Harga Online'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _skkmController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'SKKM'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Kuota'),
              ),
              const SizedBox(height: 32),

              CustomButton(
                onPressed: _isSaving ? () {} : _updateEvent,
                text: 'Simpan Perubahan',
                isLoading: _isSaving,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
