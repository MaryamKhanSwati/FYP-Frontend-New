import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

// ============================================================
// CLASS MODEL
// ============================================================

class ClassItem {
  final int id;
  final String studentName;
  final String tutorName;
  final String subjectName;
  final String classTime;
  final String status;

  ClassItem({
    required this.id,
    required this.studentName,
    required this.tutorName,
    required this.subjectName,
    required this.classTime,
    required this.status,
  });

  factory ClassItem.fromJson(Map<String, dynamic> json) {
    return ClassItem(
      id: int.tryParse(
            (json['id'] ?? json['requestId'] ?? 0).toString(),
          ) ??
          0,
      studentName: (json['studentName'] ?? '').toString(),
      tutorName: (json['tutorName'] ?? '').toString(),
      subjectName: (json['subjectName'] ?? '').toString(),
      classTime: (json['classTime'] ?? '').toString(),
      status: (json['status'] ?? 'Pending').toString(),
    );
  }
}

// ============================================================
// ADMIN ALL CLASSES SCREEN
// ============================================================

class AdminAllClasses extends StatefulWidget {
  const AdminAllClasses({super.key});

  @override
  State<AdminAllClasses> createState() => _AdminAllClassesState();
}

class _AdminAllClassesState extends State<AdminAllClasses> {
  // ============================================================
  // COLORS
  // ============================================================

  final Color primaryColor = const Color(0xFF1E8E7E);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color headingColor = const Color(0xFF263238);
  final Color subtitleColor = const Color(0xFF84919D);

  // ============================================================
  // VARIABLES
  // ============================================================

  List<ClassItem> classes = [];

  bool isLoading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  // ============================================================
  // FETCH ALL CLASSES API
  // ============================================================

  Future<void> fetchClasses() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get(
        '/api/Admin/all-classes',
      );

      debugPrint('ALL CLASSES STATUS: ${response.statusCode}');
      debugPrint('ALL CLASSES BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        List<dynamic> classList = [];

        // Direct List response
        if (data is List) {
          classList = data;
        }
        // List inside an object
        else if (data is Map) {
          if (data['data'] is List) {
            classList = data['data'];
          } else if (data['classes'] is List) {
            classList = data['classes'];
          } else if (data['result'] is List) {
            classList = data['result'];
          }
        }

        final loadedClasses = classList
            .where((item) => item is Map)
            .map(
              (item) => ClassItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

        if (!mounted) return;

        setState(() {
          classes = loadedClasses;
        });

        debugPrint('TOTAL CLASSES: ${classes.length}');
      } else {
        showMessage(
          ApiClient.messageFromBody(response.body) ??
              'Failed to load classes',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('FETCH CLASSES ERROR: $e');

      if (mounted) {
        showMessage(
          'Unable to load classes. Please try again.',
          isError: true,
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

  // ============================================================
  // DATE, DAY AND TIME FORMAT
  // ============================================================

  DateTime? getClassDateTime(String value) {
    if (value.trim().isEmpty) return null;

    return DateTime.tryParse(value.trim());
  }

  String getFormattedDate(String value) {
    final date = getClassDateTime(value);

    if (date == null) return 'Not available';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  String getFormattedDay(String value) {
    final date = getClassDateTime(value);

    if (date == null) return 'Not available';

    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[date.weekday - 1];
  }

  String getFormattedTime(String value) {
    final date = getClassDateTime(value);

    if (date == null) return 'Not available';

    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');

    final period = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '$hour:$minute $period';
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  String normalizeStatus(String status) {
    return status.trim().toLowerCase();
  }

  bool isPending(ClassItem item) {
    return normalizeStatus(item.status) == 'pending';
  }

  bool isCompleted(ClassItem item) {
    return normalizeStatus(item.status) == 'completed';
  }

  Color getStatusColor(String status) {
    switch (normalizeStatus(status)) {
      case 'completed':
        return const Color(0xFF219653);

      case 'cancelled':
      case 'rejected':
        return const Color(0xFFE05252);

      case 'pending':
        return const Color(0xFFE69B26);

      default:
        return const Color(0xFF64748B);
    }
  }

  Color getStatusBackground(String status) {
    switch (normalizeStatus(status)) {
      case 'completed':
        return const Color(0xFFE8F6EE);

      case 'cancelled':
      case 'rejected':
        return const Color(0xFFFDECEC);

      case 'pending':
        return const Color(0xFFFFF5E5);

      default:
        return const Color(0xFFF0F2F5);
    }
  }

  IconData getStatusIcon(String status) {
    switch (normalizeStatus(status)) {
      case 'completed':
        return Icons.check_circle_outline_rounded;

      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;

      case 'pending':
        return Icons.access_time_rounded;

      default:
        return Icons.info_outline_rounded;
    }
  }

  // ============================================================
  // COUNTS
  // ============================================================

  int get pendingCount =>
      classes.where((item) => isPending(item)).length;

  int get completedCount =>
      classes.where((item) => isCompleted(item)).length;

  // ============================================================
  // SNACKBAR
  // ============================================================

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFE05252)
            : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER - BACK ARROW AND CENTERED LOGO
  // ============================================================

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // BACK BUTTON ONLY
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_rounded,
              color: headingColor,
              size: 25,
            ),
          ),

          // CENTER LOGO AND NAME
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 42,
                  width: 42,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.school_rounded,
                      color: primaryColor,
                      size: 38,
                    );
                  },
                ),

                const SizedBox(width: 9),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'House of Tutor',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ADMIN PANEL',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 9,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // BALANCE SPACE FOR CENTER ALIGNMENT
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ============================================================
  // PAGE TITLE
  // ============================================================

  Widget buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Classes',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: headingColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage and monitor all scheduled classes.',
          style: TextStyle(
            fontSize: 13,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget summaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE9EEF1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 35,
              width: 35,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 19,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: headingColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY SECTION
  // ============================================================

  Widget buildSummary() {
    return Row(
      children: [
        summaryCard(
          title: 'Total Classes',
          count: classes.length,
          icon: Icons.menu_book_rounded,
          color: primaryColor,
        ),
        const SizedBox(width: 10),
        summaryCard(
          title: 'Pending',
          count: pendingCount,
          icon: Icons.access_time_rounded,
          color: const Color(0xFFE69B26),
        ),
        const SizedBox(width: 10),
        summaryCard(
          title: 'Completed',
          count: completedCount,
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF219653),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION HEADING
  // ============================================================

  Widget buildSectionHeading() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Class Records',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: headingColor,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${classes.length} Classes',
            style: TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: getStatusBackground(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getStatusIcon(status),
            color: getStatusColor(status),
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            status.isEmpty ? 'Unknown' : status,
            style: TextStyle(
              color: getStatusColor(status),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CLASS DETAIL ROW
  // ============================================================

  Widget detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(
            icon,
            color: subtitleColor,
            size: 17,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not available' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: headingColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CLASS CARD
  // ============================================================

  Widget classCard(ClassItem item) {
    final Color statusColor = getStatusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE9EEF1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // STATUS COLOR LINE
              Container(
                width: 5,
                color: statusColor,
              ),

              // CARD CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SUBJECT AND STATUS
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.subjectName.isEmpty
                                  ? 'Class Subject'
                                  : item.subjectName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          statusBadge(item.status),
                        ],
                      ),

                      const SizedBox(height: 13),

                      const Divider(
                        height: 1,
                        color: Color(0xFFEEF1F3),
                      ),

                      // STUDENT
                      detailRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Student',
                        value: item.studentName,
                      ),

                      // TUTOR
                      detailRow(
                        icon: Icons.school_outlined,
                        label: 'Tutor',
                        value: item.tutorName,
                      ),

                      // DATE
                      detailRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'Date',
                        value: getFormattedDate(item.classTime),
                      ),

                      // DAY
                      detailRow(
                        icon: Icons.today_outlined,
                        label: 'Day',
                        value: getFormattedDay(item.classTime),
                      ),

                      // TIME
                      detailRow(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: getFormattedTime(item.classTime),
                      ),

                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),
        Icon(
          Icons.event_note_rounded,
          size: 65,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No Classes Found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: headingColor,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Center(
          child: Text(
            'There are currently no class records available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: subtitleColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Pull down to refresh',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
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
    return Scaffold(
      backgroundColor: backgroundColor,

      // NO DRAWER / NO THREE-LINE MENU

      body: SafeArea(
        child: Column(
          children: [
            // HEADER WITH BACK ARROW ONLY
            buildHeader(),

            // PAGE CONTENT
            Expanded(
              child: RefreshIndicator(
                onRefresh: fetchClasses,
                color: primaryColor,
                child: isLoading
                    ? ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 220),
                          Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Center(
                            child: Text(
                              'Loading classes...',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      )
                    : classes.isEmpty
                        ? emptyState()
                        : ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              18,
                              22,
                              18,
                              25,
                            ),
                            children: [
                              // PAGE TITLE
                              buildPageTitle(),

                              const SizedBox(height: 22),

                              // SUMMARY CARDS
                              buildSummary(),

                              const SizedBox(height: 27),

                              // SECTION HEADING
                              buildSectionHeading(),

                              const SizedBox(height: 15),

                              // CLASS LIST
                              ...classes.map(
                                (item) => classCard(item),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}