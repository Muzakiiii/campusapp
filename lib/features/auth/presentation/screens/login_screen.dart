import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/shared/widgets/custom_button.dart';
import 'package:campusapp/shared/widgets/custom_text_field.dart';
import 'package:campusapp/app/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // =========================
  // LOGIN DENGAN EMAIL (FINAL)
  // =========================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Pastikan session bersih
      await FirebaseAuth.instance.signOut();

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print('LOGIN EMAIL: $email');

      // =========================
      // 1. LOGIN FIREBASE AUTH
      // =========================
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Gagal mendapatkan user dari Firebase Auth');
      }

      final uid = user.uid;
      print('AUTH UID: $uid');

      // =========================
      // 2. AMBIL DATA USER DARI FIRESTORE (BY UID)
      // =========================
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Data user tidak ditemukan di Firestore');
      }

      final data = userDoc.data()!;
      final role = data['role'];

      print('FIRESTORE ROLE: $role');

      // =========================
      // 3. VALIDASI ROLE MAHASISWA
      // =========================
      if (role != 'mahasiswa') {
        await FirebaseAuth.instance.signOut();
        throw Exception('Akun ini bukan mahasiswa');
      }

      // =========================
      // 4. LOGIN BERHASIL
      // =========================
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        Routes.mainWrapper,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_firebaseErrorMessage(e));
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =========================
  // HELPER ERROR MESSAGE
  // =========================
  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun dinonaktifkan';
      default:
        return e.message ?? 'Login gagal';
    }
  }

  // =========================
  // DIALOG ERROR
  // =========================
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Gagal'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Mahasiswa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Text(
                'Masuk sebagai Mahasiswa',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 40),

              // =========================
              // EMAIL FIELD
              // =========================
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Masukkan email Anda',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!value.contains('@')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // =========================
              // PASSWORD FIELD
              // =========================
              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Masukkan password Anda',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              CustomButton(
                onPressed: _isLoading ? null : _login,
                text: 'Masuk',
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
