import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:to_do_app/services/import_from_ics.dart';
import '../data/database.dart';

class ImportICSPage extends StatefulWidget {
  const ImportICSPage({super.key});

  @override
  State<ImportICSPage> createState() => _ImportICSPageState();
}

class _ImportICSPageState extends State<ImportICSPage> {
  List<String> repeatTypes = ["none", "daily", "weekly", "monthly", "yearly"];
  List<String> priorityTypes = ["Low", "Medium", "High"];
  List<String> remainderTypes = ["minutes", "hours", "days", "weeks", "none"];
  String _selectedPriority = "Low";

  bool _isStarred = false;

  String _selectedCategory = "None";

  String _selectedRepeatType = "none";

  String _selectedRemainderType = "none";

  TextEditingController remainderAmountController = TextEditingController(
    text: "10",
  );
  List<Map<String, dynamic>> _parsedTasks = [];
  bool _isLoading = false;
  bool _importFailed = false;
  final db = ToDoDataBase();

  Future<void> _handlePickAndParse() async {
    setState(() => _isLoading = true);
    final parsed = await ImportFromIcsService.pickAndParseICS();
    if (parsed.length == 0) _importFailed = true;
    setState(() {
      _parsedTasks = parsed;
      _isLoading = false;
      print("Parsed tasks: $_parsedTasks");
    });
  }

  Future<void> _handleImport() async {
    await ImportFromIcsService.importTasksToDB(
      context,
      db,
      _parsedTasks,
      _selectedPriority,
      _selectedCategory,
      _selectedRepeatType,
      int.tryParse(remainderAmountController.text) ?? 0,
      _selectedRemainderType,
      _isStarred,
    );
  }

  @override
  void initState() {
    super.initState();
    db.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Import Tasks from .ICS"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            if (_parsedTasks.isEmpty && !_importFailed)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16, // left & right
                      vertical: 8, // top & bottom
                    ),
                    child: Text(
                      "No tasks parsed yet. Please select an .ics file to import tasks",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 50),
                  Center(
                    child: Container(
                      width: 300,
                      height: 200,

                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(
                                context,
                              ).colorScheme.secondary, // Button background
                          foregroundColor:
                              Theme.of(
                                context,
                              ).colorScheme.onPrimary, // Text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // Rounded corners
                            side: BorderSide(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimary, // Border color
                              width: 2, // Border width
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.file_upload),
                        label: const Text("Select .ics File"),
                        onPressed: _isLoading ? null : _handlePickAndParse,
                      ),
                    ),
                  ),
                ],
              ),
            if (_parsedTasks.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.file_upload),
                label: const Text("Select .ics File"),
                onPressed: _isLoading ? null : _handlePickAndParse,
              ),
            const SizedBox(height: 20),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_parsedTasks.isEmpty && !_isLoading && _importFailed)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(
                    "No tasks parsed yet. Please selected .ics has no tasks.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            if (_parsedTasks.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _parsedTasks.length,
                  itemBuilder: (context, index) {
                    final task = _parsedTasks[index];
                    return Card(
                      color: Theme.of(context).colorScheme.secondary,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          task['taskName'],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task['taskNote'].isNotEmpty)
                              Text(
                                task['taskNote'],
                                style: const TextStyle(color: Colors.grey),
                              ),
                            if (task['dueDate'] != null)
                              Text(
                                "Due: ${task['dueDate']}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (_parsedTasks.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mark these tasks as : ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, // makes text bold
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Text("Star these tasks : "),
                        Checkbox(
                          value: _isStarred,
                          onChanged: (bool? value) {
                            _isStarred = !_isStarred;
                            setState(() {});
                            //return isStarred;
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Text("Task category : "),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: DropdownButton<String>(
                            borderRadius: BorderRadius.circular(20),
                            value: _selectedCategory,
                            items:
                                db.categories.map((String option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              if (newValue == null) return;
                              setState(() => _selectedCategory = newValue);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Text("Task priority : "),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: DropdownButton<String>(
                            value: _selectedPriority,
                            items:
                                priorityTypes.map((String option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              if (newValue == null) return;
                              print("priority changed to $newValue");
                              setState(() => _selectedPriority = newValue);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Text("Remind me before : "),
                        SizedBox(width: 20),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: TextField(
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            controller: remainderAmountController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '',
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: DropdownButton<String>(
                            value: _selectedRemainderType,
                            items:
                                remainderTypes.map((String option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              if (newValue == null) return;
                              setState(() => _selectedRemainderType = newValue);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Text(
                          "Repeat this task : ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: DropdownButton<String>(
                            value: _selectedRepeatType,
                            items:
                                repeatTypes.map((String option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              if (newValue == null) return;
                              setState(() => _selectedRepeatType = newValue);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                  ],
                ),
              ),

            if (_parsedTasks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    "Import to Tasks",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: _handleImport,
                ),
              ),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
