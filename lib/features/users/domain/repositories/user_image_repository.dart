abstract class UserImageRepository {
  Future<String?> uploadProfileImage({
    required String userId,
    required String filePath,
  });
}
