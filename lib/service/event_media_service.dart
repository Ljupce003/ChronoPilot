import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class EventMediaService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    return _persistPickedFile(picked);
  }

  Future<String?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    return _persistPickedFile(picked);
  }

  Future<String?> _persistPickedFile(XFile? picked) async {
    if (picked == null) {
      return null;
    }

    final directory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory(p.join(directory.path, 'event_images'));
    if (!await imagesDirectory.exists()) {
      await imagesDirectory.create(recursive: true);
    }

    final extension = p.extension(picked.path).isNotEmpty ? p.extension(picked.path) : '.jpg';
    final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}$extension';
    final savedPath = p.join(imagesDirectory.path, fileName);

    final savedFile = await File(picked.path).copy(savedPath);
    return savedFile.path;
  }
}

