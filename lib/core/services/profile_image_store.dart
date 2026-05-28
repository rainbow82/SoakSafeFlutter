import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores profile photos in app-private storage (`profile_images/{userId}.jpg`).
abstract final class ProfileImageStore {
  static const _subdir = 'profile_images';

  static Future<File> imageFile(int userId) async {
    final dir = await _profileDir();
    return File(p.join(dir.path, '$userId.jpg'));
  }

  static Future<bool> hasImage(int userId) async {
    final file = await imageFile(userId);
    return file.existsSync() && file.lengthSync() > 0;
  }

  static Future<bool> saveFromPicker(int userId, XFile source) async {
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) return false;
    final out = await imageFile(userId);
    await out.parent.create(recursive: true);
    await out.writeAsBytes(bytes, flush: true);
    return true;
  }

  static Future<void> delete(int userId) async {
    final file = await imageFile(userId);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  static Future<Directory> _profileDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _subdir));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
