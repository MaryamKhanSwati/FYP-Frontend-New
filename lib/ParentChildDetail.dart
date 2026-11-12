
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/ParentChildCourses.dart';
import 'package:house_of_tutor/ParentChildFee.dart';
import 'package:house_of_tutor/ParentChildProfile.dart';
import 'package:house_of_tutor/ParentChildTutor.dart';
import 'package:house_of_tutor/services/api_client.dart';

class ParentChildDetail extends StatefulWidget {
  final Map<String, dynamic> child;

  const ParentChildDetail({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ParentChildDetail> createState() => _ParentChildDetailState();
}

class _ParentChildDetailState extends State<ParentChildDetail> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF00897B);
  static const Color darkPrimaryColor = Color(0xFF00695C);
  static const Color lightPrimaryColor = Color(0xFFE0F2F1);

  // ============================================================
  // VARIABLES
  // ============================================================

  List<dynamic> scheduleList = [];

  bool isLoading = true;

  int _currentIndex = 0;

  // ============================================================
  // DAYS
  // ============================================================

  final List<String> daysOfWeek = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // ============================================================
  // TIME SLOTS
  // ============================================================

  final List<String> timeSlots = [
    '8:00-9:00 am',
    '9:00-10:00 am',
    '10:00-11:00 am',
    '11:00-12:00 pm',
    '12:00-1:00 pm',
    '1:00-2:00 pm',
    '2:00-3:00 pm',
    '3:00-4:00 pm',
    '4:00-5:00 pm',
    '5:00-6:00 pm',
    '6:00-7:00 pm',
    '7:00-8:00 pm',
    '8:00-9:00 pm',
    '9:00-10:00 pm',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    fetchChildSchedule();
  }

  // ============================================================
  // GET STUDENT ID
  // ============================================================

  int? _getStudentId() {
    final possibleIds = [
      widget.child['studentId'],
      widget.child['student_id'],
      widget.child['id'],
      widget.child['Id'],
      widget.child['StudentId'],
      widget.child['StudentID'],
    ];

    for (final value in possibleIds) {
      if (value == null) continue;

      if (value is int && value > 0) {
        return value;
      }

      final parsed = int.tryParse(value.toString());

      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    return null;
  }

  // ============================================================
  // NORMALIZE DAY
  // ============================================================

  String _normalizeDay(dynamic value) {
    if (value == null) return '';

    return value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll(' ', '');
  }

  // ============================================================
  // NORMALIZE TIME
  // ============================================================

  String _normalizeTime(dynamic value) {
    if (value == null) return '';

    String result = value.toString().trim().toLowerCase();

    result = result.replaceAll(RegExp(r'\s+'), '');

    result = result
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('−', '-');

    return result;
  }

  // ============================================================
  // FETCH CHILD SCHEDULE
  // ============================================================

  Future<void> fetchChildSchedule() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final int? studentId = _getStudentId();

      debugPrint('========================================');
      debugPrint('PARENT CHILD SCHEDULE');
      debugPrint('Child Map: ${widget.child}');
      debugPrint('Student ID: $studentId');
      debugPrint('========================================');

      if (studentId == null || studentId <= 0) {
        if (!mounted) return;

        setState(() {
          scheduleList = [];
          isLoading = false;
        });

        _showSnackBar(
          'Unable to find student ID for this child.',
        );

        return;
      }

      final response = await ApiClient.get(
        '/api/Parent/child-schedule/$studentId',
      );

      debugPrint(
        'Schedule API Status: ${response.statusCode}',
      );

      debugPrint(
        'Schedule API Response: ${response.body}',
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> schedules = [];

        // API directly returns:
        // [
        //   {...},
        //   {...}
        // ]

        if (decoded is List) {
          schedules = decoded;
        }

        // API returns:
        // {
        //   "data": [...]
        // }
        else if (decoded is Map<String, dynamic>) {
          final possibleData = [
            decoded['data'],
            decoded['schedule'],
            decoded['schedules'],
          ];

          for (final value in possibleData) {
            if (value is List) {
              schedules = value;
              break;
            }
          }
        }

        debugPrint(
          'Schedules received: ${schedules.length}',
        );

        for (final item in schedules) {
          if (item is Map) {
            debugPrint(
              'Schedule => day: ${item['day']}, time: ${item['time']}',
            );
          }
        }

        if (!mounted) return;

        setState(() {
          scheduleList = schedules;
          isLoading = false;
        });
      } else {
        String errorMessage = 'Failed to load schedule.';

        if (response.body.isNotEmpty) {
          try {
            final decoded = json.decode(response.body);

            if (decoded is Map<String, dynamic>) {
              errorMessage =
                  decoded['message']?.toString() ??
                  decoded['error']?.toString() ??
                  errorMessage;
            } else {
              errorMessage = response.body;
            }
          } catch (_) {
            errorMessage = response.body;
          }
        }

        if (!mounted) return;

        setState(() {
          scheduleList = [];
          isLoading = false;
        });

        _showSnackBar(errorMessage);
      }
    } catch (e, stackTrace) {
      debugPrint('Schedule Error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        scheduleList = [];
        isLoading = false;
      });

      _showSnackBar(
        'An error occurred while loading schedule.',
      );
    }
  }

  // ============================================================
  // CHECK ACTIVE CLASS
  // ============================================================

  bool _isClassActive(
    String day,
    String time,
  ) {
    final String requiredDay = _normalizeDay(day);

    final String requiredTime = _normalizeTime(time);

    for (final item in scheduleList) {
      if (item is! Map) continue;

      final String itemDay = _normalizeDay(
        item['day'] ?? item['Day'],
      );

      final String itemTime = _normalizeTime(
        item['time'] ?? item['Time'],
      );

      if (itemDay == requiredDay &&
          itemTime == requiredTime) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // TOTAL CLASSES
  // ============================================================

  int _getTotalClasses() {
    return scheduleList.length;
  }

  // ============================================================
  // GET DAYS WITH CLASSES
  // ============================================================

  int _getActiveDays() {
    final Set<String> activeDays = {};

    for (final item in scheduleList) {
      if (item is! Map) continue;

      final day = _normalizeDay(
        item['day'] ?? item['Day'],
      );

      if (day.isNotEmpty) {
        activeDays.add(day);
      }
    }

    return activeDays.length;
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Current screen
        break;

      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParentChildProfile(
              child: widget.child,
            ),
          ),
        );
        break;

      case 2:
        final studentId = _getStudentId() ?? 0;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParentChildCourses(
              studentId: studentId,
            ),
          ),
        );
        break;

      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParentChildTutor(
              child: widget.child,
            ),
          ),
        );
        break;

      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ParentChildFee(),
          ),
        );
        break;
    }
  }

  // ============================================================
  // PROFILE INFO ITEM
  // ============================================================

  Widget _profileInfo(
    IconData icon,
    String value,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: lightPrimaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 17,
              color: primaryColor,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: lightPrimaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 18,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: darkPrimaryColor,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LEGEND ITEM
  // ============================================================

  Widget _legend(
    Color color,
    String title,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const SizedBox(width: 6),

        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // STUDENT DATA
    // ==========================================================

    final studentName =
        widget.child['fullName'] ??
        widget.child['full_name'] ??
        widget.child['name'] ??
        'Unknown Student';

    final studentEmail =
        widget.child['email'] ??
        'Email not available';

    final studentPhone =
        widget.child['phone'] ??
        widget.child['phoneNumber'] ??
        'Phone not available';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==================================================
            // LOGO
            // ==================================================

            Image.asset(
              'assets/images/logo.png',
              height: 38,
              width: 38,
              fit: BoxFit.contain,

              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: lightPrimaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: primaryColor,
                    size: 22,
                  ),
                );
              },
            ),

            const SizedBox(width: 9),

            // ==================================================
            // TITLE
            // ==================================================

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'House of Tutor',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 1),

                Text(
                  'Child Details',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),

        centerTitle: true,

        actions: [
          IconButton(
            tooltip: 'Refresh Schedule',
            icon: const Icon(
              Icons.refresh_rounded,
              color: primaryColor,
            ),
            onPressed: isLoading
                ? null
                : fetchChildSchedule,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: fetchChildSchedule,

        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [
                // ==================================================
                // CHILD PROFILE CARD
                // ==================================================

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),

                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset:
                            const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      // ==================================================
                      // LOGO + PROFILE ICON
                      // ==================================================

                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 86,
                            height: 86,

                            padding:
                                const EdgeInsets.all(4),

                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  lightPrimaryColor,

                              border: Border.all(
                                color:
                                    Colors.teal.shade100,
                                width: 2,
                              ),
                            ),

                            child: Container(
                              decoration:
                                  const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),

                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,

                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return const Icon(
                                      Icons.person,
                                      size: 48,
                                      color:
                                          primaryColor,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          Container(
                            width: 27,
                            height: 27,

                            decoration:
                                BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),

                            child: const Icon(
                              Icons.person,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // STUDENT NAME
                      // ==================================================

                      Text(
                        studentName.toString(),
                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),

                        decoration: BoxDecoration(
                          color: lightPrimaryColor,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),

                        child: const Text(
                          'Student',
                          style: TextStyle(
                            color: darkPrimaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // EMAIL
                      // ==================================================

                      _profileInfo(
                        Icons.email_outlined,
                        studentEmail.toString(),
                      ),

                      const SizedBox(height: 8),

                      // ==================================================
                      // PHONE
                      // ==================================================

                      _profileInfo(
                        Icons.phone_outlined,
                        studentPhone.toString(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ==================================================
                // SCHEDULE SUMMARY
                // ==================================================

                Row(
                  children: [
                    _statCard(
                      Icons.event_available,
                      'Classes',
                      isLoading
                          ? '-'
                          : _getTotalClasses()
                              .toString(),
                    ),

                    const SizedBox(width: 10),

                    _statCard(
                      Icons.calendar_month,
                      'Active Days',
                      isLoading
                          ? '-'
                          : _getActiveDays()
                              .toString(),
                    ),

                    const SizedBox(width: 10),

                    _statCard(
                      Icons.access_time,
                      'Time Slots',
                      isLoading
                          ? '-'
                          : scheduleList.length
                              .toString(),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ==================================================
                // WEEKLY TIMETABLE CARD
                // ==================================================

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(20),

                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset:
                            const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ==================================================
                      // HEADER
                      // ==================================================

                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,

                            decoration: BoxDecoration(
                              color:
                                  lightPrimaryColor,
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),

                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: primaryColor,
                              size: 22,
                            ),
                          ),

                          const SizedBox(width: 11),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                const Text(
                                  'Weekly Timetable',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  'Student class schedule',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ACTIVE BADGE

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),

                            decoration: BoxDecoration(
                              color:
                                  lightPrimaryColor,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),

                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration:
                                      const BoxDecoration(
                                    color: primaryColor,
                                    shape:
                                        BoxShape.circle,
                                  ),
                                ),

                                const SizedBox(width: 5),

                                const Text(
                                  'Active',
                                  style: TextStyle(
                                    color:
                                        darkPrimaryColor,
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // LOADING
                      // ==================================================

                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding:
                                EdgeInsets.all(40),
                            child:
                                CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ),
                        )

                      // ==================================================
                      // EMPTY SCHEDULE
                      // ==================================================

                      else if (scheduleList.isEmpty)
                        Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 35,
                            ),

                            child: Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,

                                  decoration:
                                      BoxDecoration(
                                    color:
                                        Colors.grey.shade100,
                                    shape:
                                        BoxShape.circle,
                                  ),

                                  child: Icon(
                                    Icons
                                        .event_busy_outlined,
                                    size: 34,
                                    color:
                                        Colors.grey.shade500,
                                  ),
                                ),

                                const SizedBox(height: 13),

                                const Text(
                                  'No Schedule Found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  'No classes are currently scheduled for this student.',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.grey.shade600,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                OutlinedButton.icon(
                                  onPressed:
                                      fetchChildSchedule,

                                  icon: const Icon(
                                    Icons.refresh,
                                    size: 17,
                                  ),

                                  label: const Text(
                                    'Refresh Schedule',
                                  ),

                                  style:
                                      OutlinedButton.styleFrom(
                                    foregroundColor:
                                        primaryColor,
                                    side: const BorderSide(
                                      color: primaryColor,
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )

                      // ==================================================
                      // TIMETABLE
                      // ==================================================

                      else
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            // ==================================================
                            // HORIZONTAL TABLE
                            // ==================================================

                            SingleChildScrollView(
                              scrollDirection:
                                  Axis.horizontal,

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [
                                  // ==================================================
                                  // DAY HEADER
                                  // ==================================================

                                  Row(
                                    children: [
                                      Container(
                                        width: 92,
                                        height: 36,

                                        alignment:
                                            Alignment.centerLeft,

                                        child: Text(
                                          'TIME',
                                          style:
                                              TextStyle(
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.bold,
                                            color: Colors
                                                .grey
                                                .shade600,
                                          ),
                                        ),
                                      ),

                                      for (final day
                                          in daysOfWeek)
                                        Container(
                                          width: 46,
                                          height: 36,

                                          alignment:
                                              Alignment.center,

                                          child: Text(
                                            day,
                                            style:
                                                const TextStyle(
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.bold,
                                              color:
                                                  Colors.black87,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  Container(
                                    height: 1,
                                    color:
                                        Colors.grey.shade200,
                                  ),

                                  const SizedBox(height: 5),

                                  // ==================================================
                                  // TIME ROWS
                                  // ==================================================

                                  for (final timeSlot
                                      in timeSlots)
                                    Padding(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        vertical: 3,
                                      ),

                                      child: Row(
                                        children: [
                                          // ==================================================
                                          // TIME
                                          // ==================================================

                                          SizedBox(
                                            width: 92,

                                            child: Text(
                                              timeSlot,
                                              style:
                                                  TextStyle(
                                                fontSize: 9,
                                                color: Colors
                                                    .grey
                                                    .shade700,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ),

                                          // ==================================================
                                          // DAYS
                                          // ==================================================

                                          for (final day
                                              in daysOfWeek)
                                            Builder(
                                              builder:
                                                  (context) {
                                                final active =
                                                    _isClassActive(
                                                  day,
                                                  timeSlot,
                                                );

                                                return Container(
                                                  width: 42,
                                                  height: 38,

                                                  margin:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal:
                                                        2,
                                                  ),

                                                  decoration:
                                                      BoxDecoration(
                                                    color: active
                                                        ? primaryColor
                                                        : const Color(
                                                            0xFFF1F3F4,
                                                          ),

                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                      8,
                                                    ),

                                                    border:
                                                        Border.all(
                                                      color: active
                                                          ? primaryColor
                                                          : Colors
                                                              .grey
                                                              .shade200,
                                                    ),
                                                  ),

                                                  child: active
                                                      ? const Icon(
                                                          Icons
                                                              .check_rounded,
                                                          color: Colors
                                                              .white,
                                                          size: 18,
                                                        )
                                                      : null,
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // ==================================================
                            // LEGEND
                            // ==================================================

                            Container(
                              width: double.infinity,

                              padding:
                                  const EdgeInsets.all(12),

                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.grey.shade50,
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),

                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,

                                children: [
                                  _legend(
                                    primaryColor,
                                    'Scheduled Class',
                                  ),

                                  const SizedBox(width: 25),

                                  _legend(
                                    Colors.grey.shade300,
                                    'Available',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: _currentIndex,

        onTap: _onItemTapped,

        type: BottomNavigationBarType.fixed,

        backgroundColor: Colors.white,

        elevation: 12,

        selectedItemColor: primaryColor,

        unselectedItemColor:
            Colors.grey.shade500,

        selectedFontSize: 10,

        unselectedFontSize: 10,

        selectedLabelStyle:
            const TextStyle(
          fontWeight: FontWeight.bold,
        ),

        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_today_outlined,
            ),
            activeIcon: Icon(
              Icons.calendar_today,
            ),
            label: 'Schedule',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
            ),
            activeIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.menu_book_outlined,
            ),
            activeIcon: Icon(
              Icons.menu_book,
            ),
            label: 'Courses',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.school_outlined,
            ),
            activeIcon: Icon(
              Icons.school,
            ),
            label: 'Tutors',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.payment_outlined,
            ),
            activeIcon: Icon(
              Icons.payment,
            ),
            label: 'Fee',
          ),
        ],
      ),
    );
  }
}





















// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/ParentChildCourses.dart';
// import 'package:house_of_tutor/ParentChildFee.dart';
// import 'package:house_of_tutor/ParentChildProfile.dart';
// import 'package:house_of_tutor/ParentChildTutor.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class ParentChildDetail extends StatefulWidget {
//   final Map<String, dynamic> child;

//   const ParentChildDetail({
//     Key? key,
//     required this.child,
//   }) : super(key: key);

//   @override
//   State<ParentChildDetail> createState() => _ParentChildDetailState();
// }

// class _ParentChildDetailState extends State<ParentChildDetail> {
//   List<dynamic> scheduleList = [];

//   bool isLoading = true;

//   int _currentIndex = 0;

//   final List<String> daysOfWeek = [
//     'Mon',
//     'Tue',
//     'Wed',
//     'Thu',
//     'Fri',
//     'Sat',
//     'Sun',
//   ];

//   final List<String> timeSlots = [
//     '8:00-9:00 am',
//     '9:00-10:00 am',
//     '10:00-11:00 am',
//     '11:00-12:00 pm',
//     '12:00-1:00 pm',
//     '1:00-2:00 pm',
//     '2:00-3:00 pm',
//     '3:00-4:00 pm',
//     '4:00-5:00 pm',
//     '5:00-6:00 pm',
//     '6:00-7:00 pm',
//     '7:00-8:00 pm',
//     '8:00-9:00 pm',
//     '9:00-10:00 pm',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     fetchChildSchedule();
//   }

//   // ============================================================
//   // GET STUDENT ID
//   // ============================================================

//   int? _getStudentId() {
//     final possibleIds = [
//       widget.child['studentId'],
//       widget.child['student_id'],
//       widget.child['id'],
//       widget.child['Id'],
//       widget.child['StudentId'],
//       widget.child['StudentID'],
//     ];

//     for (final value in possibleIds) {
//       if (value == null) continue;

//       if (value is int && value > 0) {
//         return value;
//       }

//       final parsed = int.tryParse(value.toString());

//       if (parsed != null && parsed > 0) {
//         return parsed;
//       }
//     }

//     return null;
//   }

//   // ============================================================
//   // NORMALIZE DAY
//   // ============================================================

//   String _normalizeDay(dynamic value) {
//     if (value == null) return '';

//     return value
//         .toString()
//         .trim()
//         .toLowerCase()
//         .replaceAll('.', '')
//         .replaceAll(' ', '');
//   }

//   // ============================================================
//   // NORMALIZE TIME
//   // ============================================================

//   String _normalizeTime(dynamic value) {
//     if (value == null) return '';

//     String result = value.toString().trim().toLowerCase();

//     // Remove every space.
//     result = result.replaceAll(RegExp(r'\s+'), '');

//     // Normalize common dash characters.
//     result = result
//         .replaceAll('–', '-')
//         .replaceAll('—', '-')
//         .replaceAll('−', '-');

//     return result;
//   }

//   // ============================================================
//   // FETCH CHILD SCHEDULE
//   // ============================================================

//   Future<void> fetchChildSchedule() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final int? studentId = _getStudentId();

//       debugPrint('========================================');
//       debugPrint('PARENT CHILD SCHEDULE');
//       debugPrint('Child Map: ${widget.child}');
//       debugPrint('Student ID: $studentId');
//       debugPrint('========================================');

//       if (studentId == null || studentId <= 0) {
//         if (!mounted) return;

//         setState(() {
//           scheduleList = [];
//           isLoading = false;
//         });

//         _showSnackBar(
//           'Unable to find student ID for this child.',
//         );

//         return;
//       }

//       final response = await ApiClient.get(
//         '/api/Parent/child-schedule/$studentId',
//       );

//       debugPrint(
//         'Schedule API Status: ${response.statusCode}',
//       );

//       debugPrint(
//         'Schedule API Response: ${response.body}',
//       );

//       if (response.statusCode == 200) {
//         final decoded = json.decode(response.body);

//         List<dynamic> schedules = [];

//         if (decoded is List) {
//           schedules = decoded;
//         } else if (decoded is Map<String, dynamic>) {
//           // Handles APIs that return:
//           // { "data": [...] }
//           // { "schedule": [...] }
//           // { "schedules": [...] }

//           final possibleData = [
//             decoded['data'],
//             decoded['schedule'],
//             decoded['schedules'],
//           ];

//           for (final value in possibleData) {
//             if (value is List) {
//               schedules = value;
//               break;
//             }
//           }
//         }

//         debugPrint(
//           'Schedules received: ${schedules.length}',
//         );

//         for (final item in schedules) {
//           debugPrint(
//             'Schedule => day: ${item['day']}, time: ${item['time']}',
//           );
//         }

//         if (!mounted) return;

//         setState(() {
//           scheduleList = schedules;
//           isLoading = false;
//         });
//       } else {
//         String errorMessage = 'Failed to load schedule.';

//         if (response.body.isNotEmpty) {
//           try {
//             final decoded = json.decode(response.body);

//             if (decoded is Map<String, dynamic>) {
//               errorMessage =
//                   decoded['message']?.toString() ??
//                   decoded['error']?.toString() ??
//                   errorMessage;
//             } else {
//               errorMessage = response.body;
//             }
//           } catch (_) {
//             errorMessage = response.body;
//           }
//         }

//         if (!mounted) return;

//         setState(() {
//           scheduleList = [];
//           isLoading = false;
//         });

//         _showSnackBar(errorMessage);
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Schedule Error: $e');
//       debugPrint('$stackTrace');

//       if (!mounted) return;

//       setState(() {
//         scheduleList = [];
//         isLoading = false;
//       });

//       _showSnackBar(
//         'An error occurred while loading schedule.',
//       );
//     }
//   }

//   // ============================================================
//   // CHECK ACTIVE CLASS
//   // ============================================================

//   bool _isClassActive(String day, String time) {
//     final String requiredDay = _normalizeDay(day);
//     final String requiredTime = _normalizeTime(time);

//     for (final item in scheduleList) {
//       if (item is! Map) continue;

//       final String itemDay = _normalizeDay(
//         item['day'] ??
//             item['Day'],
//       );

//       final String itemTime = _normalizeTime(
//         item['time'] ??
//             item['Time'],
//       );

//       if (itemDay == requiredDay &&
//           itemTime == requiredTime) {
//         return true;
//       }
//     }

//     return false;
//   }

//   // ============================================================
//   // SNACKBAR
//   // ============================================================

//   void _showSnackBar(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//       ),
//     );
//   }

//   // ============================================================
//   // BOTTOM NAVIGATION
//   // ============================================================

//   void _onItemTapped(int index) {
//     if (_currentIndex == index) return;

//     setState(() {
//       _currentIndex = index;
//     });

//     switch (index) {
//       case 0:
//         // Already on Schedule.
//         break;

//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ParentChildProfile(
//               child: widget.child,
//             ),
//           ),
//         );
//         break;

//       case 2:
//         final studentId = _getStudentId() ?? 0;

//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ParentChildCourses(
//               studentId: studentId,
//             ),
//           ),
//         );
//         break;

//       case 3:
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ParentChildTutor(
//               child: widget.child,
//             ),
//           ),
//         );
//         break;

//       case 4:
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => const ParentChildFee(),
//           ),
//         );
//         break;
//     }
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     final studentName =
//         widget.child['fullName'] ??
//         widget.child['full_name'] ??
//         'Unknown';

//     final studentEmail =
//         widget.child['email'] ??
//         'Not Available';

//     final studentPhone =
//         widget.child['phone'] ??
//         widget.child['phoneNumber'] ??
//         'Not Available';

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),

//       // ========================================================
//       // APP BAR
//       // ========================================================

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,

//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back,
//             color: Colors.black87,
//           ),
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//         ),

//         title: Column(
//           children: [
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Image.asset(
//                   'assets/logo.png',
//                   height: 20,
//                   errorBuilder: (
//                     context,
//                     error,
//                     stackTrace,
//                   ) {
//                     return const Icon(
//                       Icons.school,
//                       color: Colors.teal,
//                       size: 20,
//                     );
//                   },
//                 ),

//                 const SizedBox(width: 6),

//                 const Text(
//                   'House of Tutor',
//                   style: TextStyle(
//                     color: Colors.black87,
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),

//             const Text(
//               'Child Profile Details',
//               style: TextStyle(
//                 color: Colors.teal,
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),

//         centerTitle: true,
//       ),

//       // ========================================================
//       // BODY
//       // ========================================================

//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               // ==================================================
//               // STUDENT PROFILE
//               // ==================================================

//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: Colors.grey.shade200,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.08),
//                       blurRadius: 8,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),

//                 child: Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.teal.shade50,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.person,
//                         size: 40,
//                         color: Colors.teal.shade700,
//                       ),
//                     ),

//                     const SizedBox(height: 12),

//                     Text(
//                       studentName.toString(),
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),

//                     const SizedBox(height: 8),

//                     // EMAIL

//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 6,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade100,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: Colors.grey.shade300,
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.email_outlined,
//                             size: 14,
//                             color: Colors.grey.shade600,
//                           ),

//                           const SizedBox(width: 6),

//                           Text(
//                             studentEmail.toString(),
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade800,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 6),

//                     // PHONE

//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 6,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade100,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: Colors.grey.shade300,
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.phone_outlined,
//                             size: 14,
//                             color: Colors.grey.shade600,
//                           ),

//                           const SizedBox(width: 6),

//                           Text(
//                             studentPhone.toString(),
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade800,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // ==================================================
//               // WEEKLY TIMETABLE
//               // ==================================================

//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: Colors.grey.shade200,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.08),
//                       blurRadius: 8,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),

//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,

//                   children: [
//                     // HEADER

//                     Row(
//                       mainAxisAlignment:
//                           MainAxisAlignment.spaceBetween,

//                       children: [
//                         Row(
//                           children: const [
//                             Icon(
//                               Icons.calendar_today,
//                               color: Colors.teal,
//                               size: 20,
//                             ),

//                             SizedBox(width: 8),

//                             Text(
//                               'Weekly Timetable',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                           ],
//                         ),

//                         Container(
//                           padding:
//                               const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.teal.shade50,
//                             borderRadius:
//                                 BorderRadius.circular(12),
//                           ),

//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 6,
//                                 height: 6,
//                                 decoration:
//                                     const BoxDecoration(
//                                   color: Colors.teal,
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),

//                               const SizedBox(width: 6),

//                               const Text(
//                                 'Active Class',
//                                 style: TextStyle(
//                                   color: Colors.teal,
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 16),

//                     // ==================================================
//                     // LOADING
//                     // ==================================================

//                     if (isLoading)
//                       const Center(
//                         child: Padding(
//                           padding: EdgeInsets.all(32),
//                           child: CircularProgressIndicator(
//                             color: Colors.teal,
//                           ),
//                         ),
//                       )

//                     // ==================================================
//                     // NO SCHEDULE
//                     // ==================================================

//                     else if (scheduleList.isEmpty)
//                       Center(
//                         child: Padding(
//                           padding: const EdgeInsets.all(30),
//                           child: Column(
//                             children: [
//                               Icon(
//                                 Icons.calendar_month_outlined,
//                                 size: 50,
//                                 color: Colors.grey.shade400,
//                               ),

//                               const SizedBox(height: 10),

//                               Text(
//                                 'No Schedule Found',
//                                 style: TextStyle(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.grey.shade700,
//                                 ),
//                               ),

//                               const SizedBox(height: 5),

//                               Text(
//                                 'No schedule is available for this student.',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey.shade500,
//                                 ),
//                               ),

//                               const SizedBox(height: 15),

//                               OutlinedButton.icon(
//                                 onPressed: fetchChildSchedule,
//                                 icon: const Icon(
//                                   Icons.refresh,
//                                   size: 18,
//                                 ),
//                                 label: const Text('Refresh'),
//                               ),
//                             ],
//                           ),
//                         ),
//                       )

//                     // ==================================================
//                     // TIMETABLE
//                     // ==================================================

//                     else
//                       SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,

//                         child: Column(
//                           crossAxisAlignment:
//                               CrossAxisAlignment.start,

//                           children: [
//                             // DAYS HEADER

//                             Row(
//                               children: [
//                                 const SizedBox(width: 90),

//                                 for (final day
//                                     in daysOfWeek)
//                                   SizedBox(
//                                     width: 45,
//                                     child: Center(
//                                       child: Text(
//                                         day,
//                                         style:
//                                             const TextStyle(
//                                           fontSize: 12,
//                                           fontWeight:
//                                               FontWeight.bold,
//                                           color: Colors.grey,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                               ],
//                             ),

//                             const SizedBox(height: 8),

//                             // TIME ROWS

//                             for (final timeSlot
//                                 in timeSlots)
//                               Padding(
//                                 padding:
//                                     const EdgeInsets.symmetric(
//                                   vertical: 4,
//                                 ),

//                                 child: Row(
//                                   children: [
//                                     // TIME

//                                     SizedBox(
//                                       width: 90,
//                                       child: Text(
//                                         timeSlot,
//                                         style:
//                                             const TextStyle(
//                                           fontSize: 10,
//                                           color: Colors.grey,
//                                           fontWeight:
//                                               FontWeight.w600,
//                                         ),
//                                       ),
//                                     ),

//                                     // DAYS

//                                     for (final day
//                                         in daysOfWeek)
//                                       Builder(
//                                         builder: (context) {
//                                           final active =
//                                               _isClassActive(
//                                             day,
//                                             timeSlot,
//                                           );

//                                           return Container(
//                                             width: 42,
//                                             height: 42,
//                                             margin:
//                                                 const EdgeInsets
//                                                     .symmetric(
//                                               horizontal: 1.5,
//                                             ),

//                                             decoration:
//                                                 BoxDecoration(
//                                               color: active
//                                                   ? Colors.teal
//                                                   : Colors
//                                                       .grey
//                                                       .shade100,
//                                               borderRadius:
//                                                   BorderRadius
//                                                       .circular(
//                                                 8,
//                                               ),
//                                             ),

//                                             child: active
//                                                 ? const Icon(
//                                                     Icons.check,
//                                                     color:
//                                                         Colors
//                                                             .white,
//                                                     size: 16,
//                                                   )
//                                                 : null,
//                                           );
//                                         },
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),

//       // ==========================================================
//       // BOTTOM NAVIGATION
//       // ==========================================================

//       bottomNavigationBar:
//           BottomNavigationBar(
//         currentIndex: _currentIndex,

//         onTap: _onItemTapped,

//         type: BottomNavigationBarType.fixed,

//         selectedItemColor: Colors.teal,

//         unselectedItemColor: Colors.grey,

//         selectedFontSize: 11,

//         unselectedFontSize: 11,

//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.calendar_today),
//             label: 'Schedule',
//           ),

//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_outline),
//             label: 'Profile',
//           ),

//           BottomNavigationBarItem(
//             icon: Icon(Icons.menu_book),
//             label: 'Courses',
//           ),

//           BottomNavigationBarItem(
//             icon: Icon(Icons.school_outlined),
//             label: 'Tutors',
//           ),

//           BottomNavigationBarItem(
//             icon: Icon(Icons.payment),
//             label: 'Fee',
//           ),
//         ],
//       ),
//     );
//   }
// }

















// // import 'dart:convert';

// // import 'package:flutter/material.dart';
// // //import 'package:house_of_tutor/ParentChildClasses.dart';
// // import 'package:house_of_tutor/ParentChildCourses.dart';
// // import 'package:house_of_tutor/ParentChildFee.dart';
// // import 'package:house_of_tutor/ParentChildProfile.dart';
// // import 'package:house_of_tutor/ParentChildTutor.dart';
// // import 'package:house_of_tutor/services/api_client.dart';

// // class ParentChildDetail extends StatefulWidget {
// //   final int studentId;
// //   final String childName;
// //   final String email;
// //   final String phone;

// //   const ParentChildDetail({
// //     super.key,
// //     required this.studentId,
// //     required this.childName,
// //     required this.email,
// //     required this.phone,
// //   });

// //   @override
// //   State<ParentChildDetail> createState() =>
// //       _ParentChildDetailState();
// // }

// // class _ParentChildDetailState extends State<ParentChildDetail> {

// //   bool isLoading = true;

// //   List<dynamic> schedules = [];

// //   final List<String> days = [
// //     "Mon",
// //     "Tue",
// //     "Wed",
// //     "Thu",
// //     "Fri",
// //     "Sat",
// //     "Sun",
// //   ];

// //   final List<String> timeSlots = [
// //     "8:00-9:00 am",
// //     "9:00-10:00 am",
// //     "10:00-11:00 am",
// //     "11:00-12:00 pm",
// //     "12:00-1:00 pm",
// //     "1:00-2:00 pm",
// //     "2:00-3:00 pm",
// //     "3:00-4:00 pm",
// //     "4:00-5:00 pm",
// //     "5:00-6:00 pm",
// //     "6:00-7:00 pm",
// //     "7:00-8:00 pm",
// //     "8:00-9:00 pm",
// //     "9:00-10:00 pm",
// //   ];

// //   @override
// //   void initState() {
// //     super.initState();
// //     getSchedule();
// //   }

// //   Future<void> getSchedule() async {
// //     try {

// //       final response = await ApiClient.get(
// //         "/api/Parent/child-schedule/${widget.studentId}",
// //       );

// //       if (response.statusCode == 200) {

// //         schedules = jsonDecode(
// //           utf8.decode(response.bodyBytes),
// //         );

// //       } else {

// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               ApiClient.messageFromBody(response.body) ??
// //                   "Unable to fetch schedule",
// //             ),
// //           ),
// //         );
// //       }
// //     } catch (e) {

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(e.toString()),
// //         ),
// //       );

// //     } finally {

// //       if (mounted) {
// //         setState(() {
// //           isLoading = false;
// //         });
// //       }
// //     }
// //   }

// //   bool isBooked(String day, String time) {

// //     return schedules.any((e) {

// //       return e["day"] == day &&
// //           e["time"] == time;

// //     });
// //   }
// //     @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.grey.shade100,

// //       appBar: AppBar(
// //         backgroundColor: Colors.white,
// //         elevation: 1,
// //         centerTitle: true,
// //         leading: IconButton(
// //           icon: const Icon(
// //             Icons.arrow_back,
// //             color: Colors.teal,
// //           ),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //         title: Image.asset(
// //           "assets/images/logo.png",
// //           height: 45,
// //         ),
// //       ),

// //       body: isLoading
// //           ? const Center(
// //               child: CircularProgressIndicator(),
// //             )
// //           : SingleChildScrollView(
// //               child: Column(
// //                 children: [

// //                   const SizedBox(height: 15),

// //                   Container(
// //                     margin: const EdgeInsets.symmetric(horizontal: 12),
// //                     padding: const EdgeInsets.all(20),
// //                     decoration: BoxDecoration(
// //                       color: Colors.white,
// //                       borderRadius: BorderRadius.circular(18),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: Colors.grey.shade300,
// //                           blurRadius: 6,
// //                         ),
// //                       ],
// //                     ),
// //                     child: Column(
// //                       children: [

// //                         CircleAvatar(
// //                           radius: 45,
// //                           backgroundColor: Colors.grey.shade200,
// //                           child: const Icon(
// //                             Icons.person,
// //                             color: Colors.teal,
// //                             size: 55,
// //                           ),
// //                         ),

// //                         const SizedBox(height: 15),

// //                         Text(
// //                           widget.childName,
// //                           style: const TextStyle(
// //                             fontSize: 26,
// //                             fontWeight: FontWeight.bold,
// //                             color: Colors.teal,
// //                           ),
// //                         ),

// //                         const SizedBox(height: 8),

// //                         Text(
// //                           widget.email,
// //                           style: TextStyle(
// //                             color: Colors.grey.shade700,
// //                             fontSize: 16,
// //                           ),
// //                         ),

// //                         const SizedBox(height: 6),

// //                         Text(
// //                           widget.phone,
// //                           style: TextStyle(
// //                             color: Colors.grey.shade700,
// //                             fontSize: 16,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),

// //                   const SizedBox(height: 20),

// //                   Padding(
// //                     padding:
// //                         const EdgeInsets.symmetric(horizontal: 10),

// //                     child: SingleChildScrollView(
// //                       scrollDirection: Axis.horizontal,

// //                       child: Column(

// //                         children: [

// //                           Row(
// //                             children: [

// //                               const SizedBox(
// //                                 width: 90,
// //                               ),

// //                               ...days.map(
// //                                 (day) => Container(
// //                                   width: 45,
// //                                   alignment: Alignment.center,
// //                                   margin: const EdgeInsets.all(2),
// //                                   child: Text(
// //                                     day,
// //                                     style: const TextStyle(
// //                                       fontWeight:
// //                                           FontWeight.bold,
// //                                       fontSize: 13,
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ),
// //                             ],
// //                           ),

// //                           const SizedBox(height: 5),

// //                           ...timeSlots.map(

// //                             (time) {

// //                               return Row(

// //                                 children: [

// //                                   SizedBox(
// //                                     width: 90,
// //                                     child: Text(
// //                                       time,
// //                                       style: const TextStyle(
// //                                         fontSize: 11,
// //                                       ),
// //                                     ),
// //                                   ),

// //                                   ...days.map(

// //                                     (day) {

// //                                       final booked =
// //                                           isBooked(day, time);

// //                                       return Container(
// //                                         width: 40,
// //                                         height: 40,
// //                                         margin:
// //                                             const EdgeInsets.all(2),

// //                                         decoration: BoxDecoration(
// //                                           color: booked
// //                                               ? Colors.teal
// //                                               : Colors.grey.shade200,

// //                                           borderRadius:
// //                                               BorderRadius.circular(
// //                                                   5),
// //                                         ),

// //                                         child: booked
// //                                             ? const Icon(
// //                                                 Icons.check,
// //                                                 color: Colors.white,
// //                                                 size: 18,
// //                                               )
// //                                             : null,
// //                                       );
// //                                     },
// //                                   ),
// //                                 ],
// //                               );
// //                             },
// //                           ),

// //                           const SizedBox(height: 30),
// //                                                     Row(
// //                             mainAxisAlignment:
// //                                 MainAxisAlignment.spaceEvenly,
// //                             children: [

// //                               _legend(
// //                                 Colors.teal,
// //                                 "Booked",
// //                               ),

// //                               _legend(
// //                                 Colors.grey.shade300,
// //                                 "Available",
// //                               ),
// //                             ],
// //                           ),

// //                           const SizedBox(height: 20),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //       bottomNavigationBar: BottomNavigationBar(

// //         currentIndex: 2,

// //         type: BottomNavigationBarType.fixed,

// //         selectedItemColor: Colors.teal,

// //         unselectedItemColor: Colors.grey,

// //         onTap: (index) {

// //           if (index == 0) {

// //             Navigator.pushReplacement(
// //               context,
// //               MaterialPageRoute(
// //                 builder: (_) => ParentChildProfile(
// //                   studentId: widget.studentId,
// //                 ),
// //               ),
// //             );

// //           }

// //           if (index == 1) {

// //             Navigator.pushReplacement(
// //               context,
// //               MaterialPageRoute(
// //                 builder: (_) => ParentChildCourses(
// //                   studentId: widget.studentId,
// //                 ),
// //               ),
// //             );

// //           }

// //           if (index == 2) {
// //             // Current Screen
// //           }

// //           if (index == 3) {

// //             Navigator.pushReplacement(
// //               context,
// //               MaterialPageRoute(
// //                 builder: (_) => ParentChildTutor(
// //                   studentId: widget.studentId,
// //                 ),
// //               ),
// //             );

// //           }

// //           if (index == 4) {

// //             Navigator.pushReplacement(
// //               context,
// //               MaterialPageRoute(
// //                 builder: (_) => ParentChildFee(
// //                   studentId: widget.studentId, 
// //                 ),
// //               ),
// //             );

// //           }

// //         },

// //         items: const [

// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.person),
// //             label: "Profile",
// //           ),

// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.book),
// //             label: "Courses",
// //           ),

// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.schedule),
// //             label: "Schedule",
// //           ),

// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.school),
// //             label: "Tutors",
// //           ),

// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.payment),
// //             label: "Fees",
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _legend(Color color, String text) {

// //     return Row(
// //       children: [

// //         Container(
// //           width: 18,
// //           height: 18,
// //           decoration: BoxDecoration(
// //             color: color,
// //             borderRadius: BorderRadius.circular(4),
// //           ),
// //         ),

// //         const SizedBox(width: 6),

// //         Text(
// //           text,
// //           style: const TextStyle(
// //             fontWeight: FontWeight.w600,
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }