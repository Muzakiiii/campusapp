// lib/utils/cloudinary_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // ====================
  // KONFIGURASI CLOUDINARY
  // ====================
  static const String _cloudName = 'dvf7f78gl'; // Cloud name Anda
  static const String _uploadPreset = 'ml_default'; // Upload preset
  
  // URL untuk UNSIGNED upload (tanpa API key)
  static const String _uploadUrl = 
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
  
  // ====================
  // METHOD UPLOAD (UNSIGNED)
  // ====================
  static Future<String> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    String folder = 'campusapp/payment_proofs',
  }) async {
    try {
      print('📤 Uploading to Cloudinary...');
      print('📁 Cloud Name: $_cloudName');
      print('📁 Upload Preset: $_uploadPreset');
      print('📁 File size: ${imageBytes.length} bytes');
      print('📁 File name: $fileName');
      
      // Validasi ukuran gambar (maks 10MB)
      if (imageBytes.length > 10 * 1024 * 1024) {
        throw Exception('Ukuran gambar terlalu besar (maks 10MB)');
      }
      
      // 1. BUAT MULTIPART REQUEST
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      // 2. TAMBAH FIELDS YANG DIPERLUKAN untuk UNSIGNED UPLOAD
      request.fields['upload_preset'] = _uploadPreset; // WAJIB untuk unsigned
      request.fields['folder'] = folder; // Opsional
      request.fields['public_id'] = fileName; // Opsional
      
      // 3. TAMBAH FILE GAMBAR
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ));
      
      print('🚀 Mengirim request ke Cloudinary...');
      
      // 4. KIRIM REQUEST dengan timeout
      final response = await request.send().timeout(
        Duration(seconds: 90), // Timeout lebih lama
        onTimeout: () {
          throw TimeoutException('Upload timeout setelah 90 detik');
        },
      );
      
      // 5. BACA RESPONSE
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: $responseData');
      
      // 6. CEK STATUS RESPONSE
      if (response.statusCode == 200) {
        final imageUrl = jsonResponse['secure_url'] ?? jsonResponse['url'];
        
        if (imageUrl == null) {
          print('❌ URL tidak ditemukan dalam response: $jsonResponse');
          throw Exception('URL gambar tidak ditemukan dalam response Cloudinary');
        }
        
        print('✅ Upload berhasil! URL: ${imageUrl.substring(0, 100)}...');
        return imageUrl.toString();
      } else {
        // Handle error response
        final errorMessage = jsonResponse['error']?['message'] ?? 
                            jsonResponse.toString();
        print('❌ Cloudinary error: $errorMessage');
        
        // Error messages khusus
        if (errorMessage.toString().contains('upload preset')) {
          throw Exception('Upload preset tidak ditemukan. Pastikan preset "ml_default" sudah dibuat di Cloudinary Dashboard.');
        } else if (errorMessage.toString().contains('Unauthorized')) {
          throw Exception('Akses ditolak. Periksa konfigurasi Cloudinary.');
        } else {
          throw Exception('Cloudinary error: $errorMessage');
        }
      }
      
    } on TimeoutException catch (e) {
      print('⏰ Timeout: $e');
      throw Exception('Upload timeout. Periksa koneksi internet Anda.');
    } on http.ClientException catch (e) {
      print('🌐 Network error: $e');
      throw Exception('Gagal terhubung ke Cloudinary. Cek koneksi internet.');
    } catch (e) {
      print('❌ Upload error: $e');
      rethrow;
    }
  }
  
  // ====================
  // GENERATE FILE NAME
  // ====================
  static String generateFileName({
    required String userId,
    required String paymentId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'payment_${userId.substring(0, 8)}_${paymentId.substring(0, 8)}_${timestamp}_$random.jpg';
  }
  
  // ====================
  // TEST CONNECTION
  // ====================
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/ping')
      ).timeout(Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Cloudinary connection test failed: $e');
      return false;
    }
  }
}