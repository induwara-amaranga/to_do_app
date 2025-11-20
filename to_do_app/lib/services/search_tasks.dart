class SearchTasks {
  static List<dynamic> searchByQuery(
    String searchQuery,
    List<dynamic> tasksList,
  ) {
    if (searchQuery.isNotEmpty) {
      tasksList =
          tasksList.where((task) {
            final name = (task[0] ?? "").toString().toLowerCase();
            final note = (task[2] ?? "").toString().toLowerCase();
            return name.contains(searchQuery) || note.contains(searchQuery);
          }).toList();
    }
    return tasksList;
  }
}
