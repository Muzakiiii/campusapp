import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campusapp/core/themes/app_theme.dart'; // Sesuaikan import tema kamu

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String currentFaculty;
  final String currentDepartment;
  final String currentBatch;
  final String nim;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentPhone,
    required this.currentFaculty,
    required this.currentDepartment,
    required this.currentBatch,
    required this.nim,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _facultyController;
  late TextEditingController _deptController;
  late TextEditingController _batchController;

  @override
  void initState() {
    super.initState();
    // Isi field dengan data yang dikirim dari halaman profil
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _facultyController = TextEditingController(text: widget.currentFaculty);
    _deptController = TextEditingController(text: widget.currentDepartment);
    _batchController = TextEditingController(text: widget.currentBatch);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _facultyController.dispose();
    _deptController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Update ke Firestore
      // Kita konversi no_hp dan angkatan ke int agar sesuai tipe data di gambar database kamu
      // atau simpan string jika memang maunya string. Di sini saya coba parsing ke int.
      
      int? phoneParsed = int.tryParse(_phoneController.text.trim());
      int? batchParsed = int.tryParse(_batchController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'no_hp': phoneParsed ?? _phoneController.text.trim(), 
        'fakultas': _facultyController.text.trim(),
        'departemen': _deptController.text.trim(),
        'angkatan': batchParsed ?? _batchController.text.trim(),
        // NIM tidak diupdate karena itu identity unik akademik
      });

      if (mounted) {
        // Kembali ke halaman sebelumnya dengan sinyal 'true' (berhasil)
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Edit Profil', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReadOnlyField('NIM (Tidak dapat diubah)', widget.nim),
              const SizedBox(height: 20),
              
              const Text("Informasi Pribadi", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              
              _buildTextField(
                label: 'Nama Lengkap',
                controller: _nameController,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Nomor HP (WhatsApp)',
                controller: _phoneController,
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),
              const Text("Informasi Akademik", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),

              _buildTextField(
                label: 'Fakultas',
                controller: _facultyController,
                icon: Icons.apartment,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Departemen / Prodi',
                controller: _deptController,
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Angkatan',
                controller: _batchController,
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 40),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Input Field Kustom
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label tidak boleh kosong';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  // Widget Read Only untuk NIM
  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: Colors.black54
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Simpan Perubahan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}