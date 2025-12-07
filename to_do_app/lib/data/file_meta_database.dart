import 'dart:io';

import 'package:hive/hive.dart';

class FileMetaDataBaseHelper {
  // Access Hive box
  Box get _fileMetaBox => Hive.box("fileMetaBox");

  //enable singleton pattern
  static final FileMetaDataBaseHelper _instance =
      FileMetaDataBaseHelper._internal();
  FileMetaDataBaseHelper._internal();
  factory FileMetaDataBaseHelper() {
    //loadAllFileMetadata();
    return _instance;
  }

  Map<String, Map<String, bool>> _fileMetaData = {};

  Future<void> loadAllFileMetadata() async {
    final data = _fileMetaBox.get("FILE_METADATA");
    if (data is Map) {
      _fileMetaData = data.map<String, Map<String, bool>>((key, value) {
        // convert the inner map
        final innerMap =
            value is Map
                ? value.map<String, bool>(
                  (k, v) => MapEntry(k.toString(), v == true),
                )
                : <String, bool>{};
        return MapEntry(key.toString(), innerMap);
      });
    } else {
      _fileMetaData = {};
    }
  }

  Map<String, Map<String, bool>>? getAllFiles() {
    return _fileMetaData;
  }

  Map<String, bool>? getFile(String path) {
    //final storedMetadata = _fileMetaBox.get("FILE_METADATA");
    return _fileMetaData[path];
  }

  Future<void> saveFile(String path, Map<String, bool> metadata) async {
    _fileMetaData[path] = metadata;
    await _fileMetaBox.put("FILE_METADATA", _fileMetaData);
  }

  Future<void> updateFileMetadata(
    String path,
    Map<String, bool> newMetadata,
  ) async {
    final existingMetadata = _fileMetaData[path] ?? {};
    existingMetadata.addAll(newMetadata);
    _fileMetaData[path] = existingMetadata;
    await _fileMetaBox.put("FILE_METADATA", _fileMetaData);
  }

  Future<void> removeFile(String path) async {
    _fileMetaData.remove(path);
    await _fileMetaBox.put("FILE_METADATA", _fileMetaData);
  }

  List<String> getAllKeys() {
    return _fileMetaBox.keys.cast<String>().toList();
  }

  void deleteKey(String key) {
    _fileMetaBox.delete(key);
  }
}
