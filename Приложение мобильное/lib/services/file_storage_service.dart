import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class FileStorageService {
  static final FileStorageService _instance = FileStorageService._internal();
  factory FileStorageService() => _instance;
  FileStorageService._internal();

  Future<String> saveImage(XFile image, {String? subFolder}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, 'images', subFolder ?? ''));
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(image.path).copy(path.join(imagesDir.path, fileName));
    
    return savedImage.path;
  }

  Future<String?> pickAndSaveImage({String? subFolder}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return null;
    return await saveImage(image, subFolder: subFolder);
  }

  Future<String?> pickAndSaveVideo({String? subFolder}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final videosDir = Directory(path.join(appDir.path, 'videos', subFolder ?? ''));
    
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }

    final file = File(result.files.single.path!);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
    final savedFile = await file.copy(path.join(videosDir.path, fileName));
    
    return savedFile.path;
  }

  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }
}