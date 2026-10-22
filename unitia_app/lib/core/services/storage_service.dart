import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Abre galería o cámara y sube la imagen a Firebase Storage.
  /// Retorna la URL de descarga o null si el usuario canceló.
  Future<String?> pickAndUpload({
    required String path,
    ImageSource source = ImageSource.gallery,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final ref = _storage.ref().child(path);
    await ref.putFile(File(picked.path));
    return await ref.getDownloadURL();
  }
}
