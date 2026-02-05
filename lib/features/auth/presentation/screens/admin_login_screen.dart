import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/shared/widgets/custom_button.dart';
import 'package:campusapp/shared/widgets/custom_text_field.dart';
import 'package:campusapp/app/routes.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1️⃣ LOGIN FIREBASE AUTH
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;
      print("ADMIN LOGIN UID: $uid");

      // 2️⃣ CEK ROLE DI FIRESTORE
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists || doc.data()?['role'] != 'admin') {
        await FirebaseAuth.instance.signOut();
        throw Exception('Bukan akun admin');
      }

      // 3️⃣ MASUK DASHBOARD
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.adminDashboard);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Login gagal');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.error, content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Admin/Staf')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _emailController,
                labelText: 'Email Admin',
                hintText: 'admin@gmail.com',
                prefixIcon: Icons.email,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Email wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Password',
                prefixIcon: Icons.lock,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Password wajib diisi' : null,
              ),
              const SizedBox(height: 32),
              CustomButton(
                onPressed: _login,
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
