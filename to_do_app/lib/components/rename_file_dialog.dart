import 'package:flutter/material.dart';

class RenameFileDialog extends StatelessWidget {
  String newName;
  String extension;
  List<String> nameList = [];
  RenameFileDialog({
    super.key,
    required this.newName,
    required this.extension,
  }) {
    nameList = newName.split('.');
    nameList.removeLast();
    newName = nameList.join('.');
  }

  @override
  Widget build(BuildContext context) {
    //name = newName.split('.').removeLast();
    return AlertDialog(
      title: Text("Rename File"),
      content: TextField(
        controller: TextEditingController(text: newName),
        autofocus: true,
        decoration: InputDecoration(labelText: "New file name"),
        onChanged: (value) {
          newName = value;
        },
      ),
      actions: [
        TextButton(
          child: Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text("Rename"),
          onPressed: () {
            String fullName = <String>[newName, '.', extension].join();
            Navigator.pop(context, fullName);
          },
        ),
      ],
    );
  }
}
