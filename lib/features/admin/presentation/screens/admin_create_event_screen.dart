import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminCreateEventScreen extends StatefulWidget {
  const AdminCreateEventScreen({super.key});

  @override
  State<AdminCreateEventScreen> createState() =>
      _AdminCreateEventScreenState();
}

class _AdminCreateEventScreenState extends State<AdminCreateEventScreen> {
  final _scrollController = ScrollController();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkController = TextEditingController();
  final _quotaController = TextEditingController();
  final _skkmController = TextEditingController();
  final _offlinePriceController = TextEditingController();
  final _onlinePriceController = TextEditingController();

  String _selectedCategory = 'Seminar';
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _deadline;

  File? _posterFile;
  Uint8List? _posterWeb;

  bool _isSaving = false;

  // ERROR FLAGS
  bool _errName = false;
  bool _errDesc = false;
  bool _errDate = false;
  bool _errStart = false;
  bool _errEnd = false;
  bool _errLocation = false;
  bool _errQuota = false;
  bool _errDeadline = false;
  bool _errSkkm = false;

  // ================= PICK POSTER =================
  Future<void> _pickPoster() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked =
          await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _posterWeb = bytes;
          _posterFile = null;
        });
      } else {
        setState(() {
          _posterFile = File(picked.path);
          _posterWeb = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memilih gambar')),
      );
    }
  }

  // ================= VALIDATE & SCROLL =================
  bool _validateForm() {
    setState(() {
      _errName = _nameController.text.isEmpty;
      _errDesc = _descController.text.isEmpty;
      _errDate = _selectedDate == null;
      _errStart = _startTime == null;
      _errEnd = _endTime == null;
      _errLocation = _locationController.text.isEmpty;
      _errQuota = _quotaController.text.isEmpty;
      _errDeadline = _deadline == null;
      _errSkkm = _skkmController.text.isEmpty;
    });

    if (_errName ||
        _errDesc ||
        _errDate ||
        _errStart ||
        _errEnd ||
        _errLocation ||
        _errQuota ||
        _errDeadline ||
        _errSkkm) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return false;
    }
    return true;
  }

  // ================= CREATE EVENT =================
Future<void> _createEvent() async {
  if (!_validateForm()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lengkapi semua field wajib')),
    );
    return;
  }

  setState(() => _isSaving = true);

  try {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('events').add({
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'category': _selectedCategory,
      'date': Timestamp.fromDate(_selectedDate!),
      'startTime': _startTime!.format(context),
      'endTime': _endTime!.format(context),
      'location': _locationController.text.trim(),
      'onlineLink': _linkController.text.trim(),
      'quota': int.tryParse(_quotaController.text) ?? 0,
      'deadline': Timestamp.fromDate(_deadline!),
      'skkm': int.tryParse(_skkmController.text) ?? 0,
      'offlinePrice': int.tryParse(_offlinePriceController.text) ?? 0,
      'onlinePrice': int.tryParse(_onlinePriceController.text) ?? 0,
      'posterUrl': '', // BELUM upload image
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event berhasil dibuat')),
    );

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal menyimpan event: $e')),
    );
  } finally {
    setState(() => _isSaving = false);
  }
}

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Buat Acara Baru',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionCard(
              title: 'Informasi Dasar',
              child: Column(
                children: [
                  _input('Nama Acara', _nameController, error: _errName),
                  _dropdown(),
                  _multiline('Deskripsi', _descController,
                      error: _errDesc),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _sectionCard(
              title: 'Waktu',
              child: Column(
                children: [
                  _dateField('Tanggal', _selectedDate,
                      error: _errDate, onTap: _pickDate),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _timeField('Jam Mulai', _startTime,
                            error: _errStart,
                            onTap: _pickStartTime),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timeField('Jam Selesai', _endTime,
                            error: _errEnd,
                            onTap: _pickEndTime),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _sectionCard(
              title: 'Tempat Acara',
              child: Column(
                children: [
                  _input('Lokasi Offline', _locationController,
                      error: _errLocation),
                  _input('Link Online', _linkController),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _sectionCard(
              title: 'Informasi Tambahan',
              child: Column(
                children: [
                  _input('Kuota Peserta', _quotaController,
                      keyboardType: TextInputType.number,
                      error: _errQuota),
                  _dateField('Batas Waktu Daftar', _deadline,
                      error: _errDeadline, onTap: _pickDeadline),
                  _input('Poin SKKM', _skkmController,
                      keyboardType: TextInputType.number,
                      error: _errSkkm),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _sectionCard(
              title: 'Atur Harga Partisipasi',
              child: Row(
                children: [
                  Expanded(
                      child: _input(
                          'Harga Offline', _offlinePriceController)),
                  const SizedBox(width: 12),
                  Expanded(
                      child:
                          _input('Harga Online', _onlinePriceController)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ================= MEDIA =================
            _sectionCard(
              title: 'Media',
              child: GestureDetector(
                onTap: _pickPoster,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      if (_posterWeb != null)
                        Image.memory(_posterWeb!, height: 140)
                      else if (_posterFile != null)
                        Image.file(_posterFile!, height: 140)
                      else
                        const Icon(Icons.upload_outlined, size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'Seret & lepas poster acara di sini, atau',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _pickPoster,
                        child: const Text('Pilih File'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= CREATE EVENT =================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _createEvent,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'CREATE EVENT',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController c,
      {TextInputType? keyboardType, bool error = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: error ? Colors.red : Colors.grey)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: error ? Colors.red : Colors.grey)),
          ),
        ),
      ]),
    );
  }

  Widget _multiline(String label, TextEditingController c,
      {bool error = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label),
      const SizedBox(height: 6),
      TextField(
        controller: c,
        maxLines: 4,
        decoration: InputDecoration(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: error ? Colors.red : Colors.grey)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: error ? Colors.red : Colors.grey)),
        ),
      ),
    ]);
  }

  Widget _dropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        items: const [
          DropdownMenuItem(value: 'Seminar', child: Text('Seminar')),
          DropdownMenuItem(value: 'Workshop', child: Text('Workshop')),
          DropdownMenuItem(value: 'Webinar', child: Text('Webinar')),
        ],
        onChanged: (v) => setState(() => _selectedCategory = v!),
        decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value,
      {required VoidCallback onTap, bool error = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: error ? Colors.red : Colors.grey)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: error ? Colors.red : Colors.grey)),
          ),
          child: Text(
            value == null
                ? '-'
                : '${value.day}/${value.month}/${value.year}',
          ),
        ),
      ),
    ]);
  }

  Widget _timeField(String label, TimeOfDay? value,
      {required VoidCallback onTap, bool error = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: error ? Colors.red : Colors.grey)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: error ? Colors.red : Colors.grey)),
          ),
          child: Text(value == null ? '00:00' : value.format(context)),
        ),
      ),
    ]);
  }

  // ================= PICKERS =================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (picked != null) setState(() => _deadline = picked);
  }
}
