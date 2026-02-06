// lib/utils/cloudinary_helper.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryHelper {
  static const String _cloudName = 'YOUR_CLOUD_NAME'; // 🔧 GANTI
  static const String _uploadPreset = 'ml_default';
  
  static Future<String> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    String folder = 'campusapp/payment_proofs',
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );
      
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;
      request.fields['public_id'] = fileName;
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ));
      
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseString);
      
      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Upload failed: ${jsonResponse['error']['message']}');
      }
    } catch (e) {
      throw Exception('Cloudinary upload error: $e');
    }
  }
}