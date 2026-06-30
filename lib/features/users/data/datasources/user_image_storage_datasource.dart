import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class UserImageStorageDataSource {
  final FirebaseStorage _storage;

  UserImageStorageDataSource({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String?> uploadProfileImage({
    required String userId,
    required String filePath,
  }) async {
    final storageRef = _storage.ref().child('user_images').child('$userId.jpg');
    final uploadTask = storageRef.putFile(
      File(filePath),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    await uploadTask.whenComplete(() => null);
    return storageRef.getDownloadURL();
  }
}
