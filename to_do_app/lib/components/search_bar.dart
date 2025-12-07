import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/providers/file_search_provider.dart';
import 'package:to_do_app/providers/searching_provider.dart';

class SearchBar extends StatelessWidget {
  final String searchType;
  const SearchBar({super.key, required this.searchType});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search...",
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) {
          // Get the provider and update the query
          if (searchType == "timetable") {
            context.read<FileSearchProvider>().setSearchQuery(value);
          } else if (searchType == "task") {
            //context.read<SearchingProvider>().setTaskQuery(value);
            context.read<SearchingProvider>().setQuery(value);
          }
        },
      ),
    );
  }
}
