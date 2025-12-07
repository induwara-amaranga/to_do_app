import 'package:to_do_app/data/file_meta_database.dart';

class FileRepository {
  static final helper = FileMetaDataBaseHelper();
  // Access the singleton instance of FileMetaDataBaseHelper
  FileMetaDataBaseHelper get _helper => helper;
  //enable singleton pattern
  static final FileRepository _instance = FileRepository._internal();
  FileRepository._internal();
  factory FileRepository() {
    helper.loadAllFileMetadata();
    return _instance;
  }

  //logic

  Future<void> saveFileMetaData(
    String filePath,
    Map<String, bool> metadata,
  ) async {
    await _helper.saveFile(filePath, metadata);
  }

  Future<void> changeFilePath(String oldFilePath, String newFilePath) async {
    final existingMetaData = _helper.getFile(oldFilePath);
    if (existingMetaData != null) {
      await _helper.saveFile(newFilePath, existingMetaData);
      await _helper.removeFile(oldFilePath);
    }
  }

  List<String> getAllStarredFilePaths() {
    final allMetaData = _helper.getAllFiles() ?? {};
    final starredFilePaths =
        allMetaData.entries
            .where((entry) => entry.value["isStarred"] == true)
            .map((entry) => entry.key)
            .toList();
    return starredFilePaths;
  }

  Map<String, bool>? getFileMetaData(String filePath) {
    return _helper.getFile(filePath)?.cast<String, bool>();
  }

  Future<void> toggleStar(String filepath) async {
    final existingMetaData = _helper.getFile(filepath) ?? {};
    final isStarred = existingMetaData["isStarred"] ?? false;
    existingMetaData["isStarred"] = !isStarred;
    return await _helper.updateFileMetadata(filepath, existingMetaData);
  }

  Future<void> deleteFileMetaData(String filePath) async {
    await _helper.removeFile(filePath);
  }

  bool isStarred(String path) {
    final data = getFileMetaData(path);
    if (data == null) {
      return false;
    }

    bool isStarred = data["isStarred"] ?? false;
    return isStarred;
  }
}
