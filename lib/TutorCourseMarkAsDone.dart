import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class TutorCourseMarkAsDone extends StatefulWidget {
  const TutorCourseMarkAsDone({super.key});

  @override
  State<TutorCourseMarkAsDone> createState() =>
      _TutorCourseMarkAsDoneState();
}

class _TutorCourseMarkAsDoneState
    extends State<TutorCourseMarkAsDone> {
  // =========================================================
  // COLORS
  // =========================================================

  final Color primaryColor = const Color(0xFF009688);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  // =========================================================
  // STATE VARIABLES
  // =========================================================

  bool isLoading = false;
  bool isSubmitting = false;

  List<dynamic> coursesList = [];

  @override
  void initState() {
    super.initState();
    fetchCoursesForMarkDone();
  }

  // =========================================================
  // HELPER: SAFE JSON DECODING
  // =========================================================

  dynamic _decodeResponse(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // HELPER: GET API ERROR MESSAGE
  // =========================================================

  String _getErrorMessage(dynamic decoded, String fallback) {
    if (decoded is Map) {
      return decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          fallback;
    }

    if (decoded is String && decoded.isNotEmpty) {
      return decoded;
    }

    return fallback;
  }

  // =========================================================
  // HELPER: GET INTEGER SAFELY
  // =========================================================

  int _getInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // =========================================================
  // HELPER: GET STRING SAFELY
  // =========================================================

  String _getString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;

    return value.toString();
  }

  // =========================================================
  // HELPER: GET BOOLEAN SAFELY
  // =========================================================

  bool _getBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    return value?.toString().toLowerCase() == 'true';
  }

  // =========================================================
  // FETCH COURSES API
  // =========================================================

  Future<void> fetchCoursesForMarkDone() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get(
        "/api/Tutor/my-courses-for-mark-as-done",
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = _decodeResponse(response.body);

        List<dynamic> result = [];

        if (decoded is List) {
          result = decoded;
        } else if (decoded is Map) {
          // Supports APIs returning { data: [...] }
          // or { courses: [...] }.
          final data = decoded['data'] ?? decoded['courses'];

          if (data is List) {
            result = data;
          }
        }

        setState(() {
          coursesList = result;
        });
      } else {
        final decoded = _decodeResponse(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getErrorMessage(
                decoded,
                "Failed to load courses (${response.statusCode})",
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading courses: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // GET STUDENT ID AND COURSE ID
  // =========================================================

  int _getStudentId(Map item) {
    return _getInt(
      item['student_id'] ??
          item['studentId'] ??
          item['StudentId'],
    );
  }

  int _getCourseId(Map item) {
    return _getInt(
      item['course_id'] ??
          item['courseId'] ??
          item['CourseId'],
    );
  }

  // =========================================================
  // SHOW COURSE COMPLETION DIALOG
  // =========================================================

  Future<void> _showMarkDoneDialog(
    int studentId,
    int courseId,
    String courseName,
  ) async {
    final TextEditingController gradeController =
        TextEditingController();

    final String? grade = await showDialog<String>(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Finalize Course",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                courseName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Enter the student's final grade.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: gradeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: "Example: A, B, A+",
                  prefixIcon: const Icon(Icons.grade_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You can only finalize the course after all required classes have been completed.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  gradeController.text.trim(),
                );
              },
              child: const Text(
                "Finalize Course",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    gradeController.dispose();

    if (grade == null) return;

    await markCourseDone(
      studentId,
      courseId,
      grade,
    );
  }

  // =========================================================
  // MARK COURSE DONE API
  // =========================================================

  Future<void> markCourseDone(
    int studentId,
    int courseId,
    String grade,
  ) async {
    if (isSubmitting) return;

    if (studentId <= 0 || courseId <= 0) {
      _showMessage(
        "Invalid student or course information.",
        isError: true,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      // IMPORTANT:
      // These parameter names match your backend
      // MarkCourseDoneRequest properties.

      final response = await ApiClient.post(
        "/api/Tutor/mark-course-done",
        {
          "studentId": studentId,
          "courseId": courseId,
          "grade": grade,
        },
      );

      if (!mounted) return;

      final decoded = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        final String message = _getErrorMessage(
          decoded,
          "Course finalized successfully.",
        );

        // Close any previous state and refresh courses.
        _showMessage(
          message,
          isError: false,
        );

        await fetchCoursesForMarkDone();
      } else {
        // Backend validation errors are displayed directly.
        // This includes incomplete classes, missing hourly rate,
        // invalid course plan, and other backend validations.

        final String message = _getErrorMessage(
          decoded,
          "Failed to finalize course (${response.statusCode}).",
        );

        _showMessage(
          message,
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        "Error finalizing course: $e",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // =========================================================
  // SHOW MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // =========================================================
  // GET STUDENT INITIALS
  // =========================================================

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "S";

    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }

    return parts[0][0].toUpperCase();
  }

  // =========================================================
  // BUILD COURSE CARD
  // =========================================================

  Widget _buildCourseCard(dynamic data) {
    if (data is! Map) {
      return const SizedBox.shrink();
    }

    final item = data;

    final int studentId = _getStudentId(item);
    final int courseId = _getCourseId(item);

    final String studentName = _getString(
      item['student_name'] ??
          item['studentName'] ??
          item['StudentName'],
      "Student Name",
    );

    final String courseName = _getString(
      item['course_name'] ??
          item['courseName'] ??
          item['CourseName'],
      "Course Name",
    );

    final bool isCompleted = _getBool(
      item['is_completed'] ??
          item['isCompleted'] ??
          item['IsCompleted'],
    );

    final String grade = _getString(
      item['grade'] ?? item['Grade'],
    );

    final String completedDate = _getString(
      item['completed_date'] ??
          item['completedDate'] ??
          item['CompletedDate'],
    );

    final String formattedDate =
        completedDate.isNotEmpty && completedDate != "null"
            ? completedDate.split('T')[0]
            : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STUDENT INFORMATION

          Row(
            children: [
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    _getInitials(studentName),
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            courseName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              _buildStatusBadge(isCompleted),
            ],
          ),

          // COMPLETED COURSE DETAILS

          if (isCompleted &&
              (grade.isNotEmpty || formattedDate.isNotEmpty)) ...[
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (grade.isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.star,
                    text: "Grade: $grade",
                    background: Colors.amber.shade50,
                    foreground: Colors.amber.shade800,
                  ),

                if (formattedDate.isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.check_box_outlined,
                    text: "Done: $formattedDate",
                    background: Colors.teal.shade50,
                    foreground: const Color(0xFF00695C),
                  ),
              ],
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // ACTION BUTTON

          SizedBox(
            width: double.infinity,
            child: isCompleted
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.teal.shade200,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF00695C),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "Course Completed Successfully",
                            style: TextStyle(
                              color: Color(0xFF00695C),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    onPressed: isSubmitting ||
                            studentId <= 0 ||
                            courseId <= 0
                        ? null
                        : () => _showMarkDoneDialog(
                              studentId,
                              courseId,
                              courseName,
                            ),

                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Complete Course",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget _buildStatusBadge(bool isCompleted) {
    final Color color =
        isCompleted ? const Color(0xFF00695C) : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.teal.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle
                : Icons.hourglass_empty,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isCompleted ? "Completed" : "Active",
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INFORMATION CHIP
  // =========================================================

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.school,
                color: Color(0xFF00695C),
                size: 18,
              ),
            ),

            const SizedBox(width: 8),

            const Text(
              "House of Tutor",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                "Mark Course Status",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Text(
                "Finalize your courses after completing all required classes.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // COURSE LIST

            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    )
                  : coursesList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                size: 55,
                                color: Colors.grey.shade400,
                              ),

                              const SizedBox(height: 12),

                              Text(
                                "No courses found",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                ),
                              ),

                              const SizedBox(height: 12),

                              ElevatedButton.icon(
                                onPressed:
                                    fetchCoursesForMarkDone,
                                icon: const Icon(
                                  Icons.refresh,
                                ),
                                label: const Text("Refresh"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: primaryColor,
                          onRefresh: fetchCoursesForMarkDone,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            itemCount: coursesList.length,
                            itemBuilder: (context, index) {
                              return _buildCourseCard(
                                coursesList[index],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

























// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class TutorCourseMarkAsDone extends StatefulWidget {
//   const TutorCourseMarkAsDone({super.key});

//   @override
//   State<TutorCourseMarkAsDone> createState() => _TutorCourseMarkAsDoneState();
// }

// class _TutorCourseMarkAsDoneState extends State<TutorCourseMarkAsDone> {
//   // =========================================================
//   // STATE VARIABLES
//   // =========================================================

//   bool isLoading = false;
//   List<dynamic> coursesList = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchCoursesForMarkDone();
//   }

//   // =========================================================
//   // FETCH COURSES API
//   // =========================================================

//   Future<void> fetchCoursesForMarkDone() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final response = await ApiClient.get("/api/Tutor/my-courses-for-mark-as-done");

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);

//         if (decoded is List) {
//           setState(() {
//             coursesList = decoded;
//           });
//         }
//       } else {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Failed to load courses (${response.statusCode})"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   // =========================================================
//   // MARK COURSE DONE DIALOG & API
//   // =========================================================

//   void _showMarkDoneDialog(int studentId, int courseId) {
//     final TextEditingController gradeController = TextEditingController(text: "A");

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: const Text(
//             "Complete Course",
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Enter Grade (e.g. A, B, C)",
//                 style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 6),
//               TextField(
//                 controller: gradeController,
//                 decoration: InputDecoration(
//                   hintText: "Grade",
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF009688),
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () async {
//                 Navigator.pop(context);
//                 await markCourseDone(studentId, courseId, gradeController.text.trim());
//               },
//               child: const Text("Submit", style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> markCourseDone(int studentId, int courseId, String grade) async {
//     try {
//       final response = await ApiClient.post(
//         "/api/Tutor/mark-course-done",
//         {
//           "studentId": studentId,
//           "courseId": courseId,
//           "grade": grade,
//         },
//       );

//       if (response.statusCode == 200) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Course marked as completed successfully."),
//             backgroundColor: Colors.green,
//           ),
//         );
//         fetchCoursesForMarkDone(); // Refresh list
//       } else {
//         final decoded = jsonDecode(response.body);
//         final message = decoded["message"] ?? "Failed to mark course as done";
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // =========================================================
//   // GET INITIALS FOR AVATAR
//   // =========================================================

//   String _getInitials(String name) {
//     if (name.trim().isEmpty) return "S";
//     List<String> parts = name.trim().split(" ");
//     if (parts.length >= 2) {
//       return "${parts[0][0]}${parts[1][0]}".toUpperCase();
//     }
//     return parts[0][0].toUpperCase();
//   }

//   // =========================================================
//   // BUILD
//   // =========================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               height: 28,
//               width: 28,
//               decoration: BoxDecoration(
//                 color: Colors.teal.shade50,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: const Icon(
//                 Icons.school,
//                 color: Color(0xFF00695C),
//                 size: 18,
//               ),
//             ),
//             const SizedBox(width: 8),
//             const Text(
//               "House of Tutor",
//               style: TextStyle(
//                 color: Colors.black87,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: SafeArea(
//         child: isLoading
//             ? const Center(
//                 child: CircularProgressIndicator(
//                   color: Color(0xFF009688),
//                 ),
//               )
//             : Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // HEADER TITLE & SUBTITLE
//                     const Text(
//                       "Mark Course Status",
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       "Update and finalize course completion records for your active students.",
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // COURSES LIST VIEW
//                     Expanded(
//                       child: coursesList.isEmpty
//                           ? Center(
//                               child: Text(
//                                 "No courses found",
//                                 style: TextStyle(
//                                   fontSize: 15,
//                                   color: Colors.grey.shade600,
//                                 ),
//                               ),
//                             )
//                           : ListView.builder(
//                               itemCount: coursesList.length,
//                               itemBuilder: (context, index) {
//                                 final item = coursesList[index];

//                                 final int studentId = item["student_id"] ?? 0;
//                                 final int courseId = item["course_id"] ?? 0;
//                                 final String studentName = item["student_name"] ?? "Student Name";
//                                 final String courseName = item["course_name"] ?? "Course Name";
//                                 final bool isCompleted = item["is_completed"] ?? false;
//                                 final String grade = item["grade"] ?? "";
//                                 final String rawCompletedDate =
//                                     item["completed_date"]?.toString().split("T")[0] ?? "";

//                                 return Container(
//                                   margin: const EdgeInsets.only(bottom: 16),
//                                   padding: const EdgeInsets.all(16),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(16),
//                                     border: Border.all(color: Colors.grey.shade200),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.black.withOpacity(0.03),
//                                         blurRadius: 8,
//                                         offset: const Offset(0, 2),
//                                       ),
//                                     ],
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       // TOP HEADER: AVATAR + NAME + STATUS BADGE
//                                       Row(
//                                         children: [
//                                           Container(
//                                             height: 45,
//                                             width: 45,
//                                             decoration: BoxDecoration(
//                                               color: Colors.indigo.shade50,
//                                               borderRadius: BorderRadius.circular(25),
//                                             ),
//                                             child: Center(
//                                               child: Text(
//                                                 _getInitials(studentName),
//                                                 style: TextStyle(
//                                                   color: Colors.indigo.shade700,
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 15,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                           const SizedBox(width: 12),
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment: CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   studentName,
//                                                   style: const TextStyle(
//                                                     fontSize: 16,
//                                                     fontWeight: FontWeight.bold,
//                                                     color: Colors.black87,
//                                                   ),
//                                                 ),
//                                                 const SizedBox(height: 2),
//                                                 Row(
//                                                   children: [
//                                                     Icon(
//                                                       Icons.menu_book_outlined,
//                                                       size: 14,
//                                                       color: Colors.grey.shade600,
//                                                     ),
//                                                     const SizedBox(width: 4),
//                                                     Text(
//                                                       courseName,
//                                                       style: TextStyle(
//                                                         fontSize: 12,
//                                                         color: Colors.grey.shade600,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                           // STATUS BADGE
//                                           Container(
//                                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                                             decoration: BoxDecoration(
//                                               color: isCompleted ? Colors.teal.shade50 : Colors.orange.shade50,
//                                               borderRadius: BorderRadius.circular(20),
//                                             ),
//                                             child: Row(
//                                               mainAxisSize: MainAxisSize.min,
//                                               children: [
//                                                 Icon(
//                                                   isCompleted ? Icons.check_circle : Icons.hourglass_empty,
//                                                   size: 12,
//                                                   color: isCompleted ? const Color(0xFF00695C) : Colors.orange,
//                                                 ),
//                                                 const SizedBox(width: 4),
//                                                 Text(
//                                                   isCompleted ? "Completed" : "Active",
//                                                   style: TextStyle(
//                                                     color: isCompleted ? const Color(0xFF00695C) : Colors.orange,
//                                                     fontSize: 11,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),

//                                       // GRADE & DATE CHIPS (If completed)
//                                       if (isCompleted && (grade.isNotEmpty || rawCompletedDate.isNotEmpty)) ...[
//                                         const SizedBox(height: 12),
//                                         Row(
//                                           children: [
//                                             if (grade.isNotEmpty)
//                                               Container(
//                                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                                                 decoration: BoxDecoration(
//                                                   color: Colors.amber.shade50,
//                                                   borderRadius: BorderRadius.circular(8),
//                                                   border: Border.all(color: Colors.amber.shade200),
//                                                 ),
//                                                 child: Row(
//                                                   mainAxisSize: MainAxisSize.min,
//                                                   children: [
//                                                     const Icon(Icons.star, size: 14, color: Colors.amber),
//                                                     const SizedBox(width: 4),
//                                                     Text(
//                                                       "Grade: $grade",
//                                                       style: const TextStyle(
//                                                         fontSize: 12,
//                                                         fontWeight: FontWeight.bold,
//                                                         color: Colors.black87,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             if (grade.isNotEmpty && rawCompletedDate.isNotEmpty)
//                                               const SizedBox(width: 8),
//                                             if (rawCompletedDate.isNotEmpty)
//                                               Container(
//                                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                                                 decoration: BoxDecoration(
//                                                   color: Colors.teal.shade50,
//                                                   borderRadius: BorderRadius.circular(8),
//                                                   border: Border.all(color: Colors.teal.shade100),
//                                                 ),
//                                                 child: Row(
//                                                   mainAxisSize: MainAxisSize.min,
//                                                   children: [
//                                                     const Icon(Icons.check_box_outlined, size: 14, color: Color(0xFF00695C)),
//                                                     const SizedBox(width: 4),
//                                                     Text(
//                                                       "Done: $rawCompletedDate",
//                                                       style: const TextStyle(
//                                                         fontSize: 12,
//                                                         fontWeight: FontWeight.bold,
//                                                         color: Color(0xFF00695C),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                           ],
//                                         ),
//                                       ],

//                                       const Padding(
//                                         padding: EdgeInsets.symmetric(vertical: 12),
//                                         child: Divider(height: 1),
//                                       ),

//                                       // MARK COMPLETE / SUCCESS BUTTON
//                                       SizedBox(
//                                         width: double.infinity,
//                                         child: isCompleted
//                                             ? Container(
//                                                 padding: const EdgeInsets.symmetric(vertical: 12),
//                                                 decoration: BoxDecoration(
//                                                   color: Colors.teal.shade50,
//                                                   borderRadius: BorderRadius.circular(10),
//                                                   border: Border.all(color: Colors.teal.shade200),
//                                                 ),
//                                                 child: const Row(
//                                                   mainAxisAlignment: MainAxisAlignment.center,
//                                                   children: [
//                                                     Icon(Icons.check_circle_outline, color: Color(0xFF00695C), size: 16),
//                                                     SizedBox(width: 6),
//                                                     Text(
//                                                       "Course Completed Successfully",
//                                                       style: TextStyle(
//                                                         color: Color(0xFF00695C),
//                                                         fontWeight: FontWeight.bold,
//                                                         fontSize: 13,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               )
//                                             : ElevatedButton(
//                                                 style: ElevatedButton.styleFrom(
//                                                   backgroundColor: const Color(0xFF009688),
//                                                   elevation: 0,
//                                                   padding: const EdgeInsets.symmetric(vertical: 12),
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius: BorderRadius.circular(10),
//                                                   ),
//                                                 ),
//                                                 onPressed: () => _showMarkDoneDialog(studentId, courseId),
//                                                 child: const Row(
//                                                   mainAxisAlignment: MainAxisAlignment.center,
//                                                   children: [
//                                                     Icon(Icons.check, color: Colors.white, size: 16),
//                                                     SizedBox(width: 6),
//                                                     Text(
//                                                       "Complete Course",
//                                                       style: TextStyle(
//                                                         color: Colors.white,
//                                                         fontWeight: FontWeight.bold,
//                                                         fontSize: 13,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//                               },
//                             ),
//                     ),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }
// }