
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:house_of_tutor/services/api_client.dart';

class TutorMyStudent extends StatefulWidget {
  const TutorMyStudent({super.key});

  @override
  State<TutorMyStudent> createState() => _TutorMyStudentState();
}

class _TutorMyStudentState extends State<TutorMyStudent> {
  // ============================================================
  // COLORS
  // ============================================================

  final Color primaryColor = const Color(0xFF0F766E);
  final Color secondaryColor = const Color(0xFF4F46E5);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  // ============================================================
  // VARIABLES
  // ============================================================

  bool isLoading = false;
  List<dynamic> studentsList = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    fetchMyStudents();
  }

  // ============================================================
  // GET MY STUDENTS
  // GET /api/Tutor/my-students
  // ============================================================

  Future<void> fetchMyStudents() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get(
        "/api/Tutor/my-students",
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> result = [];

        if (decoded is List) {
          result = decoded;
        } else if (decoded is Map) {
          if (decoded["data"] is List) {
            result = decoded["data"];
          } else if (decoded["students"] is List) {
            result = decoded["students"];
          }
        }

        if (!mounted) return;

        setState(() {
          studentsList = result;
        });
      } else {
        _showError(_extractErrorMessage(response.body));
      }
    } catch (e) {
      _showError("Unable to load students.\n$e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // VIEW COURSE CONTENT
  // GET /api/Tutor/tutor-course-content/{studentId}/{courseId}
  // ============================================================

  Future<List<dynamic>> fetchCourseContent(
    int studentId,
    int courseId,
  ) async {
    final response = await ApiClient.get(
      "/api/Tutor/tutor-course-content/$studentId/$courseId",
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return List<dynamic>.from(decoded);
      }

      if (decoded is Map) {
        if (decoded["data"] is List) {
          return List<dynamic>.from(decoded["data"]);
        }

        if (decoded["contents"] is List) {
          return List<dynamic>.from(decoded["contents"]);
        }
      }

      return [];
    }

    if (response.statusCode == 403) {
      throw Exception(
        "You are not authorized to view this course content.",
      );
    }

    throw Exception(_extractErrorMessage(response.body));
  }

  // ============================================================
  // SHOW COURSE CONTENT
  // ============================================================

  Future<void> showCourseContent({
    required int studentId,
    required int courseId,
    required String studentName,
    required String courseName,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final contents = await fetchCourseContent(
        studentId,
        courseId,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      showDialog(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 650,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.folder_copy_outlined,
                        color: primaryColor,
                        size: 27,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Course Content",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              courseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: secondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            studentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (contents.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_off_outlined,
                              size: 55,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "No course content found.",
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: contents.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = contents[index];

                          final title = _getString(
                            item,
                            ["title"],
                            "Untitled",
                          );

                          final fileName = _getString(
                            item,
                            ["file_name", "fileName"],
                          );

                          final description = _getString(
                            item,
                            ["description"],
                          );

                          final fileUrl = _getString(
                            item,
                            ["file_url", "fileUrl"],
                          );

                          final filePath = _getString(
                            item,
                            ["file_path", "filePath"],
                          );

                          final uploadedDate = _getString(
                            item,
                            ["uploaded_date", "uploadedDate"],
                          );

                          return _buildContentCard(
                            title: title,
                            fileName: fileName,
                            description: description,
                            fileUrl: fileUrl,
                            filePath: filePath,
                            uploadedDate: uploadedDate,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        _showError(
          e.toString().replaceFirst("Exception: ", ""),
        );
      }
    }
  }

  // ============================================================
  // COURSE CONTENT CARD
  // ============================================================

  Widget _buildContentCard({
    required String title,
    required String fileName,
    required String description,
    required String fileUrl,
    required String filePath,
    required String uploadedDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],

          if (fileName.isNotEmpty) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (uploadedDate.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              "Uploaded: ${_formatDate(uploadedDate)}",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],

          if (fileUrl.isNotEmpty || filePath.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openFile(
                    fileUrl,
                    filePath,
                    fileName,
                  );
                },
                icon: const Icon(
                  Icons.open_in_new,
                  size: 17,
                ),
                label: const Text("Open File"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // OPEN FILE
  // ============================================================

  Future<void> _openFile(
    String fileUrl,
    String filePath,
    String fileName,
  ) async {
    try {
      String url = fileUrl.isNotEmpty ? fileUrl : filePath;

      if (url.isEmpty) {
        _showError("File URL is not available.");
        return;
      }

      if (!url.startsWith("http://") &&
          !url.startsWith("https://")) {
        final baseUrl = ApiClient.baseUrlForFiles;

        if (baseUrl.endsWith("/") && url.startsWith("/")) {
          url = baseUrl.substring(0, baseUrl.length - 1) + url;
        } else if (!baseUrl.endsWith("/") &&
            !url.startsWith("/")) {
          url = "$baseUrl/$url";
        } else {
          url = "$baseUrl$url";
        }
      }

      final lowerFileName = fileName.toLowerCase();
      final lowerUrl = url.toLowerCase().split("?").first;

      final isImage =
          lowerFileName.endsWith(".jpg") ||
          lowerFileName.endsWith(".jpeg") ||
          lowerFileName.endsWith(".png") ||
          lowerFileName.endsWith(".webp") ||
          lowerUrl.endsWith(".jpg") ||
          lowerUrl.endsWith(".jpeg") ||
          lowerUrl.endsWith(".png") ||
          lowerUrl.endsWith(".webp");

      if (isImage) {
        _showImageDialog(
          imageUrl: url,
          fileName: fileName,
        );
        return;
      }

      final uri = Uri.tryParse(url);

      if (uri == null ||
          (uri.scheme != "http" && uri.scheme != "https")) {
        _showError("Invalid file URL.");
        return;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showError("Unable to open this file.");
      }
    } catch (e) {
      _showError("Unable to open file.\n$e");
    }
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  void _showImageDialog({
    required String imageUrl,
    required String fileName,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName.isNotEmpty
                              ? fileName
                              : "Uploaded Image",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(dialogContext).size.height * 0.70,
                  ),
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (
                        context,
                        child,
                        loadingProgress,
                      ) {
                        if (loadingProgress == null) return child;

                        return SizedBox(
                          height: 300,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) {
                        return const SizedBox(
                          height: 300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white,
                                  size: 55,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "Unable to load image",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.zoom_in,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          "Pinch to zoom image",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: Text(
                          "Close",
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MARK COURSE DONE
  //
  // POST /api/Tutor/mark-course-done
  //
  // BODY:
  // {
  //   "studentId": 1,
  //   "courseId": 5
  // }
  //
  // IMPORTANT:
  // Backend checks that all required classes are completed.
  // It does NOT automatically complete remaining classes.
  // ============================================================

  Future<void> completeCourse({
    required int studentId,
    required int courseId,
    required String studentName,
    required String courseName,
  }) async {
    if (studentId <= 0 || courseId <= 0) {
      _showError("Invalid student ID or course ID.");
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
                "Student: $studentName",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text("Course: $courseName"),
              const SizedBox(height: 14),
              const Text(
                "Are you sure you want to finalize this course?",
              ),
              const SizedBox(height: 8),
              Text(
                "All required classes must already be completed. "
                "The backend will calculate the total fee and finalize the course.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Finalize"),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    _showLoadingDialog();

    try {
      // ========================================================
      // CORRECT BACKEND API
      // ========================================================

      final response = await ApiClient.post(
        "/api/Tutor/mark-course-done",
        {
          "studentId": studentId,
          "courseId": courseId,
        },
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        final message = decoded is Map
            ? decoded["message"]?.toString() ??
                "Course finalized successfully."
            : "Course finalized successfully.";

        // Refresh students after successful finalization.
        await fetchMyStudents();

        if (!mounted) return;

        // Show backend success message.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // ======================================================
        // BACKEND VALIDATION ERRORS
        // ======================================================

        final errorMessage = _extractErrorMessage(
          response.body,
        );

        _showError(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        _showError(
          "Unable to finalize course.\n$e",
        );
      }
    }
  }

  // ============================================================
  // GIVE FEEDBACK
  // POST /api/Tutor/give-feedback
  // ============================================================

  Future<void> _showFeedbackDialog({
    required int studentId,
    required int courseId,
    required String studentName,
    required String courseName,
  }) async {
    double rating = 5;

    final commentController = TextEditingController();

    bool isSubmitting = false;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Give Feedback",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        courseName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        "Rating",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Row(
                        children: List.generate(5, (index) {
                          final star = index + 1;

                          return IconButton(
                            onPressed: isSubmitting
                                ? null
                                : () {
                                    setDialogState(() {
                                      rating = star.toDouble();
                                    });
                                  },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 38,
                              minHeight: 38,
                            ),
                            icon: Icon(
                              star <= rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber.shade700,
                              size: 30,
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Comment",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 7),

                      TextField(
                        controller: commentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "Write feedback...",
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
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            Navigator.pop(dialogContext);
                          },
                    child: const Text("Cancel"),
                  ),

                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setDialogState(() {
                              isSubmitting = true;
                            });

                            try {
                              final response = await ApiClient.post(
                                "/api/Tutor/give-feedback",
                                {
                                  "studentId": studentId,
                                  "courseId": courseId,
                                  "rating": rating.toInt(),
                                  "comment": commentController.text.trim(),
                                },
                              );

                              if (!dialogContext.mounted) return;

                              if (response.statusCode >= 200 &&
                                  response.statusCode < 300) {
                                Navigator.pop(dialogContext);

                                await fetchMyStudents();

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      "Feedback submitted successfully.",
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                setDialogState(() {
                                  isSubmitting = false;
                                });

                                _showError(
                                  _extractErrorMessage(response.body),
                                );
                              }
                            } catch (e) {
                              if (!dialogContext.mounted) return;

                              setDialogState(() {
                                isSubmitting = false;
                              });

                              _showError(
                                "Unable to submit feedback.\n$e",
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Submit"),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      commentController.dispose();
    }
  }

  // ============================================================
  // STUDENT CARD
  // ============================================================

  Widget _buildStudentCard({
    required int studentId,
    required int courseId,
    required String studentName,
    required String courseName,
    required bool isCompleted,
    required String completedDate,
    required bool feedbackGiven,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // STUDENT HEADER
          // ======================================================

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      secondaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            courseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // STATUS
          // ======================================================

          Row(
            children: [
              Expanded(
                child: _buildStatusBox(
                  isCompleted ? "Completed" : "In Progress",
                  isCompleted
                      ? Icons.check_circle_outline
                      : Icons.schedule_outlined,
                  isCompleted ? Colors.green : Colors.orange,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildStatusBox(
                  feedbackGiven ? "Feedback Given" : "No Feedback",
                  feedbackGiven
                      ? Icons.rate_review
                      : Icons.rate_review_outlined,
                  feedbackGiven ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          ),

          // ======================================================
          // COMPLETED DATE
          // ======================================================

          if (isCompleted && completedDate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "Completed: ${_formatDate(completedDate)}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // ======================================================
          // VIEW COURSE CONTENT
          // ======================================================

          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: studentId <= 0 || courseId <= 0
                  ? null
                  : () {
                      showCourseContent(
                        studentId: studentId,
                        courseId: courseId,
                        studentName: studentName,
                        courseName: courseName,
                      );
                    },
              icon: Icon(
                Icons.folder_copy_outlined,
                color: secondaryColor,
                size: 18,
              ),
              label: Text(
                "View Course Content",
                style: TextStyle(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: secondaryColor.withOpacity(0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 9),

          // ======================================================
          // FINALIZE COURSE
          // ======================================================

          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: studentId <= 0 || courseId <= 0
                    ? null
                    : () {
                        completeCourse(
                          studentId: studentId,
                          courseId: courseId,
                          studentName: studentName,
                          courseName: courseName,
                        );
                      },
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                ),
                label: const Text(
                  "Finalize Course",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else
            _buildCompletedBox(
              "Course Completed",
              Icons.check_circle,
              Colors.green,
            ),

          const SizedBox(height: 9),

          // ======================================================
          // FEEDBACK
          // ======================================================

          if (!feedbackGiven)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: studentId <= 0 || courseId <= 0
                    ? null
                    : () {
                        _showFeedbackDialog(
                          studentId: studentId,
                          courseId: courseId,
                          studentName: studentName,
                          courseName: courseName,
                        );
                      },
                icon: Icon(
                  Icons.rate_review_outlined,
                  color: secondaryColor,
                  size: 18,
                ),
                label: Text(
                  "Give Feedback",
                  style: TextStyle(
                    color: secondaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: secondaryColor.withOpacity(0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else
            _buildCompletedBox(
              "Feedback Submitted",
              Icons.check_circle_outline,
              Colors.blue,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BOX
  // ============================================================

  Widget _buildStatusBox(
    String title,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLETED BOX
  // ============================================================

  Widget _buildCompletedBox(
    String title,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 7),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My Students",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "${studentsList.length} student course${studentsList.length == 1 ? '' : 's'}",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : fetchMyStudents,
            icon: Icon(
              Icons.refresh,
              color: primaryColor,
            ),
            tooltip: "Refresh",
          ),
          const SizedBox(width: 6),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        onRefresh: fetchMyStudents,
        color: primaryColor,
        child: isLoading && studentsList.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                  ),
                  Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Center(
                    child: Text("Loading students..."),
                  ),
                ],
              )
            : studentsList.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                      ),
                      Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people_outline,
                            size: 45,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          "No Students Found",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Center(
                        child: Text(
                          "You currently have no students.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: fetchMyStudents,
                          icon: const Icon(
                            Icons.refresh,
                            size: 17,
                          ),
                          label: const Text("Refresh"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      25,
                    ),
                    itemCount: studentsList.length,
                    itemBuilder: (context, index) {
                      final item = studentsList[index];

                      final int studentId = _toInt(
                        _getValue(item, [
                          "studentId",
                          "student_id",
                        ]),
                      );

                      final int courseId = _toInt(
                        _getValue(item, [
                          "courseId",
                          "course_id",
                        ]),
                      );

                      final String studentName = _getString(
                        item,
                        ["studentName", "student_name"],
                        "Student Name",
                      );

                      final String courseName = _getString(
                        item,
                        ["courseName", "course_name"],
                        "Course Name",
                      );

                      final bool isCompleted = _toBool(
                        _getValue(item, [
                          "isCompleted",
                          "is_completed",
                        ]),
                      );

                      final String completedDate = _getString(
                        item,
                        ["completedDate", "completed_date"],
                      );

                      final bool feedbackGiven = _toBool(
                        _getValue(item, [
                          "feedbackGiven",
                          "feedback_given",
                        ]),
                      );

                      return _buildStudentCard(
                        studentId: studentId,
                        courseId: courseId,
                        studentName: studentName,
                        courseName: courseName,
                        isCompleted: isCompleted,
                        completedDate: completedDate,
                        feedbackGiven: feedbackGiven,
                      );
                    },
                  ),
      ),
    );
  }

  // ============================================================
  // LOADING DIALOG
  // ============================================================

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ============================================================
  // EXTRACT API ERROR
  // ============================================================

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        if (decoded["message"] != null) {
          return decoded["message"].toString();
        }

        if (decoded["error"] != null) {
          return decoded["error"].toString();
        }

        if (decoded["title"] != null) {
          return decoded["title"].toString();
        }

        if (decoded["errors"] is Map) {
          final errors = decoded["errors"] as Map;
          final messages = <String>[];

          errors.forEach((key, value) {
            if (value is List) {
              messages.addAll(
                value.map((e) => e.toString()),
              );
            } else {
              messages.add(value.toString());
            }
          });

          if (messages.isNotEmpty) {
            return messages.join("\n");
          }
        }
      }

      return body.isNotEmpty
          ? body
          : "Something went wrong.";
    } catch (_) {
      return body.isNotEmpty
          ? body
          : "Something went wrong.";
    }
  }

  // ============================================================
  // GET VALUE FROM JSON
  // Supports camelCase and snake_case.
  // ============================================================

  dynamic _getValue(
    dynamic item,
    List<String> keys,
  ) {
    if (item is! Map) return null;

    for (final key in keys) {
      if (item.containsKey(key) && item[key] != null) {
        return item[key];
      }
    }

    return null;
  }

  // ============================================================
  // GET STRING
  // ============================================================

  String _getString(
    dynamic item,
    List<String> keys, [
    String defaultValue = "",
  ]) {
    final value = _getValue(item, keys);

    if (value == null) return defaultValue;

    return value.toString();
  }

  // ============================================================
  // CONVERT TO INT
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) return value;

    if (value is double) return value.toInt();

    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  // ============================================================
  // CONVERT TO BOOL
  // ============================================================

  bool _toBool(dynamic value) {
    if (value is bool) return value;

    if (value is String) {
      return value.toLowerCase() == "true" || value == "1";
    }

    if (value is int) return value == 1;

    return false;
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);

      final day = parsed.day.toString().padLeft(2, "0");

      final month = parsed.month.toString().padLeft(2, "0");

      final year = parsed.year.toString();

      return "$day-$month-$year";
    } catch (_) {
      return date;
    }
  }
}

















































// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// import 'package:house_of_tutor/services/api_client.dart';

// class TutorMyStudent extends StatefulWidget {
//   const TutorMyStudent({super.key});

//   @override
//   State<TutorMyStudent> createState() => _TutorMyStudentState();
// }

// class _TutorMyStudentState extends State<TutorMyStudent> {
//   // ============================================================
//   // COLORS
//   // ============================================================

//   final Color primaryColor = const Color(0xFF0F766E);
//   final Color secondaryColor = const Color(0xFF4F46E5);
//   final Color backgroundColor = const Color(0xFFF5F7FA);

//   // ============================================================
//   // VARIABLES
//   // ============================================================

//   bool isLoading = false;
//   List<dynamic> studentsList = [];

//   // ============================================================
//   // INIT
//   // ============================================================

//   @override
//   void initState() {
//     super.initState();
//     fetchMyStudents();
//   }

//   // ============================================================
//   // 1. GET MY STUDENTS
//   // API: GET /api/Tutor/my-students
//   // ============================================================

//   Future<void> fetchMyStudents() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final response = await ApiClient.get(
//         "/api/Tutor/my-students",
//       );

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);

//         if (decoded is List) {
//           setState(() {
//             studentsList = List<dynamic>.from(decoded);
//           });
//         } else if (decoded is Map && decoded["data"] is List) {
//           setState(() {
//             studentsList = List<dynamic>.from(decoded["data"]);
//           });
//         } else {
//           setState(() {
//             studentsList = [];
//           });

//           _showError("Invalid students data received.");
//         }
//       } else {
//         _showError(
//           _extractErrorMessage(response.body),
//         );
//       }
//     } catch (e) {
//       _showError(
//         "Unable to load students.\n$e",
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   // ============================================================
//   // 2. VIEW COURSE CONTENT
//   // API:
//   // GET /api/Tutor/tutor-course-content/{studentId}/{courseId}
//   // ============================================================

//   Future<List<dynamic>> fetchCourseContent(
//     int studentId,
//     int courseId,
//   ) async {
//     try {
//       final response = await ApiClient.get(
//         "/api/Tutor/tutor-course-content/$studentId/$courseId",
//       );

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);

//         if (decoded is Map && decoded["data"] is List) {
//           return List<dynamic>.from(decoded["data"]);
//         }

//         if (decoded is List) {
//           return List<dynamic>.from(decoded);
//         }

//         return [];
//       }

//       if (response.statusCode == 403) {
//         throw Exception(
//           "You are not authorized to view this course content.",
//         );
//       }

//       throw Exception(
//         _extractErrorMessage(response.body),
//       );
//     } catch (e) {
//       throw Exception(
//         e.toString().replaceFirst(
//               "Exception: ",
//               "",
//             ),
//       );
//     }
//   }

//   // ============================================================
//   // SHOW COURSE CONTENT DIALOG
//   // ============================================================

//   Future<void> showCourseContent({
//     required int studentId,
//     required int courseId,
//     required String studentName,
//     required String courseName,
//   }) async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return const Center(
//           child: CircularProgressIndicator(),
//         );
//       },
//     );

//     try {
//       final contents = await fetchCourseContent(
//         studentId,
//         courseId,
//       );

//       if (mounted) {
//         Navigator.of(context).pop();
//       }

//       if (!mounted) return;

//       showDialog(
//         context: context,
//         builder: (context) {
//           return Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Container(
//               constraints: const BoxConstraints(
//                 maxHeight: 650,
//               ),
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // ==================================================
//                   // HEADER
//                   // ==================================================

//                   Row(
//                     children: [
//                       Container(
//                         width: 45,
//                         height: 45,
//                         decoration: BoxDecoration(
//                           color: primaryColor.withOpacity(0.10),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(
//                           Icons.folder_copy_outlined,
//                           color: primaryColor,
//                           size: 25,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment:
//                               CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               "Course Content",
//                               style: TextStyle(
//                                 fontSize: 19,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 3),
//                             Text(
//                               courseName,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.grey.shade600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                         icon: const Icon(Icons.close),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 12),

//                   // ==================================================
//                   // STUDENT NAME
//                   // ==================================================

//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.person_outline,
//                           size: 20,
//                           color: secondaryColor,
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             studentName,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 13,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 15),

//                   // ==================================================
//                   // NO CONTENT
//                   // ==================================================

//                   if (contents.isEmpty)
//                     Expanded(
//                       child: Center(
//                         child: Column(
//                           mainAxisAlignment:
//                               MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.folder_off_outlined,
//                               size: 55,
//                               color: Colors.grey.shade400,
//                             ),
//                             const SizedBox(height: 12),
//                             Text(
//                               "No course content found.",
//                               style: TextStyle(
//                                 color: Colors.grey.shade600,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     )

//                   // ==================================================
//                   // CONTENT LIST
//                   // ==================================================

//                   else
//                     Flexible(
//                       child: ListView.separated(
//                         shrinkWrap: true,
//                         itemCount: contents.length,
//                         separatorBuilder: (
//                           context,
//                           index,
//                         ) {
//                           return const SizedBox(height: 10);
//                         },
//                         itemBuilder: (
//                           context,
//                           index,
//                         ) {
//                           final item = contents[index];

//                           final String title =
//                               item["title"]?.toString() ??
//                                   "Untitled";

//                           final String fileName =
//                               item["file_name"]?.toString() ??
//                                   item["fileName"]?.toString() ??
//                                   "";

//                           final String description =
//                               item["description"]?.toString() ??
//                                   "";

//                           final String fileUrl =
//                               item["file_url"]?.toString() ??
//                                   item["fileUrl"]?.toString() ??
//                                   "";

//                           final String filePath =
//                               item["file_path"]?.toString() ??
//                                   item["filePath"]?.toString() ??
//                                   "";

//                           final String uploadedDate =
//                               item["uploaded_date"]?.toString() ??
//                                   item["uploadedDate"]?.toString() ??
//                                   "";

//                           return _buildContentCard(
//                             title: title,
//                             fileName: fileName,
//                             description: description,
//                             fileUrl: fileUrl,
//                             filePath: filePath,
//                             uploadedDate: uploadedDate,
//                           );
//                         },
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     } catch (e) {
//       if (mounted) {
//         Navigator.of(context).pop();
//       }

//       _showError(
//         e.toString().replaceFirst(
//               "Exception: ",
//               "",
//             ),
//       );
//     }
//   }

//   // ============================================================
//   // COURSE CONTENT CARD
//   // ============================================================

//   Widget _buildContentCard({
//     required String title,
//     required String fileName,
//     required String description,
//     required String fileUrl,
//     required String filePath,
//     required String uploadedDate,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(13),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: Colors.grey.shade200,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ========================================================
//           // TITLE
//           // ========================================================

//           Row(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 38,
//                 height: 38,
//                 decoration: BoxDecoration(
//                   color: secondaryColor.withOpacity(0.10),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   Icons.description_outlined,
//                   color: secondaryColor,
//                   size: 21,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // ========================================================
//           // DESCRIPTION
//           // ========================================================

//           if (description.isNotEmpty) ...[
//             const SizedBox(height: 10),
//             Text(
//               description,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey.shade700,
//                 height: 1.4,
//               ),
//             ),
//           ],

//           // ========================================================
//           // FILE NAME
//           // ========================================================

//           if (fileName.isNotEmpty) ...[
//             const SizedBox(height: 9),
//             Row(
//               children: [
//                 Icon(
//                   Icons.attach_file,
//                   size: 16,
//                   color: Colors.grey.shade600,
//                 ),
//                 const SizedBox(width: 5),
//                 Expanded(
//                   child: Text(
//                     fileName,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],

//           // ========================================================
//           // UPLOADED DATE
//           // ========================================================

//           if (uploadedDate.isNotEmpty) ...[
//             const SizedBox(height: 5),
//             Text(
//               "Uploaded: ${_formatDate(uploadedDate)}",
//               style: TextStyle(
//                 fontSize: 10,
//                 color: Colors.grey.shade500,
//               ),
//             ),
//           ],

//           // ========================================================
//           // OPEN FILE BUTTON
//           // ========================================================

//           if (fileUrl.isNotEmpty || filePath.isNotEmpty) ...[
//             const SizedBox(height: 10),
//             SizedBox(
//               width: double.infinity,
//               height: 38,
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   _openFile(
//                     fileUrl,
//                     filePath,
//                     fileName,
//                   );
//                 },
//                 icon: const Icon(
//                   Icons.open_in_new,
//                   size: 17,
//                 ),
//                 label: const Text(
//                   "Open File",
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: secondaryColor,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(9),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // OPEN FILE
//   //
//   // IMPORTANT:
//   // Images are NOT opened using url_launcher.
//   //
//   // JPG / JPEG / PNG
//   //       ↓
//   // Image.network()
//   //       ↓
//   // Opens directly inside Flutter
//   //
//   // Other files
//   //       ↓
//   // url_launcher
//   // ============================================================

//   Future<void> _openFile(
//     String fileUrl,
//     String filePath,
//     String fileName,
//   ) async {
//     try {
//       // ----------------------------------------------------------
//       // 1. GET URL
//       // ----------------------------------------------------------

//       String url = fileUrl.isNotEmpty
//           ? fileUrl
//           : filePath;

//       if (url.isEmpty) {
//         _showError("File URL is not available.");
//         return;
//       }

//       // ----------------------------------------------------------
//       // 2. CREATE FULL URL IF API RETURNS RELATIVE PATH
//       // ----------------------------------------------------------

//       if (!url.startsWith("http://") &&
//           !url.startsWith("https://")) {
//         String baseUrl = ApiClient.baseUrlForFiles;

//         if (baseUrl.endsWith("/") &&
//             url.startsWith("/")) {
//           url = baseUrl.substring(
//                 0,
//                 baseUrl.length - 1,
//               ) +
//               url;
//         } else if (!baseUrl.endsWith("/") &&
//             !url.startsWith("/")) {
//           url = "$baseUrl/$url";
//         } else {
//           url = "$baseUrl$url";
//         }
//       }

//       // ----------------------------------------------------------
//       // 3. CHECK FILE TYPE
//       // ----------------------------------------------------------

//       final String lowerFileName =
//           fileName.toLowerCase();

//       final String lowerUrl =
//           url.toLowerCase().split("?").first;

//       final bool isImage =
//           lowerFileName.endsWith(".jpg") ||
//           lowerFileName.endsWith(".jpeg") ||
//           lowerFileName.endsWith(".png") ||
//           lowerFileName.endsWith(".webp") ||
//           lowerUrl.endsWith(".jpg") ||
//           lowerUrl.endsWith(".jpeg") ||
//           lowerUrl.endsWith(".png") ||
//           lowerUrl.endsWith(".webp");

//       // ----------------------------------------------------------
//       // 4. IMAGE
//       //
//       // DO NOT USE launchUrl FOR IMAGE.
//       // Open it directly in Flutter.
//       // ----------------------------------------------------------

//       if (isImage) {
//         _showImageDialog(
//           imageUrl: url,
//           fileName: fileName,
//         );

//         return;
//       }

//       // ----------------------------------------------------------
//       // 5. OTHER FILES
//       // PDF / DOC / DOCX ETC.
//       // ----------------------------------------------------------

//       final Uri uri = Uri.parse(url);

//       final bool canOpen =
//           await canLaunchUrl(uri);

//       if (!canOpen) {
//         _showError(
//           "No application is available to open this file.",
//         );
//         return;
//       }

//       await launchUrl(
//         uri,
//         mode: LaunchMode.externalApplication,
//       );
//     } catch (e) {
//       _showError(
//         "Unable to open file.\n$e",
//       );
//     }
//   }

//   // ============================================================
//   // SHOW IMAGE DIALOG
//   // ============================================================

//   void _showImageDialog({
//     required String imageUrl,
//     required String fileName,
//   }) {
//     showDialog(
//       context: context,
//       barrierColor: Colors.black87,
//       builder: (dialogContext) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           insetPadding: const EdgeInsets.all(12),
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(18),
//             ),
//             clipBehavior: Clip.antiAlias,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // ==================================================
//                 // IMAGE HEADER
//                 // ==================================================

//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 10,
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.image_outlined,
//                         color: primaryColor,
//                         size: 22,
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           fileName.isNotEmpty
//                               ? fileName
//                               : "Uploaded Image",
//                           maxLines: 1,
//                           overflow:
//                               TextOverflow.ellipsis,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: () {
//                           Navigator.pop(
//                             dialogContext,
//                           );
//                         },
//                         icon: const Icon(
//                           Icons.close,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // ==================================================
//                 // IMAGE
//                 // ==================================================

//                 Container(
//                   width: double.infinity,
//                   constraints: BoxConstraints(
//                     maxHeight:
//                         MediaQuery.of(context)
//                                 .size
//                                 .height *
//                             0.70,
//                   ),
//                   color: Colors.black,
//                   child: InteractiveViewer(
//                     minScale: 0.5,
//                     maxScale: 4.0,
//                     child: Image.network(
//                       imageUrl,

//                       // ------------------------------------------------
//                       // IMAGE LOADING
//                       // ------------------------------------------------

//                       loadingBuilder: (
//                         context,
//                         child,
//                         loadingProgress,
//                       ) {
//                         if (loadingProgress ==
//                             null) {
//                           return child;
//                         }

//                         return SizedBox(
//                           height: 300,
//                           child: Center(
//                             child:
//                                 CircularProgressIndicator(
//                               color:
//                                   primaryColor,
//                               value: loadingProgress
//                                           .expectedTotalBytes !=
//                                       null
//                                   ? loadingProgress
//                                           .cumulativeBytesLoaded /
//                                       loadingProgress
//                                           .expectedTotalBytes!
//                                   : null,
//                             ),
//                           ),
//                         );
//                       },

//                       // ------------------------------------------------
//                       // IMAGE ERROR
//                       // ------------------------------------------------

//                       errorBuilder: (
//                         context,
//                         error,
//                         stackTrace,
//                       ) {
//                         return SizedBox(
//                           height: 300,
//                           child: Center(
//                             child: Padding(
//                               padding:
//                                   const EdgeInsets.all(
//                                 20,
//                               ),
//                               child: Column(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment
//                                         .center,
//                                 children: [
//                                   const Icon(
//                                     Icons.broken_image_outlined,
//                                     color: Colors.white,
//                                     size: 55,
//                                   ),
//                                   const SizedBox(
//                                     height: 12,
//                                   ),
//                                   const Text(
//                                     "Unable to load image",
//                                     style: TextStyle(
//                                       color:
//                                           Colors.white,
//                                       fontSize: 15,
//                                       fontWeight:
//                                           FontWeight.w600,
//                                     ),
//                                   ),
//                                   const SizedBox(
//                                     height: 7,
//                                   ),
//                                   Text(
//                                     imageUrl,
//                                     textAlign:
//                                         TextAlign.center,
//                                     style:
//                                         const TextStyle(
//                                       color:
//                                           Colors.white70,
//                                       fontSize: 10,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },

//                       fit: BoxFit.contain,
//                     ),
//                   ),
//                 ),

//                 // ==================================================
//                 // BOTTOM TEXT
//                 // ==================================================

//                 Container(
//                   width: double.infinity,
//                   padding:
//                       const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 10,
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.zoom_in,
//                         size: 18,
//                         color: Colors.grey.shade600,
//                       ),
//                       const SizedBox(width: 7),
//                       Expanded(
//                         child: Text(
//                           "Pinch to zoom image",
//                           style: TextStyle(
//                             fontSize: 11,
//                             color:
//                                 Colors.grey.shade600,
//                           ),
//                         ),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pop(
//                             dialogContext,
//                           );
//                         },
//                         child: Text(
//                           "Close",
//                           style: TextStyle(
//                             color: primaryColor,
//                             fontWeight:
//                                 FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ============================================================
//   // 3. MARK COURSE COMPLETE
//   // API: POST /api/Tutor/complete-course
//   // ============================================================

//   Future<void> completeCourse(
//     int courseId,
//   ) async {
//     final bool? confirm =
//         await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(18),
//           ),
//           title: const Text(
//             "Mark Course Complete",
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           content: const Text(
//             "Are you sure you want to mark this course as completed?",
//           ),
//           actions: [
//             TextButton(
//               onPressed: () =>
//                   Navigator.pop(
//                 context,
//                 false,
//               ),
//               child: const Text(
//                 "Cancel",
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () =>
//                   Navigator.pop(
//                 context,
//                 true,
//               ),
//               style:
//                   ElevatedButton.styleFrom(
//                 backgroundColor:
//                     primaryColor,
//                 foregroundColor:
//                     Colors.white,
//               ),
//               child: const Text(
//                 "Complete",
//               ),
//             ),
//           ],
//         );
//       },
//     );

//     if (confirm != true) return;

//     _showLoadingDialog();

//     try {
//       final response = await ApiClient.post(
//         "/api/Tutor/complete-course",
//         {
//           "courseId": courseId,
//         },
//       );

//       if (mounted) {
//         Navigator.of(context).pop();
//       }

//       if (response.statusCode >= 200 &&
//           response.statusCode < 300) {
//         await fetchMyStudents();

//         if (!mounted) return;

//         ScaffoldMessenger.of(context)
//             .showSnackBar(
//           SnackBar(
//             content: const Text(
//               "Course marked as completed successfully.",
//             ),
//             backgroundColor:
//                 Colors.green.shade600,
//             behavior:
//                 SnackBarBehavior.floating,
//           ),
//         );
//       } else {
//         _showError(
//           _extractErrorMessage(
//             response.body,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.of(context).pop();
//       }

//       _showError(
//         "Unable to complete course.\n$e",
//       );
//     }
//   }

//   // ============================================================
//   // 4. GIVE FEEDBACK
//   // API: POST /api/Tutor/give-feedback
//   // ============================================================

//   Future<void> _showFeedbackDialog({
//     required int studentId,
//     required int courseId,
//     required String studentName,
//     required String courseName,
//   }) async {
//     double rating = 5;

//     final TextEditingController
//         commentController =
//         TextEditingController();

//     bool isSubmitting = false;

//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (
//             context,
//             setDialogState,
//           ) {
//             return AlertDialog(
//               shape:
//                   RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(
//                   18,
//                 ),
//               ),
//               title: Row(
//                 children: [
//                   Icon(
//                     Icons.rate_review_outlined,
//                     color: primaryColor,
//                   ),
//                   const SizedBox(width: 8),
//                   const Expanded(
//                     child: Text(
//                       "Give Feedback",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight:
//                             FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               content:
//                   SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize:
//                       MainAxisSize.min,
//                   crossAxisAlignment:
//                       CrossAxisAlignment
//                           .start,
//                   children: [
//                     Text(
//                       studentName,
//                       style:
//                           const TextStyle(
//                         fontWeight:
//                             FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 3,
//                     ),
//                     Text(
//                       courseName,
//                       style: TextStyle(
//                         color: Colors
//                             .grey.shade600,
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 18,
//                     ),
//                     const Text(
//                       "Rating",
//                       style:
//                           TextStyle(
//                         fontWeight:
//                             FontWeight.w600,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 7,
//                     ),
//                     Row(
//                       children:
//                           List.generate(
//                         5,
//                         (index) {
//                           final int star =
//                               index + 1;

//                           return IconButton(
//                             onPressed: () {
//                               setDialogState(
//                                 () {
//                                   rating =
//                                       star.toDouble();
//                                 },
//                               );
//                             },
//                             padding:
//                                 EdgeInsets.zero,
//                             constraints:
//                                 const BoxConstraints(
//                               minWidth: 38,
//                               minHeight: 38,
//                             ),
//                             icon: Icon(
//                               star <= rating
//                                   ? Icons.star
//                                   : Icons.star_border,
//                               color:
//                                   Colors.amber.shade700,
//                               size: 30,
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 15,
//                     ),
//                     const Text(
//                       "Comment",
//                       style:
//                           TextStyle(
//                         fontWeight:
//                             FontWeight.w600,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 7,
//                     ),
//                     TextField(
//                       controller:
//                           commentController,
//                       maxLines: 4,
//                       decoration:
//                           InputDecoration(
//                         hintText:
//                             "Write feedback...",
//                         border:
//                             OutlineInputBorder(
//                           borderRadius:
//                               BorderRadius
//                                   .circular(
//                             10,
//                           ),
//                         ),
//                         focusedBorder:
//                             OutlineInputBorder(
//                           borderRadius:
//                               BorderRadius
//                                   .circular(
//                             10,
//                           ),
//                           borderSide:
//                               BorderSide(
//                             color:
//                                 primaryColor,
//                             width: 1.5,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed:
//                       isSubmitting
//                           ? null
//                           : () {
//                               Navigator.pop(
//                                 dialogContext,
//                               );
//                             },
//                   child:
//                       const Text(
//                     "Cancel",
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed:
//                       isSubmitting
//                           ? null
//                           : () async {
//                               setDialogState(
//                                 () {
//                                   isSubmitting =
//                                       true;
//                                 },
//                               );

//                               try {
//                                 final response =
//                                     await ApiClient
//                                         .post(
//                                   "/api/Tutor/give-feedback",
//                                   {
//                                     "studentId":
//                                         studentId,
//                                     "courseId":
//                                         courseId,
//                                     "rating":
//                                         rating.toInt(),
//                                     "comment":
//                                         commentController
//                                             .text
//                                             .trim(),
//                                   },
//                                 );

//                                 if (response
//                                             .statusCode >=
//                                         200 &&
//                                     response
//                                             .statusCode <
//                                         300) {
//                                   if (dialogContext
//                                       .mounted) {
//                                     Navigator.pop(
//                                       dialogContext,
//                                     );
//                                   }

//                                   await fetchMyStudents();

//                                   if (!mounted)
//                                     return;

//                                   ScaffoldMessenger
//                                           .of(
//                                     context,
//                                   )
//                                       .showSnackBar(
//                                     SnackBar(
//                                       content:
//                                           const Text(
//                                         "Feedback submitted successfully.",
//                                       ),
//                                       backgroundColor:
//                                           Colors
//                                               .green
//                                               .shade600,
//                                       behavior:
//                                           SnackBarBehavior
//                                               .floating,
//                                     ),
//                                   );
//                                 } else {
//                                   setDialogState(
//                                     () {
//                                       isSubmitting =
//                                           false;
//                                     },
//                                   );

//                                   _showError(
//                                     _extractErrorMessage(
//                                       response
//                                           .body,
//                                     ),
//                                   );
//                                 }
//                               } catch (e) {
//                                 setDialogState(
//                                   () {
//                                     isSubmitting =
//                                         false;
//                                   },
//                                 );

//                                 _showError(
//                                   "Unable to submit feedback.\n$e",
//                                 );
//                               }
//                             },
//                   style:
//                       ElevatedButton.styleFrom(
//                     backgroundColor:
//                         primaryColor,
//                     foregroundColor:
//                         Colors.white,
//                   ),
//                   child: isSubmitting
//                       ? const SizedBox(
//                           width: 18,
//                           height: 18,
//                           child:
//                               CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color:
//                                 Colors.white,
//                           ),
//                         )
//                       : const Text(
//                           "Submit",
//                         ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );

//     commentController.dispose();
//   }

//   // ============================================================
//   // STUDENT CARD
//   // ============================================================

//   Widget _buildStudentCard({
//     required int studentId,
//     required int courseId,
//     required String studentName,
//     required String courseName,
//     required bool isCompleted,
//     required String completedDate,
//     required bool feedbackGiven,
//   }) {
//     return Container(
//       margin:
//           const EdgeInsets.only(bottom: 14),
//       padding:
//           const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(18),
//         border: Border.all(
//           color: Colors.grey.shade200,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black
//                 .withOpacity(0.05),
//             blurRadius: 12,
//             offset:
//                 const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [
//           // ========================================================
//           // STUDENT HEADER
//           // ========================================================

//           Row(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration:
//                     BoxDecoration(
//                   gradient:
//                       LinearGradient(
//                     colors: [
//                       primaryColor,
//                       secondaryColor,
//                     ],
//                   ),
//                   borderRadius:
//                       BorderRadius
//                           .circular(14),
//                 ),
//                 child:
//                     const Icon(
//                   Icons.person,
//                   color:
//                       Colors.white,
//                   size: 25,
//                 ),
//               ),
//               const SizedBox(
//                 width: 12,
//               ),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment
//                           .start,
//                   children: [
//                     Text(
//                       studentName,
//                       maxLines: 1,
//                       overflow:
//                           TextOverflow
//                               .ellipsis,
//                       style:
//                           const TextStyle(
//                         fontSize: 16,
//                         fontWeight:
//                             FontWeight
//                                 .bold,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 5,
//                     ),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons
//                               .menu_book_outlined,
//                           size: 16,
//                           color: Colors
//                               .grey
//                               .shade600,
//                         ),
//                         const SizedBox(
//                           width: 5,
//                         ),
//                         Expanded(
//                           child:
//                               Text(
//                             courseName,
//                             maxLines:
//                                 1,
//                             overflow:
//                                 TextOverflow
//                                     .ellipsis,
//                             style:
//                                 TextStyle(
//                               fontSize:
//                                   12,
//                               color: Colors
//                                   .grey
//                                   .shade600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(
//             height: 14,
//           ),

//           // ========================================================
//           // STATUS ROW
//           // ========================================================

//           Row(
//             children: [
//               Expanded(
//                 child:
//                     Container(
//                   padding:
//                       const EdgeInsets
//                           .symmetric(
//                     horizontal:
//                         10,
//                     vertical: 8,
//                   ),
//                   decoration:
//                       BoxDecoration(
//                     color: isCompleted
//                         ? Colors
//                             .green
//                             .withOpacity(
//                             0.10,
//                           )
//                         : Colors
//                             .orange
//                             .withOpacity(
//                             0.10,
//                           ),
//                     borderRadius:
//                         BorderRadius
//                             .circular(
//                       10,
//                     ),
//                   ),
//                   child:
//                       Row(
//                     children: [
//                       Icon(
//                         isCompleted
//                             ? Icons
//                                 .check_circle_outline
//                             : Icons
//                                 .schedule_outlined,
//                         size: 17,
//                         color: isCompleted
//                             ? Colors
//                                 .green
//                             : Colors
//                                 .orange,
//                       ),
//                       const SizedBox(
//                         width: 6,
//                       ),
//                       Expanded(
//                         child:
//                             Text(
//                           isCompleted
//                               ? "Completed"
//                               : "In Progress",
//                           style:
//                               TextStyle(
//                             fontSize:
//                                 11,
//                             fontWeight:
//                                 FontWeight
//                                     .w600,
//                             color: isCompleted
//                                 ? Colors
//                                     .green
//                                 : Colors
//                                     .orange,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(
//                 width: 8,
//               ),
//               Expanded(
//                 child:
//                     Container(
//                   padding:
//                       const EdgeInsets
//                           .symmetric(
//                     horizontal:
//                         10,
//                     vertical: 8,
//                   ),
//                   decoration:
//                       BoxDecoration(
//                     color: feedbackGiven
//                         ? Colors
//                             .blue
//                             .withOpacity(
//                             0.10,
//                           )
//                         : Colors
//                             .grey
//                             .withOpacity(
//                             0.10,
//                           ),
//                     borderRadius:
//                         BorderRadius
//                             .circular(
//                       10,
//                     ),
//                   ),
//                   child:
//                       Row(
//                     children: [
//                       Icon(
//                         feedbackGiven
//                             ? Icons
//                                 .rate_review
//                             : Icons
//                                 .rate_review_outlined,
//                         size: 17,
//                         color: feedbackGiven
//                             ? Colors
//                                 .blue
//                             : Colors
//                                 .grey,
//                       ),
//                       const SizedBox(
//                         width: 6,
//                       ),
//                       Expanded(
//                         child:
//                             Text(
//                           feedbackGiven
//                               ? "Feedback Given"
//                               : "No Feedback",
//                           style:
//                               TextStyle(
//                             fontSize:
//                                 11,
//                             fontWeight:
//                                 FontWeight
//                                     .w600,
//                             color: feedbackGiven
//                                 ? Colors
//                                     .blue
//                                 : Colors
//                                     .grey
//                                     .shade700,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // ========================================================
//           // COMPLETED DATE
//           // ========================================================

//           if (isCompleted &&
//               completedDate.isNotEmpty)
//             Padding(
//               padding:
//                   const EdgeInsets
//                       .only(
//                 top: 8,
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons
//                         .event_available_outlined,
//                     size: 15,
//                     color: Colors
//                         .grey
//                         .shade600,
//                   ),
//                   const SizedBox(
//                     width: 5,
//                   ),
//                   Text(
//                     "Completed: ${_formatDate(completedDate)}",
//                     style:
//                         TextStyle(
//                       fontSize: 11,
//                       color: Colors
//                           .grey
//                           .shade600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//           const SizedBox(
//             height: 14,
//           ),

//           // ========================================================
//           // VIEW COURSE CONTENT
//           // ========================================================

//           SizedBox(
//             width: double.infinity,
//             height: 42,
//             child:
//                 OutlinedButton.icon(
//               onPressed: () {
//                 showCourseContent(
//                   studentId:
//                       studentId,
//                   courseId:
//                       courseId,
//                   studentName:
//                       studentName,
//                   courseName:
//                       courseName,
//                 );
//               },
//               icon: Icon(
//                 Icons
//                     .folder_copy_outlined,
//                 color:
//                     secondaryColor,
//                 size: 18,
//               ),
//               label: Text(
//                 "View Course Content",
//                 style:
//                     TextStyle(
//                   color:
//                       secondaryColor,
//                   fontWeight:
//                       FontWeight.w600,
//                   fontSize: 12,
//                 ),
//               ),
//               style:
//                   OutlinedButton
//                       .styleFrom(
//                 side: BorderSide(
//                   color: secondaryColor
//                       .withOpacity(
//                     0.5,
//                   ),
//                 ),
//                 shape:
//                     RoundedRectangleBorder(
//                   borderRadius:
//                       BorderRadius
//                           .circular(
//                     10,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(
//             height: 9,
//           ),

//           // ========================================================
//           // COMPLETE COURSE
//           // ========================================================

//           if (!isCompleted)
//             SizedBox(
//               width:
//                   double.infinity,
//               height: 42,
//               child:
//                   ElevatedButton
//                       .icon(
//                 onPressed: () =>
//                     completeCourse(
//                   courseId,
//                 ),
//                 icon:
//                     const Icon(
//                   Icons
//                       .check_circle_outline,
//                   size: 18,
//                 ),
//                 label:
//                     const Text(
//                   "Mark as Complete",
//                   style:
//                       TextStyle(
//                     fontSize: 12,
//                     fontWeight:
//                         FontWeight.w600,
//                   ),
//                 ),
//                 style:
//                     ElevatedButton
//                         .styleFrom(
//                   backgroundColor:
//                       primaryColor,
//                   foregroundColor:
//                       Colors.white,
//                   elevation: 0,
//                   shape:
//                       RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius
//                             .circular(
//                       10,
//                     ),
//                   ),
//                 ),
//               ),
//             )
//           else
//             Container(
//               width:
//                   double.infinity,
//               height: 42,
//               alignment:
//                   Alignment.center,
//               decoration:
//                   BoxDecoration(
//                 color: Colors.green
//                     .withOpacity(
//                   0.10,
//                 ),
//                 borderRadius:
//                     BorderRadius
//                         .circular(
//                   10,
//                 ),
//               ),
//               child: const Row(
//                 mainAxisAlignment:
//                     MainAxisAlignment
//                         .center,
//                 children: [
//                   Icon(
//                     Icons
//                         .check_circle,
//                     color:
//                         Colors.green,
//                     size: 18,
//                   ),
//                   SizedBox(
//                     width: 7,
//                   ),
//                   Text(
//                     "Course Completed",
//                     style:
//                         TextStyle(
//                       color:
//                           Colors.green,
//                       fontWeight:
//                           FontWeight
//                               .w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//           const SizedBox(
//             height: 9,
//           ),

//           // ========================================================
//           // FEEDBACK
//           // ========================================================

//           if (!feedbackGiven)
//             SizedBox(
//               width:
//                   double.infinity,
//               height: 42,
//               child:
//                   OutlinedButton
//                       .icon(
//                 onPressed: () {
//                   _showFeedbackDialog(
//                     studentId:
//                         studentId,
//                     courseId:
//                         courseId,
//                     studentName:
//                         studentName,
//                     courseName:
//                         courseName,
//                   );
//                 },
//                 icon: Icon(
//                   Icons
//                       .rate_review_outlined,
//                   color:
//                       secondaryColor,
//                   size: 18,
//                 ),
//                 label: Text(
//                   "Give Feedback",
//                   style:
//                       TextStyle(
//                     color:
//                         secondaryColor,
//                     fontWeight:
//                         FontWeight
//                             .w600,
//                     fontSize: 12,
//                   ),
//                 ),
//                 style:
//                     OutlinedButton
//                         .styleFrom(
//                   side: BorderSide(
//                     color: secondaryColor
//                         .withOpacity(
//                       0.5,
//                     ),
//                   ),
//                   shape:
//                       RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius
//                             .circular(
//                       10,
//                     ),
//                   ),
//                 ),
//               ),
//             )
//           else
//             Container(
//               width:
//                   double.infinity,
//               height: 42,
//               alignment:
//                   Alignment.center,
//               decoration:
//                   BoxDecoration(
//                 color: Colors.blue
//                     .withOpacity(
//                   0.08,
//                 ),
//                 borderRadius:
//                     BorderRadius
//                         .circular(
//                   10,
//                 ),
//               ),
//               child: const Row(
//                 mainAxisAlignment:
//                     MainAxisAlignment
//                         .center,
//                 children: [
//                   Icon(
//                     Icons
//                         .check_circle_outline,
//                     color:
//                         Colors.blue,
//                     size: 18,
//                   ),
//                   SizedBox(
//                     width: 7,
//                   ),
//                   Text(
//                     "Feedback Submitted",
//                     style:
//                         TextStyle(
//                       color:
//                           Colors.blue,
//                       fontWeight:
//                           FontWeight
//                               .w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // MAIN BUILD
//   // ============================================================

//   @override
//   Widget build(
//     BuildContext context,
//   ) {
//     return Scaffold(
//       backgroundColor:
//           backgroundColor,

//       // ==========================================================
//       // APP BAR
//       // ==========================================================

//       appBar: AppBar(
//         backgroundColor:
//             Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         title: Column(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "My Students",
//               style: TextStyle(
//                 color:
//                     Colors.black87,
//                 fontSize: 20,
//                 fontWeight:
//                     FontWeight.bold,
//               ),
//             ),
//             const SizedBox(
//               height: 2,
//             ),
//             Text(
//               "${studentsList.length} student course${studentsList.length == 1 ? '' : 's'}",
//               style:
//                   TextStyle(
//                 color: Colors
//                     .grey
//                     .shade600,
//                 fontSize: 11,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             onPressed:
//                 isLoading
//                     ? null
//                     : fetchMyStudents,
//             icon: Icon(
//               Icons.refresh,
//               color:
//                   primaryColor,
//             ),
//             tooltip:
//                 "Refresh",
//           ),
//           const SizedBox(
//             width: 6,
//           ),
//         ],
//       ),

//       // ==========================================================
//       // BODY
//       // ==========================================================

//       body:
//           RefreshIndicator(
//         onRefresh:
//             fetchMyStudents,
//         color:
//             primaryColor,
//         child: isLoading &&
//                 studentsList.isEmpty
//             ? ListView(
//                 physics:
//                     const AlwaysScrollableScrollPhysics(),
//                 children: [
//                   SizedBox(
//                     height:
//                         MediaQuery.of(
//                               context,
//                             )
//                             .size
//                             .height *
//                         0.35,
//                   ),
//                   Center(
//                     child:
//                         CircularProgressIndicator(
//                       color:
//                           primaryColor,
//                     ),
//                   ),
//                   const SizedBox(
//                     height: 15,
//                   ),
//                   const Center(
//                     child: Text(
//                       "Loading students...",
//                     ),
//                   ),
//                 ],
//               )
//             : studentsList.isEmpty
//                 ? ListView(
//                     physics:
//                         const AlwaysScrollableScrollPhysics(),
//                     children: [
//                       SizedBox(
//                         height:
//                             MediaQuery.of(
//                                   context,
//                                 )
//                                 .size
//                                 .height *
//                             0.25,
//                       ),
//                       Center(
//                         child:
//                             Container(
//                           width: 90,
//                           height: 90,
//                           decoration:
//                               BoxDecoration(
//                             color: primaryColor
//                                 .withOpacity(
//                               0.08,
//                             ),
//                             shape:
//                                 BoxShape
//                                     .circle,
//                           ),
//                           child:
//                               Icon(
//                             Icons
//                                 .people_outline,
//                             size:
//                                 45,
//                             color:
//                                 primaryColor,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(
//                         height: 18,
//                       ),
//                       const Center(
//                         child: Text(
//                           "No Students Found",
//                           style:
//                               TextStyle(
//                             fontSize:
//                                 18,
//                             fontWeight:
//                                 FontWeight
//                                     .bold,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(
//                         height: 7,
//                       ),
//                       Center(
//                         child:
//                             Text(
//                           "You currently have no students.",
//                           style:
//                               TextStyle(
//                             color: Colors
//                                 .grey
//                                 .shade600,
//                             fontSize:
//                                 13,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(
//                         height: 15,
//                       ),
//                       Center(
//                         child:
//                             OutlinedButton
//                                 .icon(
//                           onPressed:
//                               fetchMyStudents,
//                           icon:
//                               const Icon(
//                             Icons
//                                 .refresh,
//                             size:
//                                 17,
//                           ),
//                           label:
//                               const Text(
//                             "Refresh",
//                           ),
//                           style:
//                               OutlinedButton
//                                   .styleFrom(
//                             foregroundColor:
//                                 primaryColor,
//                             side:
//                                 BorderSide(
//                               color:
//                                   primaryColor,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   )
//                 : ListView
//                     .builder(
//                     physics:
//                         const AlwaysScrollableScrollPhysics(),
//                     padding:
//                         const EdgeInsets
//                             .fromLTRB(
//                       16,
//                       16,
//                       16,
//                       25,
//                     ),
//                     itemCount:
//                         studentsList.length,
//                     itemBuilder:
//                         (
//                       context,
//                       index,
//                     ) {
//                       final item =
//                           studentsList[
//                               index];

//                       final int
//                           studentId =
//                           _toInt(
//                         item[
//                             "studentId"],
//                       );

//                       final int
//                           courseId =
//                           _toInt(
//                         item[
//                             "courseId"],
//                       );

//                       final String
//                           studentName =
//                           item[
//                                       "studentName"]
//                                   ?.toString() ??
//                               "Student Name";

//                       final String
//                           courseName =
//                           item[
//                                       "courseName"]
//                                   ?.toString() ??
//                               "Course Name";

//                       final bool
//                           isCompleted =
//                           _toBool(
//                         item[
//                             "isCompleted"],
//                       );

//                       final String
//                           completedDate =
//                           item[
//                                       "completedDate"]
//                                   ?.toString() ??
//                               "";

//                       final bool
//                           feedbackGiven =
//                           _toBool(
//                         item[
//                             "feedbackGiven"],
//                       );

//                       return _buildStudentCard(
//                         studentId:
//                             studentId,
//                         courseId:
//                             courseId,
//                         studentName:
//                             studentName,
//                         courseName:
//                             courseName,
//                         isCompleted:
//                             isCompleted,
//                         completedDate:
//                             completedDate,
//                         feedbackGiven:
//                             feedbackGiven,
//                       );
//                     },
//                   ),
//       ),
//     );
//   }

//   // ============================================================
//   // LOADING DIALOG
//   // ============================================================

//   void _showLoadingDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return const Center(
//           child:
//               CircularProgressIndicator(),
//         );
//       },
//     );
//   }

//   // ============================================================
//   // ERROR MESSAGE
//   // ============================================================

//   void _showError(
//     String message,
//   ) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(
//       SnackBar(
//         content:
//             Text(message),
//         backgroundColor:
//             Colors.red.shade600,
//         behavior:
//             SnackBarBehavior
//                 .floating,
//         duration:
//             const Duration(
//           seconds: 4,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // EXTRACT API ERROR
//   // ============================================================

//   String _extractErrorMessage(
//     String body,
//   ) {
//     try {
//       final decoded =
//           jsonDecode(body);

//       if (decoded is Map) {
//         if (decoded["message"] !=
//             null) {
//           return decoded["message"]
//               .toString();
//         }

//         if (decoded["error"] !=
//             null) {
//           return decoded["error"]
//               .toString();
//         }

//         if (decoded["title"] !=
//             null) {
//           return decoded["title"]
//               .toString();
//         }
//       }

//       return body.isNotEmpty
//           ? body
//           : "Something went wrong.";
//     } catch (_) {
//       return body.isNotEmpty
//           ? body
//           : "Something went wrong.";
//     }
//   }

//   // ============================================================
//   // CONVERT TO INT
//   // ============================================================

//   int _toInt(
//     dynamic value,
//   ) {
//     if (value is int) {
//       return value;
//     }

//     if (value is double) {
//       return value.toInt();
//     }

//     return int.tryParse(
//           value?.toString() ?? "",
//         ) ??
//         0;
//   }

//   // ============================================================
//   // CONVERT TO BOOL
//   // ============================================================

//   bool _toBool(
//     dynamic value,
//   ) {
//     if (value is bool) {
//       return value;
//     }

//     if (value is String) {
//       return value.toLowerCase() ==
//               "true" ||
//           value == "1";
//     }

//     if (value is int) {
//       return value == 1;
//     }

//     return false;
//   }

//   // ============================================================
//   // FORMAT DATE
//   // ============================================================

//   String _formatDate(
//     String date,
//   ) {
//     try {
//       final parsed =
//           DateTime.parse(date);

//       final String day =
//           parsed.day
//               .toString()
//               .padLeft(
//                 2,
//                 "0",
//               );

//       final String month =
//           parsed.month
//               .toString()
//               .padLeft(
//                 2,
//                 "0",
//               );

//       final String year =
//           parsed.year.toString();

//       return "$day-$month-$year";
//     } catch (_) {
//       return date;
//     }
//   }
// }

















































// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// import 'package:house_of_tutor/services/api_client.dart';

// class TutorMyStudent extends StatefulWidget {
//   const TutorMyStudent({super.key});

//   @override
//   State<TutorMyStudent> createState() => _TutorMyStudentState();
// }

// class _TutorMyStudentState extends State<TutorMyStudent> {
//   // ============================================================
//   // COLORS
//   // ============================================================

//   final Color primaryColor = const Color(0xFF0F766E);
//   final Color secondaryColor = const Color(0xFF4F46E5);
//   final Color backgroundColor = const Color(0xFFF5F7FA);

//   // ============================================================
//   // VARIABLES
//   // ============================================================

//   bool isLoading = false;
//   List<dynamic> studentsList = [];

//   // ============================================================
//   // INIT
//   // ============================================================

//   @override
//   void initState() {
//     super.initState();
//     fetchMyStudents();
//   }

//   // ============================================================
//   // 1. GET MY STUDENTS
//   // API: GET /api/Tutor/my-students
//   // ============================================================

//   Future<void> fetchMyStudents() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final response = await ApiClient.get(
//         "/api/Tutor/my-students",
//       );

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);

//         if (decoded is List) {
//           setState(() {
//             studentsList = List<dynamic>.from(decoded);
//           });
//         } else if (decoded is Map && decoded["data"] is List) {
//           setState(() {
//             studentsList = List<dynamic>.from(decoded["data"]);
//           });
//         } else {
//           setState(() {
//             studentsList = [];
//           });
//           _showError("Invalid students data received.");
//         }
//       } else {
//         _showError(_extractErrorMessage(response.body));
//       }
//     } catch (e) {
//       _showError("Unable to load students.\n$e");
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   // ============================================================
//   // 2. VIEW COURSE CONTENT
//   // API: GET /api/Tutor/tutor-course-content/{studentId}/{courseId}
//   // ============================================================

//   Future<List<dynamic>> fetchCourseContent(
//     int studentId,
//     int courseId,
//   ) async {
//     try {
//       final response = await ApiClient.get(
//         "/api/Tutor/tutor-course-content/$studentId/$courseId",
//       );

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);

//         if (decoded is Map && decoded["data"] is List) {
//           return List<dynamic>.from(decoded["data"]);
//         }

//         if (decoded is List) {
//           return List<dynamic>.from(decoded);
//         }

//         return [];
//       }

//       if (response.statusCode == 403) {
//         throw Exception("You are not authorized to view this course content.");
//       }

//       throw Exception(_extractErrorMessage(response.body));
//     } catch (e) {
//       throw Exception(
//         e.toString().replaceFirst("Exception: ", ""),
//       );
//     }
//   }

//   // ============================================================
//   // SHOW COURSE CONTENT DIALOG
//   // ============================================================

//   Future<void> showCourseContent({
//     required int studentId,
//     required int courseId,
//     required String studentName,
//     required String courseName,
//   }) async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return const Center(
//           child: CircularProgressIndicator(),
//         );
//       },
//     );

//     try {
//       final contents = await fetchCourseContent(
//         studentId,
//         courseId,
//       );

//       if (mounted) {
//         Navigator.of(context).pop();
//       }

//       if (!mounted) return;

//       showDialog(
//         context: context,
//         builder: (context) {
//           return Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Container(
//               constraints: const BoxConstraints(
//                 maxHeight: 650,
//               ),
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         width: 45,
//                         height: 45,
//                         decoration: BoxDecoration(
//                           color: primaryColor.withOpacity(0.10),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(
//                           Icons.folder_copy_outlined,
//                           color: primaryColor,
//                           size: 25,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               "Course Content",
//                               style: TextStyle(
//                                 fontSize: 19,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 3),
//                             Text(
//                               courseName,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.grey.shade600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: () => Navigator.pop(context),
//                         icon: const Icon(Icons.close),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.person_outline,
//                           size: 20,
//                           color: secondaryColor,
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             studentName,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 13,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   if (contents.isEmpty)
//                     Expanded(
//                       child: Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.folder_off_outlined,
//                               size: 55,
//                               color: Colors.grey.shade400,
//                             ),
//                             const SizedBox(height: 12),
//                             Text(
//                               "No course content found.",
//                               style: TextStyle(
//                                 color: Colors.grey.shade600,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     )
//                   else
//                     Flexible(
//                       child: ListView.separated(
//                         shrinkWrap: true,
//                         itemCount: contents.length,
//                         separatorBuilder: (context, index) =>
//                             const SizedBox(height: 10),
//                         itemBuilder: (context, index) {
//                           final item = contents[index];

//                           final String title =
//                               item["title"]?.toString() ?? "Untitled";

//                           // Handle both snake_case and camelCase safely
//                           final String fileName =
//                               item["file_name"]?.toString() ??
//                               item["fileName"]?.toString() ??
//                               "";

//                           final String description =
//                               item["description"]?.toString() ?? "";

//                           final String fileUrl =
//                               item["file_url"]?.toString() ??
//                               item["fileUrl"]?.toString() ??
//                               "";

//                           final String filePath =
//                               item["file_path"]?.toString() ??
//                               item["filePath"]?.toString() ??
//                               "";

//                           final String uploadedDate =
//                               item["uploaded_date"]?.toString() ??
//                               item["uploadedDate"]?.toString() ??
//                               "";

//                           return _buildContentCard(
//                             title: title,
//                             fileName: fileName,
//                             description: description,
//                             fileUrl: fileUrl,
//                             filePath: filePath,
//                             uploadedDate: uploadedDate,
//                           );
//                         },
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     } catch (e) {
//       if (mounted) {
//         Navigator.of(context).pop();
//       }
//       _showError(e.toString().replaceFirst("Exception: ", ""));
//     }
//   }

//   // ============================================================
//   // COURSE CONTENT CARD
//   // ============================================================

//   Widget _buildContentCard({
//     required String title,
//     required String fileName,
//     required String description,
//     required String fileUrl,
//     required String filePath,
//     required String uploadedDate,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(13),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 38,
//                 height: 38,
//                 decoration: BoxDecoration(
//                   color: secondaryColor.withOpacity(0.10),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   Icons.description_outlined,
//                   color: secondaryColor,
//                   size: 21,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (description.isNotEmpty) ...[
//             const SizedBox(height: 10),
//             Text(
//               description,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey.shade700,
//                 height: 1.4,
//               ),
//             ),
//           ],
//           if (fileName.isNotEmpty) ...[
//             const SizedBox(height: 9),
//             Row(
//               children: [
//                 Icon(
//                   Icons.attach_file,
//                   size: 16,
//                   color: Colors.grey.shade600,
//                 ),
//                 const SizedBox(width: 5),
//                 Expanded(
//                   child: Text(
//                     fileName,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//           if (uploadedDate.isNotEmpty) ...[
//             const SizedBox(height: 5),
//             Text(
//               "Uploaded: ${_formatDate(uploadedDate)}",
//               style: TextStyle(
//                 fontSize: 10,
//                 color: Colors.grey.shade500,
//               ),
//             ),
//           ],
//           if (fileUrl.isNotEmpty || filePath.isNotEmpty) ...[
//             const SizedBox(height: 10),
//             SizedBox(
//               width: double.infinity,
//               height: 38,
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   _openFile(fileUrl, filePath);
//                 },
//                 icon: const Icon(
//                   Icons.open_in_new,
//                   size: 17,
//                 ),
//                 label: const Text(
//                   "Open File",
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: secondaryColor,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(9),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // OPEN FILE HANDLER
//   // ============================================================

//   Future<void> _openFile(String fileUrl, String filePath) async {
//     try {
//       String url = fileUrl.isNotEmpty ? fileUrl : filePath;

//       if (!url.startsWith("http://") && !url.startsWith("https://")) {
//         String baseUrl = ApiClient.baseUrlForFiles;
//         if (baseUrl.endsWith("/") && url.startsWith("/")) {
//           url = baseUrl.substring(0, baseUrl.length - 1) + url;
//         } else if (!baseUrl.endsWith("/") && !url.startsWith("/")) {
//           url = "$baseUrl/$url";
//         } else {
//           url = "$baseUrl$url";
//         }
//       }

//       final uri = Uri.parse(url);
//       final canOpen = await canLaunchUrl(uri);

//       if (!canOpen) {
//         _showError("Unable to open file.");
//         return;
//       }

//       await launchUrl(
//         uri,
//         mode: LaunchMode.externalApplication,
//       );
//     } catch (e) {
//       _showError("Unable to open file.\n$e");
//     }
//   }

//   // ============================================================
//   // 3. MARK COURSE COMPLETE
//   // API: POST /api/Tutor/complete-course
//   // ============================================================

//   Future<void> completeCourse(int courseId) async {
//     final bool? confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//           title: const Text(
//             "Mark Course Complete",
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           content: const Text(
//             "Are you sure you want to mark this course as completed?",
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, true),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryColor,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text("Complete"),
//             ),
//           ],
//         );
//       },
//     );

//     if (confirm != true) return;

//     _showLoadingDialog();

//     try {
//       final response = await ApiClient.post(
//         "/api/Tutor/complete-course",
//         {
//           "courseId": courseId,
//         },
//       );

//       if (mounted) {
//         Navigator.of(context).pop();
//       }

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         await fetchMyStudents();
//         if (!mounted) return;

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text("Course marked as completed successfully."),
//             backgroundColor: Colors.green.shade600,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       } else {
//         _showError(_extractErrorMessage(response.body));
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.of(context).pop();
//       }
//       _showError("Unable to complete course.\n$e");
//     }
//   }

//   // ============================================================
//   // 4. GIVE FEEDBACK
//   // API: POST /api/Tutor/give-feedback
//   // ============================================================

//   Future<void> _showFeedbackDialog({
//     required int studentId,
//     required int courseId,
//     required String studentName,
//     required String courseName,
//   }) async {
//     double rating = 5;
//     final TextEditingController commentController = TextEditingController();
//     bool isSubmitting = false;

//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(18),
//               ),
//               title: Row(
//                 children: [
//                   Icon(Icons.rate_review_outlined, color: primaryColor),
//                   const SizedBox(width: 8),
//                   const Expanded(
//                     child: Text(
//                       "Give Feedback",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       studentName,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 3),
//                     Text(
//                       courseName,
//                       style: TextStyle(
//                         color: Colors.grey.shade600,
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(height: 18),
//                     const Text(
//                       "Rating",
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const SizedBox(height: 7),
//                     Row(
//                       children: List.generate(5, (index) {
//                         final int star = index + 1;
//                         return IconButton(
//                           onPressed: () {
//                             setDialogState(() {
//                               rating = star.toDouble();
//                             });
//                           },
//                           padding: EdgeInsets.zero,
//                           constraints: const BoxConstraints(
//                             minWidth: 38,
//                             minHeight: 38,
//                           ),
//                           icon: Icon(
//                             star <= rating ? Icons.star : Icons.star_border,
//                             color: Colors.amber.shade700,
//                             size: 30,
//                           ),
//                         );
//                       }),
//                     ),
//                     const SizedBox(height: 15),
//                     const Text(
//                       "Comment",
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const SizedBox(height: 7),
//                     TextField(
//                       controller: commentController,
//                       maxLines: 4,
//                       decoration: InputDecoration(
//                         hintText: "Write feedback...",
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide(
//                             color: primaryColor,
//                             width: 1.5,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: isSubmitting
//                       ? null
//                       : () => Navigator.pop(dialogContext),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   onPressed: isSubmitting
//                       ? null
//                       : () async {
//                           setDialogState(() {
//                             isSubmitting = true;
//                           });

//                           try {
//                             final response = await ApiClient.post(
//                               "/api/Tutor/give-feedback",
//                               {
//                                 "studentId": studentId,
//                                 "courseId": courseId,
//                                 "rating": rating.toInt(),
//                                 "comment": commentController.text.trim(),
//                               },
//                             );

//                             if (response.statusCode >= 200 &&
//                                 response.statusCode < 300) {
//                               if (dialogContext.mounted) {
//                                 Navigator.pop(dialogContext);
//                               }

//                               await fetchMyStudents();
//                               if (!mounted) return;

//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: const Text(
//                                     "Feedback submitted successfully.",
//                                   ),
//                                   backgroundColor: Colors.green.shade600,
//                                   behavior: SnackBarBehavior.floating,
//                                 ),
//                               );
//                             } else {
//                               setDialogState(() {
//                                 isSubmitting = false;
//                               });
//                               _showError(_extractErrorMessage(response.body));
//                             }
//                           } catch (e) {
//                             setDialogState(() {
//                               isSubmitting = false;
//                             });
//                             _showError("Unable to submit feedback.\n$e");
//                           }
//                         },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryColor,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: isSubmitting
//                       ? const SizedBox(
//                           width: 18,
//                           height: 18,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : const Text("Submit"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );

//     commentController.dispose();
//   }

//   // ============================================================
//   // STUDENT CARD
//   // ============================================================

//   Widget _buildStudentCard({
//     required int studentId,
//     required int courseId,
//     required String studentName,
//     required String courseName,
//     required bool isCompleted,
//     required String completedDate,
//     required bool feedbackGiven,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [primaryColor, secondaryColor],
//                   ),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: const Icon(
//                   Icons.person,
//                   color: Colors.white,
//                   size: 25,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       studentName,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.menu_book_outlined,
//                           size: 16,
//                           color: Colors.grey.shade600,
//                         ),
//                         const SizedBox(width: 5),
//                         Expanded(
//                           child: Text(
//                             courseName,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),
//           Row(
//             children: [
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 8,
//                   ),
//                   decoration: BoxDecoration(
//                     color: isCompleted
//                         ? Colors.green.withOpacity(0.10)
//                         : Colors.orange.withOpacity(0.10),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         isCompleted
//                             ? Icons.check_circle_outline
//                             : Icons.schedule_outlined,
//                         size: 17,
//                         color: isCompleted ? Colors.green : Colors.orange,
//                       ),
//                       const SizedBox(width: 6),
//                       Expanded(
//                         child: Text(
//                           isCompleted ? "Completed" : "In Progress",
//                           style: TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                             color: isCompleted ? Colors.green : Colors.orange,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 8,
//                   ),
//                   decoration: BoxDecoration(
//                     color: feedbackGiven
//                         ? Colors.blue.withOpacity(0.10)
//                         : Colors.grey.withOpacity(0.10),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         feedbackGiven
//                             ? Icons.rate_review
//                             : Icons.rate_review_outlined,
//                         size: 17,
//                         color: feedbackGiven ? Colors.blue : Colors.grey,
//                       ),
//                       const SizedBox(width: 6),
//                       Expanded(
//                         child: Text(
//                           feedbackGiven ? "Feedback Given" : "No Feedback",
//                           style: TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                             color: feedbackGiven
//                                 ? Colors.blue
//                                 : Colors.grey.shade700,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (isCompleted && completedDate.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.event_available_outlined,
//                     size: 15,
//                     color: Colors.grey.shade600,
//                   ),
//                   const SizedBox(width: 5),
//                   Text(
//                     "Completed: ${_formatDate(completedDate)}",
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           const SizedBox(height: 14),
//           SizedBox(
//             width: double.infinity,
//             height: 42,
//             child: OutlinedButton.icon(
//               onPressed: () {
//                 showCourseContent(
//                   studentId: studentId,
//                   courseId: courseId,
//                   studentName: studentName,
//                   courseName: courseName,
//                 );
//               },
//               icon: Icon(
//                 Icons.folder_copy_outlined,
//                 color: secondaryColor,
//                 size: 18,
//               ),
//               label: Text(
//                 "View Course Content",
//                 style: TextStyle(
//                   color: secondaryColor,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 12,
//                 ),
//               ),
//               style: OutlinedButton.styleFrom(
//                 side: BorderSide(color: secondaryColor.withOpacity(0.5)),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 9),
//           if (!isCompleted)
//             SizedBox(
//               width: double.infinity,
//               height: 42,
//               child: ElevatedButton.icon(
//                 onPressed: () => completeCourse(courseId),
//                 icon: const Icon(Icons.check_circle_outline, size: 18),
//                 label: const Text(
//                   "Mark as Complete",
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryColor,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//             )
//           else
//             Container(
//               width: double.infinity,
//               height: 42,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.10),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.check_circle, color: Colors.green, size: 18),
//                   SizedBox(width: 7),
//                   Text(
//                     "Course Completed",
//                     style: TextStyle(
//                       color: Colors.green,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           const SizedBox(height: 9),
//           if (!feedbackGiven)
//             SizedBox(
//               width: double.infinity,
//               height: 42,
//               child: OutlinedButton.icon(
//                 onPressed: () {
//                   _showFeedbackDialog(
//                     studentId: studentId,
//                     courseId: courseId,
//                     studentName: studentName,
//                     courseName: courseName,
//                   );
//                 },
//                 icon: Icon(
//                   Icons.rate_review_outlined,
//                   color: secondaryColor,
//                   size: 18,
//                 ),
//                 label: Text(
//                   "Give Feedback",
//                   style: TextStyle(
//                     color: secondaryColor,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 12,
//                   ),
//                 ),
//                 style: OutlinedButton.styleFrom(
//                   side: BorderSide(color: secondaryColor.withOpacity(0.5)),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//             )
//           else
//             Container(
//               width: double.infinity,
//               height: 42,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.08),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.check_circle_outline, color: Colors.blue, size: 18),
//                   SizedBox(width: 7),
//                   Text(
//                     "Feedback Submitted",
//                     style: TextStyle(
//                       color: Colors.blue,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // MAIN BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "My Students",
//               style: TextStyle(
//                 color: Colors.black87,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               "${studentsList.length} student course${studentsList.length == 1 ? '' : 's'}",
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 11,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             onPressed: isLoading ? null : fetchMyStudents,
//             icon: Icon(Icons.refresh, color: primaryColor),
//             tooltip: "Refresh",
//           ),
//           const SizedBox(width: 6),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: fetchMyStudents,
//         color: primaryColor,
//         child: isLoading && studentsList.isEmpty
//             ? ListView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 children: [
//                   SizedBox(
//                     height: MediaQuery.of(context).size.height * 0.35,
//                   ),
//                   Center(
//                     child: CircularProgressIndicator(color: primaryColor),
//                   ),
//                   const SizedBox(height: 15),
//                   const Center(child: Text("Loading students...")),
//                 ],
//               )
//             : studentsList.isEmpty
//                 ? ListView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     children: [
//                       SizedBox(
//                         height: MediaQuery.of(context).size.height * 0.25,
//                       ),
//                       Center(
//                         child: Container(
//                           width: 90,
//                           height: 90,
//                           decoration: BoxDecoration(
//                             color: primaryColor.withOpacity(0.08),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.people_outline,
//                             size: 45,
//                             color: primaryColor,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 18),
//                       const Center(
//                         child: Text(
//                           "No Students Found",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 7),
//                       Center(
//                         child: Text(
//                           "You currently have no students.",
//                           style: TextStyle(
//                             color: Colors.grey.shade600,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 15),
//                       Center(
//                         child: OutlinedButton.icon(
//                           onPressed: fetchMyStudents,
//                           icon: const Icon(Icons.refresh, size: 17),
//                           label: const Text("Refresh"),
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: primaryColor,
//                             side: BorderSide(color: primaryColor),
//                           ),
//                         ),
//                       ),
//                     ],
//                   )
//                 : ListView.builder(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     padding: const EdgeInsets.fromLTRB(16, 16, 16, 25),
//                     itemCount: studentsList.length,
//                     itemBuilder: (context, index) {
//                       final item = studentsList[index];

//                       final int studentId = _toInt(item["studentId"]);
//                       final int courseId = _toInt(item["courseId"]);
//                       final String studentName =
//                           item["studentName"]?.toString() ?? "Student Name";
//                       final String courseName =
//                           item["courseName"]?.toString() ?? "Course Name";
//                       final bool isCompleted = _toBool(item["isCompleted"]);
//                       final String completedDate =
//                           item["completedDate"]?.toString() ?? "";
//                       final bool feedbackGiven = _toBool(item["feedbackGiven"]);

//                       return _buildStudentCard(
//                         studentId: studentId,
//                         courseId: courseId,
//                         studentName: studentName,
//                         courseName: courseName,
//                         isCompleted: isCompleted,
//                         completedDate: completedDate,
//                         feedbackGiven: feedbackGiven,
//                       );
//                     },
//                   ),
//       ),
//     );
//   }

//   // ============================================================
//   // HELPERS
//   // ============================================================

//   void _showLoadingDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator()),
//     );
//   }

//   void _showError(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red.shade600,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }

//   String _extractErrorMessage(String body) {
//     try {
//       final decoded = jsonDecode(body);
//       if (decoded is Map) {
//         if (decoded["message"] != null) return decoded["message"].toString();
//         if (decoded["error"] != null) return decoded["error"].toString();
//         if (decoded["title"] != null) return decoded["title"].toString();
//       }
//       return body.isNotEmpty ? body : "Something went wrong.";
//     } catch (_) {
//       return body.isNotEmpty ? body : "Something went wrong.";
//     }
//   }

//   int _toInt(dynamic value) {
//     if (value is int) return value;
//     if (value is double) return value.toInt();
//     return int.tryParse(value?.toString() ?? "") ?? 0;
//   }

//   bool _toBool(dynamic value) {
//     if (value is bool) return value;
//     if (value is String) return value.toLowerCase() == "true" || value == "1";
//     if (value is int) return value == 1;
//     return false;
//   }

//   String _formatDate(String date) {
//     try {
//       final parsed = DateTime.parse(date);
//       final String day = parsed.day.toString().padLeft(2, "0");
//       final String month = parsed.month.toString().padLeft(2, "0");
//       final String year = parsed.year.toString();
//       return "$day-$month-$year";
//     } catch (_) {
//       return date;
//     }
//   }
// }















































// // import 'dart:convert';

// // import 'package:flutter/material.dart';
// // import 'package:house_of_tutor/services/api_client.dart';
// // import 'package:url_launcher/url_launcher.dart';

// // class TutorMyStudent extends StatefulWidget {
// //   const TutorMyStudent({super.key});

// //   @override
// //   State<TutorMyStudent> createState() => _TutorMyStudentState();
// // }

// // class _TutorMyStudentState extends State<TutorMyStudent> {
// //   // =========================================================
// //   // COLORS
// //   // =========================================================

// //   static const Color primaryColor = Color(0xFF009688);
// //   static const Color darkPrimaryColor = Color(0xFF00695C);
// //   static const Color feedbackColor = Color(0xFF5C54ED);
// //   static const Color backgroundColor = Color(0xFFF5F7FA);

// //   // =========================================================
// //   // STATE VARIABLES
// //   // =========================================================

// //   bool isLoading = false;

// //   List<dynamic> studentsList = [];

// //   // =========================================================
// //   // INIT
// //   // =========================================================

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchMyStudents();
// //   }

// //   // =========================================================
// //   // FETCH MY STUDENTS
// //   // =========================================================

// //   Future<void> fetchMyStudents() async {
// //     if (!mounted) return;

// //     setState(() {
// //       isLoading = true;
// //     });

// //     try {
// //       final response = await ApiClient.get(
// //         "/api/Tutor/my-students",
// //       );

// //       if (response.statusCode == 200) {
// //         final decoded = jsonDecode(response.body);

// //         if (decoded is List) {
// //           if (!mounted) return;

// //           setState(() {
// //             studentsList = decoded;
// //           });
// //         } else if (decoded is Map && decoded["data"] != null) {
// //           if (!mounted) return;

// //           setState(() {
// //             studentsList = decoded["data"];
// //           });
// //         } else {
// //           if (!mounted) return;

// //           setState(() {
// //             studentsList = [];
// //           });
// //         }
// //       } else {
// //         if (!mounted) return;

// //         _showError(
// //           "Failed to load students (${response.statusCode})",
// //         );
// //       }
// //     } catch (e) {
// //       if (!mounted) return;

// //       _showError("Error: $e");
// //     } finally {
// //       if (mounted) {
// //         setState(() {
// //           isLoading = false;
// //         });
// //       }
// //     }
// //   }

// //   // =========================================================
// //   // COMPLETE COURSE API
// //   // =========================================================

// //   Future<void> completeCourse(int courseId) async {
// //     try {
// //       final response = await ApiClient.post(
// //         "/api/Tutor/complete-course",
// //         {
// //           "courseId": courseId,
// //         },
// //       );

// //       if (response.statusCode == 200) {
// //         if (!mounted) return;

// //         _showSuccess(
// //           "Course completed successfully",
// //         );

// //         await fetchMyStudents();
// //       } else {
// //         if (!mounted) return;

// //         _showError(
// //           _extractErrorMessage(response.body),
// //         );
// //       }
// //     } catch (e) {
// //       if (!mounted) return;

// //       _showError("Error: $e");
// //     }
// //   }

// //   // =========================================================
// //   // GET TUTOR COURSE CONTENT
// //   //
// //   // API:
// //   // GET
// //   // /api/Tutor/tutor-course-content/{studentId}/{courseId}
// //   // =========================================================

// //   Future<List<dynamic>> fetchCourseContent(
// //     int studentId,
// //     int courseId,
// //   ) async {
// //     try {
// //       final response = await ApiClient.get(
// //         "/api/Tutor/tutor-course-content/$studentId/$courseId",
// //       );

// //       print(
// //         "Course Content Status: ${response.statusCode}",
// //       );

// //       print(
// //         "Course Content Response: ${response.body}",
// //       );

// //       if (response.statusCode == 200) {
// //         final decoded = jsonDecode(response.body);

// //         // =====================================================
// //         // BACKEND RESPONSE:
// //         //
// //         // {
// //         //   "status": "Success",
// //         //   "message": "...",
// //         //   "count": 2,
// //         //   "data": [...]
// //         // }
// //         // =====================================================

// //         if (decoded is Map && decoded["data"] is List) {
// //           return List<dynamic>.from(
// //             decoded["data"],
// //           );
// //         }

// //         return [];
// //       }

// //       // =======================================================
// //       // FORBIDDEN
// //       // =======================================================

// //       if (response.statusCode == 403) {
// //         throw Exception(
// //           "You are not authorized to view this student's course content.",
// //         );
// //       }

// //       // =======================================================
// //       // OTHER ERROR
// //       // =======================================================

// //       throw Exception(
// //         _extractErrorMessage(response.body),
// //       );
// //     } catch (e) {
// //       rethrow;
// //     }
// //   }

// //   // =========================================================
// //   // SHOW COURSE CONTENT
// //   // =========================================================

// //   Future<void> showCourseContent(
// //     int studentId,
// //     int courseId,
// //     String studentName,
// //     String courseName,
// //   ) async {
// //     // =======================================================
// //     // SHOW LOADING DIALOG
// //     // =======================================================

// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) {
// //         return const Center(
// //           child: CircularProgressIndicator(
// //             color: primaryColor,
// //           ),
// //         );
// //       },
// //     );

// //     try {
// //       final contentList = await fetchCourseContent(
// //         studentId,
// //         courseId,
// //       );

// //       // Close loading dialog
// //       if (mounted) {
// //         Navigator.of(context).pop();
// //       }

// //       if (!mounted) return;

// //       // =====================================================
// //       // SHOW CONTENT DIALOG
// //       // =====================================================

// //       showDialog(
// //         context: context,
// //         builder: (dialogContext) {
// //           return Dialog(
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(20),
// //             ),
// //             child: Container(
// //               constraints: const BoxConstraints(
// //                 maxHeight: 650,
// //               ),
// //               padding: const EdgeInsets.all(20),
// //               child: Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   // =================================================
// //                   // HEADER
// //                   // =================================================

// //                   Row(
// //                     children: [
// //                       Container(
// //                         height: 45,
// //                         width: 45,
// //                         decoration: BoxDecoration(
// //                           color: Colors.teal.shade50,
// //                           borderRadius: BorderRadius.circular(12),
// //                         ),
// //                         child: const Icon(
// //                           Icons.folder_open_rounded,
// //                           color: darkPrimaryColor,
// //                         ),
// //                       ),

// //                       const SizedBox(width: 12),

// //                       Expanded(
// //                         child: Column(
// //                           crossAxisAlignment:
// //                               CrossAxisAlignment.start,
// //                           children: [
// //                             const Text(
// //                               "Course Content",
// //                               style: TextStyle(
// //                                 fontSize: 18,
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
// //                             const SizedBox(height: 3),
// //                             Text(
// //                               studentName,
// //                               style: TextStyle(
// //                                 fontSize: 12,
// //                                 color: Colors.grey.shade600,
// //                               ),
// //                             ),
// //                             Text(
// //                               courseName,
// //                               style: TextStyle(
// //                                 fontSize: 12,
// //                                 color: Colors.grey.shade600,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),

// //                       IconButton(
// //                         onPressed: () {
// //                           Navigator.pop(dialogContext);
// //                         },
// //                         icon: const Icon(
// //                           Icons.close,
// //                         ),
// //                       ),
// //                     ],
// //                   ),

// //                   const SizedBox(height: 16),

// //                   const Divider(),

// //                   const SizedBox(height: 8),

// //                   // =================================================
// //                   // NO CONTENT
// //                   // =================================================

// //                   if (contentList.isEmpty)
// //                     Padding(
// //                       padding: const EdgeInsets.symmetric(
// //                         vertical: 40,
// //                       ),
// //                       child: Column(
// //                         children: [
// //                           Container(
// //                             height: 65,
// //                             width: 65,
// //                             decoration: BoxDecoration(
// //                               color: Colors.grey.shade100,
// //                               shape: BoxShape.circle,
// //                             ),
// //                             child: Icon(
// //                               Icons.folder_off_outlined,
// //                               size: 32,
// //                               color: Colors.grey.shade500,
// //                             ),
// //                           ),

// //                           const SizedBox(height: 14),

// //                           const Text(
// //                             "No Course Content",
// //                             style: TextStyle(
// //                               fontSize: 16,
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                           ),

// //                           const SizedBox(height: 5),

// //                           Text(
// //                             "This student has not uploaded any\ncourse content yet.",
// //                             textAlign: TextAlign.center,
// //                             style: TextStyle(
// //                               fontSize: 13,
// //                               color: Colors.grey.shade600,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     )

// //                   // =================================================
// //                   // CONTENT LIST
// //                   // =================================================

// //                   else
// //                     Flexible(
// //                       child: ListView.builder(
// //                         shrinkWrap: true,
// //                         itemCount: contentList.length,
// //                         itemBuilder: (context, index) {
// //                           final content =
// //                               contentList[index];

// //                           final String title =
// //                               content["title"]?.toString() ??
// //                                   "Untitled Content";

// //                           final String description =
// //                               content["description"]
// //                                       ?.toString() ??
// //                                   "";

// //                           final String fileName =
// //                               content["file_name"]
// //                                       ?.toString() ??
// //                                   "";

// //                           final String fileUrl =
// //                               content["file_url"]
// //                                       ?.toString() ??
// //                                   "";

// //                           final String uploadedDate =
// //                               content["uploaded_date"]
// //                                       ?.toString() ??
// //                                   "";

// //                           return _buildContentCard(
// //                             title: title,
// //                             description: description,
// //                             fileName: fileName,
// //                             fileUrl: fileUrl,
// //                             uploadedDate: uploadedDate,
// //                           );
// //                         },
// //                       ),
// //                     ),

// //                   const SizedBox(height: 10),

// //                   // =================================================
// //                   // CLOSE BUTTON
// //                   // =================================================

// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: ElevatedButton(
// //                       onPressed: () {
// //                         Navigator.pop(dialogContext);
// //                       },
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: primaryColor,
// //                         elevation: 0,
// //                         padding: const EdgeInsets.symmetric(
// //                           vertical: 13,
// //                         ),
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius:
// //                               BorderRadius.circular(12),
// //                         ),
// //                       ),
// //                       child: const Text(
// //                         "Close",
// //                         style: TextStyle(
// //                           color: Colors.white,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           );
// //         },
// //       );
// //     } catch (e) {
// //       // Close loading dialog if still open
// //       if (mounted) {
// //         Navigator.of(context).pop();
// //       }

// //       if (!mounted) return;

// //       _showError(
// //         e.toString().replaceFirst(
// //               "Exception: ",
// //               "",
// //             ),
// //       );
// //     }
// //   }

// //   // =========================================================
// //   // CONTENT CARD
// //   // =========================================================

// //   Widget _buildContentCard({
// //     required String title,
// //     required String description,
// //     required String fileName,
// //     required String fileUrl,
// //     required String uploadedDate,
// //   }) {
// //     return Container(
// //       margin: const EdgeInsets.only(
// //         bottom: 12,
// //       ),
// //       padding: const EdgeInsets.all(14),
// //       decoration: BoxDecoration(
// //         color: Colors.grey.shade50,
// //         borderRadius: BorderRadius.circular(14),
// //         border: Border.all(
// //           color: Colors.grey.shade200,
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // =====================================================
// //           // TITLE
// //           // =====================================================

// //           Row(
// //             crossAxisAlignment:
// //                 CrossAxisAlignment.start,
// //             children: [
// //               Container(
// //                 height: 38,
// //                 width: 38,
// //                 decoration: BoxDecoration(
// //                   color: Colors.teal.shade50,
// //                   borderRadius:
// //                       BorderRadius.circular(10),
// //                 ),
// //                 child: const Icon(
// //                   Icons.description_outlined,
// //                   color: darkPrimaryColor,
// //                   size: 20,
// //                 ),
// //               ),

// //               const SizedBox(width: 10),

// //               Expanded(
// //                 child: Text(
// //                   title,
// //                   style: const TextStyle(
// //                     fontSize: 15,
// //                     fontWeight: FontWeight.bold,
// //                     color: Colors.black87,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),

// //           // =====================================================
// //           // DESCRIPTION
// //           // =====================================================

// //           if (description.isNotEmpty) ...[
// //             const SizedBox(height: 12),

// //             Text(
// //               description,
// //               style: TextStyle(
// //                 fontSize: 13,
// //                 color: Colors.grey.shade700,
// //                 height: 1.4,
// //               ),
// //             ),
// //           ],

// //           const SizedBox(height: 12),

// //           // =====================================================
// //           // FILE NAME
// //           // =====================================================

// //           if (fileName.isNotEmpty)
// //             Container(
// //               padding: const EdgeInsets.all(10),
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius:
// //                     BorderRadius.circular(10),
// //                 border: Border.all(
// //                   color: Colors.grey.shade200,
// //                 ),
// //               ),
// //               child: Row(
// //                 children: [
// //                   Icon(
// //                     _getFileIcon(fileName),
// //                     color: Colors.indigo.shade600,
// //                     size: 20,
// //                   ),

// //                   const SizedBox(width: 8),

// //                   Expanded(
// //                     child: Text(
// //                       fileName,
// //                       maxLines: 2,
// //                       overflow: TextOverflow.ellipsis,
// //                       style: TextStyle(
// //                         fontSize: 12,
// //                         color: Colors.grey.shade700,
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //           // =====================================================
// //           // UPLOAD DATE
// //           // =====================================================

// //           if (uploadedDate.isNotEmpty) ...[
// //             const SizedBox(height: 10),

// //             Row(
// //               children: [
// //                 Icon(
// //                   Icons.calendar_today_outlined,
// //                   size: 14,
// //                   color: Colors.grey.shade500,
// //                 ),

// //                 const SizedBox(width: 5),

// //                 Text(
// //                   "Uploaded: ${_formatDate(uploadedDate)}",
// //                   style: TextStyle(
// //                     fontSize: 11,
// //                     color: Colors.grey.shade600,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ],

// //           // =====================================================
// //           // OPEN FILE BUTTON
// //           // =====================================================

// //           if (fileUrl.isNotEmpty) ...[
// //             const SizedBox(height: 12),

// //             SizedBox(
// //               width: double.infinity,
// //               child: ElevatedButton.icon(
// //                 onPressed: () {
// //                   _openFile(fileUrl);
// //                 },
// //                 icon: const Icon(
// //                   Icons.open_in_new,
// //                   color: Colors.white,
// //                   size: 17,
// //                 ),
// //                 label: const Text(
// //                   "Open File",
// //                   style: TextStyle(
// //                     color: Colors.white,
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 13,
// //                   ),
// //                 ),
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: feedbackColor,
// //                   elevation: 0,
// //                   padding: const EdgeInsets.symmetric(
// //                     vertical: 11,
// //                   ),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius:
// //                         BorderRadius.circular(10),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }

// //   // =========================================================
// //   // OPEN FILE
// //   // =========================================================

// //   Future<void> _openFile(String fileUrl) async {
// //     try {
// //       final Uri url = Uri.parse(fileUrl);

// //       final bool canOpen =
// //           await canLaunchUrl(url);

// //       if (canOpen) {
// //         await launchUrl(
// //           url,
// //           mode: LaunchMode.externalApplication,
// //         );
// //       } else {
// //         if (!mounted) return;

// //         _showError(
// //           "Cannot open this file.",
// //         );
// //       }
// //     } catch (e) {
// //       if (!mounted) return;

// //       _showError(
// //         "Unable to open file.",
// //       );
// //     }
// //   }

// //   // =========================================================
// //   // FILE ICON
// //   // =========================================================

// //   IconData _getFileIcon(String fileName) {
// //     final String name =
// //         fileName.toLowerCase();

// //     if (name.endsWith(".pdf")) {
// //       return Icons.picture_as_pdf_outlined;
// //     }

// //     if (name.endsWith(".doc") ||
// //         name.endsWith(".docx")) {
// //       return Icons.article_outlined;
// //     }

// //     if (name.endsWith(".jpg") ||
// //         name.endsWith(".jpeg") ||
// //         name.endsWith(".png")) {
// //       return Icons.image_outlined;
// //     }

// //     return Icons.insert_drive_file_outlined;
// //   }

// //   // =========================================================
// //   // FORMAT DATE
// //   // =========================================================

// //   String _formatDate(String date) {
// //     try {
// //       final DateTime parsed =
// //           DateTime.parse(date);

// //       final String day =
// //           parsed.day.toString().padLeft(2, "0");

// //       final String month =
// //           parsed.month.toString().padLeft(2, "0");

// //       final String year =
// //           parsed.year.toString();

// //       return "$day-$month-$year";
// //     } catch (_) {
// //       return date;
// //     }
// //   }

// //   // =========================================================
// //   // FEEDBACK DIALOG
// //   // =========================================================

// //   void _showFeedbackDialog(
// //     int studentId,
// //     int courseId,
// //     String studentName,
// //     String courseName,
// //   ) {
// //     final TextEditingController
// //         commentController =
// //         TextEditingController();

// //     double rating = 5.0;

// //     showDialog(
// //       context: context,
// //       builder: (context) {
// //         return StatefulBuilder(
// //           builder: (
// //             context,
// //             setDialogState,
// //           ) {
// //             String getRatingText(double r) {
// //               if (r >= 4.5) return "Excellent!";
// //               if (r >= 3.5) return "Very Good!";
// //               if (r >= 2.5) return "Good";
// //               if (r >= 1.5) return "Fair";

// //               return "Needs Improvement";
// //             }

// //             return AlertDialog(
// //               shape: RoundedRectangleBorder(
// //                 borderRadius:
// //                     BorderRadius.circular(20),
// //               ),
// //               title: Row(
// //                 mainAxisAlignment:
// //                     MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   const Text(
// //                     "Student Feedback",
// //                     style: TextStyle(
// //                       fontWeight: FontWeight.bold,
// //                       fontSize: 18,
// //                     ),
// //                   ),
// //                   IconButton(
// //                     icon: const Icon(
// //                       Icons.close,
// //                       size: 20,
// //                       color: Colors.grey,
// //                     ),
// //                     onPressed: () =>
// //                         Navigator.pop(context),
// //                   ),
// //                 ],
// //               ),
// //               content:
// //                   SingleChildScrollView(
// //                 child: Column(
// //                   mainAxisSize:
// //                       MainAxisSize.min,
// //                   crossAxisAlignment:
// //                       CrossAxisAlignment.start,
// //                   children: [
// //                     Container(
// //                       width: double.infinity,
// //                       padding:
// //                           const EdgeInsets.all(12),
// //                       decoration:
// //                           BoxDecoration(
// //                         color:
// //                             Colors.grey.shade50,
// //                         borderRadius:
// //                             BorderRadius.circular(
// //                           12,
// //                         ),
// //                         border: Border(
// //                           left: BorderSide(
// //                             color:
// //                                 Colors.indigo.shade700,
// //                             width: 4,
// //                           ),
// //                         ),
// //                       ),
// //                       child: Column(
// //                         crossAxisAlignment:
// //                             CrossAxisAlignment
// //                                 .start,
// //                         children: [
// //                           Text(
// //                             studentName,
// //                             style:
// //                                 const TextStyle(
// //                               fontWeight:
// //                                   FontWeight.bold,
// //                               fontSize: 16,
// //                               color:
// //                                   Colors.black87,
// //                             ),
// //                           ),
// //                           const SizedBox(
// //                             height: 2,
// //                           ),
// //                           Text(
// //                             courseName,
// //                             style: TextStyle(
// //                               fontSize: 13,
// //                               color: Colors
// //                                   .grey.shade600,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),

// //                     const SizedBox(height: 20),

// //                     const Text(
// //                       "RATING SCORE",
// //                       style: TextStyle(
// //                         fontSize: 12,
// //                         color: Colors.grey,
// //                         fontWeight:
// //                             FontWeight.bold,
// //                         letterSpacing: 0.5,
// //                       ),
// //                     ),

// //                     const SizedBox(height: 10),

// //                     Center(
// //                       child: Row(
// //                         mainAxisAlignment:
// //                             MainAxisAlignment
// //                                 .center,
// //                         children:
// //                             List.generate(
// //                           5,
// //                           (index) {
// //                             return GestureDetector(
// //                               onTap: () {
// //                                 setDialogState(
// //                                   () {
// //                                     rating =
// //                                         (index + 1)
// //                                             .toDouble();
// //                                   },
// //                                 );
// //                               },
// //                               child: Padding(
// //                                 padding:
// //                                     const EdgeInsets
// //                                         .symmetric(
// //                                   horizontal: 4,
// //                                 ),
// //                                 child: Icon(
// //                                   index < rating
// //                                       ? Icons.star
// //                                       : Icons.star_border,
// //                                   color:
// //                                       Colors.amber,
// //                                   size: 32,
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                         ),
// //                       ),
// //                     ),

// //                     const SizedBox(height: 6),

// //                     Center(
// //                       child: Text(
// //                         getRatingText(
// //                           rating,
// //                         ),
// //                         style: TextStyle(
// //                           color:
// //                               Colors.amber.shade800,
// //                           fontWeight:
// //                               FontWeight.bold,
// //                           fontSize: 13,
// //                         ),
// //                       ),
// //                     ),

// //                     const SizedBox(height: 20),

// //                     const Text(
// //                       "FEEDBACK COMMENTS",
// //                       style: TextStyle(
// //                         fontSize: 12,
// //                         color: Colors.grey,
// //                         fontWeight:
// //                             FontWeight.bold,
// //                         letterSpacing: 0.5,
// //                       ),
// //                     ),

// //                     const SizedBox(height: 8),

// //                     TextField(
// //                       controller:
// //                           commentController,
// //                       maxLines: 4,
// //                       decoration:
// //                           InputDecoration(
// //                         hintText:
// //                             "Share performance insights, progress notes, or recommendations...",
// //                         hintStyle:
// //                             TextStyle(
// //                           color:
// //                               Colors.grey.shade400,
// //                           fontSize: 13,
// //                         ),
// //                         border:
// //                             OutlineInputBorder(
// //                           borderRadius:
// //                               BorderRadius.circular(
// //                             12,
// //                           ),
// //                           borderSide:
// //                               BorderSide(
// //                             color:
// //                                 Colors.grey.shade300,
// //                           ),
// //                         ),
// //                         enabledBorder:
// //                             OutlineInputBorder(
// //                           borderRadius:
// //                               BorderRadius.circular(
// //                             12,
// //                           ),
// //                           borderSide:
// //                               BorderSide(
// //                             color:
// //                                 Colors.grey.shade300,
// //                           ),
// //                         ),
// //                         contentPadding:
// //                             const EdgeInsets.all(
// //                           14,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               actionsPadding:
// //                   const EdgeInsets.fromLTRB(
// //                 20,
// //                 0,
// //                 20,
// //                 20,
// //               ),
// //               actions: [
// //                 Row(
// //                   children: [
// //                     Expanded(
// //                       child: TextButton(
// //                         style:
// //                             TextButton.styleFrom(
// //                           backgroundColor:
// //                               Colors.grey.shade100,
// //                           padding:
// //                               const EdgeInsets
// //                                   .symmetric(
// //                             vertical: 14,
// //                           ),
// //                           shape:
// //                               RoundedRectangleBorder(
// //                             borderRadius:
// //                                 BorderRadius.circular(
// //                               12,
// //                             ),
// //                           ),
// //                         ),
// //                         onPressed: () =>
// //                             Navigator.pop(
// //                           context,
// //                         ),
// //                         child: const Text(
// //                           "Cancel",
// //                           style: TextStyle(
// //                             color:
// //                                 Colors.black87,
// //                             fontWeight:
// //                                 FontWeight.bold,
// //                           ),
// //                         ),
// //                       ),
// //                     ),

// //                     const SizedBox(width: 12),

// //                     Expanded(
// //                       flex: 2,
// //                       child: ElevatedButton(
// //                         style:
// //                             ElevatedButton.styleFrom(
// //                           backgroundColor:
// //                               feedbackColor,
// //                           elevation: 0,
// //                           padding:
// //                               const EdgeInsets
// //                                   .symmetric(
// //                             vertical: 14,
// //                           ),
// //                           shape:
// //                               RoundedRectangleBorder(
// //                             borderRadius:
// //                                 BorderRadius.circular(
// //                               12,
// //                             ),
// //                           ),
// //                         ),
// //                         onPressed: () async {
// //                           Navigator.pop(
// //                             context,
// //                           );

// //                           await submitFeedback(
// //                             studentId,
// //                             courseId,
// //                             rating,
// //                             commentController
// //                                 .text,
// //                           );

// //                           commentController
// //                               .dispose();
// //                         },
// //                         child: const Text(
// //                           "Submit Feedback",
// //                           style: TextStyle(
// //                             color:
// //                                 Colors.white,
// //                             fontWeight:
// //                                 FontWeight.bold,
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }

// //   // =========================================================
// //   // SUBMIT FEEDBACK
// //   // =========================================================

// //   Future<void> submitFeedback(
// //     int studentId,
// //     int courseId,
// //     double rating,
// //     String comment,
// //   ) async {
// //     try {
// //       final response = await ApiClient.post(
// //         "/api/Tutor/give-feedback",
// //         {
// //           "studentId": studentId,
// //           "courseId": courseId,

// //           // Backend expects integer rating
// //           "rating": rating.toInt(),

// //           "comment": comment,
// //         },
// //       );

// //       print(
// //         "Feedback Response Code: ${response.statusCode}",
// //       );

// //       print(
// //         "Feedback Response Body: ${response.body}",
// //       );

// //       if (response.statusCode == 200) {
// //         if (!mounted) return;

// //         _showSuccess(
// //           "Feedback submitted successfully",
// //         );

// //         await fetchMyStudents();
// //       } else {
// //         if (!mounted) return;

// //         _showError(
// //           _extractErrorMessage(
// //             response.body,
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       if (!mounted) return;

// //       _showError("Error: $e");
// //     }
// //   }

// //   // =========================================================
// //   // ERROR MESSAGE
// //   // =========================================================

// //   String _extractErrorMessage(
// //     String body,
// //   ) {
// //     if (body.trim().isEmpty) {
// //       return "Server returned an empty response.";
// //     }

// //     try {
// //       final decoded =
// //           jsonDecode(body);

// //       if (decoded is Map) {
// //         if (decoded["message"] != null) {
// //           return decoded["message"]
// //               .toString();
// //         }

// //         if (decoded["errors"] != null &&
// //             decoded["errors"] is Map) {
// //           final errors =
// //               decoded["errors"] as Map;

// //           if (errors.isNotEmpty) {
// //             final firstField =
// //                 errors.values.first;

// //             if (firstField is List &&
// //                 firstField.isNotEmpty) {
// //               return firstField.first
// //                   .toString();
// //             }
// //           }
// //         }

// //         if (decoded["title"] != null) {
// //           return decoded["title"]
// //               .toString();
// //         }
// //       }
// //     } catch (_) {}

// //     return "Request failed.";
// //   }

// //   // =========================================================
// //   // INITIALS
// //   // =========================================================

// //   String _getInitials(String name) {
// //     if (name.trim().isEmpty) {
// //       return "S";
// //     }

// //     final List<String> parts =
// //         name.trim().split(" ");

// //     if (parts.length >= 2) {
// //       return "${parts[0][0]}${parts[1][0]}"
// //           .toUpperCase();
// //     }

// //     return parts[0][0].toUpperCase();
// //   }

// //   // =========================================================
// //   // SUCCESS SNACKBAR
// //   // =========================================================

// //   void _showSuccess(String message) {
// //     if (!mounted) return;

// //     ScaffoldMessenger.of(context)
// //         .showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Colors.green,
// //       ),
// //     );
// //   }

// //   // =========================================================
// //   // ERROR SNACKBAR
// //   // =========================================================

// //   void _showError(String message) {
// //     if (!mounted) return;

// //     ScaffoldMessenger.of(context)
// //         .showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }

// //   // =========================================================
// //   // BUILD
// //   // =========================================================

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: backgroundColor,

// //       // =======================================================
// //       // APP BAR
// //       // =======================================================

// //       appBar: AppBar(
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         centerTitle: true,

// //         leading: IconButton(
// //           icon: const Icon(
// //             Icons.arrow_back_ios_new,
// //             color: Colors.black87,
// //             size: 20,
// //           ),
// //           onPressed: () =>
// //               Navigator.pop(context),
// //         ),

// //         title: Row(
// //           mainAxisSize:
// //               MainAxisSize.min,
// //           children: [
// //             Container(
// //               height: 28,
// //               width: 28,
// //               decoration: BoxDecoration(
// //                 color: Colors.teal.shade50,
// //                 borderRadius:
// //                     BorderRadius.circular(6),
// //               ),
// //               child: const Icon(
// //                 Icons.school,
// //                 color: darkPrimaryColor,
// //                 size: 18,
// //               ),
// //             ),

// //             const SizedBox(width: 8),

// //             const Text(
// //               "House of Tutor",
// //               style: TextStyle(
// //                 color: Colors.black87,
// //                 fontSize: 16,
// //                 fontWeight:
// //                     FontWeight.bold,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),

// //       // =======================================================
// //       // BODY
// //       // =======================================================

// //       body: SafeArea(
// //         child: isLoading
// //             ? const Center(
// //                 child:
// //                     CircularProgressIndicator(
// //                   color: primaryColor,
// //                 ),
// //               )
// //             : Padding(
// //                 padding:
// //                     const EdgeInsets.all(16),
// //                 child: Column(
// //                   crossAxisAlignment:
// //                       CrossAxisAlignment.start,
// //                   children: [
// //                     // ===========================================
// //                     // HEADER
// //                     // ===========================================

// //                     Row(
// //                       children: [
// //                         const Text(
// //                           "My Students",
// //                           style: TextStyle(
// //                             fontSize: 20,
// //                             fontWeight:
// //                                 FontWeight.bold,
// //                             color:
// //                                 Colors.black87,
// //                           ),
// //                         ),

// //                         const SizedBox(
// //                           width: 8,
// //                         ),

// //                         Container(
// //                           padding:
// //                               const EdgeInsets
// //                                   .symmetric(
// //                             horizontal: 8,
// //                             vertical: 2,
// //                           ),
// //                           decoration:
// //                               BoxDecoration(
// //                             color:
// //                                 Colors.teal.shade50,
// //                             borderRadius:
// //                                 BorderRadius.circular(
// //                               12,
// //                             ),
// //                           ),
// //                           child: Text(
// //                             "${studentsList.length}",
// //                             style:
// //                                 const TextStyle(
// //                               color:
// //                                   darkPrimaryColor,
// //                               fontWeight:
// //                                   FontWeight.bold,
// //                               fontSize: 12,
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),

// //                     const SizedBox(
// //                       height: 16,
// //                     ),

// //                     // ===========================================
// //                     // STUDENTS LIST
// //                     // ===========================================

// //                     Expanded(
// //                       child: studentsList.isEmpty
// //                           ? Center(
// //                               child: Column(
// //                                 mainAxisSize:
// //                                     MainAxisSize.min,
// //                                 children: [
// //                                   Icon(
// //                                     Icons
// //                                         .school_outlined,
// //                                     size: 55,
// //                                     color: Colors
// //                                         .grey.shade400,
// //                                   ),

// //                                   const SizedBox(
// //                                     height: 10,
// //                                   ),

// //                                   Text(
// //                                     "No students found",
// //                                     style:
// //                                         TextStyle(
// //                                       fontSize:
// //                                           15,
// //                                       color: Colors
// //                                           .grey.shade600,
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             )
// //                           : RefreshIndicator(
// //                               color:
// //                                   primaryColor,
// //                               onRefresh:
// //                                   fetchMyStudents,
// //                               child:
// //                                   ListView.builder(
// //                                 itemCount:
// //                                     studentsList
// //                                         .length,
// //                                 itemBuilder:
// //                                     (context,
// //                                         index) {
// //                                   final item =
// //                                       studentsList[
// //                                           index];

// //                                   final int
// //                                       studentId =
// //                                       _toInt(
// //                                     item[
// //                                         "studentId"],
// //                                   );

// //                                   final int
// //                                       courseId =
// //                                       _toInt(
// //                                     item[
// //                                         "courseId"],
// //                                   );

// //                                   final String
// //                                       studentName =
// //                                       item[
// //                                               "studentName"]
// //                                           ?.toString() ??
// //                                           "Student Name";

// //                                   final String
// //                                       courseName =
// //                                       item[
// //                                               "courseName"]
// //                                           ?.toString() ??
// //                                           "Course Name";

// //                                   final bool
// //                                       isCompleted =
// //                                       item[
// //                                               "isCompleted"] ==
// //                                           true;

// //                                   final bool
// //                                       feedbackGiven =
// //                                       item[
// //                                               "feedbackGiven"] ==
// //                                           true;

// //                                   return _buildStudentCard(
// //                                     studentId:
// //                                         studentId,
// //                                     courseId:
// //                                         courseId,
// //                                     studentName:
// //                                         studentName,
// //                                     courseName:
// //                                         courseName,
// //                                     isCompleted:
// //                                         isCompleted,
// //                                     feedbackGiven:
// //                                         feedbackGiven,
// //                                   );
// //                                 },
// //                               ),
// //                             ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //       ),
// //     );
// //   }

// //   // =========================================================
// //   // STUDENT CARD
// //   // =========================================================

// //   Widget _buildStudentCard({
// //     required int studentId,
// //     required int courseId,
// //     required String studentName,
// //     required String courseName,
// //     required bool isCompleted,
// //     required bool feedbackGiven,
// //   }) {
// //     return Container(
// //       margin:
// //           const EdgeInsets.only(bottom: 16),
// //       padding:
// //           const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius:
// //             BorderRadius.circular(16),
// //         border: Border.all(
// //           color: Colors.grey.shade200,
// //         ),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black
// //                 .withOpacity(0.03),
// //             blurRadius: 8,
// //             offset:
// //                 const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment:
// //             CrossAxisAlignment.start,
// //         children: [
// //           // =====================================================
// //           // STUDENT INFO
// //           // =====================================================

// //           Row(
// //             children: [
// //               Container(
// //                 height: 45,
// //                 width: 45,
// //                 decoration:
// //                     BoxDecoration(
// //                   color:
// //                       Colors.indigo.shade50,
// //                   borderRadius:
// //                       BorderRadius.circular(
// //                     25,
// //                   ),
// //                 ),
// //                 child: Center(
// //                   child: Text(
// //                     _getInitials(
// //                       studentName,
// //                     ),
// //                     style: TextStyle(
// //                       color: Colors
// //                           .indigo.shade700,
// //                       fontWeight:
// //                           FontWeight.bold,
// //                       fontSize: 15,
// //                     ),
// //                   ),
// //                 ),
// //               ),

// //               const SizedBox(width: 12),

// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment:
// //                       CrossAxisAlignment
// //                           .start,
// //                   children: [
// //                     Text(
// //                       studentName,
// //                       style:
// //                           const TextStyle(
// //                         fontSize: 16,
// //                         fontWeight:
// //                             FontWeight.bold,
// //                         color:
// //                             Colors.black87,
// //                       ),
// //                     ),

// //                     const SizedBox(
// //                       height: 2,
// //                     ),

// //                     Row(
// //                       children: [
// //                         Icon(
// //                           Icons
// //                               .menu_book_outlined,
// //                           size: 14,
// //                           color: Colors
// //                               .grey.shade600,
// //                         ),

// //                         const SizedBox(
// //                           width: 4,
// //                         ),

// //                         Expanded(
// //                           child: Text(
// //                             courseName,
// //                             overflow:
// //                                 TextOverflow
// //                                     .ellipsis,
// //                             style:
// //                                 TextStyle(
// //                               fontSize: 12,
// //                               color: Colors
// //                                   .grey.shade600,
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),

// //           const Padding(
// //             padding:
// //                 EdgeInsets.symmetric(
// //               vertical: 12,
// //             ),
// //             child: Divider(
// //               height: 1,
// //             ),
// //           ),

// //           // =====================================================
// //           // VIEW COURSE CONTENT
// //           // =====================================================

// //           SizedBox(
// //             width: double.infinity,
// //             child: OutlinedButton.icon(
// //               onPressed: () {
// //                 showCourseContent(
// //                   studentId,
// //                   courseId,
// //                   studentName,
// //                   courseName,
// //                 );
// //               },
// //               icon: const Icon(
// //                 Icons.folder_open_outlined,
// //                 size: 17,
// //               ),
// //               label: const Text(
// //                 "View Course Content",
// //                 style: TextStyle(
// //                   fontWeight:
// //                       FontWeight.bold,
// //                   fontSize: 13,
// //                 ),
// //               ),
// //               style:
// //                   OutlinedButton.styleFrom(
// //                 foregroundColor:
// //                     darkPrimaryColor,
// //                 side: BorderSide(
// //                   color:
// //                       Colors.teal.shade200,
// //                 ),
// //                 padding:
// //                     const EdgeInsets
// //                         .symmetric(
// //                   vertical: 12,
// //                 ),
// //                 shape:
// //                     RoundedRectangleBorder(
// //                   borderRadius:
// //                       BorderRadius.circular(
// //                     10,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),

// //           const SizedBox(height: 10),

// //           // =====================================================
// //           // COMPLETE COURSE
// //           // =====================================================

// //           SizedBox(
// //             width: double.infinity,
// //             child: isCompleted
// //                 ? Container(
// //                     padding:
// //                         const EdgeInsets
// //                             .symmetric(
// //                       vertical: 10,
// //                     ),
// //                     decoration:
// //                         BoxDecoration(
// //                       color:
// //                           Colors.teal.shade50,
// //                       borderRadius:
// //                           BorderRadius.circular(
// //                         10,
// //                       ),
// //                     ),
// //                     child: const Row(
// //                       mainAxisAlignment:
// //                           MainAxisAlignment
// //                               .center,
// //                       children: [
// //                         Icon(
// //                           Icons.check_circle,
// //                           color:
// //                               darkPrimaryColor,
// //                           size: 16,
// //                         ),
// //                         SizedBox(
// //                           width: 6,
// //                         ),
// //                         Text(
// //                           "Course Completed",
// //                           style:
// //                               TextStyle(
// //                             color:
// //                                 darkPrimaryColor,
// //                             fontWeight:
// //                                 FontWeight
// //                                     .bold,
// //                             fontSize: 13,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   )
// //                 : ElevatedButton(
// //                     style:
// //                         ElevatedButton
// //                             .styleFrom(
// //                       backgroundColor:
// //                           primaryColor,
// //                       elevation: 0,
// //                       padding:
// //                           const EdgeInsets
// //                               .symmetric(
// //                         vertical: 12,
// //                       ),
// //                       shape:
// //                           RoundedRectangleBorder(
// //                         borderRadius:
// //                             BorderRadius
// //                                 .circular(
// //                           10,
// //                         ),
// //                       ),
// //                     ),
// //                     onPressed: () =>
// //                         completeCourse(
// //                       courseId,
// //                     ),
// //                     child: const Row(
// //                       mainAxisAlignment:
// //                           MainAxisAlignment
// //                               .center,
// //                       children: [
// //                         Icon(
// //                           Icons.check,
// //                           color:
// //                               Colors.white,
// //                           size: 16,
// //                         ),
// //                         SizedBox(
// //                           width: 4,
// //                         ),
// //                         Text(
// //                           "Mark as Complete",
// //                           style:
// //                               TextStyle(
// //                             color:
// //                                 Colors.white,
// //                             fontWeight:
// //                                 FontWeight.bold,
// //                             fontSize: 13,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //           ),

// //           const SizedBox(height: 10),

// //           // =====================================================
// //           // FEEDBACK
// //           // =====================================================

// //           SizedBox(
// //             width: double.infinity,
// //             child: feedbackGiven
// //                 ? Container(
// //                     padding:
// //                         const EdgeInsets
// //                             .symmetric(
// //                       vertical: 10,
// //                     ),
// //                     decoration:
// //                         BoxDecoration(
// //                       color:
// //                           Colors.blue.shade50,
// //                       borderRadius:
// //                           BorderRadius.circular(
// //                         10,
// //                       ),
// //                     ),
// //                     child: Row(
// //                       mainAxisAlignment:
// //                           MainAxisAlignment
// //                               .center,
// //                       children: [
// //                         Icon(
// //                           Icons.star,
// //                           color:
// //                               Colors.indigo
// //                                   .shade700,
// //                           size: 16,
// //                         ),
// //                         const SizedBox(
// //                           width: 6,
// //                         ),
// //                         Text(
// //                           "Feedback Submitted",
// //                           style:
// //                               TextStyle(
// //                             color: Colors
// //                                 .indigo
// //                                 .shade700,
// //                             fontWeight:
// //                                 FontWeight
// //                                     .bold,
// //                             fontSize: 13,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   )
// //                 : ElevatedButton(
// //                     style:
// //                         ElevatedButton
// //                             .styleFrom(
// //                       backgroundColor:
// //                           Colors.indigo,
// //                       elevation: 0,
// //                       padding:
// //                           const EdgeInsets
// //                               .symmetric(
// //                         vertical: 12,
// //                       ),
// //                       shape:
// //                           RoundedRectangleBorder(
// //                         borderRadius:
// //                             BorderRadius
// //                                 .circular(
// //                           10,
// //                         ),
// //                       ),
// //                     ),
// //                     onPressed: () =>
// //                         _showFeedbackDialog(
// //                       studentId,
// //                       courseId,
// //                       studentName,
// //                       courseName,
// //                     ),
// //                     child: const Row(
// //                       mainAxisAlignment:
// //                           MainAxisAlignment
// //                               .center,
// //                       children: [
// //                         Icon(
// //                           Icons
// //                               .rate_review_outlined,
// //                           color:
// //                               Colors.white,
// //                           size: 16,
// //                         ),
// //                         SizedBox(
// //                           width: 4,
// //                         ),
// //                         Text(
// //                           "Give Feedback",
// //                           style:
// //                               TextStyle(
// //                             color:
// //                                 Colors.white,
// //                             fontWeight:
// //                                 FontWeight.bold,
// //                             fontSize: 13,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // =========================================================
// //   // SAFE INT CONVERSION
// //   // =========================================================

// //   int _toInt(dynamic value) {
// //     if (value is int) {
// //       return value;
// //     }

// //     return int.tryParse(
// //           value?.toString() ?? "",
// //         ) ??
// //         0;
// //   }
// // }


































// // // import 'dart:convert';

// // // import 'package:flutter/material.dart';
// // // import 'package:house_of_tutor/services/api_client.dart';

// // // class TutorMyStudent extends StatefulWidget {
// // //   const TutorMyStudent({super.key});

// // //   @override
// // //   State<TutorMyStudent> createState() => _TutorMyStudentState();
// // // }

// // // class _TutorMyStudentState extends State<TutorMyStudent> {
// // //   // =========================================================
// // //   // STATE VARIABLES
// // //   // =========================================================

// // //   bool isLoading = false;
// // //   List<dynamic> studentsList = [];

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     fetchMyStudents();
// // //   }

// // //   // =========================================================
// // //   // FETCH MY STUDENTS API
// // //   // =========================================================

// // //   Future<void> fetchMyStudents() async {
// // //     if (!mounted) return;

// // //     setState(() {
// // //       isLoading = true;
// // //     });

// // //     try {
// // //       final response = await ApiClient.get("/api/Tutor/my-students");

// // //       if (response.statusCode == 200) {
// // //         final decoded = jsonDecode(response.body);

// // //         if (decoded is List) {
// // //           setState(() {
// // //             studentsList = decoded;
// // //           });
// // //         } else if (decoded is Map && decoded["data"] != null) {
// // //           setState(() {
// // //             studentsList = decoded["data"];
// // //           });
// // //         }
// // //       } else {
// // //         if (!mounted) return;
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text("Failed to load students (${response.statusCode})"),
// // //             backgroundColor: Colors.red,
// // //           ),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text("Error: $e"),
// // //           backgroundColor: Colors.red,
// // //         ),
// // //       );
// // //     } finally {
// // //       if (mounted) {
// // //         setState(() {
// // //           isLoading = false;
// // //         });
// // //       }
// // //     }
// // //   }

// // //   // =========================================================
// // //   // COMPLETE COURSE API
// // //   // =========================================================

// // //   Future<void> completeCourse(int courseId) async {
// // //     try {
// // //       final response = await ApiClient.post(
// // //         "/api/Tutor/complete-course",
// // //         {
// // //           "courseId": courseId,
// // //         },
// // //       );

// // //       if (response.statusCode == 200) {
// // //         if (!mounted) return;
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text("Course completed successfully"),
// // //             backgroundColor: Colors.green,
// // //           ),
// // //         );
// // //         fetchMyStudents(); // Refresh list
// // //       } else {
// // //         if (!mounted) return;
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text("Failed to complete course"),
// // //             backgroundColor: Colors.red,
// // //           ),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text("Error: $e"),
// // //           backgroundColor: Colors.red,
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   // =========================================================
// // //   // GIVE FEEDBACK DIALOG & API
// // //   // =========================================================

// // //   void _showFeedbackDialog(int studentId, int courseId, String studentName, String courseName) {
// // //     final TextEditingController commentController = TextEditingController();
// // //     double rating = 5.0;

// // //     showDialog(
// // //       context: context,
// // //       builder: (context) {
// // //         return StatefulBuilder(
// // //           builder: (context, setDialogState) {
// // //             String getRatingText(double r) {
// // //               if (r >= 4.5) return "Excellent!";
// // //               if (r >= 3.5) return "Very Good!";
// // //               if (r >= 2.5) return "Good";
// // //               if (r >= 1.5) return "Fair";
// // //               return "Needs Improvement";
// // //             }

// // //             return AlertDialog(
// // //               shape: RoundedRectangleBorder(
// // //                 borderRadius: BorderRadius.circular(20),
// // //               ),
// // //               title: Row(
// // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                 children: [
// // //                   const Text(
// // //                     "Student Feedback",
// // //                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
// // //                   ),
// // //                   IconButton(
// // //                     icon: const Icon(Icons.close, size: 20, color: Colors.grey),
// // //                     onPressed: () => Navigator.pop(context),
// // //                   ),
// // //                 ],
// // //               ),
// // //               content: SingleChildScrollView(
// // //                 child: Column(
// // //                   mainAxisSize: MainAxisSize.min,
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     // Student Info Card matching the design
// // //                     Container(
// // //                       width: double.infinity,
// // //                       padding: const EdgeInsets.all(12),
// // //                       decoration: BoxDecoration(
// // //                         color: Colors.grey.shade50,
// // //                         borderRadius: BorderRadius.circular(12),
// // //                         border: Border(
// // //                           left: BorderSide(
// // //                             color: Colors.indigo.shade700,
// // //                             width: 4,
// // //                           ),
// // //                         ),
// // //                       ),
// // //                       child: Column(
// // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // //                         children: [
// // //                           Text(
// // //                             studentName,
// // //                             style: const TextStyle(
// // //                               fontWeight: FontWeight.bold,
// // //                               fontSize: 16,
// // //                               color: Colors.black87,
// // //                             ),
// // //                           ),
// // //                           const SizedBox(height: 2),
// // //                           Text(
// // //                             courseName,
// // //                             style: TextStyle(
// // //                               fontSize: 13,
// // //                               color: Colors.grey.shade600,
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 20),
// // //                     const Text(
// // //                       "RATING SCORE",
// // //                       style: TextStyle(
// // //                         fontSize: 12,
// // //                         color: Colors.grey,
// // //                         fontWeight: FontWeight.bold,
// // //                         letterSpacing: 0.5,
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 10),
// // //                     // Interactive Stars Row
// // //                     Center(
// // //                       child: Row(
// // //                         mainAxisAlignment: MainAxisAlignment.center,
// // //                         children: List.generate(5, (index) {
// // //                           return GestureDetector(
// // //                             onTap: () {
// // //                               setDialogState(() {
// // //                                 rating = (index + 1).toDouble();
// // //                               });
// // //                             },
// // //                             child: Padding(
// // //                               padding: const EdgeInsets.symmetric(horizontal: 4.0),
// // //                               child: Icon(
// // //                                 index < rating ? Icons.star : Icons.star_border,
// // //                                 color: Colors.amber,
// // //                                 size: 32,
// // //                               ),
// // //                             ),
// // //                           );
// // //                         }),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 6),
// // //                     Center(
// // //                       child: Text(
// // //                         getRatingText(rating),
// // //                         style: TextStyle(
// // //                           color: Colors.amber.shade800,
// // //                           fontWeight: FontWeight.bold,
// // //                           fontSize: 13,
// // //                         ),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 20),
// // //                     const Text(
// // //                       "FEEDBACK COMMENTS",
// // //                       style: TextStyle(
// // //                         fontSize: 12,
// // //                         color: Colors.grey,
// // //                         fontWeight: FontWeight.bold,
// // //                         letterSpacing: 0.5,
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 8),
// // //                     TextField(
// // //                       controller: commentController,
// // //                       maxLines: 4,
// // //                       decoration: InputDecoration(
// // //                         hintText: "Share performance insights, progress notes, or recommendations...",
// // //                         hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
// // //                         border: OutlineInputBorder(
// // //                           borderRadius: BorderRadius.circular(12),
// // //                           borderSide: BorderSide(color: Colors.grey.shade300),
// // //                         ),
// // //                         enabledBorder: OutlineInputBorder(
// // //                           borderRadius: BorderRadius.circular(12),
// // //                           borderSide: BorderSide(color: Colors.grey.shade300),
// // //                         ),
// // //                         contentPadding: const EdgeInsets.all(14),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //               actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
// // //               actions: [
// // //                 Row(
// // //                   children: [
// // //                     Expanded(
// // //                       child: TextButton(
// // //                         style: TextButton.styleFrom(
// // //                           backgroundColor: Colors.grey.shade100,
// // //                           padding: const EdgeInsets.symmetric(vertical: 14),
// // //                           shape: RoundedRectangleBorder(
// // //                             borderRadius: BorderRadius.circular(12),
// // //                           ),
// // //                         ),
// // //                         onPressed: () => Navigator.pop(context),
// // //                         child: const Text(
// // //                           "Cancel",
// // //                           style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(width: 12),
// // //                     Expanded(
// // //                       flex: 2,
// // //                       child: ElevatedButton(
// // //                         style: ElevatedButton.styleFrom(
// // //                           backgroundColor: const Color(0xFF5C54ED),
// // //                           elevation: 0,
// // //                           padding: const EdgeInsets.symmetric(vertical: 14),
// // //                           shape: RoundedRectangleBorder(
// // //                             borderRadius: BorderRadius.circular(12),
// // //                           ),
// // //                         ),
// // //                         onPressed: () async {
// // //                           Navigator.pop(context);
// // //                           await submitFeedback(studentId, courseId, rating, commentController.text);
// // //                         },
// // //                         child: const Text(
// // //                           "Submit Feedback",
// // //                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ],
// // //             );
// // //           },
// // //         );
// // //       },
// // //     );
// // //   }

// // //   Future<void> submitFeedback(int studentId, int courseId, double rating, String comment) async {
// // //     try {
// // //       final response = await ApiClient.post(
// // //         "/api/Tutor/give-feedback",
// // //         {
// // //           "studentId": studentId,
// // //           "courseId": courseId,
// // //           // FIX: backend Rating property is (most likely) an int.
// // //           // Sending 5.0 instead of 5 makes System.Text.Json fail to bind it,
// // //           // which returns a 400 validation-problem response with no "message"
// // //           // key — that's why you were always seeing the generic fallback text.
// // //           "rating": rating.toInt(),
// // //           "comment": comment,
// // //         },
// // //       );

// // //       print('Feedback Response Code: ${response.statusCode}');
// // //       print('Feedback Response Body: ${response.body}');

// // //       if (response.statusCode == 200) {
// // //         if (!mounted) return;
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text("Feedback submitted successfully"),
// // //             backgroundColor: Colors.green,
// // //           ),
// // //         );
// // //         fetchMyStudents();
// // //       } else {
// // //         if (!mounted) return;
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text(_extractErrorMessage(response.body)),
// // //             backgroundColor: Colors.red,
// // //           ),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text("Error: $e"),
// // //           backgroundColor: Colors.red,
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   // =========================================================
// // //   // ERROR MESSAGE EXTRACTOR
// // //   // Handles: { "message": "..." }, ASP.NET Core validation
// // //   // problem details { "title": "...", "errors": {...} }, and
// // //   // plain/empty bodies — so you always see the real reason
// // //   // instead of a generic fallback string.
// // //   // =========================================================

// // //   String _extractErrorMessage(String body) {
// // //     if (body.trim().isEmpty) {
// // //       return "Failed to submit feedback (empty server response)";
// // //     }

// // //     try {
// // //       final decoded = jsonDecode(body);

// // //       if (decoded is Map) {
// // //         if (decoded["message"] != null) {
// // //           return decoded["message"].toString();
// // //         }

// // //         // ASP.NET Core ModelState validation error shape
// // //         if (decoded["errors"] != null && decoded["errors"] is Map) {
// // //           final errors = decoded["errors"] as Map;
// // //           final firstField = errors.values.first;
// // //           if (firstField is List && firstField.isNotEmpty) {
// // //             return firstField.first.toString();
// // //           }
// // //         }

// // //         if (decoded["title"] != null) {
// // //           return decoded["title"].toString();
// // //         }
// // //       }
// // //     } catch (_) {
// // //       // body wasn't valid JSON
// // //     }

// // //     return "Failed to submit feedback";
// // //   }

// // //   // =========================================================
// // //   // GET INITIALS FOR AVATAR
// // //   // =========================================================

// // //   String _getInitials(String name) {
// // //     if (name.trim().isEmpty) return "S";
// // //     List<String> parts = name.trim().split(" ");
// // //     if (parts.length >= 2) {
// // //       return "${parts[0][0]}${parts[1][0]}".toUpperCase();
// // //     }
// // //     return parts[0][0].toUpperCase();
// // //   }

// // //   // =========================================================
// // //   // BUILD
// // //   // =========================================================

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: const Color(0xFFF5F7FA),
// // //       appBar: AppBar(
// // //         backgroundColor: Colors.white,
// // //         elevation: 0,
// // //         centerTitle: true,
// // //         leading: IconButton(
// // //           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
// // //           onPressed: () => Navigator.pop(context),
// // //         ),
// // //         title: Row(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             Container(
// // //               height: 28,
// // //               width: 28,
// // //               decoration: BoxDecoration(
// // //                 color: Colors.teal.shade50,
// // //                 borderRadius: BorderRadius.circular(6),
// // //               ),
// // //               child: const Icon(
// // //                 Icons.school,
// // //                 color: Color(0xFF00695C),
// // //                 size: 18,
// // //               ),
// // //             ),
// // //             const SizedBox(width: 8),
// // //             const Text(
// // //               "House of Tutor",
// // //               style: TextStyle(
// // //                 color: Colors.black87,
// // //                 fontSize: 16,
// // //                 fontWeight: FontWeight.bold,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //       body: SafeArea(
// // //         child: isLoading
// // //             ? const Center(
// // //                 child: CircularProgressIndicator(
// // //                   color: Color(0xFF009688),
// // //                 ),
// // //               )
// // //             : Padding(
// // //                 padding: const EdgeInsets.all(16.0),
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     // HEADER TITLE & COUNT
// // //                     Row(
// // //                       children: [
// // //                         const Text(
// // //                           "My Students",
// // //                           style: TextStyle(
// // //                             fontSize: 20,
// // //                             fontWeight: FontWeight.bold,
// // //                             color: Colors.black87,
// // //                           ),
// // //                         ),
// // //                         const SizedBox(width: 8),
// // //                         Container(
// // //                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// // //                           decoration: BoxDecoration(
// // //                             color: Colors.teal.shade50,
// // //                             borderRadius: BorderRadius.circular(12),
// // //                           ),
// // //                           child: Text(
// // //                             "${studentsList.length}",
// // //                             style: const TextStyle(
// // //                               color: Color(0xFF00695C),
// // //                               fontWeight: FontWeight.bold,
// // //                               fontSize: 12,
// // //                             ),
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                     const SizedBox(height: 16),

// // //                     // LIST OF STUDENTS
// // //                     Expanded(
// // //                       child: studentsList.isEmpty
// // //                           ? Center(
// // //                               child: Text(
// // //                                 "No students found",
// // //                                 style: TextStyle(
// // //                                   fontSize: 15,
// // //                                   color: Colors.grey.shade600,
// // //                                 ),
// // //                               ),
// // //                             )
// // //                           : ListView.builder(
// // //                               itemCount: studentsList.length,
// // //                               itemBuilder: (context, index) {
// // //                                 final item = studentsList[index];

// // //                                 final int studentId = item["studentId"] ?? 0;
// // //                                 final int courseId = item["courseId"] ?? 0;
// // //                                 final String studentName = item["studentName"] ?? "Student Name";
// // //                                 final String courseName = item["courseName"] ?? "Course Name";
// // //                                 final bool isCompleted = item["isCompleted"] ?? false;
// // //                                 final bool feedbackGiven = item["feedbackGiven"] ?? false;

// // //                                 return Container(
// // //                                   margin: const EdgeInsets.only(bottom: 16),
// // //                                   padding: const EdgeInsets.all(16),
// // //                                   decoration: BoxDecoration(
// // //                                     color: Colors.white,
// // //                                     borderRadius: BorderRadius.circular(16),
// // //                                     border: Border.all(color: Colors.grey.shade200),
// // //                                     boxShadow: [
// // //                                       BoxShadow(
// // //                                         color: Colors.black.withOpacity(0.03),
// // //                                         blurRadius: 8,
// // //                                         offset: const Offset(0, 2),
// // //                                       ),
// // //                                     ],
// // //                                   ),
// // //                                   child: Column(
// // //                                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                                     children: [
// // //                                       // STUDENT AVATAR & INFO
// // //                                       Row(
// // //                                         children: [
// // //                                           Container(
// // //                                             height: 45,
// // //                                             width: 45,
// // //                                             decoration: BoxDecoration(
// // //                                               color: Colors.indigo.shade50,
// // //                                               borderRadius: BorderRadius.circular(25),
// // //                                             ),
// // //                                             child: Center(
// // //                                               child: Text(
// // //                                                 _getInitials(studentName),
// // //                                                 style: TextStyle(
// // //                                                   color: Colors.indigo.shade700,
// // //                                                   fontWeight: FontWeight.bold,
// // //                                                   fontSize: 15,
// // //                                                 ),
// // //                                               ),
// // //                                             ),
// // //                                           ),
// // //                                           const SizedBox(width: 12),
// // //                                           Expanded(
// // //                                             child: Column(
// // //                                               crossAxisAlignment: CrossAxisAlignment.start,
// // //                                               children: [
// // //                                                 Text(
// // //                                                   studentName,
// // //                                                   style: const TextStyle(
// // //                                                     fontSize: 16,
// // //                                                     fontWeight: FontWeight.bold,
// // //                                                     color: Colors.black87,
// // //                                                   ),
// // //                                                 ),
// // //                                                 const SizedBox(height: 2),
// // //                                                 Row(
// // //                                                   children: [
// // //                                                     Icon(
// // //                                                       Icons.menu_book_outlined,
// // //                                                       size: 14,
// // //                                                       color: Colors.grey.shade600,
// // //                                                     ),
// // //                                                     const SizedBox(width: 4),
// // //                                                     Text(
// // //                                                       courseName,
// // //                                                       style: TextStyle(
// // //                                                         fontSize: 12,
// // //                                                         color: Colors.grey.shade600,
// // //                                                       ),
// // //                                                     ),
// // //                                                   ],
// // //                                                 ),
// // //                                               ],
// // //                                             ),
// // //                                           ),
// // //                                         ],
// // //                                       ),

// // //                                       const Padding(
// // //                                         padding: EdgeInsets.symmetric(vertical: 12),
// // //                                         child: Divider(height: 1),
// // //                                       ),

// // //                                       // COURSE STATUS BUTTON / ACTION
// // //                                       SizedBox(
// // //                                         width: double.infinity,
// // //                                         child: isCompleted
// // //                                             ? Container(
// // //                                                 padding: const EdgeInsets.symmetric(vertical: 10),
// // //                                                 decoration: BoxDecoration(
// // //                                                   color: Colors.teal.shade50,
// // //                                                   borderRadius: BorderRadius.circular(10),
// // //                                                 ),
// // //                                                 child: const Row(
// // //                                                   mainAxisAlignment: MainAxisAlignment.center,
// // //                                                   children: [
// // //                                                     Icon(Icons.check_circle, color: Color(0xFF00695C), size: 16),
// // //                                                     SizedBox(width: 6),
// // //                                                     Text(
// // //                                                       "Course Completed",
// // //                                                       style: TextStyle(
// // //                                                         color: Color(0xFF00695C),
// // //                                                         fontWeight: FontWeight.bold,
// // //                                                         fontSize: 13,
// // //                                                       ),
// // //                                                     ),
// // //                                                   ],
// // //                                                 ),
// // //                                               )
// // //                                             : ElevatedButton(
// // //                                                 style: ElevatedButton.styleFrom(
// // //                                                   backgroundColor: const Color(0xFF009688),
// // //                                                   elevation: 0,
// // //                                                   padding: const EdgeInsets.symmetric(vertical: 12),
// // //                                                   shape: RoundedRectangleBorder(
// // //                                                     borderRadius: BorderRadius.circular(10),
// // //                                                   ),
// // //                                                 ),
// // //                                                 onPressed: () => completeCourse(courseId),
// // //                                                 child: const Row(
// // //                                                   mainAxisAlignment: MainAxisAlignment.center,
// // //                                                   children: [
// // //                                                     Icon(Icons.check, color: Colors.white, size: 16),
// // //                                                     SizedBox(width: 4),
// // //                                                     Text(
// // //                                                       "Mark as Complete",
// // //                                                       style: TextStyle(
// // //                                                         color: Colors.white,
// // //                                                         fontWeight: FontWeight.bold,
// // //                                                         fontSize: 13,
// // //                                                       ),
// // //                                                     ),
// // //                                                   ],
// // //                                                 ),
// // //                                               ),
// // //                                       ),

// // //                                       const SizedBox(height: 10),

// // //                                       // FEEDBACK BUTTON / STATUS
// // //                                       SizedBox(
// // //                                         width: double.infinity,
// // //                                         child: feedbackGiven
// // //                                             ? Container(
// // //                                                 padding: const EdgeInsets.symmetric(vertical: 10),
// // //                                                 decoration: BoxDecoration(
// // //                                                   color: Colors.blue.shade50,
// // //                                                   borderRadius: BorderRadius.circular(10),
// // //                                                 ),
// // //                                                 child: Row(
// // //                                                   mainAxisAlignment: MainAxisAlignment.center,
// // //                                                   children: [
// // //                                                     Icon(Icons.star, color: Colors.indigo.shade700, size: 16),
// // //                                                     const SizedBox(width: 6),
// // //                                                     Text(
// // //                                                       "Feedback Submitted",
// // //                                                       style: TextStyle(
// // //                                                         color: Colors.indigo.shade700,
// // //                                                         fontWeight: FontWeight.bold,
// // //                                                         fontSize: 13,
// // //                                                       ),
// // //                                                     ),
// // //                                                   ],
// // //                                                 ),
// // //                                               )
// // //                                             : ElevatedButton(
// // //                                                 style: ElevatedButton.styleFrom(
// // //                                                   backgroundColor: Colors.indigo,
// // //                                                   elevation: 0,
// // //                                                   padding: const EdgeInsets.symmetric(vertical: 12),
// // //                                                   shape: RoundedRectangleBorder(
// // //                                                     borderRadius: BorderRadius.circular(10),
// // //                                                   ),
// // //                                                 ),
// // //                                                 onPressed: () => _showFeedbackDialog(studentId, courseId, studentName, courseName),
// // //                                                 child: const Row(
// // //                                                   mainAxisAlignment: MainAxisAlignment.center,
// // //                                                   children: [
// // //                                                     Icon(Icons.rate_review_outlined, color: Colors.white, size: 16),
// // //                                                     SizedBox(width: 4),
// // //                                                     Text(
// // //                                                       "Give Feedback",
// // //                                                       style: TextStyle(
// // //                                                         color: Colors.white,
// // //                                                         fontWeight: FontWeight.bold,
// // //                                                         fontSize: 13,
// // //                                                       ),
// // //                                                     ),
// // //                                                   ],
// // //                                                 ),
// // //                                               ),
// // //                                       ),
// // //                                     ],
// // //                                   ),
// // //                                 );
// // //                               },
// // //                             ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //       ),
// // //     );
// // //   }
// // // }


























// // // // import 'dart:convert';

// // // // import 'package:flutter/material.dart';
// // // // import 'package:house_of_tutor/services/api_client.dart';

// // // // class TutorMyStudent extends StatefulWidget {
// // // //   const TutorMyStudent({super.key});

// // // //   @override
// // // //   State<TutorMyStudent> createState() => _TutorMyStudentState();
// // // // }

// // // // class _TutorMyStudentState extends State<TutorMyStudent> {
// // // //   // =========================================================
// // // //   // STATE VARIABLES
// // // //   // =========================================================

// // // //   bool isLoading = false;
// // // //   List<dynamic> studentsList = [];

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     fetchMyStudents();
// // // //   }

// // // //   // =========================================================
// // // //   // FETCH MY STUDENTS API
// // // //   // =========================================================

// // // //   Future<void> fetchMyStudents() async {
// // // //     if (!mounted) return;

// // // //     setState(() {
// // // //       isLoading = true;
// // // //     });

// // // //     try {
// // // //       final response = await ApiClient.get("/api/Tutor/my-students");

// // // //       if (response.statusCode == 200) {
// // // //         final decoded = jsonDecode(response.body);

// // // //         if (decoded is List) {
// // // //           setState(() {
// // // //             studentsList = decoded;
// // // //           });
// // // //         } else if (decoded is Map && decoded["data"] != null) {
// // // //           setState(() {
// // // //             studentsList = decoded["data"];
// // // //           });
// // // //         }
// // // //       } else {
// // // //         if (!mounted) return;
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(
// // // //             content: Text("Failed to load students (${response.statusCode})"),
// // // //             backgroundColor: Colors.red,
// // // //           ),
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       if (!mounted) return;
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         SnackBar(
// // // //           content: Text("Error: $e"),
// // // //           backgroundColor: Colors.red,
// // // //         ),
// // // //       );
// // // //     } finally {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           isLoading = false;
// // // //         });
// // // //       }
// // // //     }
// // // //   }

// // // //   // =========================================================
// // // //   // COMPLETE COURSE API
// // // //   // =========================================================

// // // //   Future<void> completeCourse(int courseId) async {
// // // //     try {
// // // //       final response = await ApiClient.post(
// // // //         "/api/Tutor/complete-course",
// // // //         {
// // // //           "courseId": courseId,
// // // //         },
// // // //       );

// // // //       if (response.statusCode == 200) {
// // // //         if (!mounted) return;
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(
// // // //             content: Text("Course completed successfully"),
// // // //             backgroundColor: Colors.green,
// // // //           ),
// // // //         );
// // // //         fetchMyStudents(); // Refresh list
// // // //       } else {
// // // //         if (!mounted) return;
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(
// // // //             content: Text("Failed to complete course"),
// // // //             backgroundColor: Colors.red,
// // // //           ),
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       if (!mounted) return;
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         SnackBar(
// // // //           content: Text("Error: $e"),
// // // //           backgroundColor: Colors.red,
// // // //         ),
// // // //       );
// // // //     }
// // // //   }

// // // //   // =========================================================
// // // //   // GIVE FEEDBACK DIALOG & API
// // // //   // =========================================================

// // // //   void _showFeedbackDialog(int studentId, int courseId, String studentName, String courseName) {
// // // //     final TextEditingController commentController = TextEditingController();
// // // //     double rating = 5.0;

// // // //     showDialog(
// // // //       context: context,
// // // //       builder: (context) {
// // // //         return StatefulBuilder(
// // // //           builder: (context, setDialogState) {
// // // //             String getRatingText(double r) {
// // // //               if (r >= 4.5) return "Excellent!";
// // // //               if (r >= 3.5) return "Very Good!";
// // // //               if (r >= 2.5) return "Good";
// // // //               if (r >= 1.5) return "Fair";
// // // //               return "Needs Improvement";
// // // //             }

// // // //             return AlertDialog(
// // // //               shape: RoundedRectangleBorder(
// // // //                 borderRadius: BorderRadius.circular(20),
// // // //               ),
// // // //               title: Row(
// // // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                 children: [
// // // //                   const Text(
// // // //                     "Student Feedback",
// // // //                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
// // // //                   ),
// // // //                   IconButton(
// // // //                     icon: const Icon(Icons.close, size: 20, color: Colors.grey),
// // // //                     onPressed: () => Navigator.pop(context),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //               content: SingleChildScrollView(
// // // //                 child: Column(
// // // //                   mainAxisSize: MainAxisSize.min,
// // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // //                   children: [
// // // //                     // Student Info Card matching the design
// // // //                     Container(
// // // //                       width: double.infinity,
// // // //                       padding: const EdgeInsets.all(12),
// // // //                       decoration: BoxDecoration(
// // // //                         color: Colors.grey.shade50,
// // // //                         borderRadius: BorderRadius.circular(12),
// // // //                         border: Border(
// // // //                           left: BorderSide(
// // // //                             color: Colors.indigo.shade700,
// // // //                             width: 4,
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                       child: Column(
// // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // //                         children: [
// // // //                           Text(
// // // //                             studentName,
// // // //                             style: const TextStyle(
// // // //                               fontWeight: FontWeight.bold,
// // // //                               fontSize: 16,
// // // //                               color: Colors.black87,
// // // //                             ),
// // // //                           ),
// // // //                           const SizedBox(height: 2),
// // // //                           Text(
// // // //                             courseName,
// // // //                             style: TextStyle(
// // // //                               fontSize: 13,
// // // //                               color: Colors.grey.shade600,
// // // //                             ),
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                     ),
// // // //                     const SizedBox(height: 20),
// // // //                     const Text(
// // // //                       "RATING SCORE",
// // // //                       style: TextStyle(
// // // //                         fontSize: 12,
// // // //                         color: Colors.grey,
// // // //                         fontWeight: FontWeight.bold,
// // // //                         letterSpacing: 0.5,
// // // //                       ),
// // // //                     ),
// // // //                     const SizedBox(height: 10),
// // // //                     // Interactive Stars Row
// // // //                     Center(
// // // //                       child: Row(
// // // //                         mainAxisAlignment: MainAxisAlignment.center,
// // // //                         children: List.generate(5, (index) {
// // // //                           return GestureDetector(
// // // //                             onTap: () {
// // // //                               setDialogState(() {
// // // //                                 rating = (index + 1).toDouble();
// // // //                               });
// // // //                             },
// // // //                             child: Padding(
// // // //                               padding: const EdgeInsets.symmetric(horizontal: 4.0),
// // // //                               child: Icon(
// // // //                                 index < rating ? Icons.star : Icons.star_border,
// // // //                                 color: Colors.amber,
// // // //                                 size: 32,
// // // //                               ),
// // // //                             ),
// // // //                           );
// // // //                         }),
// // // //                       ),
// // // //                     ),
// // // //                     const SizedBox(height: 6),
// // // //                     Center(
// // // //                       child: Text(
// // // //                         getRatingText(rating),
// // // //                         style: TextStyle(
// // // //                           color: Colors.amber.shade800,
// // // //                           fontWeight: FontWeight.bold,
// // // //                           fontSize: 13,
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                     const SizedBox(height: 20),
// // // //                     const Text(
// // // //                       "FEEDBACK COMMENTS",
// // // //                       style: TextStyle(
// // // //                         fontSize: 12,
// // // //                         color: Colors.grey,
// // // //                         fontWeight: FontWeight.bold,
// // // //                         letterSpacing: 0.5,
// // // //                       ),
// // // //                     ),
// // // //                     const SizedBox(height: 8),
// // // //                     TextField(
// // // //                       controller: commentController,
// // // //                       maxLines: 4,
// // // //                       decoration: InputDecoration(
// // // //                         hintText: "Share performance insights, progress notes, or recommendations...",
// // // //                         hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
// // // //                         border: OutlineInputBorder(
// // // //                           borderRadius: BorderRadius.circular(12),
// // // //                           borderSide: BorderSide(color: Colors.grey.shade300),
// // // //                         ),
// // // //                         enabledBorder: OutlineInputBorder(
// // // //                           borderRadius: BorderRadius.circular(12),
// // // //                           borderSide: BorderSide(color: Colors.grey.shade300),
// // // //                         ),
// // // //                         contentPadding: const EdgeInsets.all(14),
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //               actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
// // // //               actions: [
// // // //                 Row(
// // // //                   children: [
// // // //                     Expanded(
// // // //                       child: TextButton(
// // // //                         style: TextButton.styleFrom(
// // // //                           backgroundColor: Colors.grey.shade100,
// // // //                           padding: const EdgeInsets.symmetric(vertical: 14),
// // // //                           shape: RoundedRectangleBorder(
// // // //                             borderRadius: BorderRadius.circular(12),
// // // //                           ),
// // // //                         ),
// // // //                         onPressed: () => Navigator.pop(context),
// // // //                         child: const Text(
// // // //                           "Cancel",
// // // //                           style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                     const SizedBox(width: 12),
// // // //                     Expanded(
// // // //                       flex: 2,
// // // //                       child: ElevatedButton(
// // // //                         style: ElevatedButton.styleFrom(
// // // //                           backgroundColor: const Color(0xFF5C54ED),
// // // //                           elevation: 0,
// // // //                           padding: const EdgeInsets.symmetric(vertical: 14),
// // // //                           shape: RoundedRectangleBorder(
// // // //                             borderRadius: BorderRadius.circular(12),
// // // //                           ),
// // // //                         ),
// // // //                         onPressed: () async {
// // // //                           Navigator.pop(context);
// // // //                           await submitFeedback(studentId, courseId, rating, commentController.text);
// // // //                         },
// // // //                         child: const Text(
// // // //                           "Submit Feedback",
// // // //                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ],
// // // //             );
// // // //           },
// // // //         );
// // // //       },
// // // //     );
// // // //   }

// // // //   Future<void> submitFeedback(int studentId, int courseId, double rating, String comment) async {
// // // //     try {
// // // //       final response = await ApiClient.post(
// // // //         "/api/Tutor/give-feedback",
// // // //         {
// // // //           "studentId": studentId,
// // // //           "courseId": courseId,
// // // //           "rating": rating,
// // // //           "comment": comment,
// // // //         },
// // // //       );

// // // //       if (response.statusCode == 200) {
// // // //         if (!mounted) return;
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(
// // // //             content: Text("Feedback submitted successfully"),
// // // //             backgroundColor: Colors.green,
// // // //           ),
// // // //         );
// // // //         fetchMyStudents();
// // // //       } else {
// // // //         final decoded = jsonDecode(response.body);
// // // //         final message = decoded["message"] ?? "Failed to submit feedback";
// // // //         if (!mounted) return;
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(
// // // //             content: Text(message),
// // // //             backgroundColor: Colors.red,
// // // //           ),
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       if (!mounted) return;
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         SnackBar(
// // // //           content: Text("Error: $e"),
// // // //           backgroundColor: Colors.red,
// // // //         ),
// // // //       );
// // // //     }
// // // //   }

// // // //   // =========================================================
// // // //   // GET INITIALS FOR AVATAR
// // // //   // =========================================================

// // // //   String _getInitials(String name) {
// // // //     if (name.trim().isEmpty) return "S";
// // // //     List<String> parts = name.trim().split(" ");
// // // //     if (parts.length >= 2) {
// // // //       return "${parts[0][0]}${parts[1][0]}".toUpperCase();
// // // //     }
// // // //     return parts[0][0].toUpperCase();
// // // //   }

// // // //   // =========================================================
// // // //   // BUILD
// // // //   // =========================================================

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: const Color(0xFFF5F7FA),
// // // //       appBar: AppBar(
// // // //         backgroundColor: Colors.white,
// // // //         elevation: 0,
// // // //         centerTitle: true,
// // // //         leading: IconButton(
// // // //           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
// // // //           onPressed: () => Navigator.pop(context),
// // // //         ),
// // // //         title: Row(
// // // //           mainAxisSize: MainAxisSize.min,
// // // //           children: [
// // // //             Container(
// // // //               height: 28,
// // // //               width: 28,
// // // //               decoration: BoxDecoration(
// // // //                 color: Colors.teal.shade50,
// // // //                 borderRadius: BorderRadius.circular(6),
// // // //               ),
// // // //               child: const Icon(
// // // //                 Icons.school,
// // // //                 color: Color(0xFF00695C),
// // // //                 size: 18,
// // // //               ),
// // // //             ),
// // // //             const SizedBox(width: 8),
// // // //             const Text(
// // // //               "House of Tutor",
// // // //               style: TextStyle(
// // // //                 color: Colors.black87,
// // // //                 fontSize: 16,
// // // //                 fontWeight: FontWeight.bold,
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //       body: SafeArea(
// // // //         child: isLoading
// // // //             ? const Center(
// // // //                 child: CircularProgressIndicator(
// // // //                   color: Color(0xFF009688),
// // // //                 ),
// // // //               )
// // // //             : Padding(
// // // //                 padding: const EdgeInsets.all(16.0),
// // // //                 child: Column(
// // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // //                   children: [
// // // //                     // HEADER TITLE & COUNT
// // // //                     Row(
// // // //                       children: [
// // // //                         const Text(
// // // //                           "My Students",
// // // //                           style: TextStyle(
// // // //                             fontSize: 20,
// // // //                             fontWeight: FontWeight.bold,
// // // //                             color: Colors.black87,
// // // //                           ),
// // // //                         ),
// // // //                         const SizedBox(width: 8),
// // // //                         Container(
// // // //                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// // // //                           decoration: BoxDecoration(
// // // //                             color: Colors.teal.shade50,
// // // //                             borderRadius: BorderRadius.circular(12),
// // // //                           ),
// // // //                           child: Text(
// // // //                             "${studentsList.length}",
// // // //                             style: const TextStyle(
// // // //                               color: Color(0xFF00695C),
// // // //                               fontWeight: FontWeight.bold,
// // // //                               fontSize: 12,
// // // //                             ),
// // // //                           ),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                     const SizedBox(height: 16),

// // // //                     // LIST OF STUDENTS
// // // //                     Expanded(
// // // //                       child: studentsList.isEmpty
// // // //                           ? Center(
// // // //                               child: Text(
// // // //                                 "No students found",
// // // //                                 style: TextStyle(
// // // //                                   fontSize: 15,
// // // //                                   color: Colors.grey.shade600,
// // // //                                 ),
// // // //                               ),
// // // //                             )
// // // //                           : ListView.builder(
// // // //                               itemCount: studentsList.length,
// // // //                               itemBuilder: (context, index) {
// // // //                                 final item = studentsList[index];

// // // //                                 final int studentId = item["studentId"] ?? 0;
// // // //                                 final int courseId = item["courseId"] ?? 0;
// // // //                                 final String studentName = item["studentName"] ?? "Student Name";
// // // //                                 final String courseName = item["courseName"] ?? "Course Name";
// // // //                                 final bool isCompleted = item["isCompleted"] ?? false;
// // // //                                 final bool feedbackGiven = item["feedbackGiven"] ?? false;

// // // //                                 return Container(
// // // //                                   margin: const EdgeInsets.only(bottom: 16),
// // // //                                   padding: const EdgeInsets.all(16),
// // // //                                   decoration: BoxDecoration(
// // // //                                     color: Colors.white,
// // // //                                     borderRadius: BorderRadius.circular(16),
// // // //                                     border: Border.all(color: Colors.grey.shade200),
// // // //                                     boxShadow: [
// // // //                                       BoxShadow(
// // // //                                         color: Colors.black.withOpacity(0.03),
// // // //                                         blurRadius: 8,
// // // //                                         offset: const Offset(0, 2),
// // // //                                       ),
// // // //                                     ],
// // // //                                   ),
// // // //                                   child: Column(
// // // //                                     crossAxisAlignment: CrossAxisAlignment.start,
// // // //                                     children: [
// // // //                                       // STUDENT AVATAR & INFO
// // // //                                       Row(
// // // //                                         children: [
// // // //                                           Container(
// // // //                                             height: 45,
// // // //                                             width: 45,
// // // //                                             decoration: BoxDecoration(
// // // //                                               color: Colors.indigo.shade50,
// // // //                                               borderRadius: BorderRadius.circular(25),
// // // //                                             ),
// // // //                                             child: Center(
// // // //                                               child: Text(
// // // //                                                 _getInitials(studentName),
// // // //                                                 style: TextStyle(
// // // //                                                   color: Colors.indigo.shade700,
// // // //                                                   fontWeight: FontWeight.bold,
// // // //                                                   fontSize: 15,
// // // //                                                 ),
// // // //                                               ),
// // // //                                             ),
// // // //                                           ),
// // // //                                           const SizedBox(width: 12),
// // // //                                           Expanded(
// // // //                                             child: Column(
// // // //                                               crossAxisAlignment: CrossAxisAlignment.start,
// // // //                                               children: [
// // // //                                                 Text(
// // // //                                                   studentName,
// // // //                                                   style: const TextStyle(
// // // //                                                     fontSize: 16,
// // // //                                                     fontWeight: FontWeight.bold,
// // // //                                                     color: Colors.black87,
// // // //                                                   ),
// // // //                                                 ),
// // // //                                                 const SizedBox(height: 2),
// // // //                                                 Row(
// // // //                                                   children: [
// // // //                                                     Icon(
// // // //                                                       Icons.menu_book_outlined,
// // // //                                                       size: 14,
// // // //                                                       color: Colors.grey.shade600,
// // // //                                                     ),
// // // //                                                     const SizedBox(width: 4),
// // // //                                                     Text(
// // // //                                                       courseName,
// // // //                                                       style: TextStyle(
// // // //                                                         fontSize: 12,
// // // //                                                         color: Colors.grey.shade600,
// // // //                                                       ),
// // // //                                                     ),
// // // //                                                   ],
// // // //                                                 ),
// // // //                                               ],
// // // //                                             ),
// // // //                                           ),
// // // //                                         ],
// // // //                                       ),

// // // //                                       const Padding(
// // // //                                         padding: EdgeInsets.symmetric(vertical: 12),
// // // //                                         child: Divider(height: 1),
// // // //                                       ),

// // // //                                       // COURSE STATUS BUTTON / ACTION
// // // //                                       SizedBox(
// // // //                                         width: double.infinity,
// // // //                                         child: isCompleted
// // // //                                             ? Container(
// // // //                                                 padding: const EdgeInsets.symmetric(vertical: 10),
// // // //                                                 decoration: BoxDecoration(
// // // //                                                   color: Colors.teal.shade50,
// // // //                                                   borderRadius: BorderRadius.circular(10),
// // // //                                                 ),
// // // //                                                 child: const Row(
// // // //                                                   mainAxisAlignment: MainAxisAlignment.center,
// // // //                                                   children: [
// // // //                                                     Icon(Icons.check_circle, color: Color(0xFF00695C), size: 16),
// // // //                                                     SizedBox(width: 6),
// // // //                                                     Text(
// // // //                                                       "Course Completed",
// // // //                                                       style: TextStyle(
// // // //                                                         color: Color(0xFF00695C),
// // // //                                                         fontWeight: FontWeight.bold,
// // // //                                                         fontSize: 13,
// // // //                                                       ),
// // // //                                                     ),
// // // //                                                   ],
// // // //                                                 ),
// // // //                                               )
// // // //                                             : ElevatedButton(
// // // //                                                 style: ElevatedButton.styleFrom(
// // // //                                                   backgroundColor: const Color(0xFF009688),
// // // //                                                   elevation: 0,
// // // //                                                   padding: const EdgeInsets.symmetric(vertical: 12),
// // // //                                                   shape: RoundedRectangleBorder(
// // // //                                                     borderRadius: BorderRadius.circular(10),
// // // //                                                   ),
// // // //                                                 ),
// // // //                                                 onPressed: () => completeCourse(courseId),
// // // //                                                 child: const Row(
// // // //                                                   mainAxisAlignment: MainAxisAlignment.center,
// // // //                                                   children: [
// // // //                                                     Icon(Icons.check, color: Colors.white, size: 16),
// // // //                                                     SizedBox(width: 4),
// // // //                                                     Text(
// // // //                                                       "Mark as Complete",
// // // //                                                       style: TextStyle(
// // // //                                                         color: Colors.white,
// // // //                                                         fontWeight: FontWeight.bold,
// // // //                                                         fontSize: 13,
// // // //                                                       ),
// // // //                                                     ),
// // // //                                                   ],
// // // //                                                 ),
// // // //                                               ),
// // // //                                       ),

// // // //                                       const SizedBox(height: 10),

// // // //                                       // FEEDBACK BUTTON / STATUS
// // // //                                       SizedBox(
// // // //                                         width: double.infinity,
// // // //                                         child: feedbackGiven
// // // //                                             ? Container(
// // // //                                                 padding: const EdgeInsets.symmetric(vertical: 10),
// // // //                                                 decoration: BoxDecoration(
// // // //                                                   color: Colors.blue.shade50,
// // // //                                                   borderRadius: BorderRadius.circular(10),
// // // //                                                 ),
// // // //                                                 child: Row(
// // // //                                                   mainAxisAlignment: MainAxisAlignment.center,
// // // //                                                   children: [
// // // //                                                     Icon(Icons.star, color: Colors.indigo.shade700, size: 16),
// // // //                                                     const SizedBox(width: 6),
// // // //                                                     Text(
// // // //                                                       "Feedback Submitted",
// // // //                                                       style: TextStyle(
// // // //                                                         color: Colors.indigo.shade700,
// // // //                                                         fontWeight: FontWeight.bold,
// // // //                                                         fontSize: 13,
// // // //                                                       ),
// // // //                                                     ),
// // // //                                                   ],
// // // //                                                 ),
// // // //                                               )
// // // //                                             : ElevatedButton(
// // // //                                                 style: ElevatedButton.styleFrom(
// // // //                                                   backgroundColor: Colors.indigo,
// // // //                                                   elevation: 0,
// // // //                                                   padding: const EdgeInsets.symmetric(vertical: 12),
// // // //                                                   shape: RoundedRectangleBorder(
// // // //                                                     borderRadius: BorderRadius.circular(10),
// // // //                                                   ),
// // // //                                                 ),
// // // //                                                 onPressed: () => _showFeedbackDialog(studentId, courseId, studentName, courseName),
// // // //                                                 child: const Row(
// // // //                                                   mainAxisAlignment: MainAxisAlignment.center,
// // // //                                                   children: [
// // // //                                                     Icon(Icons.rate_review_outlined, color: Colors.white, size: 16),
// // // //                                                     SizedBox(width: 4),
// // // //                                                     Text(
// // // //                                                       "Give Feedback",
// // // //                                                       style: TextStyle(
// // // //                                                         color: Colors.white,
// // // //                                                         fontWeight: FontWeight.bold,
// // // //                                                         fontSize: 13,
// // // //                                                       ),
// // // //                                                     ),
// // // //                                                   ],
// // // //                                                 ),
// // // //                                               ),
// // // //                                       ),
// // // //                                     ],
// // // //                                   ),
// // // //                                 );
// // // //                               },
// // // //                             ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }


















// // // // import 'dart:convert';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:house_of_tutor/TutorDrawer.dart';
// // // // import 'package:house_of_tutor/TutorHome.dart';
// // // // import 'services/api_client.dart';

// // // // class TutorStudent {
// // // //   final int studentId;
// // // //   final String studentName;
// // // //   final int courseId;
// // // //   final String courseName;
// // // //   final bool isCompleted;
// // // //   final bool feedbackGiven;

// // // //   TutorStudent({
// // // //     required this.studentId,
// // // //     required this.studentName,
// // // //     required this.courseId,
// // // //     required this.courseName,
// // // //     required this.isCompleted,
// // // //     required this.feedbackGiven,
// // // //   });

// // // //   factory TutorStudent.fromJson(Map<String, dynamic> json) {
// // // //     return TutorStudent(
// // // //       studentId: json["studentId"] ?? 0,
// // // //       studentName: json["studentName"] ?? "",
// // // //       courseId: json["courseId"] ?? 0,
// // // //       courseName: json["courseName"] ?? "",
// // // //       isCompleted: json["isCompleted"] ?? false,
// // // //       feedbackGiven: json["feedbackGiven"] ?? false,
// // // //     );
// // // //   }
// // // // }

// // // // /// Tutor My Students Screen

// // // // class TutorMyStudents extends StatefulWidget {
// // // //   const TutorMyStudents({super.key});

// // // //   @override
// // // //   State<TutorMyStudents> createState() => _TutorMyStudentsState();
// // // // }

// // // // class _TutorMyStudentsState extends State<TutorMyStudents> {
// // // //   bool loading = false;
// // // //   int selectedRating = 5;
// // // //   final TextEditingController commentController = TextEditingController();
// // // //   List<TutorStudent> students = [];

// // // //   final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

// // // //   void openDrawer() {
// // // //     scaffoldKey.currentState?.openDrawer();
// // // //   }

// // // //   // ✅ FIXED BACK FUNCTION
// // // //   void _goBack() {
// // // //     if (Navigator.canPop(context)) {
// // // //       Navigator.pop(context);
// // // //     } else {
// // // //       Navigator.pushReplacement(
// // // //         context,
// // // //         MaterialPageRoute(builder: (_) => TutorHome()),
// // // //       );
// // // //     }
// // // //   }

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     fetchStudents();
// // // //   }

// // // //   //==========================================================
// // // //   // FETCH STUDENTS
// // // //   //==========================================================

// // // //   Future<void> fetchStudents() async {
// // // //     try {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           loading = true;
// // // //         });
// // // //       }

// // // //       final response = await ApiClient.get("/api/Tutor/my-students");

// // // //       debugPrint("MY STUDENTS STATUS : ${response.statusCode}");
// // // //       debugPrint("MY STUDENTS BODY : ${response.body}");

// // // //       if (!mounted) return;

// // // //       if (response.statusCode == 200) {
// // // //         final List data = jsonDecode(utf8.decode(response.bodyBytes));
// // // //         students = data.map((e) => TutorStudent.fromJson(e)).toList();
// // // //         setState(() {});
// // // //       } else {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(
// // // //             content: Text(
// // // //               ApiClient.messageFromBody(response.body) ??
// // // //                   "Unable to load students",
// // // //             ),
// // // //           ),
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint("MY STUDENTS ERROR : $e");
// // // //       if (mounted) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(content: Text("Error : $e")),
// // // //         );
// // // //       }
// // // //     } finally {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           loading = false;
// // // //         });
// // // //       }
// // // //     }
// // // //   }

// // // //   //==========================================================
// // // //   // COMPLETE COURSE
// // // //   //==========================================================

// // // //   Future<void> completeCourse(TutorStudent student) async {
// // // //     try {
// // // //       final response = await ApiClient.post(
// // // //         "/api/Tutor/complete-course",
// // // //         {"courseId": student.courseId},
// // // //       );

// // // //       debugPrint("COMPLETE COURSE : ${response.body}");

// // // //       if (!mounted) return;

// // // //       if (response.statusCode == 200) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text("Course completed successfully")),
// // // //         );
// // // //         fetchStudents();
// // // //       } else {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(
// // // //             content: Text(
// // // //               ApiClient.messageFromBody(response.body) ??
// // // //                   "Unable to complete course",
// // // //             ),
// // // //           ),
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint("COMPLETE COURSE ERROR : $e");
// // // //       if (mounted) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(content: Text("Error : $e")),
// // // //         );
// // // //       }
// // // //     }
// // // //   }
// // // //   Future<void> giveFeedback({
// // // //     required BuildContext dialogContext,
// // // //     required TutorStudent student,
// // // //     required int rating,
// // // //     required String comment,
// // // //   }) async {
// // // //     try {
// // // //       final response = await ApiClient.post(
// // // //         "/api/Tutor/give-feedback",
// // // //         {
// // // //           "studentId": student.studentId,
// // // //           "courseId": student.courseId,
// // // //           "rating": rating,
// // // //           "comment": comment,
// // // //         },
// // // //       );
// // // //       debugPrint("GIVE FEEDBACK : ${response.body}");
// // // //       if (dialogContext.mounted) {
// // // //         Navigator.pop(dialogContext);
// // // //       }
// // // //       if (!mounted) return;
// // // //       if (response.statusCode == 200) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text("Feedback submitted successfully")),
// // // //         );
// // // //         fetchStudents();
// // // //       } else {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(
// // // //             content: Text(
// // // //               ApiClient.messageFromBody(response.body) ??
// // // //                   "Unable to submit feedback",
// // // //             ),
// // // //           ),
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint("GIVE FEEDBACK ERROR : $e");
// // // //       if (mounted) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(content: Text("Error : $e")),
// // // //         );
// // // //       }
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       key: scaffoldKey,
// // // //       drawer: const TutorDrawer(),
// // // //       backgroundColor: const Color(0xffF3F4F8),
// // // //       body: SafeArea(
// // // //         child: Column(
// // // //           children: [
// // // //             //================ HEADER =================
// // // //             Container(
// // // //               height: 80,
// // // //               color: Colors.white,
// // // //               padding: const EdgeInsets.symmetric(horizontal: 15),
// // // //               child: Row(
// // // //                 children: [
// // // //                   // ✅ FIXED BACK BUTTON
// // // //                   InkWell(
// // // //                     onTap: _goBack,
// // // //                     child: const Icon(Icons.arrow_back, size: 32),
// // // //                   ),
// // // //                   const Spacer(),
// // // //                   Image.asset("assets/images/logo.png", height: 55),
// // // //                   const Spacer(),
// // // //                   IconButton(
// // // //                     onPressed: openDrawer,
// // // //                     icon: const Icon(Icons.menu, size: 32),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ),

// // // //             Expanded(
// // // //               child: loading
// // // //                   ? const Center(child: CircularProgressIndicator())
// // // //                   : students.isEmpty
// // // //                       ? const Center(
// // // //                           child: Text(
// // // //                             "No Students Found",
// // // //                             style: TextStyle(
// // // //                               fontSize: 18,
// // // //                               fontWeight: FontWeight.bold,
// // // //                             ),
// // // //                           ),
// // // //                         )
// // // //                       : RefreshIndicator(
// // // //                           onRefresh: fetchStudents,
// // // //                           child: ListView(
// // // //                             padding: const EdgeInsets.all(20),
// // // //                             children: [
// // // //                               const Text(
// // // //                                 "My Students",
// // // //                                 style: TextStyle(
// // // //                                   fontSize: 38,
// // // //                                   fontWeight: FontWeight.bold,
// // // //                                 ),
// // // //                               ),
// // // //                               const SizedBox(height: 20),
// // // //                               ...students.map((student) => studentCard(student)),
// // // //                               const SizedBox(height: 30),
// // // //                             ],
// // // //                           ),
// // // //                         ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget studentCard(TutorStudent student) {
// // // //     return Container(
// // // //       margin: const EdgeInsets.only(bottom: 22),
// // // //       padding: const EdgeInsets.all(18),
// // // //       decoration: BoxDecoration(
// // // //         color: Colors.white,
// // // //         borderRadius: BorderRadius.circular(22),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: Colors.grey.shade300,
// // // //             blurRadius: 10,
// // // //             offset: const Offset(0, 4),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           Text(
// // // //             student.studentName,
// // // //             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
// // // //           ),
// // // //           const SizedBox(height: 5),
// // // //           Text(
// // // //             student.courseName,
// // // //             style: TextStyle(color: Colors.grey.shade700, fontSize: 18),
// // // //           ),
// // // //           const SizedBox(height: 20),
// // // //           if (!student.isCompleted)
// // // //             completeCourseButton(student)
// // // //           else
// // // //             completedSection(student),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget completeCourseButton(TutorStudent student) {
// // // //     return SizedBox(
// // // //       width: double.infinity,
// // // //       height: 58,
// // // //       child: ElevatedButton.icon(
// // // //         onPressed: () {
// // // //           showDialog(
// // // //             context: context,
// // // //             builder: (alertContext) {
// // // //               return AlertDialog(
// // // //                 title: const Text("Complete Course"),
// // // //                 content: const Text(
// // // //                   "Are you sure you want to mark this course as completed?",
// // // //                 ),
// // // //                 actions: [
// // // //                   TextButton(
// // // //                     onPressed: () => Navigator.pop(alertContext),
// // // //                     child: const Text("Cancel"),
// // // //                   ),
// // // //                   ElevatedButton(
// // // //                     onPressed: () {
// // // //                       Navigator.pop(alertContext);
// // // //                       completeCourse(student);
// // // //                     },
// // // //                     child: const Text("Complete"),
// // // //                   ),
// // // //                 ],
// // // //               );
// // // //             },
// // // //           );
// // // //         },
// // // //         style: ElevatedButton.styleFrom(
// // // //           backgroundColor: const Color(0xff2DB55D),
// // // //           shape: RoundedRectangleBorder(
// // // //             borderRadius: BorderRadius.circular(16),
// // // //           ),
// // // //         ),
// // // //         icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
// // // //         label: const Text(
// // // //           "Complete Course",
// // // //           style: TextStyle(
// // // //             color: Colors.white,
// // // //             fontWeight: FontWeight.bold,
// // // //             fontSize: 22,
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget completedSection(TutorStudent student) {
// // // //     return Column(
// // // //       children: [
// // // //         Container(
// // // //           width: double.infinity,
// // // //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
// // // //           decoration: BoxDecoration(
// // // //             color: Colors.green.shade100,
// // // //             borderRadius: BorderRadius.circular(14),
// // // //           ),
// // // //           child: const Text(
// // // //             "Course Completed",
// // // //             style: TextStyle(
// // // //               fontWeight: FontWeight.bold,
// // // //               color: Colors.green,
// // // //               fontSize: 18,
// // // //             ),
// // // //           ),
// // // //         ),
// // // //         const SizedBox(height: 16),
// // // //         if (!student.feedbackGiven)
// // // //           feedbackButton(student)
// // // //         else
// // // //           feedbackSubmittedWidget(),
// // // //       ],
// // // //     );
// // // //   }

// // // //   Widget feedbackButton(TutorStudent student) {
// // // //     return SizedBox(
// // // //       width: double.infinity,
// // // //       height: 58,
// // // //       child: ElevatedButton.icon(
// // // //         onPressed: () => openFeedbackDialog(student),
// // // //         style: ElevatedButton.styleFrom(
// // // //           backgroundColor: const Color(0xff2F80ED),
// // // //           shape: RoundedRectangleBorder(
// // // //             borderRadius: BorderRadius.circular(16),
// // // //           ),
// // // //         ),
// // // //         icon: const Icon(Icons.rate_review, color: Colors.white),
// // // //         label: const Text(
// // // //           "Give Feedback",
// // // //           style: TextStyle(
// // // //             color: Colors.white,
// // // //             fontSize: 22,
// // // //             fontWeight: FontWeight.bold,
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget feedbackSubmittedWidget() {
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: const EdgeInsets.symmetric(vertical: 16),
// // // //       decoration: BoxDecoration(
// // // //         color: Colors.green.shade100,
// // // //         borderRadius: BorderRadius.circular(14),
// // // //       ),
// // // //       child: const Center(
// // // //         child: Text(
// // // //           "Feedback Submitted",
// // // //           style: TextStyle(
// // // //             color: Colors.green,
// // // //             fontWeight: FontWeight.bold,
// // // //             fontSize: 18,
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Future<void> openFeedbackDialog(TutorStudent student) async {
// // // //     selectedRating = 5;
// // // //     commentController.clear();

// // // //     showDialog(
// // // //       context: context,
// // // //       barrierDismissible: false,
// // // //       builder: (dialogContext) {
// // // //         return StatefulBuilder(
// // // //           builder: (statefulContext, setDialogState) {
// // // //             return Dialog(
// // // //               shape: RoundedRectangleBorder(
// // // //                 borderRadius: BorderRadius.circular(25),
// // // //               ),
// // // //               child: Padding(
// // // //                 padding: const EdgeInsets.all(25),
// // // //                 child: SingleChildScrollView(
// // // //                   child: Column(
// // // //                     mainAxisSize: MainAxisSize.min,
// // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // //                     children: [
// // // //                       const Text(
// // // //                         "Student Feedback",
// // // //                         style: TextStyle(
// // // //                           fontSize: 34,
// // // //                           fontWeight: FontWeight.bold,
// // // //                         ),
// // // //                       ),
// // // //                       const SizedBox(height: 30),
// // // //                       const Text(
// // // //                         "Rating",
// // // //                         style: TextStyle(
// // // //                           fontSize: 24,
// // // //                           fontWeight: FontWeight.bold,
// // // //                         ),
// // // //                       ),
// // // //                       const SizedBox(height: 15),
// // // //                       Row(
// // // //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                         children: List.generate(5, (index) {
// // // //                           return InkWell(
// // // //                             onTap: () {
// // // //                               setDialogState(() {
// // // //                                 selectedRating = index + 1;
// // // //                               });
// // // //                             },
// // // //                             child: Icon(
// // // //                               index < selectedRating
// // // //                                   ? Icons.star
// // // //                                   : Icons.star_border,
// // // //                               color: Colors.amber,
// // // //                               size: 45,
// // // //                             ),
// // // //                           );
// // // //                         }),
// // // //                       ),
// // // //                       const SizedBox(height: 30),
// // // //                       const Text(
// // // //                         "Comment",
// // // //                         style: TextStyle(
// // // //                           fontSize: 24,
// // // //                           fontWeight: FontWeight.bold,
// // // //                         ),
// // // //                       ),
// // // //                       const SizedBox(height: 10),
// // // //                       TextField(
// // // //                         controller: commentController,
// // // //                         maxLines: 5,
// // // //                         decoration: InputDecoration(
// // // //                           hintText: "Write feedback...",
// // // //                           border: OutlineInputBorder(
// // // //                             borderRadius: BorderRadius.circular(16),
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                       const SizedBox(height: 30),
// // // //                       Row(
// // // //                         children: [
// // // //                           Expanded(
// // // //                             child: SizedBox(
// // // //                               height: 55,
// // // //                               child: ElevatedButton(
// // // //                                 onPressed: () => Navigator.pop(dialogContext),
// // // //                                 style: ElevatedButton.styleFrom(
// // // //                                   backgroundColor: Colors.grey.shade300,
// // // //                                   shape: RoundedRectangleBorder(
// // // //                                     borderRadius: BorderRadius.circular(16),
// // // //                                   ),
// // // //                                 ),
// // // //                                 child: const Text(
// // // //                                   "Cancel",
// // // //                                   style: TextStyle(
// // // //                                     color: Colors.black,
// // // //                                     fontSize: 20,
// // // //                                     fontWeight: FontWeight.bold,
// // // //                                   ),
// // // //                                 ),
// // // //                               ),
// // // //                             ),
// // // //                           ),
// // // //                           const SizedBox(width: 15),
// // // //                           Expanded(
// // // //                             child: SizedBox(
// // // //                               height: 55,
// // // //                               child: ElevatedButton(
// // // //                                 onPressed: () async {
// // // //                                   if (commentController.text.trim().isEmpty) {
// // // //                                     ScaffoldMessenger.of(statefulContext)
// // // //                                         .showSnackBar(
// // // //                                       const SnackBar(
// // // //                                         content: Text("Please enter feedback"),
// // // //                                       ),
// // // //                                     );
// // // //                                     return;
// // // //                                   }
// // // //                                   await giveFeedback(
// // // //                                     dialogContext: dialogContext,
// // // //                                     student: student,
// // // //                                     rating: selectedRating,
// // // //                                     comment: commentController.text.trim(),
// // // //                                   );
// // // //                                 },
// // // //                                 style: ElevatedButton.styleFrom(
// // // //                                   backgroundColor: Colors.blue,
// // // //                                   shape: RoundedRectangleBorder(
// // // //                                     borderRadius: BorderRadius.circular(16),
// // // //                                   ),
// // // //                                 ),
// // // //                                 child: const Text(
// // // //                                   "Submit",
// // // //                                   style: TextStyle(
// // // //                                     fontSize: 20,
// // // //                                     color: Colors.white,
// // // //                                     fontWeight: FontWeight.bold,
// // // //                                   ),
// // // //                                 ),
// // // //                               ),
// // // //                             ),
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             );
// // // //           },
// // // //         );
// // // //       },
// // // //     );
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     commentController.dispose();
// // // //     super.dispose();
// // // //   }
// // // // }

























































































































// // // // // import 'dart:convert';
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:house_of_tutor/TutorDrawer.dart';
// // // // // import 'services/api_client.dart';

// // // // // /// Tutor Student Model

// // // // // class TutorStudent {
// // // // //   final int studentId;
// // // // //   final String studentName;
// // // // //   final int courseId;
// // // // //   final String courseName;
// // // // //   final bool isCompleted;
// // // // //   final bool feedbackGiven;

// // // // //   TutorStudent({
// // // // //     required this.studentId,
// // // // //     required this.studentName,
// // // // //     required this.courseId,
// // // // //     required this.courseName,
// // // // //     required this.isCompleted,
// // // // //     required this.feedbackGiven,
// // // // //   });

// // // // //   factory TutorStudent.fromJson(Map<String, dynamic> json) {
// // // // //     return TutorStudent(
// // // // //       studentId: json["studentId"] ?? 0,
// // // // //       studentName: json["studentName"] ?? "",
// // // // //       courseId: json["courseId"] ?? 0,
// // // // //       courseName: json["courseName"] ?? "",
// // // // //       isCompleted: json["isCompleted"] ?? false,
// // // // //       feedbackGiven: json["feedbackGiven"] ?? false,
// // // // //     );
// // // // //   }
// // // // // }

// // // // // // Tutor My Students Screen

// // // // // class TutorMyStudents extends StatefulWidget {
// // // // //   const TutorMyStudents({super.key});

// // // // //   @override
// // // // //   State<TutorMyStudents> createState() => _TutorMyStudentsState();
// // // // // }

// // // // // class _TutorMyStudentsState extends State<TutorMyStudents> {
// // // // //   bool loading = false;
// // // // //   int selectedRating = 5;
// // // // //   final TextEditingController commentController = TextEditingController();
// // // // //   List<TutorStudent> students = [];

// // // // //   // Used to open the drawer from the custom header
// // // // //   final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

// // // // //   void openDrawer() {
// // // // //     scaffoldKey.currentState?.openDrawer();
// // // // //   }

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     fetchStudents();
// // // // //   }

// // // // //   Future<void> fetchStudents() async {
// // // // //     try {
// // // // //       if (mounted) {
// // // // //         setState(() {
// // // // //           loading = true;
// // // // //         });
// // // // //       }

// // // // //       final response = await ApiClient.get("/api/Tutor/my-students");
// // // // //       print(response.body);

// // // // //       if (!mounted) return;

// // // // //       if (response.statusCode == 200) {
// // // // //         final List data = jsonDecode(utf8.decode(response.bodyBytes));
// // // // //         students = data.map((e) => TutorStudent.fromJson(e)).toList();
// // // // //         setState(() {});
// // // // //       } else {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(
// // // // //             content: Text(
// // // // //               ApiClient.messageFromBody(response.body) ?? "Unable to load students",
// // // // //             ),
// // // // //           ),
// // // // //         );
// // // // //       }
// // // // //     } catch (e) {
// // // // //       if (mounted) {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(content: Text("Error : $e")),
// // // // //         );
// // // // //       }
// // // // //     } finally {
// // // // //       if (mounted) {
// // // // //         setState(() {
// // // // //           loading = false;
// // // // //         });
// // // // //       }
// // // // //     }
// // // // //   }

// // // // //   Future<void> completeCourse(TutorStudent student) async {
// // // // //     try {
// // // // //       final response = await ApiClient.post(
// // // // //         "/api/Tutor/complete-course",
// // // // //         {"courseId": student.courseId},
// // // // //       );

// // // // //       print(response.body);

// // // // //       if (!mounted) return;

// // // // //       if (response.statusCode == 200) {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           const SnackBar(content: Text("Course completed successfully")),
// // // // //         );
// // // // //         fetchStudents();
// // // // //       } else {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(
// // // // //             content: Text(
// // // // //               ApiClient.messageFromBody(response.body) ?? "Unable to complete course",
// // // // //             ),
// // // // //           ),
// // // // //         );
// // // // //       }
// // // // //     } catch (e) {
// // // // //       if (mounted) {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(content: Text("Error : $e")),
// // // // //         );
// // // // //       }
// // // // //     }
// // // // //   }

// // // // //   // FIXED: Passed dialogContext into this method to pop the dialog layout, not the screen layout
// // // // //   Future<void> giveFeedback({
// // // // //     required BuildContext dialogContext,
// // // // //     required TutorStudent student,
// // // // //     required int rating,
// // // // //     required String comment,
// // // // //   }) async {
// // // // //     try {
// // // // //       final response = await ApiClient.post(
// // // // //         "/api/Tutor/give-feedback",
// // // // //         {
// // // // //           "studentId": student.studentId,
// // // // //           "courseId": student.courseId,
// // // // //           "rating": rating,
// // // // //           "comment": comment,
// // // // //         },
// // // // //       );

// // // // //       print(response.body);

// // // // //       // Safe pop using the specific dialog context instance
// // // // //       if (dialogContext.mounted) {
// // // // //         Navigator.pop(dialogContext);
// // // // //       }

// // // // //       if (!mounted) return;

// // // // //       if (response.statusCode == 200) {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           const SnackBar(content: Text("Feedback submitted successfully")),
// // // // //         );
// // // // //         fetchStudents();
// // // // //       } else {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(
// // // // //             content: Text(
// // // // //               ApiClient.messageFromBody(response.body) ?? "Unable to submit feedback",
// // // // //             ),
// // // // //           ),
// // // // //         );
// // // // //       }
// // // // //     } catch (e) {
// // // // //       if (mounted) {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(content: Text("Error : $e")),
// // // // //         );
// // // // //       }
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       key: scaffoldKey,
// // // // //       drawer: const TutorDrawer(),
// // // // //       backgroundColor: const Color(0xffF3F4F8),
// // // // //       body: SafeArea(
// // // // //         child: Column(
// // // // //           children: [
// // // // //             //================ HEADER =================
// // // // //             Container(
// // // // //               height: 80,
// // // // //               color: Colors.white,
// // // // //               padding: const EdgeInsets.symmetric(horizontal: 15),
// // // // //               child: Row(
// // // // //                 children: [
// // // // //                   InkWell(
// // // // //                     onTap: () => Navigator.pop(context),
// // // // //                     child: const Icon(Icons.arrow_back, size: 32),
// // // // //                   ),
// // // // //                   const Spacer(),
// // // // //                   Image.asset("assets/images/logo.png", height: 55),
// // // // //                   const Spacer(),
// // // // //                   IconButton(
// // // // //                     onPressed: openDrawer,
// // // // //                     icon: const Icon(Icons.menu, size: 32),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //             Expanded(
// // // // //               child: loading
// // // // //                   ? const Center(child: CircularProgressIndicator())
// // // // //                   : students.isEmpty
// // // // //                       ? const Center(
// // // // //                           child: Text(
// // // // //                             "No Students Found",
// // // // //                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // // // //                           ),
// // // // //                         )
// // // // //                       : ListView(
// // // // //                           padding: const EdgeInsets.all(20),
// // // // //                           children: [
// // // // //                             const Text(
// // // // //                               "My Students",
// // // // //                               style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
// // // // //                             ),
// // // // //                             const SizedBox(height: 20),
// // // // //                             ...students.map((student) => studentCard(student)),
// // // // //                             const SizedBox(height: 30),
// // // // //                           ],
// // // // //                         ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget studentCard(TutorStudent student) {
// // // // //     return Container(
// // // // //       margin: const EdgeInsets.only(bottom: 22),
// // // // //       padding: const EdgeInsets.all(18),
// // // // //       decoration: BoxDecoration(
// // // // //         color: Colors.white,
// // // // //         borderRadius: BorderRadius.circular(22),
// // // // //         boxShadow: [
// // // // //           BoxShadow(
// // // // //             color: Colors.grey.shade300,
// // // // //             blurRadius: 10,
// // // // //             offset: const Offset(0, 4),
// // // // //           )
// // // // //         ],
// // // // //       ),
// // // // //       child: Column(
// // // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // // //         children: [
// // // // //           Text(
// // // // //             student.studentName,
// // // // //             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
// // // // //           ),
// // // // //           const SizedBox(height: 5),
// // // // //           Text(
// // // // //             student.courseName,
// // // // //             style: TextStyle(color: Colors.grey.shade700, fontSize: 18),
// // // // //           ),
// // // // //           const SizedBox(height: 20),
// // // // //           if (!student.isCompleted)
// // // // //             completeCourseButton(student)
// // // // //           else
// // // // //             completedSection(student),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget completeCourseButton(TutorStudent student) {
// // // // //     return SizedBox(
// // // // //       width: double.infinity,
// // // // //       height: 58,
// // // // //       child: ElevatedButton.icon(
// // // // //         onPressed: () {
// // // // //           showDialog(
// // // // //             context: context,
// // // // //             builder: (alertContext) {
// // // // //               return AlertDialog(
// // // // //                 title: const Text("Complete Course"),
// // // // //                 content: const Text("Are you sure you want to mark this course as completed?"),
// // // // //                 actions: [
// // // // //                   TextButton(
// // // // //                     onPressed: () => Navigator.pop(alertContext),
// // // // //                     child: const Text("Cancel"),
// // // // //                   ),
// // // // //                   ElevatedButton(
// // // // //                     onPressed: () {
// // // // //                       Navigator.pop(alertContext);
// // // // //                       completeCourse(student);
// // // // //                     },
// // // // //                     child: const Text("Complete"),
// // // // //                   )
// // // // //                 ],
// // // // //               );
// // // // //             },
// // // // //           );
// // // // //         },
// // // // //         style: ElevatedButton.styleFrom(
// // // // //           backgroundColor: const Color(0xff2DB55D),
// // // // //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// // // // //         ),
// // // // //         icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
// // // // //         label: const Text(
// // // // //           "Complete Course",
// // // // //           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget completedSection(TutorStudent student) {
// // // // //     return Column(
// // // // //       children: [
// // // // //         Container(
// // // // //           width: double.infinity,
// // // // //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
// // // // //           decoration: BoxDecoration(
// // // // //             color: Colors.green.shade100,
// // // // //             borderRadius: BorderRadius.circular(14),
// // // // //           ),
// // // // //           child: const Text(
// // // // //             "Course Completed",
// // // // //             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18),
// // // // //           ),
// // // // //         ),
// // // // //         const SizedBox(height: 16),
// // // // //         if (!student.feedbackGiven) feedbackButton(student) else feedbackSubmittedWidget(),
// // // // //       ],
// // // // //     );
// // // // //   }

// // // // //   Widget feedbackButton(TutorStudent student) {
// // // // //     return SizedBox(
// // // // //       width: double.infinity,
// // // // //       height: 58,
// // // // //       child: ElevatedButton.icon(
// // // // //         onPressed: () => openFeedbackDialog(student),
// // // // //         style: ElevatedButton.styleFrom(
// // // // //           backgroundColor: const Color(0xff2F80ED),
// // // // //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// // // // //         ),
// // // // //         icon: const Icon(Icons.rate_review, color: Colors.white),
// // // // //         label: const Text(
// // // // //           "Give Feedback",
// // // // //           style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget feedbackSubmittedWidget() {
// // // // //     return Container(
// // // // //       width: double.infinity,
// // // // //       padding: const EdgeInsets.symmetric(vertical: 16),
// // // // //       decoration: BoxDecoration(
// // // // //         color: Colors.green.shade100,
// // // // //         borderRadius: BorderRadius.circular(14),
// // // // //       ),
// // // // //       child: const Center(
// // // // //         child: Text(
// // // // //           "Feedback Submitted",
// // // // //           style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Future<void> openFeedbackDialog(TutorStudent student) async {
// // // // //     selectedRating = 5;
// // // // //     commentController.clear();

// // // // //     showDialog(
// // // // //       context: context,
// // // // //       barrierDismissible: false,
// // // // //       builder: (dialogContext) {
// // // // //         return StatefulBuilder(
// // // // //           builder: (statefulContext, setDialogState) {
// // // // //             return Dialog(
// // // // //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
// // // // //               child: Padding(
// // // // //                 padding: const EdgeInsets.all(25),
// // // // //                 child: SingleChildScrollView(
// // // // //                   child: Column(
// // // // //                     mainAxisSize: MainAxisSize.min,
// // // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                     children: [
// // // // //                       const Text(
// // // // //                         "Student Feedback",
// // // // //                         style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
// // // // //                       ),
// // // // //                       const SizedBox(height: 30),
// // // // //                       const Text(
// // // // //                         "Rating",
// // // // //                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
// // // // //                       ),
// // // // //                       const SizedBox(height: 15),
// // // // //                       Row(
// // // // //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // //                         children: List.generate(5, (index) {
// // // // //                           return InkWell(
// // // // //                             onTap: () {
// // // // //                               setDialogState(() {
// // // // //                                 selectedRating = index + 1;
// // // // //                               });
// // // // //                             },
// // // // //                             child: Icon(
// // // // //                               index < selectedRating ? Icons.star : Icons.star_border,
// // // // //                               color: Colors.amber,
// // // // //                               size: 45,
// // // // //                             ),
// // // // //                           );
// // // // //                         }),
// // // // //                       ),
// // // // //                       const SizedBox(height: 30),
// // // // //                       const Text(
// // // // //                         "Comment",
// // // // //                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
// // // // //                       ),
// // // // //                       const SizedBox(height: 10),
// // // // //                       TextField(
// // // // //                         controller: commentController,
// // // // //                         maxLines: 5,
// // // // //                         decoration: InputDecoration(
// // // // //                           hintText: "Write feedback...",
// // // // //                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
// // // // //                         ),
// // // // //                       ),
// // // // //                       const SizedBox(height: 30),
// // // // //                       Row(
// // // // //                         children: [
// // // // //                           Expanded(
// // // // //                             child: SizedBox(
// // // // //                               height: 55,
// // // // //                               child: ElevatedButton(
// // // // //                                 onPressed: () => Navigator.pop(dialogContext),
// // // // //                                 style: ElevatedButton.styleFrom(
// // // // //                                   backgroundColor: Colors.grey.shade300,
// // // // //                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// // // // //                                 ),
// // // // //                                 child: const Text(
// // // // //                                   "Cancel",
// // // // //                                   style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
// // // // //                                 ),
// // // // //                               ),
// // // // //                             ),
// // // // //                           ),
// // // // //                           const SizedBox(width: 15),
// // // // //                           Expanded(
// // // // //                             child: SizedBox(
// // // // //                               height: 55,
// // // // //                               child: ElevatedButton(
// // // // //                                 onPressed: () async {
// // // // //                                   if (commentController.text.trim().isEmpty) {
// // // // //                                     ScaffoldMessenger.of(statefulContext).showSnackBar(
// // // // //                                       const SnackBar(content: Text("Please enter feedback")),
// // // // //                                     );
// // // // //                                     return;
// // // // //                                   }

// // // // //                                   await giveFeedback(
// // // // //                                     dialogContext: dialogContext, // Pass context explicitly here
// // // // //                                     student: student,
// // // // //                                     rating: selectedRating,
// // // // //                                     comment: commentController.text.trim(),
// // // // //                                   );
// // // // //                                 },
// // // // //                                 style: ElevatedButton.styleFrom(
// // // // //                                   backgroundColor: Colors.blue,
// // // // //                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// // // // //                                 ),
// // // // //                                 child: const Text(
// // // // //                                   "Submit",
// // // // //                                   style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
// // // // //                                 ),
// // // // //                               ),
// // // // //                             ),
// // // // //                           ),
// // // // //                         ],
// // // // //                       )
// // // // //                     ],
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //             );
// // // // //           },
// // // // //         );
// // // // //       },
// // // // //     );
// // // // //   }
// // // // //   void dispose() {
// // // // //     commentController.dispose();
// // // // //     super.dispose();
// // // // //   }
// // // // // }
















































































// // // // // // import 'dart:convert';

// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:house_of_tutor/TutorDrawer.dart';


// // // // // // import 'services/api_client.dart';

// // // // // // ///==========================================================
// // // // // // /// Tutor Student Model
// // // // // // ///==========================================================

// // // // // // class TutorStudent {
// // // // // //   final int studentId;

// // // // // //   final String studentName;

// // // // // //   final int courseId;

// // // // // //   final String courseName;

// // // // // //   final bool isCompleted;

// // // // // //   final bool feedbackGiven;

// // // // // //   TutorStudent({
// // // // // //     required this.studentId,
// // // // // //     required this.studentName,
// // // // // //     required this.courseId,
// // // // // //     required this.courseName,
// // // // // //     required this.isCompleted,
// // // // // //     required this.feedbackGiven,
// // // // // //   });

// // // // // //   factory TutorStudent.fromJson(Map<String, dynamic> json) {
// // // // // //     return TutorStudent(
// // // // // //       studentId: json["studentId"] ?? 0,
// // // // // //       studentName: json["studentName"] ?? "",
// // // // // //       courseId: json["courseId"] ?? 0,
// // // // // //       courseName: json["courseName"] ?? "",
// // // // // //       isCompleted: json["isCompleted"] ?? false,
// // // // // //       feedbackGiven: json["feedbackGiven"] ?? false,
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // ///==========================================================
// // // // // // /// Tutor My Students Screen
// // // // // // ///==========================================================

// // // // // // class TutorMyStudents extends StatefulWidget {
// // // // // //   const TutorMyStudents({super.key});

// // // // // //   @override
// // // // // //   State<TutorMyStudents> createState() => _TutorMyStudentsState();
// // // // // // }

// // // // // // class _TutorMyStudentsState extends State<TutorMyStudents> {
// // // // // //   bool loading = false;
// // // // // //   int selectedRating = 5;

// // // // // //   final TextEditingController commentController = TextEditingController();

// // // // // //   List<TutorStudent> students = [];

// // // // // //   /// Used to open the drawer from the custom header
// // // // // //   final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

// // // // // //   void openDrawer() {
// // // // // //     scaffoldKey.currentState?.openDrawer();
// // // // // //   }

// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();

// // // // // //     fetchStudents();
// // // // // //   }

// // // // // //   Future<void> fetchStudents() async {
// // // // // //     try {
// // // // // //       if (mounted) {
// // // // // //         setState(() {
// // // // // //           loading = true;
// // // // // //         });
// // // // // //       }

// // // // // //       final response = await ApiClient.get(
// // // // // //         "/api/Tutor/my-students",
// // // // // //       );

// // // // // //       print(response.body);

// // // // // //       if (response.statusCode == 200) {
// // // // // //         final List data = jsonDecode(
// // // // // //           utf8.decode(response.bodyBytes),
// // // // // //         );

// // // // // //         students = data
// // // // // //             .map(
// // // // // //               (e) => TutorStudent.fromJson(e),
// // // // // //             )
// // // // // //             .toList();

// // // // // //         if (mounted) {
// // // // // //           setState(() {});
// // // // // //         }
// // // // // //       } else {
// // // // // //         if (mounted) {
// // // // // //           ScaffoldMessenger.of(context).showSnackBar(
// // // // // //             SnackBar(
// // // // // //               content: Text(
// // // // // //                 ApiClient.messageFromBody(
// // // // // //                       response.body,
// // // // // //                     ) ??
// // // // // //                     "Unable to load students",
// // // // // //               ),
// // // // // //             ),
// // // // // //           );
// // // // // //         }
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       if (mounted) {
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(
// // // // // //             content: Text(
// // // // // //               "Error : $e",
// // // // // //             ),
// // // // // //           ),
// // // // // //         );
// // // // // //       }
// // // // // //     } finally {
// // // // // //       if (mounted) {
// // // // // //         setState(() {
// // // // // //           loading = false;
// // // // // //         });
// // // // // //       }
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> completeCourse(TutorStudent student) async {
// // // // // //     try {
// // // // // //       final response = await ApiClient.post(
// // // // // //         "/api/Tutor/complete-course",
// // // // // //         {
// // // // // //           "courseId": student.courseId,
// // // // // //         },
// // // // // //       );

// // // // // //       print(response.body);

// // // // // //       if (response.statusCode == 200) {
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           const SnackBar(
// // // // // //             content: Text(
// // // // // //               "Course completed successfully",
// // // // // //             ),
// // // // // //           ),
// // // // // //         );

// // // // // //         fetchStudents();
// // // // // //       } else {
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(
// // // // // //             content: Text(
// // // // // //               ApiClient.messageFromBody(
// // // // // //                     response.body,
// // // // // //                   ) ??
// // // // // //                   "Unable to complete course",
// // // // // //             ),
// // // // // //           ),
// // // // // //         );
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         SnackBar(
// // // // // //           content: Text(
// // // // // //             "Error : $e",
// // // // // //           ),
// // // // // //         ),
// // // // // //       );
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> giveFeedback({
// // // // // //     required TutorStudent student,
// // // // // //     required int rating,
// // // // // //     required String comment,
// // // // // //   }) async {
// // // // // //     try {
// // // // // //       final response = await ApiClient.post(
// // // // // //         "/api/Tutor/give-feedback",
// // // // // //         {
// // // // // //           "studentId": student.studentId,
// // // // // //           "courseId": student.courseId,
// // // // // //           "rating": rating,
// // // // // //           "comment": comment,
// // // // // //         },
// // // // // //       );

// // // // // //       print(response.body);

// // // // // //       if (response.statusCode == 200) {
// // // // // //         Navigator.pop(context);

// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           const SnackBar(
// // // // // //             content: Text(
// // // // // //               "Feedback submitted successfully",
// // // // // //             ),
// // // // // //           ),
// // // // // //         );

// // // // // //         fetchStudents();
// // // // // //       } else {
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(
// // // // // //             content: Text(
// // // // // //               ApiClient.messageFromBody(
// // // // // //                     response.body,
// // // // // //                   ) ??
// // // // // //                   "Unable to submit feedback",
// // // // // //             ),
// // // // // //           ),
// // // // // //         );
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         SnackBar(
// // // // // //           content: Text(
// // // // // //             "Error : $e",
// // // // // //           ),
// // // // // //         ),
// // // // // //       );
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       key: scaffoldKey,
// // // // // //       drawer: const TutorDrawer(),
// // // // // //       backgroundColor: const Color(0xffF3F4F8),
// // // // // //       body: SafeArea(
// // // // // //         child: Column(
// // // // // //           children: [
// // // // // //             //================ HEADER =================

// // // // // //             Container(
// // // // // //               height: 80,
// // // // // //               color: Colors.white,
// // // // // //               padding: const EdgeInsets.symmetric(horizontal: 15),
// // // // // //               child: Row(
// // // // // //                 children: [
// // // // // //                   InkWell(
// // // // // //                     onTap: () {
// // // // // //                       Navigator.pop(context);
// // // // // //                     },
// // // // // //                     child: const Icon(
// // // // // //                       Icons.arrow_back,
// // // // // //                       size: 32,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   const Spacer(),
// // // // // //                   Image.asset(
// // // // // //                     "assets/images/logo.png",
// // // // // //                     height: 55,
// // // // // //                   ),
// // // // // //                   const Spacer(),
// // // // // //                   IconButton(
// // // // // //                     onPressed: openDrawer,
// // // // // //                     icon: const Icon(
// // // // // //                       Icons.menu,
// // // // // //                       size: 32,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                 ],
// // // // // //               ),
// // // // // //             ),

// // // // // //             Expanded(
// // // // // //               child: loading
// // // // // //                   ? const Center(
// // // // // //                       child: CircularProgressIndicator(),
// // // // // //                     )
// // // // // //                   : students.isEmpty
// // // // // //                       ? const Center(
// // // // // //                           child: Text(
// // // // // //                             "No Students Found",
// // // // // //                             style: TextStyle(
// // // // // //                               fontSize: 18,
// // // // // //                               fontWeight: FontWeight.bold,
// // // // // //                             ),
// // // // // //                           ),
// // // // // //                         )
// // // // // //                       : ListView(
// // // // // //                           padding: const EdgeInsets.all(20),
// // // // // //                           children: [
// // // // // //                             const Text(
// // // // // //                               "My Students",
// // // // // //                               style: TextStyle(
// // // // // //                                 fontSize: 38,
// // // // // //                                 fontWeight: FontWeight.bold,
// // // // // //                               ),
// // // // // //                             ),
// // // // // //                             const SizedBox(height: 20),
// // // // // //                             ...students.map(
// // // // // //                               (student) => studentCard(student),
// // // // // //                             ),
// // // // // //                             const SizedBox(height: 30),
// // // // // //                           ],
// // // // // //                         ),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   Widget studentCard(TutorStudent student) {
// // // // // //     return Container(
// // // // // //       margin: const EdgeInsets.only(bottom: 22),
// // // // // //       padding: const EdgeInsets.all(18),
// // // // // //       decoration: BoxDecoration(
// // // // // //         color: Colors.white,
// // // // // //         borderRadius: BorderRadius.circular(22),
// // // // // //         boxShadow: [
// // // // // //           BoxShadow(
// // // // // //             color: Colors.grey.shade300,
// // // // // //             blurRadius: 10,
// // // // // //             offset: const Offset(0, 4),
// // // // // //           )
// // // // // //         ],
// // // // // //       ),
// // // // // //       child: Column(
// // // // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //         children: [
// // // // // //           Text(
// // // // // //             student.studentName,
// // // // // //             style: const TextStyle(
// // // // // //               fontWeight: FontWeight.bold,
// // // // // //               fontSize: 22,
// // // // // //             ),
// // // // // //           ),
// // // // // //           const SizedBox(height: 5),
// // // // // //           Text(
// // // // // //             student.courseName,
// // // // // //             style: TextStyle(
// // // // // //               color: Colors.grey.shade700,
// // // // // //               fontSize: 18,
// // // // // //             ),
// // // // // //           ),
// // // // // //           const SizedBox(height: 20),
// // // // // //           if (!student.isCompleted)
// // // // // //             completeCourseButton(student)
// // // // // //           else
// // // // // //             completedSection(student),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   Widget completeCourseButton(TutorStudent student) {
// // // // // //     return SizedBox(
// // // // // //       width: double.infinity,
// // // // // //       height: 58,
// // // // // //       child: ElevatedButton.icon(
// // // // // //         onPressed: () {
// // // // // //           showDialog(
// // // // // //             context: context,
// // // // // //             builder: (_) {
// // // // // //               return AlertDialog(
// // // // // //                 title: const Text("Complete Course"),
// // // // // //                 content: const Text(
// // // // // //                   "Are you sure you want to mark this course as completed?",
// // // // // //                 ),
// // // // // //                 actions: [
// // // // // //                   TextButton(
// // // // // //                     onPressed: () {
// // // // // //                       Navigator.pop(context);
// // // // // //                     },
// // // // // //                     child: const Text("Cancel"),
// // // // // //                   ),
// // // // // //                   ElevatedButton(
// // // // // //                     onPressed: () {
// // // // // //                       Navigator.pop(context);

// // // // // //                       completeCourse(student);
// // // // // //                     },
// // // // // //                     child: const Text("Complete"),
// // // // // //                   )
// // // // // //                 ],
// // // // // //               );
// // // // // //             },
// // // // // //           );
// // // // // //         },
// // // // // //         style: ElevatedButton.styleFrom(
// // // // // //           backgroundColor: const Color(0xff2DB55D),
// // // // // //           shape: RoundedRectangleBorder(
// // // // // //             borderRadius: BorderRadius.circular(16),
// // // // // //           ),
// // // // // //         ),
// // // // // //         icon: const Icon(
// // // // // //           Icons.check_circle,
// // // // // //           color: Colors.white,
// // // // // //           size: 28,
// // // // // //         ),
// // // // // //         label: const Text(
// // // // // //           "Complete Course",
// // // // // //           style: TextStyle(
// // // // // //             color: Colors.white,
// // // // // //             fontWeight: FontWeight.bold,
// // // // // //             fontSize: 22,
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   Widget completedSection(TutorStudent student) {
// // // // // //     return Column(
// // // // // //       children: [
// // // // // //         Container(
// // // // // //           width: double.infinity,
// // // // // //           padding: const EdgeInsets.symmetric(
// // // // // //             horizontal: 20,
// // // // // //             vertical: 16,
// // // // // //           ),
// // // // // //           decoration: BoxDecoration(
// // // // // //             color: Colors.green.shade100,
// // // // // //             borderRadius: BorderRadius.circular(14),
// // // // // //           ),
// // // // // //           child: const Text(
// // // // // //             "Course Completed",
// // // // // //             style: TextStyle(
// // // // // //               fontWeight: FontWeight.bold,
// // // // // //               color: Colors.green,
// // // // // //               fontSize: 18,
// // // // // //             ),
// // // // // //           ),
// // // // // //         ),
// // // // // //         const SizedBox(height: 16),
// // // // // //         if (!student.feedbackGiven)
// // // // // //           feedbackButton(student)
// // // // // //         else
// // // // // //           feedbackSubmittedWidget(),
// // // // // //       ],
// // // // // //     );
// // // // // //   }

// // // // // //   Widget feedbackButton(TutorStudent student) {
// // // // // //     return SizedBox(
// // // // // //       width: double.infinity,
// // // // // //       height: 58,
// // // // // //       child: ElevatedButton.icon(
// // // // // //         onPressed: () {
// // // // // //           openFeedbackDialog(student);
// // // // // //         },
// // // // // //         style: ElevatedButton.styleFrom(
// // // // // //           backgroundColor: const Color(0xff2F80ED),
// // // // // //           shape: RoundedRectangleBorder(
// // // // // //             borderRadius: BorderRadius.circular(16),
// // // // // //           ),
// // // // // //         ),
// // // // // //         icon: const Icon(
// // // // // //           Icons.rate_review,
// // // // // //           color: Colors.white,
// // // // // //         ),
// // // // // //         label: const Text(
// // // // // //           "Give Feedback",
// // // // // //           style: TextStyle(
// // // // // //             color: Colors.white,
// // // // // //             fontSize: 22,
// // // // // //             fontWeight: FontWeight.bold,
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   Widget feedbackSubmittedWidget() {
// // // // // //     return Container(
// // // // // //       width: double.infinity,
// // // // // //       padding: const EdgeInsets.symmetric(
// // // // // //         vertical: 16,
// // // // // //       ),
// // // // // //       decoration: BoxDecoration(
// // // // // //         color: Colors.green.shade100,
// // // // // //         borderRadius: BorderRadius.circular(14),
// // // // // //       ),
// // // // // //       child: const Center(
// // // // // //         child: Text(
// // // // // //           "Feedback Submitted",
// // // // // //           style: TextStyle(
// // // // // //             color: Colors.green,
// // // // // //             fontWeight: FontWeight.bold,
// // // // // //             fontSize: 18,
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   Future<void> openFeedbackDialog(TutorStudent student) async {
// // // // // //     selectedRating = 5;
// // // // // //     commentController.clear();

// // // // // //     showDialog(
// // // // // //       context: context,
// // // // // //       barrierDismissible: false,
// // // // // //       builder: (context) {
// // // // // //         return StatefulBuilder(
// // // // // //           builder: (context, setDialogState) {
// // // // // //             return Dialog(
// // // // // //               shape: RoundedRectangleBorder(
// // // // // //                 borderRadius: BorderRadius.circular(25),
// // // // // //               ),
// // // // // //               child: Padding(
// // // // // //                 padding: const EdgeInsets.all(25),
// // // // // //                 child: SingleChildScrollView(
// // // // // //                   child: Column(
// // // // // //                     mainAxisSize: MainAxisSize.min,
// // // // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //                     children: [
// // // // // //                       const Text(
// // // // // //                         "Student Feedback",
// // // // // //                         style: TextStyle(
// // // // // //                           fontSize: 34,
// // // // // //                           fontWeight: FontWeight.bold,
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                       const SizedBox(height: 30),
// // // // // //                       const Text(
// // // // // //                         "Rating",
// // // // // //                         style: TextStyle(
// // // // // //                           fontSize: 24,
// // // // // //                           fontWeight: FontWeight.bold,
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                       const SizedBox(height: 15),
// // // // // //                       Row(
// // // // // //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // // //                         children: List.generate(5, (index) {
// // // // // //                           return InkWell(
// // // // // //                             onTap: () {
// // // // // //                               setDialogState(() {
// // // // // //                                 selectedRating = index + 1;
// // // // // //                               });
// // // // // //                             },
// // // // // //                             child: Icon(
// // // // // //                               index < selectedRating
// // // // // //                                   ? Icons.star
// // // // // //                                   : Icons.star_border,
// // // // // //                               color: Colors.amber,
// // // // // //                               size: 45,
// // // // // //                             ),
// // // // // //                           );
// // // // // //                         }),
// // // // // //                       ),
// // // // // //                       const SizedBox(height: 30),
// // // // // //                       const Text(
// // // // // //                         "Comment",
// // // // // //                         style: TextStyle(
// // // // // //                           fontSize: 24,
// // // // // //                           fontWeight: FontWeight.bold,
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                       const SizedBox(height: 10),
// // // // // //                       TextField(
// // // // // //                         controller: commentController,
// // // // // //                         maxLines: 5,
// // // // // //                         decoration: InputDecoration(
// // // // // //                           hintText: "Write feedback...",
// // // // // //                           border: OutlineInputBorder(
// // // // // //                             borderRadius: BorderRadius.circular(16),
// // // // // //                           ),
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                       const SizedBox(height: 30),
// // // // // //                       Row(
// // // // // //                         children: [
// // // // // //                           Expanded(
// // // // // //                             child: SizedBox(
// // // // // //                               height: 55,
// // // // // //                               child: ElevatedButton(
// // // // // //                                 onPressed: () {
// // // // // //                                   Navigator.pop(context);
// // // // // //                                 },
// // // // // //                                 style: ElevatedButton.styleFrom(
// // // // // //                                   backgroundColor: Colors.grey.shade300,
// // // // // //                                   shape: RoundedRectangleBorder(
// // // // // //                                     borderRadius: BorderRadius.circular(16),
// // // // // //                                   ),
// // // // // //                                 ),
// // // // // //                                 child: const Text(
// // // // // //                                   "Cancel",
// // // // // //                                   style: TextStyle(
// // // // // //                                     color: Colors.black,
// // // // // //                                     fontSize: 20,
// // // // // //                                     fontWeight: FontWeight.bold,
// // // // // //                                   ),
// // // // // //                                 ),
// // // // // //                               ),
// // // // // //                             ),
// // // // // //                           ),
// // // // // //                           const SizedBox(width: 15),
// // // // // //                           Expanded(
// // // // // //                             child: SizedBox(
// // // // // //                               height: 55,
// // // // // //                               child: ElevatedButton(
// // // // // //                                 onPressed: () async {
// // // // // //                                   if (commentController.text.trim().isEmpty) {
// // // // // //                                     ScaffoldMessenger.of(context).showSnackBar(
// // // // // //                                       const SnackBar(
// // // // // //                                         content: Text(
// // // // // //                                           "Please enter feedback",
// // // // // //                                         ),
// // // // // //                                       ),
// // // // // //                                     );

// // // // // //                                     return;
// // // // // //                                   }

// // // // // //                                   await giveFeedback(
// // // // // //                                     student: student,
// // // // // //                                     rating: selectedRating,
// // // // // //                                     comment: commentController.text.trim(),
// // // // // //                                   );
// // // // // //                                 },
// // // // // //                                 style: ElevatedButton.styleFrom(
// // // // // //                                   backgroundColor: Colors.blue,
// // // // // //                                   shape: RoundedRectangleBorder(
// // // // // //                                     borderRadius: BorderRadius.circular(16),
// // // // // //                                   ),
// // // // // //                                 ),
// // // // // //                                 child: const Text(
// // // // // //                                   "Submit",
// // // // // //                                   style: TextStyle(
// // // // // //                                     fontSize: 20,
// // // // // //                                     color: Colors.white,
// // // // // //                                     fontWeight: FontWeight.bold,
// // // // // //                                   ),
// // // // // //                                 ),
// // // // // //                               ),
// // // // // //                             ),
// // // // // //                           ),
// // // // // //                         ],
// // // // // //                       )
// // // // // //                     ],
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ),
// // // // // //             );
// // // // // //           },
// // // // // //         );
// // // // // //       },
// // // // // //     );
// // // // // //   }

// // // // // //   @override
// // // // // //   void dispose() {
// // // // // //     commentController.dispose();
// // // // // //     super.dispose();
// // // // // //   }
// // // // // // }