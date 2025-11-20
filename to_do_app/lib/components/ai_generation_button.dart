import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:to_do_app/services/AiTaskService.dart';

class AiGenerationButton extends StatefulWidget {
  final BuildContext context;
  final TextEditingController goal;
  final String timeframe;
  final void Function(Map<String, dynamic>)? onResult;

  AiGenerationButton({
    super.key,
    required this.timeframe,
    required this.goal,
    this.onResult,
    required this.context,
  });

  @override
  State<AiGenerationButton> createState() => _AiGenerationButtonState();
}

class _AiGenerationButtonState extends State<AiGenerationButton> {
  bool isLoading = false;

  Future<void> callApi(BuildContext context) async {
    try {
      AiTaskService.generateTasks(
        goal: widget.goal.text,
        timeframe: widget.timeframe,
      ).then((response) {
        print('✅ Response: $response');

        if (widget.onResult != null) {
          widget.onResult!(response);
        }

        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Tasks generated successfully')),
        );
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      print('⚠️ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Error occurred.Check network connection.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          isLoading
              ? null
              : () {
                isLoading = true;
                callApi(context);
                setState(() {});
              },

      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child:
            isLoading
                ? Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
                : Image.asset(
                  'assets/images/ai.png',
                  key: const ValueKey('ai_image'),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
      ),
    );
  }
}
