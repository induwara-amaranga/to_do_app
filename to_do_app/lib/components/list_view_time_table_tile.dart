import 'dart:ffi';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:to_do_app/components/rename_file_dialog.dart';
import 'package:to_do_app/data/file_database_repository.dart';
import 'package:to_do_app/services/file_storage_service.dart';

class ListViewTimeTableTile extends StatefulWidget {
  final File file;
  final void Function(File) onRenamed;
  final VoidCallback onDeleted;
  late FileRepository _fileRepository;
  ListViewTimeTableTile({
    super.key,
    required this.file,
    required this.onRenamed,
    required this.onDeleted,
    required fileRepository,
  }) {
    this._fileRepository = fileRepository;
  }

  @override
  State<ListViewTimeTableTile> createState() => _ListViewTimeTableTileState();
}

class _ListViewTimeTableTileState extends State<ListViewTimeTableTile> {
  late FileRepository _repo;
  late File file;
  bool _isStarred = false;
  String fileName = "";
  String fileExtension = "";
  int fileSize = 0;
  IconData fileIcon = Icons.insert_drive_file;
  @override
  void initState() {
    super.initState();
    _repo = widget._fileRepository;
    _loadFileDetails();
    _isStarred = _repo.isStarred(file.path);
  }

  Future<void> _loadFileDetails() async {
    file = widget.file;
    fileName = p.basename(file.path);
    fileExtension = p.extension(file.path).replaceFirst('.', '');
    final stat = await file.stat();
    fileSize = stat.size;
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        fileIcon = Icons.picture_as_pdf;
        break;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        fileIcon = Icons.image;
        break;
      case 'doc':
      case 'docx':
        fileIcon = Icons.description;
        break;
      case 'xls':
      case 'xlsx':
        fileIcon = Icons.table_chart;
        break;
      case 'txt':
        fileIcon = Icons.text_snippet;
        break;
      default:
        fileIcon = Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.grey.withOpacity(0.5),
          //     spreadRadius: 2,
          //     blurRadius: 5,
          //     offset: Offset(0, 3),
          //   ),
          // ],
          borderRadius: BorderRadius.circular(8),
          border: Border(
            bottom: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          color: Theme.of(context).colorScheme.secondary,
        ),
        padding: EdgeInsets.all(8),

        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),

                splashColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.2),
                radius: 30,
                onTap: () async {
                  // Implement file open functionality
                  await FileStorageService.openFile(widget.file);
                },
                child: Row(
                  //mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      fileIcon,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$fileSize bytes",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    _isStarred
                        ? Icon(Icons.star, color: Colors.amber)
                        : SizedBox.shrink(),
                  ],
                ),
              ),
            ),

            //Spacer(),
            PopupMenuButton<String>(
              onSelected: (String value) async {
                switch (value) {
                  case 'star':
                    _repo.toggleStar(file.path);
                    setState(() {
                      _isStarred = !_isStarred;
                    });
                    break;
                  case 'share':
                    // Implement share functionality
                    await FileStorageService.shareFile(file.path);
                    break;
                  case 'rename':
                    // Implement rename functionality
                    String newName = fileName;

                    final reName = await showDialog(
                      context: context,
                      builder: (context) {
                        String newName = fileName; // initialize ONCE

                        return RenameFileDialog(
                          newName: newName,
                          extension: fileExtension,
                        );
                      },
                    );
                    if (reName == null || reName == fileName) {
                      return; // User cancelled or no change
                    }
                    newName = reName;

                    file = await FileStorageService.renameOnlyFileName(
                      file.path,
                      newName,
                    );

                    widget.onRenamed?.call(file);
                    //setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('File Renamed')));
                    }
                    break;
                  case 'delete':

                    // Implement delete functionality
                    FileStorageService.deleteFile(file);
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('File deleted')));
                    }
                    widget.onDeleted?.call();

                    break;
                }
              },
              itemBuilder:
                  (context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(child: Text("Star"), value: "star"),
                    PopupMenuItem<String>(child: Text("Share"), value: "share"),
                    PopupMenuItem<String>(
                      child: Text("Rename"),
                      value: "rename",
                    ),
                    PopupMenuItem<String>(
                      child: Text("Delete"),
                      value: "delete",
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }
}
