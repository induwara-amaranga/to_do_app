import 'package:flutter/material.dart';

class AddSubTaskDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final DateTime dueDate;
  final DateTime dueTime;
  const AddSubTaskDialog({
    super.key,
    required this.onAdd,
    required this.dueDate,
    required this.dueTime,
  });

  @override
  State<AddSubTaskDialog> createState() => _AddSubTaskDialogState();
}

class _AddSubTaskDialogState extends State<AddSubTaskDialog> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _subDueDate;
  DateTime? _subDueTime;
  @override
  initState() {
    super.initState();
    _subDueDate = widget.dueDate;
    _subDueTime = widget.dueTime;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Subtask"),
      content: Column(
        //mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Subtask Name"),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: _subDueDate ?? DateTime.now(),
              );
              if (picked != null) setState(() => _subDueDate = picked);
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text("Select Due Date"),
          ),
          TextButton.icon(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime:
                    TimeOfDay(
                      hour: _subDueTime!.hour,
                      minute: _subDueTime!.minute,
                    ) ??
                    TimeOfDay.now(),
              );
              if (picked != null) {
                final now = DateTime.now();
                setState(() {
                  _subDueTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    picked.hour,
                    picked.minute,
                  );
                });
              }
            },
            icon: const Icon(Icons.access_time),
            label: const Text("Select Due Time"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onAdd({
                "name": _nameController.text,
                "dueDate": _subDueDate?.toIso8601String(),
                "dueTime": _subDueTime?.toIso8601String(),
                "completed": false,
              });
              Navigator.pop(context);
            }
          },
          child: const Text("Add"),
        ),
      ],
    );
  }
}
