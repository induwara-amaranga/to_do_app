import 'dart:io';

import 'package:flutter/material.dart';

class PickedFileTile extends StatelessWidget {
  final File? pickedFile;
  const PickedFileTile({super.key, required this.pickedFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      //width: double.infinity,
      //height: 100,
      child: ListTile(
        tileColor: Theme.of(context).colorScheme.secondary,
        leading: Icon(Icons.insert_drive_file),
        title: Text(pickedFile!.path.split('/').last),
        subtitle: Text("${pickedFile!.lengthSync()} bytes"),
        trailing: IconButton(icon: Icon(Icons.close), onPressed: () {}),
      ),
    );
  }
}
