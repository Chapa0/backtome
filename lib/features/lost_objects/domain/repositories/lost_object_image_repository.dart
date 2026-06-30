abstract class LostObjectImageRepository {
  Future<List<String>> uploadLostObjectImages(List<String> filePaths);

  Future<String?> uploadClaimImage({
    required String objectId,
    required String filePath,
  });
}
