import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../network/edu_api_service.dart';
import 'sound_service.dart';

class UploadedFileInfo {
  final String url;
  final String name;
  final int size;

  const UploadedFileInfo({
    required this.url,
    required this.name,
    required this.size,
  });
}

class UploadService {
  UploadService._();

  static final ImagePicker _imagePicker = ImagePicker();

  /// التقاط أو اختيار صورة من المعرض ورفعها فوراً للتخزين السحابي
  static Future<String?> pickAndUploadImage({
    ImageSource source = ImageSource.gallery,
    String folder = 'general',
    int imageQuality = 85,
  }) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );

      if (picked == null) return null;

      SoundService.lightImpact();
      final bytes = await picked.readAsBytes();
      final name = picked.name.isNotEmpty
          ? picked.name
          : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final url = await EduApiService().uploadImageFile(
        bytes,
        folder: folder,
        customFileName: name,
      );

      if (url != null && url.isNotEmpty) {
        SoundService.successFeedback();
        return url;
      }
      return null;
    } catch (e) {
      SoundService.errorFeedback();
      debugPrint('Error in pickAndUploadImage: $e');
      rethrow;
    }
  }

  /// اختيار ملف أو مستند (PDF / ملازم / مرفقات) ورفعه للتخزين السحابي
  static Future<UploadedFileInfo?> pickAndUploadDocument({
    List<String> allowedExtensions = const ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'zip'],
    String folder = 'materials',
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final fileName = file.name;
      final fileSize = file.size;

      SoundService.lightImpact();

      String? url;
      if (file.bytes != null) {
        url = await EduApiService().uploadImageFile(
          file.bytes!,
          folder: folder,
          customFileName: fileName,
        );
      } else if (file.path != null) {
        url = await EduApiService().uploadImageFile(
          File(file.path!),
          folder: folder,
          customFileName: fileName,
        );
      }

      if (url != null && url.isNotEmpty) {
        SoundService.successFeedback();
        return UploadedFileInfo(
          url: url,
          name: fileName,
          size: fileSize,
        );
      }
      return null;
    } catch (e) {
      SoundService.errorFeedback();
      debugPrint('Error in pickAndUploadDocument: $e');
      rethrow;
    }
  }
}
