import 'dart:io';
import 'package:flutter/material.dart';
import 'package:to_do_app/components/picked_file_tile.dart';
import 'package:to_do_app/services/file_storage_service.dart';
//import 'package:pdf_render/pdf_render.dart';

class PickTimetableDialog extends StatefulWidget {
  final List<File>? pickedFiles;
  final VoidCallback onFIlesPicked;
  const PickTimetableDialog({
    super.key,
    required this.pickedFiles,
    required this.onFIlesPicked,
  });

  @override
  State<PickTimetableDialog> createState() => _PickTimetableDialogState();
}

class _PickTimetableDialogState extends State<PickTimetableDialog> {
  List<File> files = [];

  @override
  void initState() {
    super.initState();
    if (widget.pickedFiles != null) {
      files = widget.pickedFiles!;
    }
  }

  // // Generate PDF thumbnail as Image.memory
  // Future<Widget> _buildPdfThumbnail(File file) async {
  //   final doc = await PdfDocument.openFile(file.path);
  //   final page = await doc.getPage(1);
  //   final pageImage = await page.render(width: 150, height: 200);
  //   //await page.close();
  //   //await doc.close();
  //   return Image.memory(pageImage.pixels, fit: BoxFit.cover);
  // }

  // Widget _buildFilePreview(File file) {
  //   if (file.path.toLowerCase().endsWith('.pdf')) {
  //     return FutureBuilder<Widget>(
  //       future: _buildPdfThumbnail(file),
  //       builder: (context, snapshot) {
  //         if (snapshot.connectionState == ConnectionState.waiting) {
  //           return Container(
  //             color: Colors.grey[200],
  //             child: Center(
  //               child: Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
  //             ),
  //           );
  //         }
  //         return snapshot.data!;
  //       },
  //     );
  //   } else {
  //     return Image.file(file, fit: BoxFit.cover);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        padding: EdgeInsets.all(16),
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Center(
              child: Text(
                "Select Timetable Files",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Supported file types : ${FileStorageService.allowedExtensions.join(" , ")} ",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 12),

            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text("Add Files"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 45),
              ),
              onPressed: () async {
                final picked = await FileStorageService.pickTimetableFiles();
                if (picked != null && picked.isNotEmpty) {
                  setState(() {
                    files.addAll(picked);
                  });
                }
              },
            ),
            SizedBox(height: 16),
            if (files.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 250,
                //width: 200,
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: PickedFileTile(pickedFile: file),
                    );
                  },
                ),
              ),
            SizedBox(height: 12),

            Row(children: [Text("${files.length} file(s) selected")]),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onFIlesPicked();

                    //widget.pickedFiles?.clear();
                    Navigator.pop(context, files);
                  },
                  child: Text("Done"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
