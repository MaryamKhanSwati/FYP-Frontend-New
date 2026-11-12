
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:house_of_tutor/AdminApprovedTutor.dart';
import 'package:house_of_tutor/AdminDrawer.dart';
import 'package:house_of_tutor/AdminHome.dart';
import 'package:house_of_tutor/AdminStudent.dart';
import 'package:house_of_tutor/services/api_client.dart';

// ================================================================
// 1. COLORS
// ================================================================

class SubjectColors {
  static const Color primary = Color(0xff168F83);
  static const Color primaryDark = Color(0xff10776D);

  static const Color background = Color(0xffF5F7FA);
  static const Color white = Colors.white;

  static const Color text = Color(0xff202938);
  static const Color secondaryText = Color(0xff7B8494);

  static const Color border = Color(0xffE8ECF1);

  static const Color greenLight = Color(0xffE8F7F1);
  static const Color blueLight = Color(0xffEEF2FF);
  static const Color purpleLight = Color(0xffF3EEFF);
  static const Color orangeLight = Color(0xffFFF5E8);
  static const Color redLight = Color(0xffFFF0F0);

  static const Color red = Color(0xffE04444);
  static const Color blue = Color(0xff5265CE);
  static const Color purple = Color(0xff8456C8);
  static const Color orange = Color(0xffD98924);
}

// ================================================================
// 2. COURSE CODE MODEL
// ================================================================

class CourseCode {
  final int courseCodeId;
  final String institute;
  final String courseCode;
  final String program;
  final String description;

  const CourseCode({
    required this.courseCodeId,
    required this.institute,
    required this.courseCode,
    required this.program,
    required this.description,
  });

  factory CourseCode.fromJson(Map<String, dynamic> json) {
    return CourseCode(
      courseCodeId: _toInt(
        json['courseCodeId'] ?? json['CourseCodeId'],
      ),
      institute: _toString(
        json['institute'] ?? json['Institute'],
      ),
      courseCode: _toString(
        json['courseCode'] ?? json['CourseCode'],
      ),
      program: _toString(
        json['program'] ?? json['Program'],
      ),
      description: _toString(
        json['description'] ?? json['Description'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }
}

// ================================================================
// 3. SUBJECT MODEL
// ================================================================

class Subject {
  final int id;
  final String courseTitle;

  final double minRate;
  final double maxRate;

  final int standardDurationWeeks;
  final int standardClassesPerWeek;
  final int totalStandardClasses;

  final List<CourseCode> courseCodes;

  const Subject({
    required this.id,
    required this.courseTitle,
    required this.minRate,
    required this.maxRate,
    required this.standardDurationWeeks,
    required this.standardClassesPerWeek,
    required this.totalStandardClasses,
    required this.courseCodes,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    final codesJson =
        json['courseCodes'] ?? json['CourseCodes'];

    final List<CourseCode> codes = [];

    if (codesJson is List) {
      for (final item in codesJson) {
        if (item is Map) {
          codes.add(
            CourseCode.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final duration = _toInt(
      json['standardDurationWeeks'] ??
          json['StandardDurationWeeks'],
    );

    final classesPerWeek = _toInt(
      json['standardClassesPerWeek'] ??
          json['StandardClassesPerWeek'],
    );

    final totalClasses = _toInt(
      json['totalStandardClasses'] ??
          json['TotalStandardClasses'],
    );

    return Subject(
      id: _toInt(
        json['id'] ??
            json['courseId'] ??
            json['course_id'] ??
            json['CourseId'],
      ),

      courseTitle: _toString(
        json['courseTitle'] ??
            json['CourseTitle'] ??
            json['course_title'],
      ),

      minRate: _toDouble(
        json['minRate'] ??
            json['MinRate'] ??
            json['adminSetMinHourlyRate'] ??
            json['AdminSetMinHourlyRate'],
      ),

      maxRate: _toDouble(
        json['maxRate'] ??
            json['MaxRate'] ??
            json['adminSetMaxHourlyRate'] ??
            json['AdminSetMaxHourlyRate'],
      ),

      standardDurationWeeks: duration,

      standardClassesPerWeek: classesPerWeek,

      totalStandardClasses: totalClasses > 0
          ? totalClasses
          : duration * classesPerWeek,

      courseCodes: codes,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }
}

// ================================================================
// 4. ADMIN SUBJECT SCREEN
// ================================================================

class AdminSubject extends StatefulWidget {
  const AdminSubject({super.key});

  @override
  State<AdminSubject> createState() => _AdminSubjectState();
}

class _AdminSubjectState extends State<AdminSubject> {
  int _selectedIndex = 3;

  List<Subject> subjects = [];
  List<Subject> filteredSubjects = [];

  bool isLoading = true;
  bool isDeleting = false;

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ==============================================================
  // 5. GET ALL SUBJECTS API
  // GET /api/Admin/all-subjects
  // ==============================================================

  Future<void> fetchSubjects() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get(
        "/api/Admin/all-subjects",
      );

      debugPrint("GET SUBJECT STATUS: ${response.statusCode}");
      debugPrint("GET SUBJECT BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (decoded is! List) {
          throw const FormatException(
            "Invalid subjects response.",
          );
        }

        final loadedSubjects = decoded.map((item) {
          return Subject.fromJson(
            Map<String, dynamic>.from(item),
          );
        }).toList();

        if (!mounted) return;

        setState(() {
          subjects = loadedSubjects;
          _applySearch(searchController.text);
        });
      } else {
        if (!mounted) return;

        _showMessage(
          _getErrorMessage(
            response.body,
            "Unable to load subjects.",
          ),
          SubjectColors.red,
        );
      }
    } catch (e) {
      debugPrint("FETCH SUBJECT ERROR: $e");

      if (mounted) {
        _showMessage(
          "Something went wrong while loading subjects.",
          SubjectColors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==============================================================
  // 6. SEARCH SUBJECTS
  // ==============================================================

  void _applySearch(String query) {
    final search = query.trim().toLowerCase();

    if (search.isEmpty) {
      filteredSubjects = List.from(subjects);
      return;
    }

    filteredSubjects = subjects.where((subject) {
      final titleMatches =
          subject.courseTitle.toLowerCase().contains(search);

      final codeMatches = subject.courseCodes.any((code) {
        return code.institute.toLowerCase().contains(search) ||
            code.courseCode.toLowerCase().contains(search) ||
            code.program.toLowerCase().contains(search) ||
            code.description.toLowerCase().contains(search);
      });

      return titleMatches || codeMatches;
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _applySearch(value);
    });
  }

  // ==============================================================
  // 7. ADD SUBJECT API
  // POST /api/Admin/add-subject
  //
  // IMPORTANT:
  // MinRate and MaxRate can be null when adding another
  // university course code to an existing common course.
  //
  // Backend requires both rates when creating a new course.
  // ==============================================================

  Future<bool> addSubjectApi({
    required String courseTitle,
    required String institute,
    required String courseCode,
    required String program,
    required String description,
    required double? minRate,
    required double? maxRate,
    required int standardDurationWeeks,
    required int standardClassesPerWeek,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "courseTitle": courseTitle,
        "institute": institute,
        "courseCode": courseCode,
        "program": program.isEmpty ? null : program,
        "description": description.isEmpty ? null : description,

        "minRate": minRate,
        "maxRate": maxRate,

        // NEW BACKEND FIELDS
        "standardDurationWeeks": standardDurationWeeks,
        "standardClassesPerWeek": standardClassesPerWeek,
      };

      debugPrint("ADD SUBJECT REQUEST: $requestBody");

      final response = await ApiClient.post(
        "/api/Admin/add-subject",
        requestBody,
      );

      debugPrint("ADD SUBJECT STATUS: ${response.statusCode}");
      debugPrint("ADD SUBJECT BODY: ${response.body}");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return true;
      }

      if (mounted) {
        _showMessage(
          _getErrorMessage(
            response.body,
            "Unable to add subject.",
          ),
          SubjectColors.red,
        );
      }

      return false;
    } catch (e) {
      debugPrint("ADD SUBJECT ERROR: $e");

      if (mounted) {
        _showMessage(
          "Error adding subject. Please try again.",
          SubjectColors.red,
        );
      }

      return false;
    }
  }

  // ==============================================================
  // 8. DELETE SUBJECT API
  // DELETE /api/Admin/delete-subject/{id}
  // ==============================================================

  Future<void> deleteSubjectApi(int id) async {
    if (isDeleting) return;

    setState(() {
      isDeleting = true;
    });

    try {
      final response = await ApiClient.delete(
        "/api/Admin/delete-subject/$id",
      );

      debugPrint("DELETE STATUS: ${response.statusCode}");
      debugPrint("DELETE BODY: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        _showMessage(
          "Subject deleted successfully.",
          SubjectColors.primary,
        );

        await fetchSubjects();
      } else {
        _showMessage(
          _getErrorMessage(
            response.body,
            "Unable to delete subject.",
          ),
          SubjectColors.red,
        );
      }
    } catch (e) {
      debugPrint("DELETE SUBJECT ERROR: $e");

      if (mounted) {
        _showMessage(
          "Something went wrong while deleting.",
          SubjectColors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  // ==============================================================
  // 9. API ERROR MESSAGE
  // ==============================================================

  String _getErrorMessage(
    String body,
    String defaultMessage,
  ) {
    if (body.trim().isEmpty) return defaultMessage;

    try {
      final data = jsonDecode(body);

      if (data is Map) {
        for (final key in [
          'message',
          'error',
          'title',
          'detail',
        ]) {
          final value = data[key];

          if (value != null &&
              value.toString().trim().isNotEmpty) {
            return value.toString();
          }
        }

        if (data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final messages = <String>[];

          for (final value in errors.values) {
            if (value is List) {
              messages.addAll(
                value.map((item) => item.toString()),
              );
            } else {
              messages.add(value.toString());
            }
          }

          if (messages.isNotEmpty) {
            return messages.join("\n");
          }
        }
      }
    } catch (_) {
      return defaultMessage;
    }

    return defaultMessage;
  }

  // ==============================================================
  // 10. MESSAGE
  // ==============================================================

  void _showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ==============================================================
  // 11. INITIALS
  // ==============================================================

  String getInitials(String title) {
    final parts = title.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty || parts.first.isEmpty) {
      return "?";
    }

    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ==============================================================
  // 12. NAVIGATION
  // ==============================================================

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminHome(),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminApprovedTutor(),
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminStudent(),
        ),
      );
    }
  }

  // ==============================================================
  // 13. DELETE CONFIRMATION
  // ==============================================================

  Future<void> confirmDeleteSubject(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: SubjectColors.red,
              ),
              SizedBox(width: 10),
              Text(
                "Delete Subject",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SubjectColors.text,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${subject.courseTitle}"?',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: SubjectColors.secondaryText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: SubjectColors.secondaryText,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SubjectColors.red,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await deleteSubjectApi(subject.id);
    }
  }

  // ==============================================================
  // 14. ADD SUBJECT BOTTOM SHEET
  // ==============================================================

  Future<void> addSubject() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddSubjectSheet(
          onSave: ({
            required String courseTitle,
            required String institute,
            required String courseCode,
            required String program,
            required String description,
            required double? minRate,
            required double? maxRate,
            required int standardDurationWeeks,
            required int standardClassesPerWeek,
          }) {
            return addSubjectApi(
              courseTitle: courseTitle,
              institute: institute,
              courseCode: courseCode,
              program: program,
              description: description,
              minRate: minRate,
              maxRate: maxRate,
              standardDurationWeeks: standardDurationWeeks,
              standardClassesPerWeek: standardClassesPerWeek,
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      await fetchSubjects();

      if (!mounted) return;

      _showMessage(
        "Course and university details added successfully.",
        SubjectColors.primary,
      );
    }
  }

  // ==============================================================
  // 15. SMALL INFORMATION PILL
  // ==============================================================

  Widget _infoPill({
    required IconData icon,
    required String title,
    required String value,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 16. COURSE CODE CARD
  // ==============================================================

  Widget _courseCodeCard(CourseCode code, int index) {
    final backgrounds = [
      SubjectColors.greenLight,
      SubjectColors.blueLight,
      SubjectColors.purpleLight,
    ];

    final foregrounds = [
      SubjectColors.primary,
      SubjectColors.blue,
      SubjectColors.purple,
    ];

    final background = backgrounds[index % backgrounds.length];
    final foreground = foregrounds[index % foregrounds.length];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffFAFBFD),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: SubjectColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  code.courseCode.isEmpty
                      ? "No Code"
                      : code.courseCode,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: foreground,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  code.institute.isEmpty
                      ? "Institute not specified"
                      : code.institute,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SubjectColors.text,
                  ),
                ),
              ),
            ],
          ),

          if (code.program.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 15,
                  color: SubjectColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    code.program,
                    style: const TextStyle(
                      fontSize: 11,
                      color: SubjectColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (code.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              code.description,
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                color: SubjectColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==============================================================
  // 17. SUBJECT CARD
  // ==============================================================

  Widget _subjectCard(Subject subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SubjectColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SUBJECT HEADER
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SubjectColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  getInitials(subject.courseTitle),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: SubjectColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subject.courseTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: SubjectColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: isDeleting
                    ? null
                    : () => confirmDeleteSubject(subject),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SubjectColors.redLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: SubjectColors.red,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          // HOURLY RATES
          Row(
            children: [
              Expanded(
                child: _infoPill(
                  icon: Icons.trending_down,
                  title: "MINIMUM RATE",
                  value: "Rs. ${subject.minRate.toStringAsFixed(0)}",
                  background: SubjectColors.greenLight,
                  foreground: SubjectColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoPill(
                  icon: Icons.trending_up,
                  title: "MAXIMUM RATE",
                  value: "Rs. ${subject.maxRate.toStringAsFixed(0)}",
                  background: SubjectColors.blueLight,
                  foreground: SubjectColors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // NEW COURSE DURATION AND CLASSES
          Row(
            children: [
              Expanded(
                child: _infoPill(
                  icon: Icons.calendar_month_outlined,
                  title: "DURATION",
                  value: "${subject.standardDurationWeeks} Weeks",
                  background: SubjectColors.purpleLight,
                  foreground: SubjectColors.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoPill(
                  icon: Icons.event_available_outlined,
                  title: "CLASSES / WEEK",
                  value: "${subject.standardClassesPerWeek}",
                  background: SubjectColors.orangeLight,
                  foreground: SubjectColors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // TOTAL CLASSES
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xffF1F8F7),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: const Color(0xffDDEFEA),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: SubjectColors.primary,
                  size: 19,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    "Total Standard Classes",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SubjectColors.text,
                    ),
                  ),
                ),
                Text(
                  "${subject.totalStandardClasses} Classes",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: SubjectColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 17),

          // UNIVERSITY COURSE DETAILS
          Row(
            children: [
              const Icon(
                Icons.account_balance_outlined,
                color: SubjectColors.primary,
                size: 18,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  "University Course Details",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: SubjectColors.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: SubjectColors.greenLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${subject.courseCodes.length}",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: SubjectColors.primary,
                  ),
                ),
              ),
            ],
          ),

          if (subject.courseCodes.isNotEmpty)
            ...List.generate(
              subject.courseCodes.length,
              (index) => _courseCodeCard(
                subject.courseCodes[index],
                index,
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: SubjectColors.secondaryText,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      "No university course details available.",
                      style: TextStyle(
                        fontSize: 11,
                        color: SubjectColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==============================================================
  // 18. SEARCH BAR
  // ==============================================================

  Widget _searchBar() {
    return Container(
      height: 49,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SubjectColors.border),
      ),
      child: TextField(
        controller: searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(
          fontSize: 13,
          color: SubjectColors.text,
        ),
        decoration: InputDecoration(
          hintText: "Search subject, institute or course code...",
          hintStyle: const TextStyle(
            fontSize: 12,
            color: SubjectColors.secondaryText,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: SubjectColors.primary,
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    _onSearchChanged("");
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: SubjectColors.secondaryText,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ==============================================================
  // 19. SUMMARY CARD
  // ==============================================================

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: SubjectColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SubjectColors.greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.library_books_rounded,
              color: SubjectColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${subjects.length}",
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: SubjectColors.text,
                  ),
                ),
                const Text(
                  "Total Subjects",
                  style: TextStyle(
                    fontSize: 11,
                    color: SubjectColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: addSubject,
            style: ElevatedButton.styleFrom(
              backgroundColor: SubjectColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add, size: 17),
            label: const Text(
              "Add New",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 20. EMPTY STATE
  // ==============================================================

  Widget _emptyState() {
    final isSearching = searchController.text.trim().isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(
          isSearching
              ? Icons.search_off_rounded
              : Icons.menu_book_outlined,
          size: 65,
          color: const Color(0xffC5CDD7),
        ),
        const SizedBox(height: 15),
        Center(
          child: Text(
            isSearching
                ? "No matching subjects found"
                : "No subjects available",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: SubjectColors.text,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Center(
          child: Text(
            isSearching
                ? "Try another subject name or course code."
                : "Start by adding your first subject.",
            style: const TextStyle(
              fontSize: 12,
              color: SubjectColors.secondaryText,
            ),
          ),
        ),
        if (!isSearching) ...[
          const SizedBox(height: 18),
          Center(
            child: ElevatedButton.icon(
              onPressed: addSubject,
              style: ElevatedButton.styleFrom(
                backgroundColor: SubjectColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text("Add Subject"),
            ),
          ),
        ],
      ],
    );
  }

  // ==============================================================
  // 21. MAIN SCREEN
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SubjectColors.background,
      drawer: const AdminDrawer(),

      body: SafeArea(
        child: Column(
          children: [
            // TOP HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      return IconButton(
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                        icon: const Icon(
                          Icons.menu_rounded,
                          color: SubjectColors.primary,
                          size: 26,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  Image.asset(
                    "assets/images/logo.png",
                    height: 43,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.school_rounded,
                        size: 35,
                        color: SubjectColors.primary,
                      );
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: isLoading ? null : fetchSubjects,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: SubjectColors.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // PAGE HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Subject Management",
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: SubjectColors.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Manage courses, university codes, duration and tutor hourly rates.",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: SubjectColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 17),
                  _summaryCard(),
                  const SizedBox(height: 13),
                  _searchBar(),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "All Subjects",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: SubjectColors.text,
                          ),
                        ),
                      ),
                      Text(
                        "${filteredSubjects.length} found",
                        style: const TextStyle(
                          fontSize: 11,
                          color: SubjectColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // SUBJECT LIST
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: SubjectColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchSubjects,
                      color: SubjectColors.primary,
                      child: filteredSubjects.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                20,
                              ),
                              itemCount: filteredSubjects.length,
                              itemBuilder: (context, index) {
                                return _subjectCard(
                                  filteredSubjects[index],
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedItemColor: SubjectColors.primary,
        unselectedItemColor: SubjectColors.secondaryText,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people_rounded),
            label: "Tutors",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school_rounded),
            label: "Student",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book_rounded),
            label: "Subject",
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 22. ADD SUBJECT BOTTOM SHEET
// ================================================================

class _AddSubjectSheet extends StatefulWidget {
  final Future<bool> Function({
    required String courseTitle,
    required String institute,
    required String courseCode,
    required String program,
    required String description,
    required double? minRate,
    required double? maxRate,
    required int standardDurationWeeks,
    required int standardClassesPerWeek,
  }) onSave;

  const _AddSubjectSheet({
    required this.onSave,
  });

  @override
  State<_AddSubjectSheet> createState() =>
      _AddSubjectSheetState();
}

class _AddSubjectSheetState extends State<_AddSubjectSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController courseController =
      TextEditingController();

  final TextEditingController instituteController =
      TextEditingController();

  final TextEditingController codeController =
      TextEditingController();

  final TextEditingController programController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  final TextEditingController minController =
      TextEditingController();

  final TextEditingController maxController =
      TextEditingController();

  final TextEditingController durationController =
      TextEditingController(text: "16");

  final TextEditingController classesController =
      TextEditingController(text: "1");

  bool saving = false;

  @override
  void dispose() {
    courseController.dispose();
    instituteController.dispose();
    codeController.dispose();
    programController.dispose();
    descriptionController.dispose();
    minController.dispose();
    maxController.dispose();
    durationController.dispose();
    classesController.dispose();
    super.dispose();
  }

  // ==============================================================
  // INPUT DECORATION
  // ==============================================================

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xffA0A8B5),
      ),
      prefixIcon: Icon(
        icon,
        size: 19,
        color: SubjectColors.secondaryText,
      ),
      filled: true,
      fillColor: const Color(0xffF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: SubjectColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: SubjectColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: SubjectColors.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: SubjectColors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: SubjectColors.red,
        ),
      ),
    );
  }

  // ==============================================================
  // TEXT FORM FIELD
  // ==============================================================

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool requiredField,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SubjectColors.text,
            ),
            children: [
              if (requiredField)
                const TextSpan(
                  text: " *",
                  style: TextStyle(
                    color: SubjectColors.red,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(hint, icon),
          validator: (value) {
            if (requiredField &&
                (value == null || value.trim().isEmpty)) {
              return "$label is required";
            }
            return null;
          },
        ),
      ],
    );
  }

  // ==============================================================
  // NUMBER FORM FIELD
  // ==============================================================

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool requiredField,
    bool allowDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SubjectColors.text,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: allowDecimal
              ? const TextInputType.numberWithOptions(
                  decimal: true,
                )
              : TextInputType.number,
          inputFormatters: allowDecimal
              ? [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}'),
                  ),
                ]
              : [
                  FilteringTextInputFormatter.digitsOnly,
                ],
          decoration: _inputDecoration(hint, icon),
          validator: (value) {
            final text = value?.trim() ?? '';

            if (text.isEmpty) {
              return requiredField ? "Required" : null;
            }

            final number = allowDecimal
                ? double.tryParse(text)
                : int.tryParse(text);

            if (number == null) {
              return "Invalid number";
            }

            if (number < 0 || (requiredField && number == 0)) {
              return "Enter a valid value";
            }

            return null;
          },
        ),
      ],
    );
  }

  // ==============================================================
  // SECTION HEADING
  // ==============================================================

  Widget _sectionHeading(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: SubjectColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: SubjectColors.text,
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // INFORMATION BOX
  // ==============================================================

  Widget _infoBox({
    required String message,
    required IconData icon,
    Color background = SubjectColors.blueLight,
    Color foreground = SubjectColors.blue,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // FORM MESSAGE
  // ==============================================================

  void _showFormMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: SubjectColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==============================================================
  // SAVE SUBJECT
  // ==============================================================

  Future<void> _saveSubject() async {
    if (saving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final duration = int.tryParse(
      durationController.text.trim(),
    );

    final classesPerWeek = int.tryParse(
      classesController.text.trim(),
    );

    if (duration == null || duration <= 0) {
      _showFormMessage(
        "Course duration must be greater than zero.",
      );
      return;
    }

    if (classesPerWeek == null || classesPerWeek <= 0) {
      _showFormMessage(
        "Classes per week must be greater than zero.",
      );
      return;
    }

    // Rates are optional when adding a code to an existing course.
    final minText = minController.text.trim();
    final maxText = maxController.text.trim();

    double? min;
    double? max;

    if (minText.isNotEmpty || maxText.isNotEmpty) {
      if (minText.isEmpty || maxText.isEmpty) {
        _showFormMessage(
          "Enter both minimum and maximum rates, or leave both empty.",
        );
        return;
      }

      min = double.tryParse(minText);
      max = double.tryParse(maxText);

      if (min == null || max == null) {
        _showFormMessage("Please enter valid hourly rates.");
        return;
      }

      if (min < 0 || max < 0) {
        _showFormMessage("Rates cannot be negative.");
        return;
      }

      if (min > max) {
        _showFormMessage(
          "Minimum rate cannot exceed maximum rate.",
        );
        return;
      }
    }

    setState(() {
      saving = true;
    });

    final success = await widget.onSave(
      courseTitle: courseController.text.trim(),
      institute: instituteController.text.trim(),
      courseCode: codeController.text.trim(),
      program: programController.text.trim(),
      description: descriptionController.text.trim(),
      minRate: min,
      maxRate: max,
      standardDurationWeeks: duration,
      standardClassesPerWeek: classesPerWeek,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        saving = false;
      });
    }
  }

  // ==============================================================
  // TOTAL CLASSES PREVIEW
  // ==============================================================

  Widget _totalClassesPreview() {
    final duration = int.tryParse(durationController.text) ?? 0;
    final classes = int.tryParse(classesController.text) ?? 0;

    final total = duration * classes;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SubjectColors.greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xffD2EDE3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calculate_outlined,
              color: SubjectColors.primary,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Standard Classes",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SubjectColors.text,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Duration × Classes per week",
                  style: TextStyle(
                    fontSize: 10,
                    color: SubjectColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "$total",
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: SubjectColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // BUILD BOTTOM SHEET
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: SubjectColors.greenLight,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: SubjectColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add New Subject",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: SubjectColors.text,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Add course and university details",
                          style: TextStyle(
                            fontSize: 12,
                            color: SubjectColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(
                      Icons.close,
                      color: SubjectColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
              color: SubjectColors.border,
            ),

            // FORM
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  15,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // COURSE INFORMATION
                      _sectionHeading(
                        "Course Information",
                        Icons.menu_book_outlined,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: courseController,
                        label: "Course Name",
                        hint: "e.g. Object Oriented Programming",
                        icon: Icons.book_outlined,
                        requiredField: true,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: instituteController,
                        label: "Institute / University",
                        hint: "e.g. COMSATS University",
                        icon: Icons.account_balance_outlined,
                        requiredField: true,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: codeController,
                        label: "Course Code",
                        hint: "e.g. CSC201",
                        icon: Icons.numbers_rounded,
                        requiredField: true,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: programController,
                        label: "Program",
                        hint: "e.g. BS Computer Science",
                        icon: Icons.school_outlined,
                        requiredField: false,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: descriptionController,
                        label: "Description",
                        hint: "Enter course description (optional)",
                        icon: Icons.description_outlined,
                        requiredField: false,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 22),

                      // COURSE DURATION
                      _sectionHeading(
                        "Standard Course Plan",
                        Icons.calendar_month_outlined,
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "Set the normal course duration and number of classes per week.",
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: SubjectColors.secondaryText,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _numberField(
                              controller: durationController,
                              label: "Duration (Weeks)",
                              hint: "16",
                              icon: Icons.date_range_outlined,
                              requiredField: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _numberField(
                              controller: classesController,
                              label: "Classes / Week",
                              hint: "1",
                              icon: Icons.event_available_outlined,
                              requiredField: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // UPDATE TOTAL AUTOMATICALLY
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          durationController,
                          classesController,
                        ]),
                        builder: (context, child) {
                          return _totalClassesPreview();
                        },
                      ),

                      const SizedBox(height: 22),

                      // HOURLY RATES
                      _sectionHeading(
                        "Hourly Rate Configuration",
                        Icons.payments_outlined,
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "Set the minimum and maximum amount tutors can charge. Leave both empty when adding another university code to an existing course.",
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: SubjectColors.secondaryText,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _numberField(
                              controller: minController,
                              label: "Minimum Rate",
                              hint: "500",
                              icon: Icons.trending_down,
                              requiredField: false,
                              allowDecimal: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _numberField(
                              controller: maxController,
                              label: "Maximum Rate",
                              hint: "2500",
                              icon: Icons.trending_up,
                              requiredField: false,
                              allowDecimal: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      _infoBox(
                        icon: Icons.info_outline,
                        message:
                            "Different universities can use different course codes for the same subject. Use the same common course name to add another university code. When creating a new subject, both hourly rates are required.",
                      ),

                      const SizedBox(height: 12),

                      _infoBox(
                        icon: Icons.lightbulb_outline,
                        background: SubjectColors.greenLight,
                        foreground: SubjectColors.primary,
                        message:
                            "Example: 16 weeks × 1 class per week = 16 standard classes. The total is calculated automatically.",
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),

            // BOTTOM BUTTONS
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: SubjectColors.border,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SubjectColors.text,
                          side: const BorderSide(
                            color: SubjectColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: saving ? null : _saveSubject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SubjectColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: saving
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.add,
                                size: 19,
                              ),
                        label: Text(
                          saving ? "Saving..." : "Add Subject",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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

// import 'package:house_of_tutor/AdminApprovedTutor.dart';
// import 'package:house_of_tutor/AdminDrawer.dart';
// import 'package:house_of_tutor/AdminHome.dart';
// import 'package:house_of_tutor/AdminStudent.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// // ================================================================
// // 1. APP COLORS
// // Change the colors of the complete screen here.
// // ================================================================

// class SubjectColors {
//   static const Color primary = Color(0xff168F83);
//   static const Color primaryDark = Color(0xff10776D);

//   static const Color background = Color(0xffF5F7FA);
//   static const Color white = Colors.white;

//   static const Color text = Color(0xff202938);
//   static const Color secondaryText = Color(0xff7B8494);

//   static const Color border = Color(0xffE8ECF1);

//   static const Color greenLight = Color(0xffE8F7F1);
//   static const Color blueLight = Color(0xffEEF2FF);
//   static const Color purpleLight = Color(0xffF3EEFF);
//   static const Color redLight = Color(0xffFFF0F0);

//   static const Color red = Color(0xffE04444);
//   static const Color blue = Color(0xff5265CE);
//   static const Color purple = Color(0xff8456C8);
// }

// // ================================================================
// // 2. COURSE CODE MODEL
// // ================================================================

// class CourseCode {
//   final int courseCodeId;
//   final String institute;
//   final String courseCode;
//   final String program;
//   final String description;

//   const CourseCode({
//     required this.courseCodeId,
//     required this.institute,
//     required this.courseCode,
//     required this.program,
//     required this.description,
//   });

//   factory CourseCode.fromJson(Map<String, dynamic> json) {
//     return CourseCode(
//       courseCodeId: _toInt(
//         json['courseCodeId'] ?? json['CourseCodeId'],
//       ),
//       institute: _toString(
//         json['institute'] ?? json['Institute'],
//       ),
//       courseCode: _toString(
//         json['courseCode'] ?? json['CourseCode'],
//       ),
//       program: _toString(
//         json['program'] ?? json['Program'],
//       ),
//       description: _toString(
//         json['description'] ?? json['Description'],
//       ),
//     );
//   }

//   static int _toInt(dynamic value) {
//     if (value is int) return value;
//     return int.tryParse(value?.toString() ?? '') ?? 0;
//   }

//   static String _toString(dynamic value) {
//     return value?.toString() ?? '';
//   }
// }

// // ================================================================
// // 3. SUBJECT MODEL
// // ================================================================

// class Subject {
//   final int id;
//   final String courseTitle;
//   final double minRate;
//   final double maxRate;
//   final List<CourseCode> courseCodes;

//   const Subject({
//     required this.id,
//     required this.courseTitle,
//     required this.minRate,
//     required this.maxRate,
//     required this.courseCodes,
//   });

//   factory Subject.fromJson(Map<String, dynamic> json) {
//     final codesJson = json['courseCodes'] ?? json['CourseCodes'];

//     final List<CourseCode> codes = [];

//     if (codesJson is List) {
//       for (final item in codesJson) {
//         if (item is Map) {
//           codes.add(
//             CourseCode.fromJson(
//               Map<String, dynamic>.from(item),
//             ),
//           );
//         }
//       }
//     }

//     return Subject(
//       id: _toInt(
//         json['id'] ??
//             json['courseId'] ??
//             json['course_id'] ??
//             json['CourseId'],
//       ),
//       courseTitle: _toString(
//         json['courseTitle'] ??
//             json['CourseTitle'] ??
//             json['course_title'],
//       ),
//       minRate: _toDouble(
//         json['minRate'] ??
//             json['MinRate'] ??
//             json['adminSetMinHourlyRate'] ??
//             json['AdminSetMinHourlyRate'],
//       ),
//       maxRate: _toDouble(
//         json['maxRate'] ??
//             json['MaxRate'] ??
//             json['adminSetMaxHourlyRate'] ??
//             json['AdminSetMaxHourlyRate'],
//       ),
//       courseCodes: codes,
//     );
//   }

//   static int _toInt(dynamic value) {
//     if (value is int) return value;
//     return int.tryParse(value?.toString() ?? '') ?? 0;
//   }

//   static double _toDouble(dynamic value) {
//     if (value is num) return value.toDouble();
//     return double.tryParse(value?.toString() ?? '') ?? 0;
//   }

//   static String _toString(dynamic value) {
//     return value?.toString() ?? '';
//   }
// }

// // ================================================================
// // 4. ADMIN SUBJECT SCREEN
// // ================================================================

// class AdminSubject extends StatefulWidget {
//   const AdminSubject({super.key});

//   @override
//   State<AdminSubject> createState() => _AdminSubjectState();
// }

// class _AdminSubjectState extends State<AdminSubject> {
//   int _selectedIndex = 3;

//   List<Subject> subjects = [];
//   List<Subject> filteredSubjects = [];

//   bool isLoading = true;
//   bool isDeleting = false;

//   final TextEditingController searchController =
//       TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     fetchSubjects();
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }

//   // ==============================================================
//   // 5. GET SUBJECTS API
//   // GET /api/Admin/all-subjects
//   // ==============================================================

//   Future<void> fetchSubjects() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final response = await ApiClient.get(
//         "/api/Admin/all-subjects",
//       );

//       debugPrint("SUBJECT STATUS: ${response.statusCode}");
//       debugPrint("SUBJECT BODY: ${response.body}");

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(
//           utf8.decode(response.bodyBytes),
//         );

//         if (decoded is! List) {
//           throw const FormatException(
//             "Invalid subjects response format.",
//           );
//         }

//         final List<Subject> loadedSubjects = decoded.map((item) {
//           return Subject.fromJson(
//             Map<String, dynamic>.from(item),
//           );
//         }).toList();

//         if (!mounted) return;

//         setState(() {
//           subjects = loadedSubjects;
//           _applySearch(searchController.text);
//         });
//       } else {
//         if (!mounted) return;

//         _showMessage(
//           _getErrorMessage(
//             response.body,
//             "Unable to load subjects.",
//           ),
//           SubjectColors.red,
//         );
//       }
//     } catch (e) {
//       debugPrint("FETCH SUBJECT ERROR: $e");

//       if (mounted) {
//         _showMessage(
//           "Something went wrong while loading subjects.",
//           SubjectColors.red,
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   // ==============================================================
//   // 6. SEARCH
//   // Search by course name, institute, course code and program.
//   // ==============================================================

//   void _applySearch(String query) {
//     final search = query.trim().toLowerCase();

//     if (search.isEmpty) {
//       filteredSubjects = List<Subject>.from(subjects);
//       return;
//     }

//     filteredSubjects = subjects.where((subject) {
//       final titleMatches =
//           subject.courseTitle.toLowerCase().contains(search);

//       final codeMatches = subject.courseCodes.any((code) {
//         return code.institute.toLowerCase().contains(search) ||
//             code.courseCode.toLowerCase().contains(search) ||
//             code.program.toLowerCase().contains(search) ||
//             code.description.toLowerCase().contains(search);
//       });

//       return titleMatches || codeMatches;
//     }).toList();
//   }

//   void _onSearchChanged(String value) {
//     setState(() {
//       _applySearch(value);
//     });
//   }

//   // ==============================================================
//   // 7. ADD SUBJECT API
//   // POST /api/Admin/add-subject
//   // ==============================================================

//   Future<bool> addSubjectApi({
//     required String courseTitle,
//     required String institute,
//     required String courseCode,
//     required String program,
//     required String description,
//     required double minRate,
//     required double maxRate,
//   }) async {
//     try {
//       final response = await ApiClient.post(
//         "/api/Admin/add-subject",
//         {
//           "courseTitle": courseTitle,
//           "institute": institute,
//           "courseCode": courseCode,
//           "program": program.isEmpty ? null : program,
//           "description": description.isEmpty ? null : description,
//           "minRate": minRate,
//           "maxRate": maxRate,
//         },
//       );

//       debugPrint("ADD SUBJECT STATUS: ${response.statusCode}");
//       debugPrint("ADD SUBJECT BODY: ${response.body}");

//       if (response.statusCode == 200 ||
//           response.statusCode == 201) {
//         return true;
//       }

//       if (mounted) {
//         _showMessage(
//           _getErrorMessage(
//             response.body,
//             "Unable to add subject.",
//           ),
//           SubjectColors.red,
//         );
//       }

//       return false;
//     } catch (e) {
//       debugPrint("ADD SUBJECT ERROR: $e");

//       if (mounted) {
//         _showMessage(
//           "Error adding subject. Please try again.",
//           SubjectColors.red,
//         );
//       }

//       return false;
//     }
//   }

//   // ==============================================================
//   // 8. DELETE SUBJECT API
//   // DELETE /api/Admin/delete-subject/{id}
//   // ==============================================================

//   Future<void> deleteSubjectApi(int id) async {
//     if (isDeleting) return;

//     setState(() {
//       isDeleting = true;
//     });

//     try {
//       final response = await ApiClient.delete(
//         "/api/Admin/delete-subject/$id",
//       );

//       debugPrint("DELETE STATUS: ${response.statusCode}");
//       debugPrint("DELETE BODY: ${response.body}");

//       if (!mounted) return;

//       if (response.statusCode == 200 ||
//           response.statusCode == 204) {
//         _showMessage(
//           "Subject deleted successfully.",
//           SubjectColors.primary,
//         );

//         await fetchSubjects();
//       } else {
//         _showMessage(
//           _getErrorMessage(
//             response.body,
//             "Unable to delete subject.",
//           ),
//           SubjectColors.red,
//         );
//       }
//     } catch (e) {
//       debugPrint("DELETE SUBJECT ERROR: $e");

//       if (mounted) {
//         _showMessage(
//           "Something went wrong while deleting.",
//           SubjectColors.red,
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isDeleting = false;
//         });
//       }
//     }
//   }

//   // ==============================================================
//   // 9. ERROR MESSAGE
//   // ==============================================================

//   String _getErrorMessage(
//     String body,
//     String defaultMessage,
//   ) {
//     if (body.trim().isEmpty) return defaultMessage;

//     try {
//       final data = jsonDecode(body);

//       if (data is Map) {
//         for (final key in [
//           'message',
//           'error',
//           'title',
//           'detail',
//         ]) {
//           final value = data[key];

//           if (value != null &&
//               value.toString().trim().isNotEmpty) {
//             return value.toString();
//           }
//         }

//         if (data['errors'] is Map) {
//           final errors = data['errors'] as Map;
//           final messages = <String>[];

//           for (final value in errors.values) {
//             if (value is List) {
//               messages.addAll(
//                 value.map((item) => item.toString()),
//               );
//             } else {
//               messages.add(value.toString());
//             }
//           }

//           if (messages.isNotEmpty) {
//             return messages.join("\n");
//           }
//         }
//       }
//     } catch (_) {
//       return defaultMessage;
//     }

//     return defaultMessage;
//   }

//   // ==============================================================
//   // 10. SNACKBAR
//   // ==============================================================

//   void _showMessage(String message, Color color) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Text(
//             message,
//             style: const TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//               color: Colors.white,
//             ),
//           ),
//           backgroundColor: color,
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.all(12),
//           duration: const Duration(seconds: 3),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );
//   }

//   // ==============================================================
//   // 11. INITIALS
//   // ==============================================================

//   String getInitials(String title) {
//     final parts = title.trim().split(RegExp(r'\s+'));

//     if (parts.isEmpty || parts.first.isEmpty) {
//       return "?";
//     }

//     if (parts.length == 1) {
//       return parts.first
//           .substring(0, parts.first.length >= 2 ? 2 : 1)
//           .toUpperCase();
//     }

//     return (parts[0][0] + parts[1][0]).toUpperCase();
//   }

//   // ==============================================================
//   // 12. NAVIGATION
//   // ==============================================================

//   void _onItemTapped(int index) {
//     if (index == _selectedIndex) return;

//     if (index == 0) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const AdminHome(),
//         ),
//       );
//     } else if (index == 1) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const AdminApprovedTutor(),
//         ),
//       );
//     } else if (index == 2) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const AdminStudent(),
//         ),
//       );
//     }
//   }

//   // ==============================================================
//   // 13. DELETE CONFIRMATION
//   // ==============================================================

//   Future<void> confirmDeleteSubject(Subject subject) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//           title: const Row(
//             children: [
//               Icon(
//                 Icons.delete_outline,
//                 color: SubjectColors.red,
//                 size: 25,
//               ),
//               SizedBox(width: 10),
//               Text(
//                 "Delete Subject",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: SubjectColors.text,
//                 ),
//               ),
//             ],
//           ),
//           content: Text(
//             'Are you sure you want to delete "${subject.courseTitle}"?',
//             style: const TextStyle(
//               fontSize: 14,
//               height: 1.5,
//               color: SubjectColors.secondaryText,
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(dialogContext, false);
//               },
//               child: const Text(
//                 "Cancel",
//                 style: TextStyle(
//                   color: SubjectColors.secondaryText,
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: SubjectColors.red,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(9),
//                 ),
//               ),
//               onPressed: () {
//                 Navigator.pop(dialogContext, true);
//               },
//               child: const Text("Delete"),
//             ),
//           ],
//         );
//       },
//     );

//     if (confirmed == true && mounted) {
//       await deleteSubjectApi(subject.id);
//     }
//   }

//   // ==============================================================
//   // 14. OPEN ADD SUBJECT FORM
//   // The form is a separate StatefulWidget. Its controllers are
//   // disposed safely in the form's own dispose() method.
//   // ==============================================================

//   Future<void> addSubject() async {
//     final result = await showModalBottomSheet<bool>(
//       context: context,
//       isScrollControlled: true,
//       useSafeArea: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) {
//         return _AddSubjectSheet(
//           onSave: ({
//             required String courseTitle,
//             required String institute,
//             required String courseCode,
//             required String program,
//             required String description,
//             required double minRate,
//             required double maxRate,
//           }) {
//             return addSubjectApi(
//               courseTitle: courseTitle,
//               institute: institute,
//               courseCode: courseCode,
//               program: program,
//               description: description,
//               minRate: minRate,
//               maxRate: maxRate,
//             );
//           },
//         );
//       },
//     );

//     if (result == true && mounted) {
//       await fetchSubjects();

//       if (!mounted) return;

//       _showMessage(
//         "Subject added successfully.",
//         SubjectColors.primary,
//       );
//     }
//   }

//   // ==============================================================
//   // 15. SECTION HEADING
//   // ==============================================================

//   Widget _sectionHeading(String title, IconData icon) {
//     return Row(
//       children: [
//         Icon(
//           icon,
//           size: 19,
//           color: SubjectColors.primary,
//         ),
//         const SizedBox(width: 8),
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.bold,
//             color: SubjectColors.text,
//           ),
//         ),
//       ],
//     );
//   }

//   // ==============================================================
//   // 16. RATE DISPLAY
//   // ==============================================================

//   Widget _ratePill({
//     required IconData icon,
//     required String label,
//     required double value,
//     required Color background,
//     required Color foreground,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: background,
//         borderRadius: BorderRadius.circular(11),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 15, color: foreground),
//               const SizedBox(width: 5),
//               Expanded(
//                 child: Text(
//                   label,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w700,
//                     color: foreground,
//                     letterSpacing: 0.3,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 7),
//           Text(
//             "Rs. ${value.toStringAsFixed(0)}",
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//               color: foreground,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ==============================================================
//   // 17. UNIVERSITY COURSE DETAILS
//   // ==============================================================

//   Widget _courseCodeCard(CourseCode code, int index) {
//     final backgrounds = [
//       SubjectColors.greenLight,
//       SubjectColors.blueLight,
//       SubjectColors.purpleLight,
//     ];

//     final foregrounds = [
//       SubjectColors.primary,
//       SubjectColors.blue,
//       SubjectColors.purple,
//     ];

//     final background = backgrounds[index % backgrounds.length];
//     final foreground = foregrounds[index % foregrounds.length];

//     return Container(
//       margin: const EdgeInsets.only(top: 9),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xffFAFBFD),
//         borderRadius: BorderRadius.circular(11),
//         border: Border.all(color: SubjectColors.border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 7,
//                 ),
//                 decoration: BoxDecoration(
//                   color: background,
//                   borderRadius: BorderRadius.circular(7),
//                 ),
//                 child: Text(
//                   code.courseCode.isEmpty
//                       ? "No Code"
//                       : code.courseCode,
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                     color: foreground,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 9),
//               Expanded(
//                 child: Text(
//                   code.institute.isEmpty
//                       ? "Institute not specified"
//                       : code.institute,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: SubjectColors.text,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (code.program.isNotEmpty) ...[
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 const Icon(
//                   Icons.school_outlined,
//                   size: 15,
//                   color: SubjectColors.secondaryText,
//                 ),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child: Text(
//                     code.program,
//                     style: const TextStyle(
//                       fontSize: 11,
//                       color: SubjectColors.secondaryText,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//           if (code.description.isNotEmpty) ...[
//             const SizedBox(height: 8),
//             Text(
//               code.description,
//               style: const TextStyle(
//                 fontSize: 11,
//                 height: 1.4,
//                 color: SubjectColors.secondaryText,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ==============================================================
//   // 18. SUBJECT CARD
//   // Removed the "1 University Course Code" subtitle.
//   // ==============================================================

//   Widget _subjectCard(Subject subject) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: SubjectColors.border),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.025),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 46,
//                 height: 46,
//                 alignment: Alignment.center,
//                 decoration: BoxDecoration(
//                   color: SubjectColors.greenLight,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   getInitials(subject.courseTitle),
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.bold,
//                     color: SubjectColors.primary,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   subject.courseTitle,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.bold,
//                     color: SubjectColors.text,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               InkWell(
//                 onTap: isDeleting
//                     ? null
//                     : () => confirmDeleteSubject(subject),
//                 borderRadius: BorderRadius.circular(10),
//                 child: Container(
//                   width: 38,
//                   height: 38,
//                   alignment: Alignment.center,
//                   decoration: BoxDecoration(
//                     color: SubjectColors.redLight,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Icon(
//                     Icons.delete_outline,
//                     color: SubjectColors.red,
//                     size: 20,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 15),

//           Row(
//             children: [
//               Expanded(
//                 child: _ratePill(
//                   icon: Icons.trending_down,
//                   label: "MINIMUM RATE",
//                   value: subject.minRate,
//                   background: SubjectColors.greenLight,
//                   foreground: SubjectColors.primary,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: _ratePill(
//                   icon: Icons.trending_up,
//                   label: "MAXIMUM RATE",
//                   value: subject.maxRate,
//                   background: SubjectColors.blueLight,
//                   foreground: SubjectColors.blue,
//                 ),
//               ),
//             ],
//           ),

//           if (subject.courseCodes.isNotEmpty) ...[
//             const SizedBox(height: 17),
//             Row(
//               children: [
//                 const Icon(
//                   Icons.account_balance_outlined,
//                   color: SubjectColors.primary,
//                   size: 17,
//                 ),
//                 const SizedBox(width: 7),
//                 const Expanded(
//                   child: Text(
//                     "University Course Details",
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.bold,
//                       color: SubjectColors.text,
//                     ),
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 9,
//                     vertical: 5,
//                   ),
//                   decoration: BoxDecoration(
//                     color: SubjectColors.greenLight,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     "${subject.courseCodes.length}",
//                     style: const TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.bold,
//                       color: SubjectColors.primary,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             ...List.generate(
//               subject.courseCodes.length,
//               (index) => _courseCodeCard(
//                 subject.courseCodes[index],
//                 index,
//               ),
//             ),
//           ] else ...[
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(11),
//               decoration: BoxDecoration(
//                 color: const Color(0xffF8FAFC),
//                 borderRadius: BorderRadius.circular(9),
//               ),
//               child: const Row(
//                 children: [
//                   Icon(
//                     Icons.info_outline,
//                     size: 16,
//                     color: SubjectColors.secondaryText,
//                   ),
//                   SizedBox(width: 7),
//                   Expanded(
//                     child: Text(
//                       "No university course details available.",
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: SubjectColors.secondaryText,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ==============================================================
//   // 19. SEARCH BAR
//   // ==============================================================

//   Widget _searchBar() {
//     return Container(
//       height: 49,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: SubjectColors.border),
//       ),
//       child: TextField(
//         controller: searchController,
//         onChanged: _onSearchChanged,
//         style: const TextStyle(
//           fontSize: 13,
//           color: SubjectColors.text,
//         ),
//         decoration: InputDecoration(
//           hintText: "Search subjects, institutes or course codes...",
//           hintStyle: const TextStyle(
//             fontSize: 12,
//             color: SubjectColors.secondaryText,
//           ),
//           prefixIcon: const Icon(
//             Icons.search,
//             color: SubjectColors.primary,
//             size: 21,
//           ),
//           suffixIcon: searchController.text.isNotEmpty
//               ? IconButton(
//                   onPressed: () {
//                     searchController.clear();
//                     _onSearchChanged("");
//                   },
//                   icon: const Icon(
//                     Icons.close,
//                     size: 18,
//                     color: SubjectColors.secondaryText,
//                   ),
//                 )
//               : null,
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(vertical: 14),
//         ),
//       ),
//     );
//   }

//   // ==============================================================
//   // 20. SUMMARY CARD
//   // ==============================================================

//   Widget _summaryCard() {
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(color: SubjectColors.border),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 45,
//             height: 45,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: SubjectColors.greenLight,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(
//               Icons.library_books_rounded,
//               color: SubjectColors.primary,
//               size: 23,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "${subjects.length}",
//                   style: const TextStyle(
//                     fontSize: 21,
//                     fontWeight: FontWeight.bold,
//                     color: SubjectColors.text,
//                   ),
//                 ),
//                 const Text(
//                   "Total Subjects",
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: SubjectColors.secondaryText,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           ElevatedButton.icon(
//             onPressed: addSubject,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: SubjectColors.primary,
//               foregroundColor: Colors.white,
//               elevation: 0,
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 12,
//                 vertical: 11,
//               ),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             icon: const Icon(Icons.add, size: 17),
//             label: const Text(
//               "Add New",
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ==============================================================
//   // 21. EMPTY STATE
//   // ==============================================================

//   Widget _emptyState() {
//     final isSearching = searchController.text.trim().isNotEmpty;

//     return ListView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       children: [
//         const SizedBox(height: 80),
//         Icon(
//           isSearching
//               ? Icons.search_off_rounded
//               : Icons.menu_book_outlined,
//           size: 65,
//           color: const Color(0xffC5CDD7),
//         ),
//         const SizedBox(height: 15),
//         Center(
//           child: Text(
//             isSearching
//                 ? "No matching subjects found"
//                 : "No subjects available",
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: SubjectColors.text,
//             ),
//           ),
//         ),
//         const SizedBox(height: 7),
//         Center(
//           child: Text(
//             isSearching
//                 ? "Try another subject name or course code."
//                 : "Start by adding your first subject.",
//             style: const TextStyle(
//               fontSize: 12,
//               color: SubjectColors.secondaryText,
//             ),
//           ),
//         ),
//         if (!isSearching) ...[
//           const SizedBox(height: 18),
//           Center(
//             child: ElevatedButton.icon(
//               onPressed: addSubject,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: SubjectColors.primary,
//                 foregroundColor: Colors.white,
//               ),
//               icon: const Icon(Icons.add),
//               label: const Text("Add Subject"),
//             ),
//           ),
//         ],
//       ],
//     );
//   }

//   // ==============================================================
//   // 22. MAIN SCREEN
//   // ==============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: SubjectColors.background,
//       drawer: const AdminDrawer(),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // TOP HEADER
//             Padding(
//               padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
//               child: Row(
//                 children: [
//                   Builder(
//                     builder: (context) {
//                       return IconButton(
//                         onPressed: () {
//                           Scaffold.of(context).openDrawer();
//                         },
//                         icon: const Icon(
//                           Icons.menu_rounded,
//                           color: SubjectColors.primary,
//                           size: 26,
//                         ),
//                       );
//                     },
//                   ),
//                   const Spacer(),
//                   Image.asset(
//                     "assets/images/logo.png",
//                     height: 43,
//                     fit: BoxFit.contain,
//                     errorBuilder: (context, error, stackTrace) {
//                       return const Icon(
//                         Icons.school_rounded,
//                         size: 35,
//                         color: SubjectColors.primary,
//                       );
//                     },
//                   ),
//                   const Spacer(),
//                   IconButton(
//                     onPressed: isLoading ? null : fetchSubjects,
//                     icon: const Icon(
//                       Icons.refresh_rounded,
//                       color: SubjectColors.primary,
//                       size: 24,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // PAGE TITLE AND SEARCH
//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Subject Management",
//                     style: TextStyle(
//                       fontSize: 23,
//                       fontWeight: FontWeight.bold,
//                       color: SubjectColors.text,
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   const Text(
//                     "Manage courses, university codes and tutor hourly rates.",
//                     style: TextStyle(
//                       fontSize: 12,
//                       height: 1.5,
//                       color: SubjectColors.secondaryText,
//                     ),
//                   ),
//                   const SizedBox(height: 17),
//                   _summaryCard(),
//                   const SizedBox(height: 13),
//                   _searchBar(),
//                   const SizedBox(height: 15),
//                   Row(
//                     children: [
//                       const Expanded(
//                         child: Text(
//                           "All Subjects",
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold,
//                             color: SubjectColors.text,
//                           ),
//                         ),
//                       ),
//                       Text(
//                         "${filteredSubjects.length} found",
//                         style: const TextStyle(
//                           fontSize: 11,
//                           color: SubjectColors.secondaryText,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                 ],
//               ),
//             ),

//             // SUBJECT LIST
//             Expanded(
//               child: isLoading
//                   ? const Center(
//                       child: CircularProgressIndicator(
//                         color: SubjectColors.primary,
//                         strokeWidth: 2.5,
//                       ),
//                     )
//                   : RefreshIndicator(
//                       onRefresh: fetchSubjects,
//                       color: SubjectColors.primary,
//                       child: filteredSubjects.isEmpty
//                           ? _emptyState()
//                           : ListView.builder(
//                               physics:
//                                   const AlwaysScrollableScrollPhysics(),
//                               padding: const EdgeInsets.fromLTRB(
//                                 16,
//                                 0,
//                                 16,
//                                 20,
//                               ),
//                               itemCount: filteredSubjects.length,
//                               itemBuilder: (context, index) {
//                                 return _subjectCard(
//                                   filteredSubjects[index],
//                                 );
//                               },
//                             ),
//                     ),
//             ),
//           ],
//         ),
//       ),

//       // BOTTOM NAVIGATION
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.white,
//         elevation: 10,
//         selectedItemColor: SubjectColors.primary,
//         unselectedItemColor: SubjectColors.secondaryText,
//         selectedFontSize: 11,
//         unselectedFontSize: 10,
//         selectedLabelStyle: const TextStyle(
//           fontWeight: FontWeight.w600,
//         ),
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home_outlined),
//             activeIcon: Icon(Icons.home_rounded),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.people_outline),
//             activeIcon: Icon(Icons.people_rounded),
//             label: "Tutors",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.school_outlined),
//             activeIcon: Icon(Icons.school_rounded),
//             label: "Student",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.menu_book_outlined),
//             activeIcon: Icon(Icons.menu_book_rounded),
//             label: "Subject",
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ================================================================
// // 23. ADD SUBJECT BOTTOM SHEET
// // Separate StatefulWidget prevents the old bottom-sheet lifecycle
// // and controller-disposal problem.
// // ================================================================

// class _AddSubjectSheet extends StatefulWidget {
//   final Future<bool> Function({
//     required String courseTitle,
//     required String institute,
//     required String courseCode,
//     required String program,
//     required String description,
//     required double minRate,
//     required double maxRate,
//   }) onSave;

//   const _AddSubjectSheet({
//     required this.onSave,
//   });

//   @override
//   State<_AddSubjectSheet> createState() => _AddSubjectSheetState();
// }

// class _AddSubjectSheetState extends State<_AddSubjectSheet> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

//   final TextEditingController courseController =
//       TextEditingController();

//   final TextEditingController instituteController =
//       TextEditingController();

//   final TextEditingController codeController =
//       TextEditingController();

//   final TextEditingController programController =
//       TextEditingController();

//   final TextEditingController descriptionController =
//       TextEditingController();

//   final TextEditingController minController =
//       TextEditingController();

//   final TextEditingController maxController =
//       TextEditingController();

//   bool saving = false;

//   @override
//   void dispose() {
//     courseController.dispose();
//     instituteController.dispose();
//     codeController.dispose();
//     programController.dispose();
//     descriptionController.dispose();
//     minController.dispose();
//     maxController.dispose();
//     super.dispose();
//   }

//   // ==============================================================
//   // FORM INPUT DECORATION
//   // ==============================================================

//   InputDecoration _inputDecoration(
//     String hint,
//     IconData icon,
//   ) {
//     return InputDecoration(
//       hintText: hint,
//       hintStyle: const TextStyle(
//         fontSize: 12,
//         color: Color(0xffA0A8B5),
//       ),
//       prefixIcon: Icon(
//         icon,
//         size: 19,
//         color: SubjectColors.secondaryText,
//       ),
//       filled: true,
//       fillColor: const Color(0xffF8FAFC),
//       contentPadding: const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 14,
//       ),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(11),
//         borderSide: const BorderSide(
//           color: SubjectColors.border,
//         ),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(11),
//         borderSide: const BorderSide(
//           color: SubjectColors.border,
//         ),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(11),
//         borderSide: const BorderSide(
//           color: SubjectColors.primary,
//           width: 1.5,
//         ),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(11),
//         borderSide: const BorderSide(
//           color: SubjectColors.red,
//         ),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(11),
//         borderSide: const BorderSide(
//           color: SubjectColors.red,
//         ),
//       ),
//     );
//   }

//   // ==============================================================
//   // NORMAL FORM FIELD
//   // ==============================================================

//   Widget _formField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//     required bool requiredField,
//     int maxLines = 1,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RichText(
//           text: TextSpan(
//             text: label,
//             style: const TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: SubjectColors.text,
//             ),
//             children: [
//               if (requiredField)
//                 const TextSpan(
//                   text: " *",
//                   style: TextStyle(
//                     color: SubjectColors.red,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 7),
//         TextFormField(
//           controller: controller,
//           maxLines: maxLines,
//           textCapitalization: TextCapitalization.sentences,
//           decoration: _inputDecoration(hint, icon),
//           validator: (value) {
//             if (requiredField &&
//                 (value == null || value.trim().isEmpty)) {
//               return "$label is required";
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   // ==============================================================
//   // RATE FIELD
//   // ==============================================================

//   Widget _rateFormField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w600,
//             color: SubjectColors.text,
//           ),
//         ),
//         const SizedBox(height: 7),
//         TextFormField(
//           controller: controller,
//           keyboardType: const TextInputType.numberWithOptions(
//             decimal: true,
//           ),
//           decoration: _inputDecoration(hint, icon),
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return "Required";
//             }

//             final rate = double.tryParse(value.trim());

//             if (rate == null || !rate.isFinite || rate < 0) {
//               return "Invalid rate";
//             }

//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   // ==============================================================
//   // SECTION HEADING
//   // ==============================================================

//   Widget _sectionHeading(String title, IconData icon) {
//     return Row(
//       children: [
//         Icon(
//           icon,
//           size: 19,
//           color: SubjectColors.primary,
//         ),
//         const SizedBox(width: 8),
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.bold,
//             color: SubjectColors.text,
//           ),
//         ),
//       ],
//     );
//   }

//   // ==============================================================
//   // FORM SNACKBAR
//   // ==============================================================

//   void _showFormMessage(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: SubjectColors.red,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//   }

//   // ==============================================================
//   // SAVE SUBJECT
//   // ==============================================================

//   Future<void> _saveSubject() async {
//     if (saving) return;

//     FocusScope.of(context).unfocus();

//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     final min = double.tryParse(minController.text.trim());
//     final max = double.tryParse(maxController.text.trim());

//     if (min == null || max == null) {
//       _showFormMessage("Please enter valid rates.");
//       return;
//     }

//     if (min > max) {
//       _showFormMessage(
//         "Minimum rate cannot exceed maximum rate.",
//       );
//       return;
//     }

//     setState(() {
//       saving = true;
//     });

//     final success = await widget.onSave(
//       courseTitle: courseController.text.trim(),
//       institute: instituteController.text.trim(),
//       courseCode: codeController.text.trim(),
//       program: programController.text.trim(),
//       description: descriptionController.text.trim(),
//       minRate: min,
//       maxRate: max,
//     );

//     if (!mounted) return;

//     if (success) {
//       Navigator.of(context).pop(true);
//     } else {
//       setState(() {
//         saving = false;
//       });
//     }
//   }

//   // ==============================================================
//   // BUILD BOTTOM SHEET
//   // ==============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom,
//       ),
//       child: Container(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.90,
//         ),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(
//             top: Radius.circular(25),
//           ),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // HEADER
//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 46,
//                     height: 46,
//                     decoration: BoxDecoration(
//                       color: SubjectColors.greenLight,
//                       borderRadius: BorderRadius.circular(13),
//                     ),
//                     child: const Icon(
//                       Icons.menu_book_rounded,
//                       color: SubjectColors.primary,
//                       size: 24,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   const Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Add New Subject",
//                           style: TextStyle(
//                             fontSize: 19,
//                             fontWeight: FontWeight.bold,
//                             color: SubjectColors.text,
//                           ),
//                         ),
//                         SizedBox(height: 3),
//                         Text(
//                           "Add course and university details",
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: SubjectColors.secondaryText,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: saving
//                         ? null
//                         : () => Navigator.of(context).pop(false),
//                     icon: const Icon(
//                       Icons.close,
//                       color: SubjectColors.secondaryText,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const Divider(
//               height: 1,
//               color: SubjectColors.border,
//             ),

//             // FORM CONTENT
//             Flexible(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(20, 18, 20, 15),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _sectionHeading(
//                         "Course Information",
//                         Icons.menu_book_outlined,
//                       ),
//                       const SizedBox(height: 14),

//                       _formField(
//                         controller: courseController,
//                         label: "Course Name",
//                         hint: "e.g. Object Oriented Programming",
//                         icon: Icons.book_outlined,
//                         requiredField: true,
//                       ),
//                       const SizedBox(height: 14),

//                       _formField(
//                         controller: instituteController,
//                         label: "Institute / University",
//                         hint: "e.g. COMSATS University",
//                         icon: Icons.account_balance_outlined,
//                         requiredField: true,
//                       ),
//                       const SizedBox(height: 14),

//                       _formField(
//                         controller: codeController,
//                         label: "Course Code",
//                         hint: "e.g. CSC201",
//                         icon: Icons.numbers_rounded,
//                         requiredField: true,
//                       ),
//                       const SizedBox(height: 14),

//                       _formField(
//                         controller: programController,
//                         label: "Program",
//                         hint: "e.g. BS Computer Science",
//                         icon: Icons.school_outlined,
//                         requiredField: false,
//                       ),
//                       const SizedBox(height: 14),

//                       _formField(
//                         controller: descriptionController,
//                         label: "Description",
//                         hint: "Enter course description (optional)",
//                         icon: Icons.description_outlined,
//                         requiredField: false,
//                         maxLines: 3,
//                       ),

//                       const SizedBox(height: 22),

//                       _sectionHeading(
//                         "Hourly Rate Configuration",
//                         Icons.payments_outlined,
//                       ),
//                       const SizedBox(height: 6),

//                       const Text(
//                         "Set the minimum and maximum amount tutors can charge.",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: SubjectColors.secondaryText,
//                         ),
//                       ),
//                       const SizedBox(height: 14),

//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Expanded(
//                             child: _rateFormField(
//                               controller: minController,
//                               label: "Minimum Rate",
//                               hint: "500",
//                               icon: Icons.trending_down,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: _rateFormField(
//                               controller: maxController,
//                               label: "Maximum Rate",
//                               hint: "2500",
//                               icon: Icons.trending_up,
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 15),

//                       // INFORMATION BOX
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: SubjectColors.blueLight,
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(
//                             color: const Color(0xffDFE5FF),
//                           ),
//                         ),
//                         child: const Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Icon(
//                               Icons.info_outline,
//                               color: SubjectColors.blue,
//                               size: 19,
//                             ),
//                             SizedBox(width: 9),
//                             Expanded(
//                               child: Text(
//                                 "Different universities can use different course codes for the same subject. Add the university details with the common subject name.",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   height: 1.5,
//                                   color: Color(0xff4456A6),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // BOTTOM BUTTONS
//             Container(
//               padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 border: Border(
//                   top: BorderSide(
//                     color: SubjectColors.border,
//                   ),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: SizedBox(
//                       height: 48,
//                       child: OutlinedButton(
//                         onPressed: saving
//                             ? null
//                             : () => Navigator.of(context).pop(false),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: SubjectColors.text,
//                           side: const BorderSide(
//                             color: SubjectColors.border,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text(
//                           "Cancel",
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     flex: 2,
//                     child: SizedBox(
//                       height: 48,
//                       child: ElevatedButton.icon(
//                         onPressed: saving ? null : _saveSubject,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: SubjectColors.primary,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         icon: saving
//                             ? const SizedBox(
//                                 width: 17,
//                                 height: 17,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: Colors.white,
//                                 ),
//                               )
//                             : const Icon(Icons.add, size: 19),
//                         label: Text(
//                           saving ? "Saving..." : "Add Subject",
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }