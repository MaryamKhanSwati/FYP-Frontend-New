import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class MyTutorsScreen extends StatefulWidget {
  const MyTutorsScreen({super.key});

  @override
  State<MyTutorsScreen> createState() => _MyTutorsScreenState();
}

class _MyTutorsScreenState extends State<MyTutorsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tutors = [];

  @override
  void initState() {
    super.initState();
    _fetchTutors();
  }

  Future<void> _fetchTutors() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.get('/api/Student/my-tutors');

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));

        if (data is List) {
          _tutors = data.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      } else {
        _error = ApiClient.messageFromBody(res.body) ?? "Failed to load tutors";
      }
    } catch (e) {
      _error = "Network error: $e";
    }

    setState(() => _loading = false);
  }

  void _openFeedbackDialog(int tutorId, int courseId) {
    double rating = 0;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Give Feedback"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Rating"),
                  const SizedBox(height: 8),

                  // ⭐ Rating stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            rating = index + 1;
                          });
                        },
                        icon: Icon(
                          Icons.star,
                          color: index < rating ? Colors.amber : Colors.grey,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Write your feedback...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _submitFeedback(
                      tutorId,
                      courseId,
                      rating.toInt(),
                      commentController.text,
                    );

                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitFeedback(
    int tutorId,
    int courseId,
    int rating,
    String comment,
  ) async {
    try {
      final res = await ApiClient.post(
        '/api/Student/give-feedback',
        {
          "tutorId": tutorId,
          "courseId": courseId,
          "rating": rating,
          "comment": comment,
        },
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Feedback submitted")),
        );
        _fetchTutors();
      } else {
        final msg =
            ApiClient.messageFromBody(res.body) ?? "Failed to submit feedback";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tutors"),
        backgroundColor: Colors.teal,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchTutors,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tutors.length,
                    itemBuilder: (context, index) {
                      final t = _tutors[index];

                      final tutorId =
                          (t['tutorId'] ?? t['tutor_id'] ?? 0) as int;
                      final courseId =
                          (t['courseId'] ?? t['course_id'] ?? 0) as int;

                      final tutorName = t['tutorName'] ?? t['tutor_name'];
                      final courseName = t['courseName'] ?? t['course_name'];

                      final isCompleted = t['isCompleted'] ?? false;
                      final feedbackGiven = t['feedbackGiven'] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tutorName ?? "",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(courseName ?? ""),
                            const SizedBox(height: 12),

                            /// STATUS ROW
                            Row(
                              children: [
                                if (isCompleted == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "Course Completed By Tutor",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                const SizedBox(width: 10),

                                if (feedbackGiven == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "Feedback Submitted",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            /// BUTTON
                            if (feedbackGiven == false)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  onPressed: () {
                                    _openFeedbackDialog(tutorId, courseId);
                                  },
                                  child: const Text(
                                    "Give Feedback",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}