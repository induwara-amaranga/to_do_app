import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
import 'package:to_do_app/components/animated_tap_widget.dart';
import 'package:to_do_app/components/list_view_time_table_tile.dart';
import 'package:to_do_app/data/file_database_repository.dart';
import 'package:to_do_app/services/file_storage_service.dart';

class TileViewTimeTableTile extends StatelessWidget {
  final File file;
  final VoidCallback onDelete;
  final void Function(File) onRenamed;
  late FileRepository _fileRepository;

  TileViewTimeTableTile({
    super.key,
    required this.file,
    required this.onDelete,
    required this.onRenamed,
    required fileRepository,
  }) {
    this._fileRepository = fileRepository;
  }

  // Check if file is an image
  bool isImageFile() {
    final ext = p.extension(file.path).toLowerCase().replaceAll('.', '');
    return ['png', 'jpg', 'jpeg', 'webp'].contains(ext);
  }

  bool isPdfFile() {
    final ext = p.extension(file.path).toLowerCase().replaceAll('.', '');
    return ext == 'pdf';
  }

  // Icon for non-image files
  IconData getFileIcon() {
    final ext = p.extension(file.path).toLowerCase().replaceAll('.', '');
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(file.path);
    final fileSize = file.lengthSync();

    return Container(
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            border: Border.all(color: Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(8),
          ),
          width: 190,
          height: 230,

          child: Column(
            children: [
              Expanded(
                child: AnimatedTap(
                  onTap: () async {
                    // Open file or preview
                    await FileStorageService.openFile(file);
                  },
                  child:
                      isImageFile()
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox.expand(
                              child: Image.file(
                                file,
                                fit:
                                    BoxFit
                                        .cover, // fills the box, crops if needed
                              ),
                            ),
                          )
                          : isPdfFile()
                          ? FutureBuilder<Image>(
                            future: generatePdfThumbnail(file),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox.expand(child: snapshot.data!),
                                );
                              } else if (snapshot.hasError) {
                                return Icon(Icons.picture_as_pdf, size: 80);
                              } else {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                            },
                          )
                          : Icon(getFileIcon(), size: 80),
                ),
              ),
              ListViewTimeTableTile(
                file: file,
                onRenamed: onRenamed,
                onDeleted: onDelete,
                fileRepository: _fileRepository,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Image> generatePdfThumbnail(File file, {int width = 200}) async {
    final doc = await PdfDocument.openFile(file.path);
    final page = await doc.getPage(1);

    // Render page as image
    final pageImage = await page.render(
      width: 200,
      //height: 200,
      quality: 75,
      height:
          (width * page.height / page.width).toDouble(), // keep aspect ratio
      format: PdfPageImageFormat.png,
      backgroundColor: '#FFFFFF',
    );

    await page.close();
    await doc.close();

    return Image.memory(pageImage!.bytes, fit: BoxFit.cover);
  }
}
