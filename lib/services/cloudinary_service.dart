import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dfkirrpkz';
  // Create an unsigned upload preset in Cloudinary Dashboard:
  // Settings → Upload → Upload Presets → Add Unsigned Preset
  // Then paste the preset name below.
  static const String uploadPreset = 'mezz_unsigned';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );

      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        return data['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
