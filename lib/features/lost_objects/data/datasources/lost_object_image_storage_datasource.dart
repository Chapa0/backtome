import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class LostObjectImageStorageDataSource {
  final FirebaseStorage _storage;

  LostObjectImageStorageDataSource({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<List<String>> uploadLostObjectImages(List<String> filePaths) async {
    final urls = <String>[];
    for (var i = 0; i < filePaths.length; i++) {
      final fileName =
          'lost_objects/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final url = await _uploadImage(
        filePath: filePaths[i],
        storagePath: fileName,
      );
      urls.add(url);
    }
    return urls;
  }

  Future<String?> uploadClaimImage({
    required String objectId,
    required String filePath,
  }) {
    return _uploadImage(
      filePath: filePath,
      storagePath:
          'reclamaciones/$objectId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<String> _uploadImage({
    required String filePath,
    required String storagePath,
  }) async {
    final storageRef = _storage.ref().child(storagePath);
    final uploadTask = await storageRef.putFile(
      File(filePath),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return uploadTask.ref.getDownloadURL();
  }
}
