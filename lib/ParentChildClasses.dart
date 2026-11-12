import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class ParentChildClasses extends StatefulWidget {
  final int studentId;
  final int courseId;
  final String courseTitle;

  const ParentChildClasses({
    Key? key,
    required this.studentId,
    required this.courseId,
    required this.courseTitle,
  }) : super(key: key);

  @override
  State<ParentChildClasses> createState() => _ParentChildClassesState();
}

class _ParentChildClassesState extends State<ParentChildClasses> {
  // =====================================================
  // VARIABLES
  // =====================================================

  List<dynamic> classesList = [];

  bool isLoading = true;

  // =====================================================
  // WEEK DAYS (full + short labels used by the grid)
  // =====================================================

  final List<String> weekDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  final List<String> weekDaysShort = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];

  // =====================================================
  // TIME SLOTS FOR THE GRID (8:00 am -> 10:00 pm)
  // =====================================================

  final List<String> timeSlotLabels = [
    "8:00-9:00 am",
    "9:00-10:00 am",
    "10:00-11:00 am",
    "11:00-12:00 pm",
    "12:00-1:00 pm",
    "1:00-2:00 pm",
    "2:00-3:00 pm",
    "3:00-4:00 pm",
    "4:00-5:00 pm",
    "5:00-6:00 pm",
    "6:00-7:00 pm",
    "7:00-8:00 pm",
    "8:00-9:00 pm",
    "9:00-10:00 pm",
  ];

  static const int gridStartHour = 8; // 8 am
  static const int gridSlotCount = 14;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    fetchChildClasses();
  }

  // =====================================================
  // GET CHILD CLASSES API
  // =====================================================

  Future<void> fetchChildClasses() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response = await ApiClient.get(
        '/api/Parent/child-classes/${widget.studentId}/${widget.courseId}',
      );

      debugPrint("========================================");
      debugPrint("CHILD CLASSES STATUS: ${response.statusCode}");
      debugPrint("CHILD CLASSES BODY: ${response.body}");
      debugPrint("========================================");

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        List<dynamic> result = [];

        // =====================================================
        // API RESPONSE IS DIRECT LIST
        // =====================================================

        if (decodedData is List) {
          result = List<dynamic>.from(decodedData);
        }

        // =====================================================
        // API RESPONSE IS OBJECT
        // =====================================================

        else if (decodedData is Map<String, dynamic>) {
          if (decodedData['classes'] is List) {
            result = List<dynamic>.from(
              decodedData['classes'],
            );
          } else if (decodedData['data'] is List) {
            result = List<dynamic>.from(
              decodedData['data'],
            );
          } else if (decodedData['result'] is List) {
            result = List<dynamic>.from(
              decodedData['result'],
            );
          }
        }

        debugPrint(
          "TOTAL CLASSES FROM API: ${result.length}",
        );

        // =====================================================
        // COURSE FILTER
        // =====================================================

        result = result.where((item) {
          if (item is! Map) {
            return false;
          }

          final itemCourseId =
              item['courseId'] ??
              item['course_id'];

          if (itemCourseId == null) {
            return false;
          }

          return itemCourseId.toString().trim() ==
              widget.courseId.toString().trim();
        }).toList();

        debugPrint(
          "AFTER COURSE FILTER: ${result.length}",
        );

        // =====================================================
        // STATUS FILTER (Accepted = Active for this screen)
        // =====================================================

        result = result.where((item) {
          if (item is! Map) {
            return false;
          }

          final status = (
            item['status'] ??
            ''
          ).toString().trim().toLowerCase();

          return status == "accepted" ||
              status == "active";
        }).toList();

        debugPrint(
          "AFTER STATUS FILTER: ${result.length}",
        );

        // =====================================================
        // SORT BY WEEK DAY
        // =====================================================

        result.sort((a, b) {
          final dayA = _getDayIndex(
            _getItemValue(a, ['day']),
          );

          final dayB = _getDayIndex(
            _getItemValue(b, ['day']),
          );

          return dayA.compareTo(dayB);
        });

        // =====================================================
        // SET DATA
        // =====================================================

        if (mounted) {
          setState(() {
            classesList = result;
            isLoading = false;
          });
        }

        debugPrint(
          "FINAL CLASSES TO DISPLAY: ${classesList.length}",
        );
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            classesList = [];
          });

          String message = "Failed to load class sessions.";

          try {
            final data = jsonDecode(
              utf8.decode(response.bodyBytes),
            );

            if (data is Map<String, dynamic>) {
              message =
                  data['message']?.toString() ??
                  data['error']?.toString() ??
                  message;
            }
          } catch (_) {}

          _showSnackBar(message);
        }
      }
    } catch (e) {
      debugPrint("CHILD CLASSES ERROR: $e");

      if (mounted) {
        setState(() {
          isLoading = false;
          classesList = [];
        });

        _showSnackBar(
          "An error occurred while loading classes.",
        );
      }
    }
  }

  // =====================================================
  // SAFE MAP VALUE
  // =====================================================

  String _getItemValue(dynamic item, List<String> keys) {
    if (item is! Map) {
      return "";
    }

    for (final key in keys) {
      final value = item[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return "";
  }

  // =====================================================
  // GET DAY INDEX
  // =====================================================

  int _getDayIndex(String day) {
    final value = day.toLowerCase().trim();

    switch (value) {
      case "monday":
      case "mon":
        return 1;
      case "tuesday":
      case "tue":
      case "tues":
        return 2;
      case "wednesday":
      case "wed":
        return 3;
      case "thursday":
      case "thu":
      case "thur":
      case "thurs":
        return 4;
      case "friday":
      case "fri":
        return 5;
      case "saturday":
      case "sat":
        return 6;
      case "sunday":
      case "sun":
        return 7;
      default:
        return 8;
    }
  }

  // =====================================================
  // NORMALIZE DAY
  // =====================================================

  String _getFullDayName(String day) {
    final value = day.toLowerCase().trim();

    switch (value) {
      case "monday":
      case "mon":
        return "Monday";
      case "tuesday":
      case "tue":
      case "tues":
        return "Tuesday";
      case "wednesday":
      case "wed":
        return "Wednesday";
      case "thursday":
      case "thu":
      case "thur":
      case "thurs":
        return "Thursday";
      case "friday":
      case "fri":
        return "Friday";
      case "saturday":
      case "sat":
        return "Saturday";
      case "sunday":
      case "sun":
        return "Sunday";
      default:
        return day.isEmpty ? "Day Not Available" : day;
    }
  }

  // =====================================================
  // EXTRACT START HOUR FROM TIME STRING (for grid placement)
  // =====================================================
  //
  // Supports formats like:
  // "8:00 am", "08:00", "8:00-9:00 am", "20:00"
  //

  int? _extractStartHour(String time) {
    if (time.isEmpty) {
      return null;
    }

    final match = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*(am|pm|AM|PM)?',
    ).firstMatch(time);

    if (match == null) {
      return null;
    }

    int? hour = int.tryParse(match.group(1) ?? '');

    if (hour == null) {
      return null;
    }

    final meridiem = match.group(3)?.toLowerCase();

    if (meridiem == 'pm' && hour != 12) {
      hour += 12;
    } else if (meridiem == 'am' && hour == 12) {
      hour = 0;
    }

    return hour;
  }

  int? _getSlotIndex(String time) {
    final hour = _extractStartHour(time);

    if (hour == null) {
      return null;
    }

    final index = hour - gridStartHour;

    if (index < 0 || index >= gridSlotCount) {
      return null;
    }

    return index;
  }

  // =====================================================
  // REFRESH
  // =====================================================

  Future<void> refreshClasses() async {
    await fetchChildClasses();
  }

  // =====================================================
  // SNACKBAR
  // =====================================================

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // =====================================================
  // STUDENT (CHILD) PROFILE HEADER
  // =====================================================

  Widget _buildProfileHeader() {
    // Pull student info from the first class record (falls back
    // gracefully if the API doesn't include these fields).
    final firstItem = classesList.isNotEmpty ? classesList.first : null;

    final studentName = _getItemValue(
      firstItem,
      ['studentName', 'student_name', 'childName', 'child_name'],
    );

    final studentEmail = _getItemValue(
      firstItem,
      ['studentEmail', 'student_email', 'childEmail', 'child_email'],
    );

    final studentPhone = _getItemValue(
      firstItem,
      ['studentPhone', 'student_phone', 'childPhone', 'child_phone'],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.teal.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 36,
              color: Colors.teal.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            studentName.isNotEmpty ? studentName : "Student",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (studentEmail.isNotEmpty)
            _profileInfoRow(Icons.email_outlined, studentEmail),
          if (studentPhone.isNotEmpty) ...[
            const SizedBox(height: 4),
            _profileInfoRow(Icons.phone_outlined, studentPhone),
          ],
        ],
      ),
    );
  }

  Widget _profileInfoRow(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  // =====================================================
  // WEEKLY TIMETABLE GRID
  // =====================================================

  Widget _buildTimetableGrid() {
    const double timeColWidth = 92;
    const double dayColWidth = 52;
    const double rowHeight = 40;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================
          // TITLE + LEGEND
          // ============================================
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Weekly Timetable",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                "Active Class",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ============================================
          // GRID: fixed time column + horizontally
          // scrollable day columns, sharing the same
          // vertical scroll so rows line up.
          // ============================================

          SizedBox(
            height: rowHeight * (gridSlotCount + 1) + 4,
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TIME LABEL COLUMN (fixed)
                  SizedBox(
                    width: timeColWidth,
                    child: Column(
                      children: [
                        SizedBox(height: rowHeight), // aligns with day header row
                        ...List.generate(gridSlotCount, (i) {
                          return SizedBox(
                            height: rowHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                timeSlotLabels[i],
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // DAY COLUMNS (horizontally scrollable)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        children: [
                          // DAY HEADER ROW
                          Row(
                            children: List.generate(7, (dayIdx) {
                              return SizedBox(
                                width: dayColWidth,
                                height: rowHeight,
                                child: Center(
                                  child: Text(
                                    weekDaysShort[dayIdx],
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          // SLOT ROWS
                          ...List.generate(gridSlotCount, (slotIdx) {
                            return Row(
                              children: List.generate(7, (dayIdx) {
                                final hasClass = classesList.any((item) {
                                  if (item is! Map) return false;

                                  final itemDayIndex = _getDayIndex(
                                    _getItemValue(item, ['day']),
                                  );

                                  final itemSlot = _getSlotIndex(
                                    _getItemValue(
                                      item,
                                      ['time', 'classTime', 'class_time'],
                                    ),
                                  );

                                  return itemDayIndex == (dayIdx + 1) &&
                                      itemSlot == slotIdx;
                                });

                                return SizedBox(
                                  width: dayColWidth,
                                  height: rowHeight,
                                  child: Center(
                                    child: hasClass
                                        ? Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade600,
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                          ),
                                  ),
                                );
                              }),
                            );
                          }),
                        ],
                      ),
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

  // =====================================================
  // CLASS DETAIL CARD (kept for full tutor/course info)
  // =====================================================

  Widget _buildClassCard(dynamic item) {
    if (item is! Map) {
      return const SizedBox.shrink();
    }

    final courseName = _getItemValue(
      item,
      ['courseName', 'course_name', 'course'],
    );

    final finalCourseName =
        courseName.isNotEmpty ? courseName : widget.courseTitle;

    final tutorName = _getItemValue(
      item,
      ['tutorName', 'tutor_name', 'instructor'],
    );

    final finalTutorName =
        tutorName.isNotEmpty ? tutorName : 'Unknown Instructor';

    final tutorEmail = _getItemValue(
      item,
      ['tutorEmail', 'tutor_email', 'email'],
    );

    final finalTutorEmail =
        tutorEmail.isNotEmpty ? tutorEmail : 'Not Available';

    final tutorPhone = _getItemValue(
      item,
      ['tutorPhone', 'tutor_phone', 'phone'],
    );

    final finalTutorPhone =
        tutorPhone.isNotEmpty ? tutorPhone : 'Not Available';

    final day = _getItemValue(item, ['day']);
    final fullDay = _getFullDayName(day);

    final time = _getItemValue(
      item,
      ['time', 'classTime', 'class_time'],
    );

    final finalTime = time.isNotEmpty ? time : 'N/A';

    final classDate = _formatDate(
      item['classDate'] ?? item['class_date'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.menu_book, color: Colors.teal.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        finalCourseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Active",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, size: 18, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                const Text(
                  "Weekly Class:",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fullDay,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            finalTutorName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Text(
                            "Assigned Instructor",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        finalTutorEmail,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        finalTutorPhone,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _infoItem(icon: Icons.access_time, title: "Class Time", value: finalTime),

          if (classDate != "N/A") ...[
            const SizedBox(height: 10),
            _infoItem(icon: Icons.event_outlined, title: "Class Date", value: classDate),
          ],
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return "N/A";

    final date = value.toString().trim();

    if (date.isEmpty) return "N/A";

    return date.split('T')[0];
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school, color: Colors.teal, size: 24);
              },
            ),
            const SizedBox(width: 8),
            const Text(
              "House of Tutor",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        color: Colors.teal,
        onRefresh: refreshClasses,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.courseTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Weekly active class schedule",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  if (classesList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 55, color: Colors.grey.shade400),
                          const SizedBox(height: 15),
                          Text(
                            "No active classes found",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "No active weekly class is available for this course.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _buildProfileHeader(),
                    const SizedBox(height: 16),
                    _buildTimetableGrid(),
                    const SizedBox(height: 20),
                    const Text(
                      "Class Details",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...classesList.map((item) => _buildClassCard(item)),
                  ],
                ],
              ),
      ),
    );
  }
}






















// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class ParentChildClasses extends StatefulWidget {
//   final int studentId;
//   final int courseId;
//   final String courseTitle;

//   const ParentChildClasses({
//     Key? key,
//     required this.studentId,
//     required this.courseId,
//     required this.courseTitle,
//   }) : super(key: key);

//   @override
//   State<ParentChildClasses> createState() => _ParentChildClassesState();
// }

// class _ParentChildClassesState extends State<ParentChildClasses> {
//   // =====================================================
//   // VARIABLES
//   // =====================================================

//   List<dynamic> classesList = [];

//   bool isLoading = true;

//   // =====================================================
//   // WEEK DAYS
//   // =====================================================

//   final List<String> weekDays = [
//     "Monday",
//     "Tuesday",
//     "Wednesday",
//     "Thursday",
//     "Friday",
//     "Saturday",
//     "Sunday",
//   ];

//   // =====================================================
//   // INIT
//   // =====================================================

//   @override
//   void initState() {
//     super.initState();

//     fetchChildClasses();
//   }

//   // =====================================================
//   // GET CHILD CLASSES API
//   // =====================================================

//   Future<void> fetchChildClasses() async {
//     if (mounted) {
//       setState(() {
//         isLoading = true;
//       });
//     }

//     try {
//       final response = await ApiClient.get(
//         '/api/Parent/child-classes/${widget.studentId}/${widget.courseId}',
//       );

//       debugPrint("========================================");
//       debugPrint("CHILD CLASSES STATUS: ${response.statusCode}");
//       debugPrint("CHILD CLASSES BODY: ${response.body}");
//       debugPrint("========================================");

//       if (response.statusCode == 200) {
//         final decodedData = jsonDecode(
//           utf8.decode(response.bodyBytes),
//         );

//         List<dynamic> result = [];

//         // =====================================================
//         // API RESPONSE IS DIRECT LIST
//         // =====================================================

//         if (decodedData is List) {
//           result = List<dynamic>.from(decodedData);
//         }

//         // =====================================================
//         // API RESPONSE IS OBJECT
//         // =====================================================

//         else if (decodedData is Map<String, dynamic>) {
//           if (decodedData['classes'] is List) {
//             result = List<dynamic>.from(
//               decodedData['classes'],
//             );
//           } else if (decodedData['data'] is List) {
//             result = List<dynamic>.from(
//               decodedData['data'],
//             );
//           } else if (decodedData['result'] is List) {
//             result = List<dynamic>.from(
//               decodedData['result'],
//             );
//           }
//         }

//         debugPrint(
//           "TOTAL CLASSES FROM API: ${result.length}",
//         );

//         // =====================================================
//         // COURSE FILTER
//         // =====================================================
//         //
//         // API:
//         // "courseId": 1
//         //
//         // Current screen:
//         // widget.courseId = 1
//         //

//         result = result.where((item) {
//           if (item is! Map) {
//             return false;
//           }

//           final itemCourseId =
//               item['courseId'] ??
//               item['course_id'];

//           if (itemCourseId == null) {
//             return false;
//           }

//           return itemCourseId.toString().trim() ==
//               widget.courseId.toString().trim();
//         }).toList();

//         debugPrint(
//           "AFTER COURSE FILTER: ${result.length}",
//         );

//         // =====================================================
//         // STATUS FILTER
//         // =====================================================
//         //
//         // IMPORTANT:
//         //
//         // Your API returns:
//         //
//         // "status": "Accepted"
//         //
//         // Previous code was checking:
//         //
//         // "active"
//         //
//         // So all records were removed.
//         //
//         // Accepted = Active class for this screen.
//         //
//         // We also support "Active" in case backend
//         // returns that value later.
//         //

//         result = result.where((item) {
//           if (item is! Map) {
//             return false;
//           }

//           final status = (
//             item['status'] ??
//             ''
//           ).toString().trim().toLowerCase();

//           return status == "accepted" ||
//               status == "active";
//         }).toList();

//         debugPrint(
//           "AFTER STATUS FILTER: ${result.length}",
//         );

//         // =====================================================
//         // SORT BY WEEK DAY
//         // =====================================================

//         result.sort((a, b) {
//           final dayA = _getDayIndex(
//             _getItemValue(
//               a,
//               ['day'],
//             ),
//           );

//           final dayB = _getDayIndex(
//             _getItemValue(
//               b,
//               ['day'],
//             ),
//           );

//           return dayA.compareTo(dayB);
//         });

//         // =====================================================
//         // SET DATA
//         // =====================================================

//         if (mounted) {
//           setState(() {
//             classesList = result;
//             isLoading = false;
//           });
//         }

//         debugPrint(
//           "FINAL CLASSES TO DISPLAY: ${classesList.length}",
//         );
//       } else {
//         if (mounted) {
//           setState(() {
//             isLoading = false;
//             classesList = [];
//           });

//           String message =
//               "Failed to load class sessions.";

//           try {
//             final data = jsonDecode(
//               utf8.decode(response.bodyBytes),
//             );

//             if (data is Map<String, dynamic>) {
//               message =
//                   data['message']?.toString() ??
//                   data['error']?.toString() ??
//                   message;
//             }
//           } catch (_) {}

//           _showSnackBar(message);
//         }
//       }
//     } catch (e) {
//       debugPrint(
//         "CHILD CLASSES ERROR: $e",
//       );

//       if (mounted) {
//         setState(() {
//           isLoading = false;
//           classesList = [];
//         });

//         _showSnackBar(
//           "An error occurred while loading classes.",
//         );
//       }
//     }
//   }

//   // =====================================================
//   // SAFE MAP VALUE
//   // =====================================================
//   //
//   // This method allows us to support different API
//   // property names safely.
//   //

//   String _getItemValue(
//     dynamic item,
//     List<String> keys,
//   ) {
//     if (item is! Map) {
//       return "";
//     }

//     for (final key in keys) {
//       final value = item[key];

//       if (value != null &&
//           value.toString().trim().isNotEmpty) {
//         return value.toString().trim();
//       }
//     }

//     return "";
//   }

//   // =====================================================
//   // GET DAY INDEX
//   // =====================================================

//   int _getDayIndex(String day) {
//     final value = day.toLowerCase().trim();

//     switch (value) {
//       case "monday":
//       case "mon":
//         return 1;

//       case "tuesday":
//       case "tue":
//       case "tues":
//         return 2;

//       case "wednesday":
//       case "wed":
//         return 3;

//       case "thursday":
//       case "thu":
//       case "thur":
//       case "thurs":
//         return 4;

//       case "friday":
//       case "fri":
//         return 5;

//       case "saturday":
//       case "sat":
//         return 6;

//       case "sunday":
//       case "sun":
//         return 7;

//       default:
//         return 8;
//     }
//   }

//   // =====================================================
//   // NORMALIZE DAY
//   // =====================================================

//   String _getFullDayName(String day) {
//     final value = day.toLowerCase().trim();

//     switch (value) {
//       case "monday":
//       case "mon":
//         return "Monday";

//       case "tuesday":
//       case "tue":
//       case "tues":
//         return "Tuesday";

//       case "wednesday":
//       case "wed":
//         return "Wednesday";

//       case "thursday":
//       case "thu":
//       case "thur":
//       case "thurs":
//         return "Thursday";

//       case "friday":
//       case "fri":
//         return "Friday";

//       case "saturday":
//       case "sat":
//         return "Saturday";

//       case "sunday":
//       case "sun":
//         return "Sunday";

//       default:
//         return day.isEmpty
//             ? "Day Not Available"
//             : day;
//     }
//   }

//   // =====================================================
//   // REFRESH
//   // =====================================================

//   Future<void> refreshClasses() async {
//     await fetchChildClasses();
//   }

//   // =====================================================
//   // SNACKBAR
//   // =====================================================

//   void _showSnackBar(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//       ),
//     );
//   }

//   // =====================================================
//   // CLASS CARD
//   // =====================================================

//   Widget _buildClassCard(dynamic item) {
//     if (item is! Map) {
//       return const SizedBox.shrink();
//     }

//     // =====================================================
//     // COURSE
//     // =====================================================

//     final courseName = _getItemValue(
//       item,
//       [
//         'courseName',
//         'course_name',
//         'course',
//       ],
//     );

//     final finalCourseName =
//         courseName.isNotEmpty
//             ? courseName
//             : widget.courseTitle;

//     // =====================================================
//     // STATUS
//     // =====================================================

//     final apiStatus = _getItemValue(
//       item,
//       ['status'],
//     );

//     // Accepted classes are displayed as Active
//     final displayStatus = "Active";

//     // =====================================================
//     // TUTOR
//     // =====================================================

//     final tutorName = _getItemValue(
//       item,
//       [
//         'tutorName',
//         'tutor_name',
//         'instructor',
//       ],
//     );

//     final finalTutorName =
//         tutorName.isNotEmpty
//             ? tutorName
//             : 'Unknown Instructor';

//     // =====================================================
//     // TUTOR EMAIL
//     // =====================================================

//     final tutorEmail = _getItemValue(
//       item,
//       [
//         'tutorEmail',
//         'tutor_email',
//         'email',
//       ],
//     );

//     final finalTutorEmail =
//         tutorEmail.isNotEmpty
//             ? tutorEmail
//             : 'Not Available';

//     // =====================================================
//     // TUTOR PHONE
//     // =====================================================

//     final tutorPhone = _getItemValue(
//       item,
//       [
//         'tutorPhone',
//         'tutor_phone',
//         'phone',
//       ],
//     );

//     final finalTutorPhone =
//         tutorPhone.isNotEmpty
//             ? tutorPhone
//             : 'Not Available';

//     // =====================================================
//     // DAY
//     // =====================================================

//     final day = _getItemValue(
//       item,
//       ['day'],
//     );

//     final fullDay = _getFullDayName(day);

//     // =====================================================
//     // TIME
//     // =====================================================

//     final time = _getItemValue(
//       item,
//       [
//         'time',
//         'classTime',
//         'class_time',
//       ],
//     );

//     final finalTime =
//         time.isNotEmpty
//             ? time
//             : 'N/A';

//     // =====================================================
//     // DATE
//     // =====================================================

//     final classDate = _formatDate(
//       item['classDate'] ??
//           item['class_date'],
//     );

//     // =====================================================
//     // CARD
//     // =====================================================

//     return Container(
//       margin: const EdgeInsets.only(
//         bottom: 14,
//       ),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(16),
//         border: Border.all(
//           color: Colors.grey.shade200,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color:
//                 Colors.grey.withOpacity(0.08),
//             blurRadius: 8,
//             offset:
//                 const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [

//           // =====================================================
//           // COURSE + ACTIVE STATUS
//           // =====================================================

//           Row(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [

//               Expanded(
//                 child: Row(
//                   children: [

//                     Icon(
//                       Icons.menu_book,
//                       color:
//                           Colors.teal.shade700,
//                       size: 20,
//                     ),

//                     const SizedBox(
//                       width: 8,
//                     ),

//                     Expanded(
//                       child: Text(
//                         finalCourseName,
//                         style:
//                             const TextStyle(
//                           fontSize: 16,
//                           fontWeight:
//                               FontWeight.bold,
//                           color:
//                               Colors.black87,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(
//                 width: 8,
//               ),

//               // =================================================
//               // ACTIVE
//               // =================================================

//               Container(
//                 padding:
//                     const EdgeInsets
//                         .symmetric(
//                   horizontal: 10,
//                   vertical: 5,
//                 ),
//                 decoration:
//                     BoxDecoration(
//                   color: Colors.green
//                       .withOpacity(0.1),
//                   borderRadius:
//                       BorderRadius.circular(
//                     12,
//                   ),
//                 ),
//                 child: Text(
//                   displayStatus,
//                   style:
//                       const TextStyle(
//                     color: Colors.green,
//                     fontSize: 11,
//                     fontWeight:
//                         FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(
//             height: 12,
//           ),

//           // =====================================================
//           // WEEKLY DAY
//           // =====================================================

//           Container(
//             width: double.infinity,
//             padding:
//                 const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 10,
//             ),
//             decoration:
//                 BoxDecoration(
//               color: Colors.teal
//                   .withOpacity(0.08),
//               borderRadius:
//                   BorderRadius.circular(10),
//             ),
//             child: Row(
//               children: [

//                 Icon(
//                   Icons.calendar_month,
//                   size: 18,
//                   color:
//                       Colors.teal.shade700,
//                 ),

//                 const SizedBox(
//                   width: 8,
//                 ),

//                 const Text(
//                   "Weekly Class:",
//                   style:
//                       TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey,
//                     fontWeight:
//                         FontWeight.w500,
//                   ),
//                 ),

//                 const SizedBox(
//                   width: 6,
//                 ),

//                 Expanded(
//                   child: Text(
//                     fullDay,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight:
//                           FontWeight.bold,
//                       color:
//                           Colors.teal.shade800,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(
//             height: 12,
//           ),

//           // =====================================================
//           // TUTOR DETAILS
//           // =====================================================

//           Container(
//             width: double.infinity,
//             padding:
//                 const EdgeInsets.all(12),
//             decoration:
//                 BoxDecoration(
//               color:
//                   Colors.grey.shade50,
//               borderRadius:
//                   BorderRadius.circular(12),
//               border: Border.all(
//                 color:
//                     Colors.grey.shade200,
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [

//                 // =================================================
//                 // TUTOR NAME
//                 // =================================================

//                 Row(
//                   children: [

//                     Icon(
//                       Icons.person_outline,
//                       size: 18,
//                       color:
//                           Colors.grey.shade700,
//                     ),

//                     const SizedBox(
//                       width: 8,
//                     ),

//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment:
//                             CrossAxisAlignment.start,
//                         children: [

//                           Text(
//                             finalTutorName,
//                             style:
//                                 const TextStyle(
//                               fontSize: 14,
//                               fontWeight:
//                                   FontWeight.bold,
//                               color:
//                                   Colors.black87,
//                             ),
//                           ),

//                           const Text(
//                             "Assigned Instructor",
//                             style:
//                                 TextStyle(
//                               fontSize: 11,
//                               color:
//                                   Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(
//                   height: 8,
//                 ),

//                 // =================================================
//                 // EMAIL
//                 // =================================================

//                 Row(
//                   children: [

//                     Icon(
//                       Icons.email_outlined,
//                       size: 14,
//                       color:
//                           Colors.grey.shade600,
//                     ),

//                     const SizedBox(
//                       width: 6,
//                     ),

//                     Expanded(
//                       child: Text(
//                         finalTutorEmail,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color:
//                               Colors.grey.shade800,
//                         ),
//                         overflow:
//                             TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(
//                   height: 4,
//                 ),

//                 // =================================================
//                 // PHONE
//                 // =================================================

//                 Row(
//                   children: [

//                     Icon(
//                       Icons.phone_outlined,
//                       size: 14,
//                       color:
//                           Colors.grey.shade600,
//                     ),

//                     const SizedBox(
//                       width: 6,
//                     ),

//                     Expanded(
//                       child: Text(
//                         finalTutorPhone,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color:
//                               Colors.grey.shade800,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(
//             height: 12,
//           ),

//           // =====================================================
//           // CLASS TIME
//           // =====================================================

//           _infoItem(
//             icon: Icons.access_time,
//             title: "Class Time",
//             value: finalTime,
//           ),

//           // =====================================================
//           // CLASS DATE
//           // =====================================================

//           if (classDate != "N/A") ...[
//             const SizedBox(
//               height: 10,
//             ),

//             _infoItem(
//               icon: Icons.event_outlined,
//               title: "Class Date",
//               value: classDate,
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // =====================================================
//   // INFO ITEM
//   // =====================================================

//   Widget _infoItem({
//     required IconData icon,
//     required String title,
//     required String value,
//   }) {
//     return Row(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [

//         Icon(
//           icon,
//           size: 16,
//           color: Colors.grey.shade600,
//         ),

//         const SizedBox(
//           width: 6,
//         ),

//         Expanded(
//           child: Column(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [

//               Text(
//                 title,
//                 style:
//                     const TextStyle(
//                   fontSize: 10,
//                   color: Colors.grey,
//                 ),
//               ),

//               const SizedBox(
//                 height: 2,
//               ),

//               Text(
//                 value,
//                 style:
//                     const TextStyle(
//                   fontSize: 12,
//                   fontWeight:
//                       FontWeight.bold,
//                   color:
//                       Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // =====================================================
//   // DATE FORMAT
//   // =====================================================

//   String _formatDate(dynamic value) {
//     if (value == null) {
//       return "N/A";
//     }

//     final date = value.toString().trim();

//     if (date.isEmpty) {
//       return "N/A";
//     }

//     // Example:
//     // 2026-09-27T19:15:49.533
//     //
//     // becomes:
//     // 2026-09-27

//     return date.split('T')[0];
//   }

//   // =====================================================
//   // BUILD WEEKLY SUMMARY
//   // =====================================================

//   Widget _buildWeeklySummary() {
//     return Container(
//       width: double.infinity,
//       padding:
//           const EdgeInsets.all(14),
//       decoration:
//           BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(16),
//         border: Border.all(
//           color: Colors.grey.shade200,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [

//           const Text(
//             "Weekly Classes",
//             style:
//                 TextStyle(
//               fontSize: 16,
//               fontWeight:
//                   FontWeight.bold,
//               color:
//                   Colors.black87,
//             ),
//           ),

//           const SizedBox(
//             height: 10,
//           ),

//           // =====================================================
//           // MONDAY -> SUNDAY
//           // =====================================================

//           ...weekDays.map(
//             (day) {

//               final dayClasses =
//                   classesList.where(
//                 (item) {

//                   if (item is! Map) {
//                     return false;
//                   }

//                   final itemDay =
//                       _getItemValue(
//                     item,
//                     ['day'],
//                   );

//                   return _getDayIndex(
//                         itemDay,
//                       ) ==
//                       _getDayIndex(day);
//                 },
//               ).toList();

//               final hasClass =
//                   dayClasses.isNotEmpty;

//               return Container(
//                 margin:
//                     const EdgeInsets.only(
//                   bottom: 7,
//                 ),
//                 padding:
//                     const EdgeInsets
//                         .symmetric(
//                   horizontal: 12,
//                   vertical: 9,
//                 ),
//                 decoration:
//                     BoxDecoration(
//                   color: hasClass
//                       ? Colors.teal
//                           .withOpacity(
//                           0.07,
//                         )
//                       : Colors.grey.shade50,
//                   borderRadius:
//                       BorderRadius.circular(
//                     9,
//                   ),
//                 ),
//                 child: Row(
//                   children: [

//                     // =================================================
//                     // DAY
//                     // =================================================

//                     SizedBox(
//                       width: 85,
//                       child: Text(
//                         day,
//                         style:
//                             TextStyle(
//                           fontSize: 12,
//                           fontWeight:
//                               FontWeight.bold,
//                           color: hasClass
//                               ? Colors
//                                   .teal
//                                   .shade800
//                               : Colors
//                                   .grey
//                                   .shade500,
//                         ),
//                       ),
//                     ),

//                     // =================================================
//                     // STATUS
//                     // =================================================

//                     Expanded(
//                       child: Text(
//                         hasClass
//                             ? "${dayClasses.length} Active Class${dayClasses.length > 1 ? 'es' : ''}"
//                             : "No Class",
//                         style:
//                             TextStyle(
//                           fontSize: 11,
//                           fontWeight:
//                               hasClass
//                                   ? FontWeight
//                                       .w600
//                                   : FontWeight
//                                       .normal,
//                           color: hasClass
//                               ? Colors
//                                   .green
//                                   .shade700
//                               : Colors
//                                   .grey
//                                   .shade500,
//                         ),
//                       ),
//                     ),

//                     if (hasClass)
//                       const Icon(
//                         Icons
//                             .check_circle,
//                         size: 17,
//                         color:
//                             Colors.green,
//                       ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   // =====================================================
//   // BUILD
//   // =====================================================

//   @override
//   Widget build(
//     BuildContext context,
//   ) {
//     return Scaffold(
//       backgroundColor:
//           const Color(0xFFF8F9FA),

//       // =====================================================
//       // APP BAR
//       // =====================================================

//       appBar: AppBar(
//         backgroundColor:
//             Colors.white,
//         elevation: 0,

//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back,
//             color: Colors.teal,
//           ),
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//         ),

//         title: Row(
//           mainAxisSize:
//               MainAxisSize.min,
//           children: [

//             Image.asset(
//               'assets/logo.png',
//               height: 24,
//               errorBuilder:
//                   (
//                 context,
//                 error,
//                 stackTrace,
//               ) {
//                 return const Icon(
//                   Icons.school,
//                   color:
//                       Colors.teal,
//                   size: 24,
//                 );
//               },
//             ),

//             const SizedBox(
//               width: 8,
//             ),

//             const Text(
//               "House of Tutor",
//               style:
//                   TextStyle(
//                 color:
//                     Colors.black87,
//                 fontSize: 14,
//                 fontWeight:
//                     FontWeight.bold,
//               ),
//             ),
//           ],
//         ),

//         centerTitle: true,
//       ),

//       // =====================================================
//       // BODY
//       // =====================================================

//       body: RefreshIndicator(
//         color: Colors.teal,

//         onRefresh:
//             refreshClasses,

//         child: isLoading

//             // =================================================
//             // LOADING
//             // =================================================

//             ? const Center(
//                 child:
//                     CircularProgressIndicator(
//                   color:
//                       Colors.teal,
//                 ),
//               )

//             // =================================================
//             // MAIN LIST
//             // =================================================

//             : ListView(
//                 physics:
//                     const AlwaysScrollableScrollPhysics(),

//                 padding:
//                     const EdgeInsets.all(
//                   16,
//                 ),

//                 children: [

//                   // =================================================
//                   // PAGE TITLE
//                   // =================================================

//                   Text(
//                     widget.courseTitle,
//                     style:
//                         const TextStyle(
//                       fontSize: 22,
//                       fontWeight:
//                           FontWeight.bold,
//                       color:
//                           Colors.black87,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 4,
//                   ),

//                   const Text(
//                     "Weekly active class schedule",
//                     style:
//                         TextStyle(
//                       fontSize: 13,
//                       color:
//                           Colors.grey,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   // =================================================
//                   // NO ACTIVE CLASSES
//                   // =================================================

//                   if (classesList.isEmpty)

//                     Padding(
//                       padding:
//                           const EdgeInsets
//                               .symmetric(
//                         vertical: 80,
//                       ),
//                       child: Column(
//                         mainAxisAlignment:
//                             MainAxisAlignment
//                                 .center,
//                         children: [

//                           Icon(
//                             Icons.event_busy,
//                             size: 55,
//                             color:
//                                 Colors
//                                     .grey
//                                     .shade400,
//                           ),

//                           const SizedBox(
//                             height: 15,
//                           ),

//                           Text(
//                             "No active classes found",
//                             style:
//                                 TextStyle(
//                               color: Colors
//                                   .grey
//                                   .shade600,
//                               fontSize: 15,
//                               fontWeight:
//                                   FontWeight
//                                       .w500,
//                             ),
//                           ),

//                           const SizedBox(
//                             height: 5,
//                           ),

//                           Text(
//                             "No active weekly class is available for this course.",
//                             textAlign:
//                                 TextAlign
//                                     .center,
//                             style:
//                                 TextStyle(
//                               color: Colors
//                                   .grey
//                                   .shade500,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )

//                   else ...[

//                     // =================================================
//                     // WEEKLY SUMMARY
//                     // =================================================

//                     _buildWeeklySummary(),

//                     const SizedBox(
//                       height: 16,
//                     ),

//                     // =================================================
//                     // CLASS DETAILS
//                     // =================================================

//                     ...classesList.map(
//                       (item) {
//                         return _buildClassCard(
//                           item,
//                         );
//                       },
//                     ),
//                   ],
//                 ],
//               ),
//       ),
//     );
//   }
// }
