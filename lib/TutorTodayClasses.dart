import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:house_of_tutor/TutorAddSubject.dart';
import 'package:house_of_tutor/TutorDrawer.dart';
import 'package:house_of_tutor/TutorHome.dart';
import 'package:house_of_tutor/TutorStudentRequest.dart';
import 'package:house_of_tutor/services/api_client.dart';

class TutorTodayClasses extends StatefulWidget {
  const TutorTodayClasses({super.key});

  @override
  State<TutorTodayClasses> createState() => _TutorTodayClassesState();
}

class _TutorTodayClassesState extends State<TutorTodayClasses> {
  int currentIndex = 2;
  bool loading = true;
  List<dynamic> classes = [];

  // 🎨 MAIN THEME COLOR
  final Color mainColor = Colors.teal;

  @override
  void initState() {
    super.initState();
    fetchTodayClasses();
  }

  // =====================================================
  // FETCH TODAY CLASSES
  // =====================================================

  Future<void> fetchTodayClasses() async {
    try {
      setState(() => loading = true);

      final response = await ApiClient.get('/api/Tutor/today-classes');

      debugPrint("TODAY STATUS : ${response.statusCode}");
      debugPrint("TODAY BODY : ${response.body}");

      classes = [];

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));

        if (decoded is Map &&
            decoded["data"] != null &&
            decoded["data"] is List) {
          classes = List<dynamic>.from(decoded["data"]);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ApiClient.messageFromBody(response.body) ??
                    "Failed to load classes",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("TODAY ERROR : $e");
      classes = [];
    }

    if (mounted) setState(() => loading = false);
  }

  // =====================================================
  // COMPLETE CLASS
  // =====================================================

  Future<void> completeClass(int requestId) async {
    try {
      final response = await ApiClient.put(
        '/api/Tutor/complete-class/$requestId',
        {},
      );

      debugPrint("COMPLETE STATUS : ${response.statusCode}");
      debugPrint("COMPLETE BODY : ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Class marked as Complete")),
        );
        fetchTodayClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiClient.messageFromBody(response.body) ?? "Failed",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("COMPLETE ERROR : $e");
    }
  }

  // =====================================================
  // CANCEL CLASS
  // =====================================================

  Future<void> cancelClass(int requestId) async {
    try {
      final response = await ApiClient.put(
        '/api/Tutor/cancel-class/$requestId',
        {},
      );

      debugPrint("CANCEL STATUS : ${response.statusCode}");
      debugPrint("CANCEL BODY : ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Class Cancelled")),
        );
        fetchTodayClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiClient.messageFromBody(response.body) ?? "Failed",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("CANCEL ERROR : $e");
    }
  }

  // =====================================================
  // AUTO SCHEDULE (Pre / Re)
  // =====================================================

  Future<void> autoSchedule({
    required int requestId,
    required String requestType,
  }) async {
    try {
      setState(() => loading = true);

      final endpoint = requestType == "Preschedule"
          ? '/api/Tutor/preschedule'
          : '/api/Tutor/reschedule';

      final response = await ApiClient.post(endpoint, {
        "requestId": requestId,
      });

      debugPrint("AUTO SCHEDULE STATUS : ${response.statusCode}");
      debugPrint("AUTO SCHEDULE BODY : ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final bool autoScheduled = json["autoScheduled"] ?? false;
        final bool manualRequired = json["manualRequired"] ?? false;

        if (autoScheduled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                json["message"] ?? "$requestType successful",
              ),
            ),
          );
          fetchTodayClasses();
        } else if (manualRequired) {
          setState(() => loading = false);
          openManualDialog(requestId, requestType);
        }
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiClient.messageFromBody(response.body) ??
                  "Unable to $requestType",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("AUTO SCHEDULE ERROR : $e");
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  // =====================================================
  // MANUAL SCHEDULE DIALOG
  // =====================================================

  void openManualDialog(int requestId, String requestType) {
    final days = [
      "Monday", "Tuesday", "Wednesday",
      "Thursday", "Friday", "Saturday", "Sunday",
    ];

    String selectedDay = days.first;
    TimeOfDay selectedTime = TimeOfDay.now();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Manual $requestType",
                style: TextStyle(
                  color: mainColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "No common slot found. Please pick a day, date and time.",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // DAY
                    const Text("Day",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: days
                          .map((d) =>
                              DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedDay = val!);
                      },
                    ),

                    const SizedBox(height: 16),

                    // DATE
                    const Text("Date",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        child: Text(
                          "${selectedDate.year}-"
                          "${selectedDate.month.toString().padLeft(2, '0')}-"
                          "${selectedDate.day.toString().padLeft(2, '0')}",
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TIME
                    const Text("Time",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        child: Text(selectedTime.format(context)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await manualSchedule(
                      requestId: requestId,
                      requestType: requestType,
                      day: selectedDay,
                      time: selectedTime.format(context),
                      date: selectedDate,
                    );
                  },
                  child: const Text(
                    "Send Request",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =====================================================
  // MANUAL SCHEDULE API
  // =====================================================

  Future<void> manualSchedule({
    required int requestId,
    required String requestType,
    required String day,
    required String time,
    required DateTime date,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/Tutor/manual-schedule',
        {
          "requestId": requestId,
          "requestType": requestType,
          "day": day,
          "time": time,
          "classDate": date.toIso8601String(),
        },
      );

      debugPrint("MANUAL STATUS : ${response.statusCode}");
      debugPrint("MANUAL BODY : ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Schedule request sent to student."),
          ),
        );
        fetchTodayClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiClient.messageFromBody(response.body) ??
                  "Unable to send request",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("MANUAL ERROR : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  // =====================================================
  // NAVIGATION
  // =====================================================

  void navigateScreen(int value) {
    if (value == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TutorHome()),
      );
    } else if (value == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TutorStudentRequest()),
      );
    } else if (value == 2) {
      return;
    } else if (value == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TutorAddSubject()),
      );
    }
  }

  // =====================================================
  // SINGLE-LINE ACTION BUTTON
  // =====================================================
  // FittedBox keeps Complete / Pre-Schedule / Re-Schedule /
  // Cancel from wrapping onto a second line on narrow screens.

  Widget actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // CLASS CARD
  // =====================================================

  Widget classCard(dynamic data) {
    final int requestId = (data["request_id"] as num?)?.toInt() ?? 0;
    final String time = data["time"]?.toString() ?? "";
    final String student = data["student_name"]?.toString() ?? "";
    final String subject = data["course_name"]?.toString() ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE7E9ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIME BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: 15, color: mainColor),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: TextStyle(
                    color: mainColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xffE7E9ED)),
          const SizedBox(height: 12),

          // STUDENT / SUBJECT ROW
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: mainColor,
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff101C33),
                      ),
                    ),
                    Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ACTION BUTTONS (4-in-a-row, single line each)
          Row(
            children: [
              Expanded(
                child: actionButton(
                  label: "Complete",
                  icon: Icons.check_circle_outline,
                  color: const Color(0xff2DB55D),
                  onTap: () => completeClass(requestId),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: actionButton(
                  label: "Pre-Sch.",
                  icon: Icons.history_toggle_off,
                  color: const Color(0xff9B51E0),
                  onTap: () => autoSchedule(
                    requestId: requestId,
                    requestType: "Preschedule",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: actionButton(
                  label: "Re-Sch.",
                  icon: Icons.event_repeat,
                  color: const Color(0xff2F80ED),
                  onTap: () => autoSchedule(
                    requestId: requestId,
                    requestType: "Reschedule",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: actionButton(
                  label: "Cancel",
                  icon: Icons.cancel_outlined,
                  color: Colors.redAccent,
                  onTap: () => cancelClass(requestId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      drawer: const TutorDrawer(),

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/images/logo.png",
              height: 26,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.school, color: mainColor);
              },
            ),
            const SizedBox(width: 8),
            Text(
              "House of Tutor",
              style: TextStyle(
                color: mainColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: loading
          ? Center(child: CircularProgressIndicator(color: mainColor))
          : RefreshIndicator(
              onRefresh: fetchTodayClasses,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Classes",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff101C33),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: mainColor.withOpacity(.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${classes.length} Sessions",
                            style: TextStyle(
                              color: mainColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 20),
                    child: Text(
                      "Manage your active teaching schedule for today.",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),

                  // LIST
                  if (classes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text(
                          "No classes today",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    ...classes.map((c) => classCard(c)),
                ],
              ),
            ),

      // =====================================================
      // BOTTOM NAVIGATION
      // =====================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: mainColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (value) {
          setState(() => currentIndex = value);
          navigateScreen(value);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Schedule",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Request",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: "Today",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Add",
          ),
        ],
      ),
    );
  }
}





















































// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/TutorAddSubject.dart';
// import 'package:house_of_tutor/TutorDrawer.dart';
// import 'package:house_of_tutor/TutorHome.dart';
// import 'package:house_of_tutor/TutorStudentRequest.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class TutorTodayClasses extends StatefulWidget {
//   const TutorTodayClasses({super.key});

//   @override
//   State<TutorTodayClasses> createState() => _TutorTodayClassesState();
// }

// class _TutorTodayClassesState extends State<TutorTodayClasses> {

//   int currentIndex = 2;
//   bool loading = true;
//   List<dynamic> classes = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchTodayClasses();
//   }

//   // =====================================================
//   // FETCH TODAY CLASSES
//   // =====================================================

//   Future<void> fetchTodayClasses() async {
//     try {
//       setState(() => loading = true);

//       final response = await ApiClient.get('/api/Tutor/today-classes');

//       debugPrint("TODAY STATUS : ${response.statusCode}");
//       debugPrint("TODAY BODY : ${response.body}");

//       classes = [];

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(utf8.decode(response.bodyBytes));

//         if (decoded is Map &&
//             decoded["data"] != null &&
//             decoded["data"] is List) {
//           classes = List<dynamic>.from(decoded["data"]);
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 ApiClient.messageFromBody(response.body) ??
//                     "Failed to load classes",
//               ),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("TODAY ERROR : $e");
//       classes = [];
//     }

//     if (mounted) setState(() => loading = false);
//   }

//   // =====================================================
//   // COMPLETE CLASS
//   // =====================================================

//   Future<void> completeClass(int requestId) async {
//     try {
//       final response = await ApiClient.put(
//         '/api/Tutor/complete-class/$requestId',
//         {},
//       );

//       debugPrint("COMPLETE STATUS : ${response.statusCode}");
//       debugPrint("COMPLETE BODY : ${response.body}");

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Class marked as Complete")),
//         );
//         fetchTodayClasses();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               ApiClient.messageFromBody(response.body) ?? "Failed",
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint("COMPLETE ERROR : $e");
//     }
//   }

//   // =====================================================
//   // CANCEL CLASS
//   // =====================================================

//   Future<void> cancelClass(int requestId) async {
//     try {
//       final response = await ApiClient.put(
//         '/api/Tutor/cancel-class/$requestId',
//         {},
//       );

//       debugPrint("CANCEL STATUS : ${response.statusCode}");
//       debugPrint("CANCEL BODY : ${response.body}");

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Class Cancelled")),
//         );
//         fetchTodayClasses();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               ApiClient.messageFromBody(response.body) ?? "Failed",
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint("CANCEL ERROR : $e");
//     }
//   }

//   // =====================================================
//   // AUTO SCHEDULE (Pre / Re)
//   // =====================================================

//   Future<void> autoSchedule({
//     required int requestId,
//     required String requestType,
//   }) async {
//     try {
//       setState(() => loading = true);

//       final endpoint = requestType == "Preschedule"
//           ? '/api/Tutor/preschedule'
//           : '/api/Tutor/reschedule';

//       final response = await ApiClient.post(endpoint, {
//         "requestId": requestId,
//       });

//       debugPrint("AUTO SCHEDULE STATUS : ${response.statusCode}");
//       debugPrint("AUTO SCHEDULE BODY : ${response.body}");

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final json = jsonDecode(utf8.decode(response.bodyBytes));
//         final bool autoScheduled = json["autoScheduled"] ?? false;
//         final bool manualRequired = json["manualRequired"] ?? false;

//         if (autoScheduled) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 json["message"] ?? "$requestType successful",
//               ),
//             ),
//           );
//           fetchTodayClasses();
//         } else if (manualRequired) {
//           setState(() => loading = false);
//           openManualDialog(requestId, requestType);
//         }
//       } else {
//         setState(() => loading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               ApiClient.messageFromBody(response.body) ??
//                   "Unable to $requestType",
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint("AUTO SCHEDULE ERROR : $e");
//       if (mounted) {
//         setState(() => loading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString())),
//         );
//       }
//     }
//   }

//   // =====================================================
//   // MANUAL SCHEDULE DIALOG
//   // =====================================================

//   void openManualDialog(int requestId, String requestType) {
//     final days = [
//       "Monday", "Tuesday", "Wednesday",
//       "Thursday", "Friday", "Saturday", "Sunday",
//     ];

//     String selectedDay = days.first;
//     TimeOfDay selectedTime = TimeOfDay.now();
//     DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               title: Text(
//                 "Manual $requestType",
//                 style: const TextStyle(
//                   color: Colors.teal,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "No common slot found. Please pick a day, date and time.",
//                       style: TextStyle(fontSize: 13, color: Colors.grey),
//                     ),
//                     const SizedBox(height: 20),

//                     // DAY
//                     const Text("Day",
//                         style: TextStyle(fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 6),
//                     DropdownButtonFormField<String>(
//                       value: selectedDay,
//                       decoration: const InputDecoration(
//                         border: OutlineInputBorder(),
//                         contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                       ),
//                       items: days
//                           .map((d) =>
//                               DropdownMenuItem(value: d, child: Text(d)))
//                           .toList(),
//                       onChanged: (val) {
//                         setDialogState(() => selectedDay = val!);
//                       },
//                     ),

//                     const SizedBox(height: 16),

//                     // DATE
//                     const Text("Date",
//                         style: TextStyle(fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 6),
//                     InkWell(
//                       onTap: () async {
//                         final picked = await showDatePicker(
//                           context: context,
//                           initialDate: selectedDate,
//                           firstDate: DateTime.now(),
//                           lastDate:
//                               DateTime.now().add(const Duration(days: 365)),
//                         );
//                         if (picked != null) {
//                           setDialogState(() => selectedDate = picked);
//                         }
//                       },
//                       child: InputDecorator(
//                         decoration: const InputDecoration(
//                           border: OutlineInputBorder(),
//                           contentPadding: EdgeInsets.symmetric(
//                               horizontal: 12, vertical: 14),
//                         ),
//                         child: Text(
//                           "${selectedDate.year}-"
//                           "${selectedDate.month.toString().padLeft(2, '0')}-"
//                           "${selectedDate.day.toString().padLeft(2, '0')}",
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     // TIME
//                     const Text("Time",
//                         style: TextStyle(fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 6),
//                     InkWell(
//                       onTap: () async {
//                         final picked = await showTimePicker(
//                           context: context,
//                           initialTime: selectedTime,
//                         );
//                         if (picked != null) {
//                           setDialogState(() => selectedTime = picked);
//                         }
//                       },
//                       child: InputDecorator(
//                         decoration: const InputDecoration(
//                           border: OutlineInputBorder(),
//                           contentPadding: EdgeInsets.symmetric(
//                               horizontal: 12, vertical: 14),
//                         ),
//                         child: Text(selectedTime.format(context)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                   ),
//                   onPressed: () async {
//                     Navigator.pop(context);
//                     await manualSchedule(
//                       requestId: requestId,
//                       requestType: requestType,
//                       day: selectedDay,
//                       time: selectedTime.format(context),
//                       date: selectedDate,
//                     );
//                   },
//                   child: const Text(
//                     "Send Request",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   // =====================================================
//   // MANUAL SCHEDULE API
//   // =====================================================

//   Future<void> manualSchedule({
//     required int requestId,
//     required String requestType,
//     required String day,
//     required String time,
//     required DateTime date,
//   }) async {
//     try {
//       final response = await ApiClient.post(
//         '/api/Tutor/manual-schedule',
//         {
//           "requestId": requestId,
//           "requestType": requestType,
//           "day": day,
//           "time": time,
//           "classDate": date.toIso8601String(),
//         },
//       );

//       debugPrint("MANUAL STATUS : ${response.statusCode}");
//       debugPrint("MANUAL BODY : ${response.body}");

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Schedule request sent to student."),
//           ),
//         );
//         fetchTodayClasses();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               ApiClient.messageFromBody(response.body) ??
//                   "Unable to send request",
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint("MANUAL ERROR : $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString())),
//         );
//       }
//     }
//   }

//   // =====================================================
//   // NAVIGATION
//   // =====================================================

//   void navigateScreen(int value) {
//     if (value == 0) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const TutorHome()),
//       );
//     } else if (value == 1) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const TutorStudentRequest()),
//       );
//     } else if (value == 2) {
//       return;
//     } else if (value == 3) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const TutorAddSubject()),
//       );
//     }
//   }

//   // =====================================================
//   // BUTTON WIDGET
//   // =====================================================

//   Widget buildButton({
//     required String text,
//     required VoidCallback onTap,
//     Color color = Colors.teal,
//   }) {
//     return SizedBox(
//       height: 42,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color,
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(25),
//           ),
//         ),
//         onPressed: onTap,
//         child: Text(
//           text,
//           style: const TextStyle(color: Colors.white, fontSize: 14),
//         ),
//       ),
//     );
//   }

//   // =====================================================
//   // CLASS CARD
//   // =====================================================

//   Widget classCard(dynamic data) {
//     final int requestId =
//         (data["request_id"] as num?)?.toInt() ?? 0;
//     final String time = data["time"]?.toString() ?? "";
//     final String student = data["student_name"]?.toString() ?? "";
//     final String subject = data["course_name"]?.toString() ?? "";

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [

//           // TIME
//           Text(
//             time,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.teal,
//             ),
//           ),

//           const SizedBox(height: 10),

//           // STUDENT
//           Text(
//             "Student: $student",
//             style: const TextStyle(fontSize: 16),
//           ),

//           const SizedBox(height: 4),

//           // SUBJECT
//           Text(
//             "Subject: $subject",
//             style: const TextStyle(fontSize: 16),
//           ),

//           const SizedBox(height: 18),

//           // BUTTONS
//           Wrap(
//             spacing: 10,
//             runSpacing: 10,
//             children: [

//               // COMPLETE
//               buildButton(
//                 text: "Complete",
//                 color: const Color(0xff2DB55D),
//                 onTap: () => completeClass(requestId),
//               ),

//               // PRE-SCHEDULE
//               buildButton(
//                 text: "Pre-Schedule",
//                 color: const Color(0xff9B51E0),
//                 onTap: () => autoSchedule(
//                   requestId: requestId,
//                   requestType: "Preschedule",
//                 ),
//               ),

//               // RE-SCHEDULE
//               buildButton(
//                 text: "Re-Schedule",
//                 color: const Color(0xff2F80ED),
//                 onTap: () => autoSchedule(
//                   requestId: requestId,
//                   requestType: "Reschedule",
//                 ),
//               ),

//               // CANCEL
//               buildButton(
//                 text: "Cancel",
//                 color: Colors.red,
//                 onTap: () => cancelClass(requestId),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // =====================================================
//   // UI
//   // =====================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xfff7f1f8),
//       drawer: const TutorDrawer(),

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         iconTheme: const IconThemeData(color: Colors.teal),
//         centerTitle: true,
//         toolbarHeight: 90,
//         title: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Image.asset("assets/images/logo.png", height: 45),
//             const SizedBox(height: 5),
//             const Text(
//               "House of Tutor",
//               style: TextStyle(
//                 color: Colors.teal,
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),

//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : classes.isEmpty
//               ? const Center(
//                   child: Text(
//                     "No Classes Today",
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                 )
//               : RefreshIndicator(
//                   onRefresh: fetchTodayClasses,
//                   child: ListView.builder(
//                     padding: const EdgeInsets.only(top: 10, bottom: 20),
//                     itemCount: classes.length,
//                     itemBuilder: (context, index) {
//                       return classCard(classes[index]);
//                     },
//                   ),
//                 ),

//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: currentIndex,
//         selectedItemColor: Colors.teal,
//         unselectedItemColor: Colors.grey,
//         type: BottomNavigationBarType.fixed,
//         onTap: (value) {
//           setState(() => currentIndex = value);
//           navigateScreen(value);
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.calendar_month),
//             label: "Schedule",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.menu_book),
//             label: "Request",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.class_),
//             label: "Today Class",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.add_box),
//             label: "Add Subject",
//           ),
//         ],
//       ),
//     );
//   }
// }



































// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:house_of_tutor/TutorAddSubject.dart';
// // import 'package:house_of_tutor/TutorDrawer.dart';
// // import 'package:house_of_tutor/TutorHome.dart';
// // import 'package:house_of_tutor/TutorStudentRequest.dart';
// // import 'package:house_of_tutor/services/api_client.dart';

// // class TutorTodayClasses extends StatefulWidget {
// //   const TutorTodayClasses({super.key});

// //   @override
// //   State<TutorTodayClasses> createState() => _TutorTodayClassesState();
// // }

// // class _TutorTodayClassesState extends State<TutorTodayClasses> {

// //   int currentIndex = 2;
// //   bool loading = true;
// //   List<dynamic> classes = [];

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchTodayClasses();
// //   }

// //   // =====================================================
// //   // FETCH TODAY CLASSES
// //   // =====================================================

// //   Future<void> fetchTodayClasses() async {
// //     try {
// //       setState(() => loading = true);

// //       final response = await ApiClient.get('/api/Tutor/today-classes');

// //       debugPrint("TODAY STATUS : ${response.statusCode}");
// //       debugPrint("TODAY BODY : ${response.body}");

// //       classes = [];

// //       if (response.statusCode == 200) {
// //         final decoded = jsonDecode(utf8.decode(response.bodyBytes));

// //         if (decoded is Map &&
// //             decoded["data"] != null &&
// //             decoded["data"] is List) {
// //           classes = List<dynamic>.from(decoded["data"]);
// //         }
// //       } else {
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text(
// //                 ApiClient.messageFromBody(response.body) ??
// //                     "Failed to load classes",
// //               ),
// //             ),
// //           );
// //         }
// //       }
// //     } catch (e) {
// //       debugPrint("TODAY ERROR : $e");
// //       classes = [];
// //     }

// //     if (mounted) setState(() => loading = false);
// //   }

// //   // =====================================================
// //   // COMPLETE CLASS
// //   // =====================================================

// //   Future<void> completeClass(int requestId) async {
// //     try {
// //       final response = await ApiClient.put(
// //         '/api/Tutor/complete-class/$requestId',
// //         {}, body: {},
// //       );

// //       debugPrint("COMPLETE STATUS : ${response.statusCode}");
// //       debugPrint("COMPLETE BODY : ${response.body}");

// //       if (!mounted) return;

// //       if (response.statusCode == 200) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Class marked as Complete")),
// //         );
// //         fetchTodayClasses();
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               ApiClient.messageFromBody(response.body) ?? "Failed",
// //             ),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       debugPrint("COMPLETE ERROR : $e");
// //     }
// //   }

// //   // =====================================================
// //   // CANCEL CLASS
// //   // =====================================================

// //   Future<void> cancelClass(int requestId) async {
// //     try {
// //       final response = await ApiClient.put(
// //         '/api/Tutor/cancel-class/$requestId',
// //         {}, body: {},
// //       );

// //       debugPrint("CANCEL STATUS : ${response.statusCode}");
// //       debugPrint("CANCEL BODY : ${response.body}");

// //       if (!mounted) return;

// //       if (response.statusCode == 200) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Class Cancelled")),
// //         );
// //         fetchTodayClasses();
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               ApiClient.messageFromBody(response.body) ?? "Failed",
// //             ),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       debugPrint("CANCEL ERROR : $e");
// //     }
// //   }

// //   // =====================================================
// //   // AUTO SCHEDULE (Pre / Re)
// //   // =====================================================

// //   Future<void> autoSchedule({
// //     required int requestId,
// //     required String requestType,
// //   }) async {
// //     try {
// //       setState(() => loading = true);

// //       // ✅ FIX: sahi endpoints
// //       final endpoint = requestType == "Preschedule"
// //           ? '/api/Tutor/preschedule'
// //           : '/api/Tutor/reschedule';

// //       final response = await ApiClient.post(endpoint, {
// //         "requestId": requestId,
// //       });

// //       debugPrint("AUTO SCHEDULE STATUS : ${response.statusCode}");
// //       debugPrint("AUTO SCHEDULE BODY : ${response.body}");

// //       if (!mounted) return;

// //       if (response.statusCode == 200) {
// //         final json = jsonDecode(utf8.decode(response.bodyBytes));
// //         final bool autoScheduled = json["autoScheduled"] ?? false;
// //         final bool manualRequired = json["manualRequired"] ?? false;

// //         if (autoScheduled) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text(
// //                 json["message"] ?? "$requestType successful",
// //               ),
// //             ),
// //           );
// //           fetchTodayClasses();
// //         } else if (manualRequired) {
// //           setState(() => loading = false);
// //           openManualDialog(requestId, requestType);
// //         }
// //       } else {
// //         setState(() => loading = false);
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               ApiClient.messageFromBody(response.body) ??
// //                   "Unable to $requestType",
// //             ),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       debugPrint("AUTO SCHEDULE ERROR : $e");
// //       if (mounted) {
// //         setState(() => loading = false);
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text(e.toString())),
// //         );
// //       }
// //     }
// //   }

// //   // =====================================================
// //   // MANUAL SCHEDULE DIALOG
// //   // =====================================================

// //   void openManualDialog(int requestId, String requestType) {
// //     final days = [
// //       "Monday", "Tuesday", "Wednesday",
// //       "Thursday", "Friday", "Saturday", "Sunday",
// //     ];

// //     String selectedDay = days.first;
// //     TimeOfDay selectedTime = TimeOfDay.now();
// //     DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) {
// //         return StatefulBuilder(
// //           builder: (context, setDialogState) {
// //             return AlertDialog(
// //               shape: RoundedRectangleBorder(
// //                 borderRadius: BorderRadius.circular(20),
// //               ),
// //               title: Text(
// //                 "Manual $requestType",
// //                 style: const TextStyle(
// //                   color: Colors.teal,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               content: SingleChildScrollView(
// //                 child: Column(
// //                   mainAxisSize: MainAxisSize.min,
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "No common slot found. Please pick a day, date and time.",
// //                       style: TextStyle(fontSize: 13, color: Colors.grey),
// //                     ),
// //                     const SizedBox(height: 20),

// //                     // DAY
// //                     const Text("Day",
// //                         style: TextStyle(fontWeight: FontWeight.bold)),
// //                     const SizedBox(height: 6),
// //                     DropdownButtonFormField<String>(
// //                       value: selectedDay,
// //                       decoration: const InputDecoration(
// //                         border: OutlineInputBorder(),
// //                         contentPadding: EdgeInsets.symmetric(horizontal: 12),
// //                       ),
// //                       items: days
// //                           .map((d) =>
// //                               DropdownMenuItem(value: d, child: Text(d)))
// //                           .toList(),
// //                       onChanged: (val) {
// //                         setDialogState(() => selectedDay = val!);
// //                       },
// //                     ),

// //                     const SizedBox(height: 16),

// //                     // DATE
// //                     const Text("Date",
// //                         style: TextStyle(fontWeight: FontWeight.bold)),
// //                     const SizedBox(height: 6),
// //                     InkWell(
// //                       onTap: () async {
// //                         final picked = await showDatePicker(
// //                           context: context,
// //                           initialDate: selectedDate,
// //                           firstDate: DateTime.now(),
// //                           lastDate:
// //                               DateTime.now().add(const Duration(days: 365)),
// //                         );
// //                         if (picked != null) {
// //                           setDialogState(() => selectedDate = picked);
// //                         }
// //                       },
// //                       child: InputDecorator(
// //                         decoration: const InputDecoration(
// //                           border: OutlineInputBorder(),
// //                           contentPadding: EdgeInsets.symmetric(
// //                               horizontal: 12, vertical: 14),
// //                         ),
// //                         child: Text(
// //                           "${selectedDate.year}-"
// //                           "${selectedDate.month.toString().padLeft(2, '0')}-"
// //                           "${selectedDate.day.toString().padLeft(2, '0')}",
// //                         ),
// //                       ),
// //                     ),

// //                     const SizedBox(height: 16),

// //                     // TIME
// //                     const Text("Time",
// //                         style: TextStyle(fontWeight: FontWeight.bold)),
// //                     const SizedBox(height: 6),
// //                     InkWell(
// //                       onTap: () async {
// //                         final picked = await showTimePicker(
// //                           context: context,
// //                           initialTime: selectedTime,
// //                         );
// //                         if (picked != null) {
// //                           setDialogState(() => selectedTime = picked);
// //                         }
// //                       },
// //                       child: InputDecorator(
// //                         decoration: const InputDecoration(
// //                           border: OutlineInputBorder(),
// //                           contentPadding: EdgeInsets.symmetric(
// //                               horizontal: 12, vertical: 14),
// //                         ),
// //                         child: Text(selectedTime.format(context)),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               actions: [
// //                 TextButton(
// //                   onPressed: () => Navigator.pop(context),
// //                   child: const Text("Cancel"),
// //                 ),
// //                 ElevatedButton(
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Colors.teal,
// //                   ),
// //                   onPressed: () async {
// //                     Navigator.pop(context);
// //                     await manualSchedule(
// //                       requestId: requestId,
// //                       requestType: requestType,
// //                       day: selectedDay,
// //                       time: selectedTime.format(context),
// //                       date: selectedDate,
// //                     );
// //                   },
// //                   child: const Text(
// //                     "Send Request",
// //                     style: TextStyle(color: Colors.white),
// //                   ),
// //                 ),
// //               ],
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }

// //   // =====================================================
// //   // MANUAL SCHEDULE API
// //   // =====================================================

// //   Future<void> manualSchedule({
// //     required int requestId,
// //     required String requestType,
// //     required String day,
// //     required String time,
// //     required DateTime date,
// //   }) async {
// //     try {
// //       final response = await ApiClient.post(
// //         '/api/Tutor/manual-schedule',
// //         {
// //           "requestId": requestId,
// //           "requestType": requestType,
// //           "day": day,
// //           "time": time,
// //           "classDate": date.toIso8601String(),
// //         },
// //       );

// //       debugPrint("MANUAL STATUS : ${response.statusCode}");
// //       debugPrint("MANUAL BODY : ${response.body}");

// //       if (!mounted) return;

// //       if (response.statusCode == 200) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Schedule request sent to student."),
// //           ),
// //         );
// //         fetchTodayClasses();
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               ApiClient.messageFromBody(response.body) ??
// //                   "Unable to send request",
// //             ),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       debugPrint("MANUAL ERROR : $e");
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text(e.toString())),
// //         );
// //       }
// //     }
// //   }

// //   // =====================================================
// //   // NAVIGATION
// //   // =====================================================

// //   void navigateScreen(int value) {
// //     if (value == 0) {
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(builder: (_) => const TutorHome()),
// //       );
// //     } else if (value == 1) {
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(builder: (_) => TutorStudentRequest()),
// //       );
// //     } else if (value == 2) {
// //       return;
// //     } else if (value == 3) {
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(builder: (_) => TutorAddSubject()),
// //       );
// //     }
// //   }

// //   // =====================================================
// //   // BUTTON WIDGET
// //   // =====================================================

// //   Widget buildButton({
// //     required String text,
// //     required VoidCallback onTap,
// //     Color color = Colors.teal,
// //   }) {
// //     return SizedBox(
// //       height: 42,
// //       child: ElevatedButton(
// //         style: ElevatedButton.styleFrom(
// //           backgroundColor: color,
// //           padding: const EdgeInsets.symmetric(horizontal: 16),
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(25),
// //           ),
// //         ),
// //         onPressed: onTap,
// //         child: Text(
// //           text,
// //           style: const TextStyle(color: Colors.white, fontSize: 14),
// //         ),
// //       ),
// //     );
// //   }

// //   // =====================================================
// //   // CLASS CARD
// //   // =====================================================

// //   Widget classCard(dynamic data) {
// //     final int requestId =
// //         (data["request_id"] as num?)?.toInt() ?? 0;
// //     final String time = data["time"]?.toString() ?? "";
// //     final String student = data["student_name"]?.toString() ?? "";
// //     final String subject = data["course_name"]?.toString() ?? "";

// //     return Container(
// //       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.05),
// //             blurRadius: 6,
// //             offset: const Offset(0, 3),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [

// //           // TIME
// //           Text(
// //             time,
// //             style: const TextStyle(
// //               fontSize: 18,
// //               fontWeight: FontWeight.w600,
// //               color: Colors.teal,
// //             ),
// //           ),

// //           const SizedBox(height: 10),

// //           // STUDENT
// //           Text(
// //             "Student: $student",
// //             style: const TextStyle(fontSize: 16),
// //           ),

// //           const SizedBox(height: 4),

// //           // SUBJECT
// //           Text(
// //             "Subject: $subject",
// //             style: const TextStyle(fontSize: 16),
// //           ),

// //           const SizedBox(height: 18),

// //           // BUTTONS
// //           Wrap(
// //             spacing: 10,
// //             runSpacing: 10,
// //             children: [

// //               // COMPLETE
// //               buildButton(
// //                 text: "Complete",
// //                 color: const Color(0xff2DB55D),
// //                 onTap: () => completeClass(requestId),
// //               ),

// //               // PRE-SCHEDULE
// //               buildButton(
// //                 text: "Pre-Schedule",
// //                 color: const Color(0xff9B51E0),
// //                 onTap: () => autoSchedule(
// //                   requestId: requestId,
// //                   requestType: "Preschedule",
// //                 ),
// //               ),

// //               // RE-SCHEDULE
// //               buildButton(
// //                 text: "Re-Schedule",
// //                 color: const Color(0xff2F80ED),
// //                 onTap: () => autoSchedule(
// //                   requestId: requestId,
// //                   requestType: "Reschedule",
// //                 ),
// //               ),

// //               // CANCEL
// //               buildButton(
// //                 text: "Cancel",
// //                 color: Colors.red,
// //                 onTap: () => cancelClass(requestId),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // =====================================================
// //   // UI
// //   // =====================================================

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xfff7f1f8),
// //       drawer: const TutorDrawer(),

// //       appBar: AppBar(
// //         backgroundColor: Colors.white,
// //         elevation: 1,
// //         iconTheme: const IconThemeData(color: Colors.teal),
// //         centerTitle: true,
// //         toolbarHeight: 90,
// //         title: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Image.asset("assets/images/logo.png", height: 45),
// //             const SizedBox(height: 5),
// //             const Text(
// //               "House of Tutor",
// //               style: TextStyle(
// //                 color: Colors.teal,
// //                 fontSize: 22,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),

// //       body: loading
// //           ? const Center(child: CircularProgressIndicator())
// //           : classes.isEmpty
// //               ? const Center(
// //                   child: Text(
// //                     "No Classes Today",
// //                     style: TextStyle(fontSize: 16, color: Colors.grey),
// //                   ),
// //                 )
// //               : RefreshIndicator(
// //                   onRefresh: fetchTodayClasses,
// //                   child: ListView.builder(
// //                     padding: const EdgeInsets.only(top: 10, bottom: 20),
// //                     itemCount: classes.length,
// //                     itemBuilder: (context, index) {
// //                       return classCard(classes[index]);
// //                     },
// //                   ),
// //                 ),

// //       bottomNavigationBar: BottomNavigationBar(
// //         currentIndex: currentIndex,
// //         selectedItemColor: Colors.teal,
// //         unselectedItemColor: Colors.grey,
// //         type: BottomNavigationBarType.fixed,
// //         onTap: (value) {
// //           setState(() => currentIndex = value);
// //           navigateScreen(value);
// //         },
// //         items: const [
// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.calendar_month),
// //             label: "Schedule",
// //           ),
// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.menu_book),
// //             label: "Request",
// //           ),
// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.class_),
// //             label: "Today Class",
// //           ),
// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.add_box),
// //             label: "Add Subject",
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }













































// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:house_of_tutor/TutorAddSubject.dart';
// // import 'package:house_of_tutor/TutorDrawer.dart';
// // import 'package:house_of_tutor/TutorHome.dart';
// // import 'package:house_of_tutor/TutorStudentRequest.dart';
// // import 'package:house_of_tutor/services/api_client.dart';

// // class TutorTodayClasses extends StatefulWidget {

// //   const TutorTodayClasses({
// //     super.key,
// //   });

// //   @override
// //   State<TutorTodayClasses> createState() =>
// //       _TutorTodayClassesState();
// // }

// // class _TutorTodayClassesState
// //     extends State<TutorTodayClasses> {
// //   // STATES
// //   int currentIndex = 2;

// //   bool loading = true;

// //   List<dynamic> classes = [];

// //   @override
// //   void initState() {
// //     super.initState();

// //     fetchTodayClasses();
// //   }

// //   Future<void> fetchTodayClasses() async {
// //   try {
// //     setState(() {
// //       loading = true;
// //     });

// //     final response =
// //         await ApiClient.get('/api/Tutor/today-classes');

// //     debugPrint("TODAY STATUS : ${response.statusCode}");
// //     debugPrint("TODAY BODY : ${response.body}");

// //     if (response.statusCode == 200) {
// //       final decoded =
// //           jsonDecode(utf8.decode(response.bodyBytes));

// //       debugPrint("JSON TYPE : ${decoded.runtimeType}");

// //       classes = [];

// //       if (decoded is Map &&
// //           decoded["data"] != null &&
// //           decoded["data"] is List) {
// //         classes = List<dynamic>.from(decoded["data"]);

// //         debugPrint(
// //             "TOTAL CLASSES : ${classes.length}");

// //         for (var c in classes) {
// //           debugPrint(c.toString());
// //         }
// //       }

// //       debugPrint(
// //           "FINAL CLASS COUNT : ${classes.length}");
// //     } else {
// //       classes = [];
// //     }
// //   } catch (e) {
// //     debugPrint("TODAY ERROR : $e");
// //     classes = [];
// //   }

// //   if (mounted) {
// //     setState(() {
// //       loading = false;
// //     });
// //   }
// // }
// //   // =====================================================
// //   // COMPLETE CLASS
// //   // =====================================================

// //   Future<void> completeClass(
// //     int requestId,
// //   ) async {

// //     try {

// //       final response =
// //           await ApiClient.put(
// //         '/api/Tutor/complete-class/$requestId',
// //         {},
// //       );

// //       if (response.statusCode == 200) {

// //         ScaffoldMessenger.of(context)
// //             .showSnackBar(
// //           const SnackBar(
// //             content: Text(
// //               "Class Completed",
// //             ),
// //           ),
// //         );

// //         fetchTodayClasses();

// //       } else {

// //         ScaffoldMessenger.of(context)
// //             .showSnackBar(
// //           const SnackBar(
// //             content: Text(
// //               "Failed",
// //             ),
// //           ),
// //         );
// //       }

// //     } catch (e) {

// //       debugPrint(
// //         "COMPLETE ERROR : $e",
// //       );
// //     }
// //   }
// //   // CANCEL CLASS
 
// //   Future<void> cancelClass(
// //     int requestId,
// //   ) async {

// //     try {

// //       final response =
// //           await ApiClient.put(
// //         '/api/Tutor/cancel-class/$requestId',
// //         {},
// //       );

// //       if (response.statusCode == 200) {

// //         ScaffoldMessenger.of(context)
// //             .showSnackBar(
// //           const SnackBar(
// //             content: Text(
// //               "Class Cancelled",
// //             ),
// //           ),
// //         );

// //         fetchTodayClasses();

// //       } else {

// //         ScaffoldMessenger.of(context)
// //             .showSnackBar(
// //           const SnackBar(
// //             content: Text(
// //               "Failed",
// //             ),
// //           ),
// //         );
// //       }

// //     } catch (e) {

// //       debugPrint(
// //         "CANCEL ERROR : $e",
// //       );
// //     }
// //   }

// //   Future<void> createSchedule({

// //     required int requestId,

// //     required String type,
// //   }) async {

// //     try {

// //       final payload = {
// //         "parentRequestId":
// //             requestId,
// //       };

// //       final endpoint =
// //           type == "Pre"

// //               ? '/api/Tutor/create-preschedule'

// //               : '/api/Tutor/create-reschedule';

// //       final response =
// //           await ApiClient.post(
// //         endpoint,
// //         payload,
// //       );

// //       if (response.statusCode == 200) {

// //         ScaffoldMessenger.of(context)
// //             .showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               "$type-Schedule Sent",
// //             ),
// //           ),
// //         );

// //       } else {

// //         ScaffoldMessenger.of(context)
// //             .showSnackBar(
// //           const SnackBar(
// //             content: Text(
// //               "Failed",
// //             ),
// //           ),
// //         );
// //       }

// //     } catch (e) {

// //       debugPrint(
// //         "SCHEDULE ERROR : $e",
// //       );
// //     }
// //   }

// //   // NAVIGATION
// //   void navigateScreen(int value) {

// //     if (value == 0) {

// //       Navigator.pushReplacement(

// //         context,

// //         MaterialPageRoute(
// //           builder: (_) =>
// //               const TutorHome(teacherName: '',),
// //         ),
// //       );
// //     }

// //     if (value == 1) {

// //       Navigator.pushReplacement(

// //         context,

// //         MaterialPageRoute(
// //           builder: (_) =>
// //                TutorStudentRequest(),
// //         ),
// //       );
// //     }

// //     if (value == 2) {

// //       return;
// //     }

// //     if (value == 3) {

// //       Navigator.pushReplacement(

// //         context,

// //         MaterialPageRoute(
// //           builder: (_) =>
// //     TutorAddSubject(),
// //         ),
// //       );
// //     }
// //   }

// //   // BUTTON
// //   Widget buildButton({

// //     required String text,

// //     required VoidCallback onTap,
// //   }) {

// //     return SizedBox(

// //       height: 42,

// //       child: ElevatedButton(

// //         style:
// //             ElevatedButton.styleFrom(

// //           backgroundColor:
// //               Colors.teal,

// //           padding:
// //               const EdgeInsets
// //                   .symmetric(
// //             horizontal: 16,
// //           ),

// //           shape:
// //               RoundedRectangleBorder(

// //             borderRadius:
// //                 BorderRadius.circular(
// //                     25),
// //           ),
// //         ),

// //         onPressed: onTap,

// //         child: Text(

// //           text,

// //           style: const TextStyle(

// //             color: Colors.white,

// //             fontSize: 16,
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   // CLASS CARD

// //   Widget classCard(
// //     dynamic data,
// //   ) {

// //     final requestId =
// //         data["request_id"];

// //     final time =
// //         data["time"]
// //                 ?.toString() ??
// //             "";

// //     final student =
// //         data["student_name"]
// //                 ?.toString() ??
// //             "";

// //     final subject =
// //         data["course_name"]
// //                 ?.toString() ??
// //             "";

// //     return Container(

// //       margin:
// //           const EdgeInsets.symmetric(
// //         horizontal: 12,
// //         vertical: 8,
// //       ),

// //       padding:
// //           const EdgeInsets.all(16),

// //       decoration: BoxDecoration(

// //         color: Colors.white,

// //         borderRadius:
// //             BorderRadius.circular(
// //                 10),
// //       ),

// //       child: Column(

// //         crossAxisAlignment:
// //             CrossAxisAlignment
// //                 .start,

// //         children: [

// //           // TIME

// //           Text(

// //             time,

// //             style:
// //                 const TextStyle(

// //               fontSize: 18,

// //               fontWeight:
// //                   FontWeight.w500,
// //             ),
// //           ),

// //           const SizedBox(
// //               height: 10),

// //           // STUDENT

// //           Text(

// //             "Student: $student",

// //             style:
// //                 const TextStyle(
// //               fontSize: 16,
// //             ),
// //           ),

// //           const SizedBox(
// //               height: 4),

// //           // SUBJECT

// //           Text(

// //             "Subject : $subject",

// //             style:
// //                 const TextStyle(
// //               fontSize: 16,
// //             ),
// //           ),

// //           const SizedBox(
// //               height: 18),

// //           // BUTTONS

// //           Wrap(

// //             spacing: 10,

// //             runSpacing: 10,

// //             children: [

// //               // COMPLETE

// //               buildButton(

// //                 text: "Complete",

// //                 onTap: () {

// //                   completeClass(
// //                     requestId,
// //                   );
// //                 },
// //               ),

// //               // PRE-SCHEDULE

// //               buildButton(

// //                 text:
// //                     "Pre-Schedule",

// //                 onTap: () {

// //                   createSchedule(

// //                     requestId:
// //                         requestId,

// //                     type: "Pre",
// //                   );
// //                 },
// //               ),

// //               // RE-SCHEDULE

// //               buildButton(

// //                 text:
// //                     "Re-Schedule",

// //                 onTap: () {

// //                   createSchedule(

// //                     requestId:
// //                         requestId,

// //                     type: "Re",
// //                   );
// //                 },
// //               ),

// //               // CANCEL

// //               buildButton(

// //                 text: "Cancel",

// //                 onTap: () {

// //                   cancelClass(
// //                     requestId,
// //                   );
// //                 },
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {

// //     return Scaffold(

// //       backgroundColor:
// //           const Color(0xfff7f1f8),

// //       drawer: const TutorDrawer(),

// //       appBar: AppBar(

// //         backgroundColor:
// //             Colors.white,

// //         elevation: 1,

// //         iconTheme:
// //             const IconThemeData(
// //           color: Colors.teal,
// //         ),

// //         centerTitle: true,

// //         toolbarHeight: 90,

// //         title: Column(

// //           mainAxisAlignment:
// //               MainAxisAlignment
// //                   .center,

// //           children: [

// //             Image.asset(
// //               "assets/images/logo.png",
// //               height: 45,
// //             ),

// //             const SizedBox(
// //                 height: 5),

// //             const Text(

// //               "House of Tutor",

// //               style: TextStyle(

// //                 color: Colors.teal,

// //                 fontSize: 22,

// //                 fontWeight:
// //                     FontWeight.bold,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),

// //       // =================================================
// //       // BODY
// //       // =================================================

// //       body: loading

// //           ? const Center(
// //               child:
// //                   CircularProgressIndicator(),
// //             )

// //           : classes.isEmpty

// //               ? const Center(
// //                   child: Text(
// //                     "No Classes Found",
// //                   ),
// //                 )

// //               : RefreshIndicator(

// //                   onRefresh:
// //                       fetchTodayClasses,

// //                   child:
// //                       ListView.builder(

// //                     padding:
// //                         const EdgeInsets.only(
// //                       top: 10,
// //                       bottom: 20,
// //                     ),

// //                     itemCount:
// //                         classes.length,

// //                     itemBuilder:
// //                         (context,
// //                             index) {

// //                       return classCard(
// //                         classes[index],
// //                       );
// //                     },
// //                   ),
// //                 ),

// //       // =================================================
// //       // BOTTOM NAVIGATION
// //       // =================================================

// //       bottomNavigationBar:
// //           BottomNavigationBar(

// //         currentIndex:
// //             currentIndex,

// //         selectedItemColor:
// //             Colors.blue,

// //         unselectedItemColor:
// //             Colors.grey,

// //         type:
// //             BottomNavigationBarType
// //                 .fixed,

// //         onTap: (value) {

// //           setState(() {
// //             currentIndex = value;
// //           });

// //           navigateScreen(value);
// //         },

// //         items: const [

// //           BottomNavigationBarItem(
// //             icon:
// //                 Icon(Icons.calendar_month),
// //             label: "Schedule",
// //           ),

// //           BottomNavigationBarItem(
// //             icon:
// //                 Icon(Icons.menu_book),
// //             label: "Request",
// //           ),

// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.class_),
// //             label: "Today Class",
// //           ),

// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.add_box),
// //             label: "Add Subject",
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

















































































// // // import 'dart:convert';
// // // import 'package:flutter/material.dart';
// // // import 'package:house_of_tutor/TutorAddSubject.dart';
// // // import 'package:house_of_tutor/TutorDrawer.dart';
// // // import 'package:house_of_tutor/TutorHome.dart';
// // // import 'package:house_of_tutor/TutorStudentRequest.dart';
// // // import 'package:house_of_tutor/services/api_client.dart';

// // // class TutorTodayClasses extends StatefulWidget {

// // //   const TutorTodayClasses({
// // //     super.key,
// // //     required this.teacherName,
// // //   });

// // //   final String teacherName;

// // //   @override
// // //   State<TutorTodayClasses> createState() =>
// // //       _TutorTodayClassesState();
// // // }

// // // class _TutorTodayClassesState
// // //     extends State<TutorTodayClasses> {

// // //   // =========================================
// // //   // STATES
// // //   // =========================================

// // //   int currentIndex = 2;

// // //   bool loading = true;

// // //   List<Map<String, dynamic>>
// // //       classes = [];

// // //   // =========================================
// // //   // INIT
// // //   // =========================================

// // //   @override
// // //   void initState() {
// // //     super.initState();

// // //     fetchClasses();
// // //   }

// // //   // =========================================
// // //   // FETCH CLASSES
// // //   // =========================================

// // //   Future<void> fetchClasses() async {

// // //     try {

// // //       setState(() {
// // //         loading = true;
// // //       });

// // //       final response =
// // //           await ApiClient.get(
// // //         '/api/Tutor/today-classes',
// // //       );

// // //       debugPrint(
// // //         "TODAY STATUS : ${response.statusCode}",
// // //       );

// // //       debugPrint(
// // //         "TODAY BODY : ${response.body}",
// // //       );

// // //       if (response.statusCode == 200) {

// // //         final decoded = jsonDecode(
// // //           utf8.decode(
// // //             response.bodyBytes,
// // //           ),
// // //         );

// // //         if (decoded is List) {

// // //           classes = decoded
// // //               .whereType<Map>()
// // //               .map<Map<String, dynamic>>(
// // //                   (e) {

// // //             final fullTime =
// // //                 e["time"]
// // //                         ?.toString() ??
// // //                     "";

// // //             String day = "";

// // //             String time = fullTime;

// // //             if (fullTime.contains(",")) {

// // //               final parts =
// // //                   fullTime.split(",");

// // //               day =
// // //                   parts.first.trim();

// // //               time = parts
// // //                   .sublist(1)
// // //                   .join(",")
// // //                   .trim();
// // //             }

// // //             return {

// // //               "request_id":
// // //                   int.tryParse(
// // //                         e["request_id"]
// // //                                 ?.toString() ??
// // //                             e["requestId"]
// // //                                 ?.toString() ??
// // //                             "0",
// // //                       ) ??
// // //                       0,

// // //               "student_name":
// // //                   e["student_name"]
// // //                           ?.toString() ??
// // //                       e["studentName"]
// // //                           ?.toString() ??
// // //                       "",

// // //               "course_name":
// // //                   e["course_name"]
// // //                           ?.toString() ??
// // //                       e["courseName"]
// // //                           ?.toString() ??
// // //                       "",

// // //               "day": day,

// // //               "time": time,
// // //             };

// // //           }).toList();
// // //         }
// // //       }

// // //     } catch (e) {

// // //       debugPrint(
// // //         "FETCH ERROR : $e",
// // //       );

// // //       ScaffoldMessenger.of(context)
// // //           .showSnackBar(
// // //         SnackBar(
// // //           content: Text(
// // //             "Error : $e",
// // //           ),
// // //         ),
// // //       );
// // //     }

// // //     if (mounted) {

// // //       setState(() {
// // //         loading = false;
// // //       });
// // //     }
// // //   }

// // //   // =========================================
// // //   // COMPLETE CLASS
// // //   // =========================================

// // //   Future<void> completeClass(
// // //     int requestId,
// // //     int index,
// // //   ) async {

// // //     try {

// // //       final response =
// // //           await ApiClient.put(
// // //         '/api/Tutor/complete-class/$requestId',
// // //       );

// // //       if (!mounted) return;

// // //       if (response.statusCode == 200) {

// // //         setState(() {
// // //           classes.removeAt(index);
// // //         });

// // //         ScaffoldMessenger.of(context)
// // //             .showSnackBar(
// // //           const SnackBar(
// // //             content:
// // //                 Text("Class Completed"),
// // //           ),
// // //         );

// // //       } else {

// // //         ScaffoldMessenger.of(context)
// // //             .showSnackBar(
// // //           SnackBar(
// // //             content: Text(
// // //               response.body,
// // //             ),
// // //           ),
// // //         );
// // //       }

// // //     } catch (e) {

// // //       ScaffoldMessenger.of(context)
// // //           .showSnackBar(
// // //         SnackBar(
// // //           content: Text(
// // //             "Error : $e",
// // //           ),
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   // =========================================
// // //   // PRE SCHEDULE
// // //   // =========================================

// // //   Future<void> preSchedule(
// // //     int requestId,
// // //   ) async {

// // //     try {

// // //       final response =
// // //           await ApiClient.put(
// // //         '/api/Tutor/pre-schedule/$requestId',
// // //       );

// // //       if (!mounted) return;

// // //       ScaffoldMessenger.of(context)
// // //           .showSnackBar(
// // //         SnackBar(
// // //           content: Text(
// // //             response.statusCode == 200
// // //                 ? "Pre Scheduled"
// // //                 : "Failed",
// // //           ),
// // //         ),
// // //       );

// // //     } catch (e) {

// // //       ScaffoldMessenger.of(context)
// // //           .showSnackBar(
// // //         SnackBar(
// // //           content: Text(
// // //             "Error : $e",
// // //           ),
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   // =========================================
// // //   // RE SCHEDULE
// // //   // =========================================

// // //   Future<void> reSchedule(
// // //     int requestId,
// // //   ) async {

// // //     try {

// // //       final response =
// // //           await ApiClient.put(
// // //         '/api/Tutor/re-schedule/$requestId',
// // //       );

// // //       if (!mounted) return;

// // //       ScaffoldMessenger.of(context)
// // //           .showSnackBar(
// // //         SnackBar(
// // //           content: Text(
// // //             response.statusCode == 200
// // //                 ? "Re Scheduled"
// // //                 : "Failed",
// // //           ),
// // //         ),
// // //       );

// // //     } catch (e) {

// // //       ScaffoldMessenger.of(context)
// // //           .showSnackBar(
// // //         SnackBar(
// // //           content: Text(
// // //             "Error : $e",
// // //           ),
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   // =========================================
// // //   // CANCEL
// // //   // =========================================

// // //   Future<void> cancelClass(
// // //     int requestId,
// // //     int index,
// // //   ) async {

// // //     try {

// // //       final response =
// // //           await ApiClient.put(
// // //         '/api/Tutor/cancel-class/$requestId',
// // //       );

// // //       if (!mounted) return;

// // //       if (response.statusCode == 200) {

// // //         setState(() {
// // //           classes.removeAt(index);
// // //         });

// // //         ScaffoldMessenger.of(context)
// // //             .showSnackBar(
// // //           const SnackBar(
// // //             content:
// // //                 Text("Class Cancelled"),
// // //           ),
// // //         );

// // //       } else {

// // //         ScaffoldMessenger.of(context)
// // //             .showSnackBar(
// // //           SnackBar(
// // //             content: Text(
// // //               response.body,
// // //             ),
// // //           ),
// // //         );
// // //       }

// // //     } catch (e) {

// // //       ScaffoldMessenger.of(context)
// // //           .showSnackBar(
// // //         SnackBar(
// // //           content: Text(
// // //             "Error : $e",
// // //           ),
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   // =========================================
// // //   // NAVIGATION
// // //   // =========================================

// // //   void navigateScreen(int value) {

// // //     setState(() {
// // //       currentIndex = value;
// // //     });

// // //     if (value == 0) {

// // //       Navigator.pushReplacement(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder: (_) => TutorHome(
           
// // //           ),
// // //         ),
// // //       );
// // //     }

// // //     else if (value == 1) {

// // //       Navigator.pushReplacement(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder: (_) =>
// // //               TutorStudentRequest(
// // //           ),
// // //         ),
// // //       );
// // //     }

// // //     else if (value == 2) {

// // //       return;
// // //     }

// // //     else if (value == 3) {

// // //       Navigator.pushReplacement(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder: (_) =>
// // //               TutorAddSubject(
// // //             teacherName:
// // //                 widget.teacherName,
// // //           ),
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   // =========================================
// // //   // BUTTON
// // //   // =========================================

// // //   Widget buildButton({

// // //     required String text,

// // //     required VoidCallback onTap,

// // //     Color color = Colors.teal,
// // //   }) {

// // //     return SizedBox(

// // //       height: 42,

// // //       child: ElevatedButton(

// // //         style:
// // //             ElevatedButton.styleFrom(

// // //           backgroundColor: color,

// // //           shape:
// // //               RoundedRectangleBorder(
// // //             borderRadius:
// // //                 BorderRadius.circular(
// // //                     25),
// // //           ),
// // //         ),

// // //         onPressed: onTap,

// // //         child: Text(
// // //           text,

// // //           style: const TextStyle(
// // //             color: Colors.white,
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   // =========================================
// // //   // UI
// // //   // =========================================

// // //   @override
// // //   Widget build(BuildContext context) {

// // //     return Scaffold(

// // //       backgroundColor:
// // //           const Color(0xfff7f1f8),

// // //       drawer: const TutorDrawer(),

// // //       // =========================================
// // //       // APP BAR
// // //       // =========================================

// // //       appBar: AppBar(

// // //         backgroundColor: Colors.white,

// // //         elevation: 1,

// // //         iconTheme:
// // //             const IconThemeData(
// // //           color: Colors.teal,
// // //         ),

// // //         centerTitle: true,

// // //         toolbarHeight: 90,

// // //         title: Column(
// // //           mainAxisAlignment:
// // //               MainAxisAlignment.center,

// // //           children: [

// // //             Image.asset(
// // //               "assets/images/logo.png",
// // //               height: 45,
// // //               fit: BoxFit.contain,
// // //             ),

// // //             const SizedBox(height: 5),

// // //             const Text(
// // //               "House of Tutor",

// // //               style: TextStyle(
// // //                 color: Colors.teal,
// // //                 fontSize: 22,
// // //                 fontWeight:
// // //                     FontWeight.bold,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),

// // //       // =========================================
// // //       // BODY
// // //       // =========================================

// // //       body: loading

// // //           ? const Center(
// // //               child:
// // //                   CircularProgressIndicator(),
// // //             )

// // //           : classes.isEmpty

// // //               ? const Center(
// // //                   child: Text(
// // //                     "No Classes Available",

// // //                     style: TextStyle(
// // //                       fontSize: 18,
// // //                       fontWeight:
// // //                           FontWeight.bold,
// // //                     ),
// // //                   ),
// // //                 )

// // //               : RefreshIndicator(

// // //                   onRefresh:
// // //                       fetchClasses,

// // //                   child:
// // //                       ListView.builder(

// // //                     padding:
// // //                         const EdgeInsets.only(
// // //                       top: 10,
// // //                       bottom: 20,
// // //                     ),

// // //                     itemCount:
// // //                         classes.length,

// // //                     itemBuilder:
// // //                         (context, index) {

// // //                       final data =
// // //                           classes[index];

// // //                       final requestId =
// // //                           data["request_id"] ??
// // //                               0;

// // //                       return Container(

// // //                         margin:
// // //                             const EdgeInsets
// // //                                 .symmetric(
// // //                           horizontal: 12,
// // //                           vertical: 8,
// // //                         ),

// // //                         padding:
// // //                             const EdgeInsets
// // //                                 .all(16),

// // //                         decoration:
// // //                             BoxDecoration(
// // //                           color: Colors.white,

// // //                           borderRadius:
// // //                               BorderRadius
// // //                                   .circular(
// // //                                       10),
// // //                         ),

// // //                         child: Column(

// // //                           crossAxisAlignment:
// // //                               CrossAxisAlignment
// // //                                   .start,

// // //                           children: [

// // //                             // ================= TIME =================

// // //                             Text(
// // //                               "${data["day"]}, ${data["time"]}",

// // //                               style:
// // //                                   const TextStyle(
// // //                                 fontSize: 18,

// // //                                 fontWeight:
// // //                                     FontWeight
// // //                                         .w500,
// // //                               ),
// // //                             ),

// // //                             const SizedBox(
// // //                                 height: 10),

// // //                             // ================= STUDENT =================

// // //                             Text(
// // //                               "Student : ${data["student_name"]}",

// // //                               style:
// // //                                   const TextStyle(
// // //                                 fontSize: 16,
// // //                               ),
// // //                             ),

// // //                             const SizedBox(
// // //                                 height: 4),

// // //                             // ================= SUBJECT =================

// // //                             Text(
// // //                               "Subject : ${data["course_name"]}",

// // //                               style:
// // //                                   const TextStyle(
// // //                                 fontSize: 16,
// // //                               ),
// // //                             ),

// // //                             const SizedBox(
// // //                                 height: 18),

// // //                             // ================= BUTTONS =================

// // //                             Wrap(

// // //                               spacing: 10,

// // //                               runSpacing: 10,

// // //                               children: [

// // //                                 // COMPLETE

// // //                                 buildButton(

// // //                                   text:
// // //                                       "Complete",

// // //                                   onTap: () {

// // //                                     completeClass(
// // //                                       requestId,
// // //                                       index,
// // //                                     );
// // //                                   },
// // //                                 ),

// // //                                 // PRE

// // //                                 buildButton(

// // //                                   text:
// // //                                       "Pre-Schedule",

// // //                                   onTap: () {

// // //                                     preSchedule(
// // //                                       requestId,
// // //                                     );
// // //                                   },
// // //                                 ),

// // //                                 // RE

// // //                                 buildButton(

// // //                                   text:
// // //                                       "Re-Schedule",

// // //                                   onTap: () {

// // //                                     reSchedule(
// // //                                       requestId,
// // //                                     );
// // //                                   },
// // //                                 ),

// // //                                 // CANCEL

// // //                                 buildButton(

// // //                                   text:
// // //                                       "Cancel",

// // //                                   color:
// // //                                       Colors.red,

// // //                                   onTap: () {

// // //                                     cancelClass(
// // //                                       requestId,
// // //                                       index,
// // //                                     );
// // //                                   },
// // //                                 ),
// // //                               ],
// // //                             ),
// // //                           ],
// // //                         ),
// // //                       );
// // //                     },
// // //                   ),
// // //                 ),

// // //       // =========================================
// // //       // BOTTOM NAVIGATION
// // //       // =========================================

// // //       bottomNavigationBar:
// // //           BottomNavigationBar(

// // //         currentIndex:
// // //             currentIndex,

// // //         selectedItemColor:
// // //             Colors.blue,

// // //         unselectedItemColor:
// // //             Colors.grey,

// // //         type:
// // //             BottomNavigationBarType
// // //                 .fixed,

// // //         selectedFontSize: 14,

// // //         unselectedFontSize: 13,

// // //         onTap: navigateScreen,

// // //         items: const [

// // //           BottomNavigationBarItem(
// // //             icon:
// // //                 Icon(Icons.calendar_month),
// // //             label: "Schedule",
// // //           ),

// // //           BottomNavigationBarItem(
// // //             icon:
// // //                 Icon(Icons.menu_book),
// // //             label: "Request",
// // //           ),

// // //           BottomNavigationBarItem(
// // //             icon: Icon(Icons.class_),
// // //             label: "Today Class",
// // //           ),

// // //           BottomNavigationBarItem(
// // //             icon: Icon(Icons.add_box),
// // //             label: "Add Subject",
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
































































// // // // import 'dart:convert';

// // // // import 'package:flutter/material.dart';
// // // // import 'package:house_of_tutor/TutorAddSubject.dart';
// // // // import 'package:house_of_tutor/TutorDrawer.dart';
// // // // import 'package:house_of_tutor/TutorHome.dart';
// // // // import 'package:house_of_tutor/TutorStudentRequest.dart';
// // // // import 'package:house_of_tutor/services/api_client.dart';

// // // // class TutorTodayClasses extends StatefulWidget {
// // // //   const TutorTodayClasses({
// // // //     super.key,
// // // //     required this.teacherName,
// // // //   });

// // // //   final String teacherName;

// // // //   @override
// // // //   State<TutorTodayClasses> createState() =>
// // // //       _TutorTodayClassesState();
// // // // }

// // // // class _TutorTodayClassesState
// // // //     extends State<TutorTodayClasses> {

// // // //   // =========================================
// // // //   // STATES
// // // //   // =========================================
// // // //   int _selectedIndex = 2;

// // // //   bool _loading = true;

// // // //   List<Map<String, dynamic>> classes = [];

// // // //   // =========================================
// // // //   // INIT
// // // //   // =========================================
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();

// // // //     _loadClasses();
// // // //   }

// // // //   // =========================================
// // // //   // LOAD CLASSES
// // // //   // =========================================
// // // //   Future<void> _loadClasses() async {

// // // //     try {

// // // //       setState(() {
// // // //         _loading = true;
// // // //       });

// // // //       final response = await ApiClient.get(
// // // //         '/api/Tutor/today-classes',
// // // //       );

// // // //       debugPrint(
// // // //         "STATUS: ${response.statusCode}",
// // // //       );

// // // //       debugPrint(
// // // //         "BODY: ${response.body}",
// // // //       );

// // // //       if (response.statusCode == 200) {

// // // //         final decoded = jsonDecode(
// // // //           utf8.decode(response.bodyBytes),
// // // //         );

// // // //         if (decoded is List) {

// // // //           classes = decoded
// // // //               .whereType<Map>()
// // // //               .map((e) {

// // // //             final fullTime =
// // // //                 e['time']?.toString() ?? '';

// // // //             String day = '';

// // // //             String time = fullTime;

// // // //             if (fullTime.contains(',')) {

// // // //               final parts =
// // // //                   fullTime.split(',');

// // // //               day = parts.first.trim();

// // // //               time = parts
// // // //                   .sublist(1)
// // // //                   .join(',')
// // // //                   .trim();
// // // //             }

// // // //             return {

// // // //               "request_id":
// // // //                   e['request_id'] ?? 0,

// // // //               "student_name":
// // // //                   e['student_name']
// // // //                           ?.toString() ??
// // // //                       '',

// // // //               "course_name":
// // // //                   e['course_name']
// // // //                           ?.toString() ??
// // // //                       '',

// // // //               "day": day,

// // // //               "time": time,
// // // //             };

// // // //           }).toList();
// // // //         }
// // // //       }

// // // //     } catch (e) {

// // // //       debugPrint(
// // // //         "LOAD ERROR: $e",
// // // //       );
// // // //     }

// // // //     if (mounted) {

// // // //       setState(() {
// // // //         _loading = false;
// // // //       });
// // // //     }
// // // //   }

// // // //   // =========================================
// // // //   // COMPLETE
// // // //   // =========================================
// // // //   Future<void> _completeClass(
// // // //     int requestId,
// // // //     int index,
// // // //   ) async {

// // // //     try {

// // // //       final response =
// // // //           await ApiClient.put(
// // // //         '/api/Tutor/complete-class/$requestId',
// // // //       );

// // // //       if (!mounted) return;

// // // //       if (response.statusCode == 200) {

// // // //         setState(() {
// // // //           classes.removeAt(index);
// // // //         });

// // // //         ScaffoldMessenger.of(context)
// // // //             .showSnackBar(
// // // //           const SnackBar(
// // // //             content: Text(
// // // //               "Class Completed",
// // // //             ),
// // // //           ),
// // // //         );

// // // //       } else {

// // // //         ScaffoldMessenger.of(context)
// // // //             .showSnackBar(
// // // //           SnackBar(
// // // //             content: Text(
// // // //               response.body,
// // // //             ),
// // // //           ),
// // // //         );
// // // //       }

// // // //     } catch (e) {

// // // //       ScaffoldMessenger.of(context)
// // // //           .showSnackBar(
// // // //         SnackBar(
// // // //           content: Text(
// // // //             "Error: $e",
// // // //           ),
// // // //         ),
// // // //       );
// // // //     }
// // // //   }

// // // //   // =========================================
// // // //   // PRE SCHEDULE
// // // //   // =========================================
// // // //   Future<void> _preSchedule(
// // // //     int requestId,
// // // //   ) async {

// // // //     try {

// // // //       final response =
// // // //           await ApiClient.put(
// // // //         '/api/Tutor/pre-schedule/$requestId',
// // // //       );

// // // //       if (!mounted) return;

// // // //       ScaffoldMessenger.of(context)
// // // //           .showSnackBar(
// // // //         SnackBar(
// // // //           content: Text(
// // // //             response.statusCode == 200
// // // //                 ? "Pre-Scheduled"
// // // //                 : "Failed",
// // // //           ),
// // // //         ),
// // // //       );

// // // //     } catch (e) {

// // // //       ScaffoldMessenger.of(context)
// // // //           .showSnackBar(
// // // //         SnackBar(
// // // //           content: Text(
// // // //             "Error: $e",
// // // //           ),
// // // //         ),
// // // //       );
// // // //     }
// // // //   }

// // // //   // =========================================
// // // //   // RE SCHEDULE
// // // //   // =========================================
// // // //   Future<void> _reSchedule(
// // // //     int requestId,
// // // //   ) async {

// // // //     try {

// // // //       final response =
// // // //           await ApiClient.put(
// // // //         '/api/Tutor/re-schedule/$requestId',
// // // //       );

// // // //       if (!mounted) return;

// // // //       ScaffoldMessenger.of(context)
// // // //           .showSnackBar(
// // // //         SnackBar(
// // // //           content: Text(
// // // //             response.statusCode == 200
// // // //                 ? "Re-Scheduled"
// // // //                 : "Failed",
// // // //           ),
// // // //         ),
// // // //       );

// // // //     } catch (e) {

// // // //       ScaffoldMessenger.of(context)
// // // //           .showSnackBar(
// // // //         SnackBar(
// // // //           content: Text(
// // // //             "Error: $e",
// // // //           ),
// // // //         ),
// // // //       );
// // // //     }
// // // //   }

// // // //   // =========================================
// // // //   // CANCEL
// // // //   // =========================================
// // // //   Future<void> _cancelClass(
// // // //     int requestId,
// // // //     int index,
// // // //   ) async {

// // // //     try {

// // // //       final response =
// // // //           await ApiClient.put(
// // // //         '/api/Tutor/cancel-class/$requestId',
// // // //       );

// // // //       if (!mounted) return;

// // // //       if (response.statusCode == 200) {

// // // //         setState(() {
// // // //           classes.removeAt(index);
// // // //         });

// // // //         ScaffoldMessenger.of(context)
// // // //             .showSnackBar(
// // // //           const SnackBar(
// // // //             content: Text(
// // // //               "Class Cancelled",
// // // //             ),
// // // //           ),
// // // //         );

// // // //       } else {

// // // //         ScaffoldMessenger.of(context)
// // // //             .showSnackBar(
// // // //           SnackBar(
// // // //             content: Text(
// // // //               response.body,
// // // //             ),
// // // //           ),
// // // //         );
// // // //       }

// // // //     } catch (e) {

// // // //       ScaffoldMessenger.of(context)
// // // //           .showSnackBar(
// // // //         SnackBar(
// // // //           content: Text(
// // // //             "Error: $e",
// // // //           ),
// // // //         ),
// // // //       );
// // // //     }
// // // //   }

// // // //   // =========================================
// // // //   // NAVIGATION
// // // //   // =========================================
// // // //   void _onItemTapped(int index) {

// // // //     setState(() {
// // // //       _selectedIndex = index;
// // // //     });

// // // //     // SCHEDULE
// // // //     if (index == 0) {

// // // //       Navigator.pushReplacement(
// // // //         context,
// // // //         MaterialPageRoute(
// // // //           builder: (_) => TutorHome(
// // // //             teacherName:
// // // //                 widget.teacherName,
// // // //           ),
// // // //         ),
// // // //       );
// // // //     }

// // // //     // REQUEST
// // // //     else if (index == 1) {

// // // //       Navigator.pushReplacement(
// // // //         context,
// // // //         MaterialPageRoute(
// // // //           builder: (_) =>
// // // //               TutorStudentRequest(
// // // //             teacherName:
// // // //                 widget.teacherName,
// // // //           ),
// // // //         ),
// // // //       );
// // // //     }

// // // //     // TODAY
// // // //     else if (index == 2) {

// // // //       return;
// // // //     }

// // // //     // ADD
// // // //     else if (index == 3) {

// // // //       Navigator.pushReplacement(
// // // //         context,
// // // //         MaterialPageRoute(
// // // //           builder: (_) =>
// // // //               TutorAddSubject(
// // // //             teacherName:
// // // //                 widget.teacherName,
// // // //           ),
// // // //         ),
// // // //       );
// // // //     }
// // // //   }

// // // //   // =========================================
// // // //   // BUTTON
// // // //   // =========================================
// // // //   Widget actionButton({
// // // //     required String text,
// // // //     required VoidCallback onTap,
// // // //     bool filled = false,
// // // //     Color borderColor = Colors.teal,
// // // //     Color textColor = Colors.teal,
// // // //   }) {

// // // //     return Expanded(

// // // //       child: GestureDetector(

// // // //         onTap: onTap,

// // // //         child: Container(

// // // //           height: 42,

// // // //           alignment: Alignment.center,

// // // //           decoration: BoxDecoration(

// // // //             color:
// // // //                 filled
// // // //                     ? Colors.teal
// // // //                     : Colors.white,

// // // //             borderRadius:
// // // //                 BorderRadius.circular(25),

// // // //             border: Border.all(
// // // //               color: borderColor,
// // // //             ),
// // // //           ),

// // // //           child: Text(
// // // //             text,

// // // //             style: TextStyle(
// // // //               color:
// // // //                   filled
// // // //                       ? Colors.white
// // // //                       : textColor,

// // // //               fontWeight:
// // // //                   FontWeight.w600,

// // // //               fontSize: 15,
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   // =========================================
// // // //   // UI
// // // //   // =========================================
// // // //   @override
// // // //   Widget build(BuildContext context) {

// // // //     return Scaffold(

// // // //       backgroundColor:
// // // //           const Color(0xffF4F4F4),

// // // //       drawer: const TutorDrawer(),

// // // //       // =====================================
// // // //       // APP BAR
// // // //       // =====================================
// // // //       appBar: AppBar(

// // // //         backgroundColor: Colors.white,

// // // //         elevation: 1,

// // // //         leading: IconButton(
// // // //           icon: const Icon(
// // // //             Icons.arrow_back,
// // // //             color: Colors.black,
// // // //           ),

// // // //           onPressed: () {
// // // //             Navigator.pop(context);
// // // //           },
// // // //         ),

// // // //         centerTitle: true,

// // // //         title: Column(
// // // //           children: [

// // // //             Image.asset(
// // // //               'assets/images/logo.png',
// // // //               height: 35,
// // // //             ),

// // // //             const SizedBox(height: 4),

// // // //             const Text(
// // // //               "House of Tutor",

// // // //               style: TextStyle(
// // // //                 color: Colors.teal,
// // // //                 fontWeight:
// // // //                     FontWeight.bold,
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),

// // // //       // =====================================
// // // //       // BODY
// // // //       // =====================================
// // // //       body: _loading

// // // //           ? const Center(
// // // //               child:
// // // //                   CircularProgressIndicator(),
// // // //             )

// // // //           : classes.isEmpty

// // // //               ? const Center(
// // // //                   child: Text(
// // // //                     "No Classes Available",

// // // //                     style: TextStyle(
// // // //                       fontSize: 18,
// // // //                       fontWeight:
// // // //                           FontWeight.bold,
// // // //                     ),
// // // //                   ),
// // // //                 )

// // // //               : ListView.builder(

// // // //                   padding:
// // // //                       const EdgeInsets.all(16),

// // // //                   itemCount:
// // // //                       classes.length,

// // // //                   itemBuilder:
// // // //                       (context, index) {

// // // //                     final c =
// // // //                         classes[index];

// // // //                     final requestId =
// // // //                         c["request_id"] ?? 0;

// // // //                     final day =
// // // //                         c["day"]
// // // //                                 ?.toString() ??
// // // //                             '';

// // // //                     final time =
// // // //                         c["time"]
// // // //                                 ?.toString() ??
// // // //                             '';

// // // //                     final studentName =
// // // //                         c["student_name"]
// // // //                                 ?.toString() ??
// // // //                             '';

// // // //                     final courseName =
// // // //                         c["course_name"]
// // // //                                 ?.toString() ??
// // // //                             '';

// // // //                     return Container(

// // // //                       margin:
// // // //                           const EdgeInsets.only(
// // // //                         bottom: 20,
// // // //                       ),

// // // //                       padding:
// // // //                           const EdgeInsets.all(20),

// // // //                       decoration:
// // // //                           BoxDecoration(

// // // //                         color: Colors.white,

// // // //                         borderRadius:
// // // //                             BorderRadius.circular(
// // // //                                 25),

// // // //                         boxShadow: [

// // // //                           BoxShadow(
// // // //                             color: Colors.black
// // // //                                 .withOpacity(
// // // //                                     0.08),

// // // //                             blurRadius: 10,

// // // //                             offset:
// // // //                                 const Offset(0, 4),
// // // //                           ),
// // // //                         ],
// // // //                       ),

// // // //                       child: Column(

// // // //                         crossAxisAlignment:
// // // //                             CrossAxisAlignment
// // // //                                 .start,

// // // //                         children: [

// // // //                           // ======================
// // // //                           // DATE TIME
// // // //                           // ======================
// // // //                           Text(
// // // //                             "$day, $time",

// // // //                             style:
// // // //                                 const TextStyle(
// // // //                               color:
// // // //                                   Colors.teal,

// // // //                               fontSize: 18,

// // // //                               fontWeight:
// // // //                                   FontWeight.bold,
// // // //                             ),
// // // //                           ),

// // // //                           const SizedBox(
// // // //                               height: 15),

// // // //                           // ======================
// // // //                           // STUDENT
// // // //                           // ======================
// // // //                           Row(
// // // //                             children: [

// // // //                               const Icon(
// // // //                                 Icons.person,
// // // //                                 color: Colors.blue,
// // // //                               ),

// // // //                               const SizedBox(
// // // //                                   width: 8),

// // // //                               Expanded(
// // // //                                 child: Text(
// // // //                                   studentName,

// // // //                                   style:
// // // //                                       const TextStyle(
// // // //                                     fontSize: 18,
// // // //                                   ),
// // // //                                 ),
// // // //                               ),
// // // //                             ],
// // // //                           ),

// // // //                           const SizedBox(
// // // //                               height: 10),

// // // //                           // ======================
// // // //                           // SUBJECT
// // // //                           // ======================
// // // //                           Row(
// // // //                             children: [

// // // //                               const Icon(
// // // //                                 Icons.book,
// // // //                                 color: Colors.blue,
// // // //                               ),

// // // //                               const SizedBox(
// // // //                                   width: 8),

// // // //                               Expanded(
// // // //                                 child: Text(
// // // //                                   courseName,

// // // //                                   style:
// // // //                                       const TextStyle(
// // // //                                     fontSize: 18,
// // // //                                   ),
// // // //                                 ),
// // // //                               ),
// // // //                             ],
// // // //                           ),

// // // //                           const SizedBox(
// // // //                               height: 25),

// // // //                           // ======================
// // // //                           // BUTTONS ROW
// // // //                           // ======================
// // // //                           Row(
// // // //                             children: [

// // // //                               // COMPLETE
// // // //                               actionButton(
// // // //                                 text: "Complete",

// // // //                                 filled: true,

// // // //                                 onTap: () {

// // // //                                   _completeClass(
// // // //                                     requestId,
// // // //                                     index,
// // // //                                   );
// // // //                                 },
// // // //                               ),

// // // //                               const SizedBox(
// // // //                                   width: 10),

// // // //                               // PRE
// // // //                               actionButton(
// // // //                                 text:
// // // //                                     "Pre-Schedule",

// // // //                                 onTap: () {

// // // //                                   _preSchedule(
// // // //                                     requestId,
// // // //                                   );
// // // //                                 },
// // // //                               ),

// // // //                               const SizedBox(
// // // //                                   width: 10),

// // // //                               // RE
// // // //                               actionButton(
// // // //                                 text:
// // // //                                     "Re-Schedule",

// // // //                                 onTap: () {

// // // //                                   _reSchedule(
// // // //                                     requestId,
// // // //                                   );
// // // //                                 },
// // // //                               ),

// // // //                               const SizedBox(
// // // //                                   width: 10),

// // // //                               // CANCEL
// // // //                               actionButton(
// // // //                                 text: "Cancel",

// // // //                                 borderColor:
// // // //                                     Colors.red,

// // // //                                 textColor:
// // // //                                     Colors.red,

// // // //                                 onTap: () {

// // // //                                   _cancelClass(
// // // //                                     requestId,
// // // //                                     index,
// // // //                                   );
// // // //                                 },
// // // //                               ),
// // // //                             ],
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                     );
// // // //                   },
// // // //                 ),

// // // //       // =====================================
// // // //       // BOTTOM NAVIGATION
// // // //       // =====================================
// // // //       bottomNavigationBar:
// // // //           BottomNavigationBar(

// // // //         type:
// // // //             BottomNavigationBarType.fixed,

// // // //         currentIndex:
// // // //             _selectedIndex,

// // // //         onTap: _onItemTapped,

// // // //         selectedItemColor:
// // // //             Colors.teal,

// // // //         unselectedItemColor:
// // // //             Colors.grey,

// // // //         items: const [

// // // //           BottomNavigationBarItem(
// // // //             icon: Icon(
// // // //               Icons.calendar_today,
// // // //             ),

// // // //             label: 'Schedule',
// // // //           ),

// // // //           BottomNavigationBarItem(
// // // //             icon: Icon(
// // // //               Icons.request_page,
// // // //             ),

// // // //             label: 'Request',
// // // //           ),

// // // //           BottomNavigationBarItem(
// // // //             icon: Icon(
// // // //               Icons.school,
// // // //             ),

// // // //             label: 'Today',
// // // //           ),

// // // //           BottomNavigationBarItem(
// // // //             icon: Icon(
// // // //               Icons.add_box,
// // // //             ),

// // // //             label: 'Add',
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }































// // // // // import 'dart:convert';

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:house_of_tutor/TutorAddSubject.dart';
// // // // // import 'package:house_of_tutor/TutorDrawer.dart';
// // // // // import 'package:house_of_tutor/TutorHome.dart';
// // // // // import 'package:house_of_tutor/TutorStudentRequest.dart';
// // // // // import 'package:house_of_tutor/services/api_client.dart';

// // // // // class TutorTodayClasses extends StatefulWidget {
// // // // //   const TutorTodayClasses({
// // // // //     super.key,
// // // // //     required this.teacherName,
// // // // //   });

// // // // //   final String teacherName;

// // // // //   @override
// // // // //   State<TutorTodayClasses> createState() =>
// // // // //       _TutorTodayClassesState();
// // // // // }

// // // // // class _TutorTodayClassesState
// // // // //     extends State<TutorTodayClasses> {

// // // // //   int _selectedIndex = 3;

// // // // //   bool _loading = true;

// // // // //   List<Map<String, dynamic>> classes = [];

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();

// // // // //     _loadClasses();
// // // // //   }

// // // // //   // ================= LOAD TODAY CLASSES =================
// // // // //   Future<void> _loadClasses() async {

// // // // //     setState(() {
// // // // //       _loading = true;
// // // // //     });

// // // // //     try {

// // // // //       final response = await ApiClient.get(
// // // // //         '/api/Tutor/today-classes',
// // // // //       );

// // // // //       if (response.statusCode == 200) {

// // // // //         final decoded = jsonDecode(
// // // // //           utf8.decode(response.bodyBytes),
// // // // //         );

// // // // //         if (decoded is List) {

// // // // //           classes = decoded
// // // // //               .whereType<Map>()
// // // // //               .map((e) {

// // // // //             final fullTime =
// // // // //                 e['time']?.toString() ?? '';

// // // // //             String day = '';
// // // // //             String time = fullTime;

// // // // //             if (fullTime.contains(',')) {

// // // // //               final parts =
// // // // //                   fullTime.split(',');

// // // // //               day = parts.first.trim();

// // // // //               time = parts
// // // // //                   .sublist(1)
// // // // //                   .join(',')
// // // // //                   .trim();
// // // // //             }

// // // // //             return {

// // // // //               // IMPORTANT
// // // // //               "request_id":
// // // // //                   e['request_id'],

// // // // //               "student_name":
// // // // //                   e['student_name']
// // // // //                           ?.toString() ??
// // // // //                       e['studentName']
// // // // //                           ?.toString() ??
// // // // //                       '',

// // // // //               "course_name":
// // // // //                   e['course_name']
// // // // //                           ?.toString() ??
// // // // //                       e['courseName']
// // // // //                           ?.toString() ??
// // // // //                       '',

// // // // //               "day": day,

// // // // //               "time": time,
// // // // //             };

// // // // //           }).toList();
// // // // //         }
// // // // //       }

// // // // //     } catch (e) {

// // // // //       debugPrint(e.toString());
// // // // //     }

// // // // //     if (mounted) {

// // // // //       setState(() {
// // // // //         _loading = false;
// // // // //       });
// // // // //     }
// // // // //   }

// // // // //   // ================= COMPLETE CLASS =================
// // // // //   Future<void> _completeClass(
// // // // //       int requestId,
// // // // //       int index,
// // // // //       ) async {

// // // // //     try {

// // // // //       final response = await ApiClient.put(
// // // // //         '/api/Tutor/complete-class/$requestId',
// // // // //       );

// // // // //       if (!mounted) return;

// // // // //       if (response.statusCode == 200) {

// // // // //         setState(() {
// // // // //           classes.removeAt(index);
// // // // //         });

// // // // //         ScaffoldMessenger.of(context)
// // // // //             .showSnackBar(
// // // // //           const SnackBar(
// // // // //             content:
// // // // //                 Text("Class Completed"),
// // // // //           ),
// // // // //         );

// // // // //       } else {

// // // // //         final message =
// // // // //             ApiClient.messageFromBody(
// // // // //                   response.body,
// // // // //                 ) ??
// // // // //                 "Failed";

// // // // //         ScaffoldMessenger.of(context)
// // // // //             .showSnackBar(
// // // // //           SnackBar(
// // // // //             content: Text(message),
// // // // //           ),
// // // // //         );
// // // // //       }

// // // // //     } catch (e) {

// // // // //       ScaffoldMessenger.of(context)
// // // // //           .showSnackBar(
// // // // //         SnackBar(
// // // // //           content: Text(
// // // // //             "Error: $e",
// // // // //           ),
// // // // //         ),
// // // // //       );
// // // // //     }
// // // // //   }

// // // // //   // ================= NAVIGATION =================
// // // // //   void _onItemTapped(int index) {

// // // // //     final teacherName =
// // // // //         widget.teacherName;

// // // // //     if (index == 0) {

// // // // //       Navigator.pushReplacement(
// // // // //         context,
// // // // //         MaterialPageRoute(
// // // // //           builder: (_) => TutorHome(
// // // // //             teacherName:
// // // // //                 teacherName,
// // // // //           ),
// // // // //         ),
// // // // //       );
// // // // //     }

// // // // //     else if (index == 1) {

// // // // //       Navigator.pushReplacement(
// // // // //         context,
// // // // //         MaterialPageRoute(
// // // // //           builder: (_) =>
// // // // //               TutorAddSubject(
// // // // //             teacherName:
// // // // //                 teacherName,
// // // // //           ),
// // // // //         ),
// // // // //       );
// // // // //     }

// // // // //     else if (index == 2) {

// // // // //       Navigator.pushReplacement(
// // // // //         context,
// // // // //         MaterialPageRoute(
// // // // //           builder: (_) =>
// // // // //               TutorStudentRequest(
// // // // //             teacherName:
// // // // //                 teacherName,
// // // // //           ),
// // // // //         ),
// // // // //       );
// // // // //     }

// // // // //     setState(() {
// // // // //       _selectedIndex = index;
// // // // //     });
// // // // //   }

// // // // //   // ================= UI =================
// // // // //   @override
// // // // //   Widget build(BuildContext context) {

// // // // //     return Scaffold(

// // // // //       backgroundColor:
// // // // //           const Color(0xFFF5F7FA),

// // // // //       // ================= APP BAR =================
// // // // //       appBar: AppBar(

// // // // //         backgroundColor: Colors.white,
// // // // //         elevation: 2,

// // // // //         leading: Builder(
// // // // //           builder: (context) =>
// // // // //               IconButton(

// // // // //             icon: const Icon(
// // // // //               Icons.menu,
// // // // //               color: Colors.teal,
// // // // //             ),

// // // // //             onPressed: () {
// // // // //               Scaffold.of(context)
// // // // //                   .openDrawer();
// // // // //             },
// // // // //           ),
// // // // //         ),

// // // // //         centerTitle: true,

// // // // //         title: Column(
// // // // //           children: [

// // // // //             Image.asset(
// // // // //               'assets/images/logo.png',
// // // // //               height: 40,
// // // // //             ),

// // // // //             const Text(
// // // // //               'House of Tutor',

// // // // //               style: TextStyle(
// // // // //                 color: Colors.teal,
// // // // //                 fontWeight:
// // // // //                     FontWeight.bold,
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),

// // // // //       // ================= DRAWER =================
// // // // //       drawer: const TutorDrawer(),

// // // // //       // ================= BODY =================
// // // // //       body: _loading

// // // // //           ? const Center(
// // // // //               child:
// // // // //                   CircularProgressIndicator(),
// // // // //             )

// // // // //           : classes.isEmpty

// // // // //               ? const Center(
// // // // //                   child: Text(
// // // // //                     "No Classes Available",

// // // // //                     style: TextStyle(
// // // // //                       fontSize: 18,
// // // // //                       fontWeight:
// // // // //                           FontWeight.bold,
// // // // //                     ),
// // // // //                   ),
// // // // //                 )

// // // // //               : ListView.builder(

// // // // //                   padding:
// // // // //                       const EdgeInsets.all(
// // // // //                           16),

// // // // //                   itemCount:
// // // // //                       classes.length,

// // // // //                   itemBuilder:
// // // // //                       (context, index) {

// // // // //                     final c =
// // // // //                         classes[index];

// // // // //                     final requestId =
// // // // //                         c["request_id"] ?? 0;

// // // // //                     final day =
// // // // //                         c["day"]
// // // // //                                 ?.toString() ??
// // // // //                             '';

// // // // //                     final time =
// // // // //                         c["time"]
// // // // //                                 ?.toString() ??
// // // // //                             '';

// // // // //                     final studentName =
// // // // //                         c["student_name"]
// // // // //                                 ?.toString() ??
// // // // //                             '';

// // // // //                     final courseName =
// // // // //                         c["course_name"]
// // // // //                                 ?.toString() ??
// // // // //                             '';

// // // // //                     return Container(

// // // // //                       margin:
// // // // //                           const EdgeInsets.only(
// // // // //                         bottom: 16,
// // // // //                       ),

// // // // //                       padding:
// // // // //                           const EdgeInsets.all(
// // // // //                               18),

// // // // //                       decoration:
// // // // //                           BoxDecoration(

// // // // //                         color: Colors.white,

// // // // //                         borderRadius:
// // // // //                             BorderRadius
// // // // //                                 .circular(
// // // // //                                     18),

// // // // //                         boxShadow: [

// // // // //                           BoxShadow(
// // // // //                             color: Colors
// // // // //                                 .black
// // // // //                                 .withOpacity(
// // // // //                                     0.05),

// // // // //                             blurRadius: 10,

// // // // //                             offset:
// // // // //                                 const Offset(
// // // // //                                     0, 4),
// // // // //                           ),
// // // // //                         ],
// // // // //                       ),

// // // // //                       child: Column(

// // // // //                         crossAxisAlignment:
// // // // //                             CrossAxisAlignment
// // // // //                                 .start,

// // // // //                         children: [

// // // // //                           // ================= DATE/TIME =================
// // // // //                           Row(
// // // // //                             children: [

// // // // //                               const Icon(
// // // // //                                 Icons.access_time,
// // // // //                                 color:
// // // // //                                     Colors.teal,
// // // // //                               ),

// // // // //                               const SizedBox(
// // // // //                                   width: 8),

// // // // //                               Expanded(
// // // // //                                 child: Text(
// // // // //                                   "$day, $time",

// // // // //                                   style:
// // // // //                                       const TextStyle(
// // // // //                                     fontSize:
// // // // //                                         16,

// // // // //                                     fontWeight:
// // // // //                                         FontWeight
// // // // //                                             .bold,

// // // // //                                     color:
// // // // //                                         Colors
// // // // //                                             .teal,
// // // // //                                   ),
// // // // //                                 ),
// // // // //                               ),
// // // // //                             ],
// // // // //                           ),

// // // // //                           const SizedBox(
// // // // //                               height: 18),

// // // // //                           // ================= STUDENT =================
// // // // //                           Row(
// // // // //                             children: [

// // // // //                               const CircleAvatar(
// // // // //                                 radius: 22,

// // // // //                                 backgroundColor:
// // // // //                                     Color(
// // // // //                                         0xFFE8F5E9),

// // // // //                                 child: Icon(
// // // // //                                   Icons.person,

// // // // //                                   color: Colors
// // // // //                                       .green,
// // // // //                                 ),
// // // // //                               ),

// // // // //                               const SizedBox(
// // // // //                                   width: 12),

// // // // //                               Expanded(
// // // // //                                 child: Column(

// // // // //                                   crossAxisAlignment:
// // // // //                                       CrossAxisAlignment
// // // // //                                           .start,

// // // // //                                   children: [

// // // // //                                     const Text(
// // // // //                                       "Student",

// // // // //                                       style:
// // // // //                                           TextStyle(
// // // // //                                         color:
// // // // //                                             Colors.grey,
// // // // //                                       ),
// // // // //                                     ),

// // // // //                                     Text(
// // // // //                                       studentName,

// // // // //                                       style:
// // // // //                                           const TextStyle(
// // // // //                                         fontSize:
// // // // //                                             16,

// // // // //                                         fontWeight:
// // // // //                                             FontWeight.bold,
// // // // //                                       ),
// // // // //                                     ),
// // // // //                                   ],
// // // // //                                 ),
// // // // //                               ),
// // // // //                             ],
// // // // //                           ),

// // // // //                           const SizedBox(
// // // // //                               height: 14),

// // // // //                           // ================= SUBJECT =================
// // // // //                           Row(
// // // // //                             children: [

// // // // //                               const CircleAvatar(
// // // // //                                 radius: 22,

// // // // //                                 backgroundColor:
// // // // //                                     Color(
// // // // //                                         0xFFE3F2FD),

// // // // //                                 child: Icon(
// // // // //                                   Icons
// // // // //                                       .menu_book,

// // // // //                                   color:
// // // // //                                       Colors
// // // // //                                           .blue,
// // // // //                                 ),
// // // // //                               ),

// // // // //                               const SizedBox(
// // // // //                                   width: 12),

// // // // //                               Expanded(
// // // // //                                 child: Column(

// // // // //                                   crossAxisAlignment:
// // // // //                                       CrossAxisAlignment
// // // // //                                           .start,

// // // // //                                   children: [

// // // // //                                     const Text(
// // // // //                                       "Subject",

// // // // //                                       style:
// // // // //                                           TextStyle(
// // // // //                                         color:
// // // // //                                             Colors.grey,
// // // // //                                       ),
// // // // //                                     ),

// // // // //                                     Text(
// // // // //                                       courseName,

// // // // //                                       style:
// // // // //                                           const TextStyle(
// // // // //                                         fontSize:
// // // // //                                             16,

// // // // //                                         fontWeight:
// // // // //                                             FontWeight.bold,
// // // // //                                       ),
// // // // //                                     ),
// // // // //                                   ],
// // // // //                                 ),
// // // // //                               ),
// // // // //                             ],
// // // // //                           ),

// // // // //                           const SizedBox(
// // // // //                               height: 22),

// // // // //                           // ================= COMPLETE BUTTON =================
// // // // //                           SizedBox(

// // // // //                             width:
// // // // //                                 double.infinity,

// // // // //                             child:
// // // // //                                 ElevatedButton.icon(

// // // // //                               onPressed: () {

// // // // //                                 _completeClass(
// // // // //                                   requestId,
// // // // //                                   index,
// // // // //                                 );
// // // // //                               },

// // // // //                               style:
// // // // //                                   ElevatedButton.styleFrom(

// // // // //                                 backgroundColor:
// // // // //                                     Colors
// // // // //                                         .teal,

// // // // //                                 padding:
// // // // //                                     const EdgeInsets.symmetric(
// // // // //                                   vertical:
// // // // //                                       14,
// // // // //                                 ),

// // // // //                                 shape:
// // // // //                                     RoundedRectangleBorder(
// // // // //                                   borderRadius:
// // // // //                                       BorderRadius.circular(
// // // // //                                           12),
// // // // //                                 ),
// // // // //                               ),

// // // // //                               icon: const Icon(
// // // // //                                 Icons.check_circle,
// // // // //                                 color: Colors
// // // // //                                     .white,
// // // // //                               ),

// // // // //                               label:
// // // // //                                   const Text(
// // // // //                                 "Mark as Completed",

// // // // //                                 style:
// // // // //                                     TextStyle(
// // // // //                                   color: Colors
// // // // //                                       .white,

// // // // //                                   fontSize: 16,

// // // // //                                   fontWeight:
// // // // //                                       FontWeight.bold,
// // // // //                                 ),
// // // // //                               ),
// // // // //                             ),
// // // // //                           ),
// // // // //                         ],
// // // // //                       ),
// // // // //                     );
// // // // //                   },
// // // // //                 ),

// // // // //       // ================= BOTTOM NAVIGATION =================
// // // // //       bottomNavigationBar:
// // // // //           BottomNavigationBar(

// // // // //         type:
// // // // //             BottomNavigationBarType.fixed,

// // // // //         currentIndex:
// // // // //             _selectedIndex,

// // // // //         onTap: _onItemTapped,

// // // // //         selectedItemColor:
// // // // //             Colors.teal,

// // // // //         unselectedItemColor:
// // // // //             Colors.grey,

// // // // //         items: const [

// // // // //           BottomNavigationBarItem(
// // // // //             icon: Icon(
// // // // //               Icons.calendar_today,
// // // // //             ),

// // // // //             label: 'Schedule',
// // // // //           ),

// // // // //           BottomNavigationBarItem(
// // // // //             icon: Icon(
// // // // //               Icons.request_page,
// // // // //             ),

// // // // //             label: 'Request',
// // // // //           ),

// // // // //           BottomNavigationBarItem(
// // // // //             icon: Icon(
// // // // //               Icons.school,
// // // // //             ),

// // // // //             label: 'Today',
// // // // //           ),

// // // // //           BottomNavigationBarItem(
// // // // //             icon: Icon(
// // // // //               Icons.add_box,
// // // // //             ),

// // // // //             label: 'Add Subject',
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }






































// // // // // import 'dart:convert';

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:house_of_tutor/TutorAddSubject.dart';
// // // // // import 'package:house_of_tutor/TutorDrawer.dart';
// // // // // import 'package:house_of_tutor/TutorHome.dart';
// // // // // import 'package:house_of_tutor/TutorStudentRequest.dart';
// // // // // import 'package:house_of_tutor/services/api_client.dart';

// // // // // class TutorTodayClasses extends StatefulWidget {
// // // // //   const TutorTodayClasses({
// // // // //     super.key,
// // // // //     required this.teacherName,
// // // // //   });

// // // // //   final String teacherName;

// // // // //   @override
// // // // //   State<TutorTodayClasses> createState() =>
// // // // //       _TutorTodayClassesState();
// // // // // }

// // // // // class _TutorTodayClassesState
// // // // //     extends State<TutorTodayClasses> {
// // // // //   int _selectedIndex = 3;

// // // // //   bool _loading = true;

// // // // //   List<Map<String, dynamic>> classes = [];

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();

// // // // //     _loadClasses();
// // // // //   }

// // // // //   // ================= LOAD TODAY CLASSES =================
// // // // //   Future<void> _loadClasses() async {
// // // // //     setState(() {
// // // // //       _loading = true;
// // // // //     });

// // // // //     try {
// // // // //       final response = await ApiClient.get(
// // // // //         '/api/Tutor/today-classes',
// // // // //       );

// // // // //       if (response.statusCode == 200) {
// // // // //         final decoded = jsonDecode(
// // // // //           utf8.decode(response.bodyBytes),
// // // // //         );

// // // // //         if (decoded is List) {
// // // // //           classes = decoded
// // // // //               .whereType<Map>()
// // // // //               .map((e) {
// // // // //             final fullTime =
// // // // //                 e['time']?.toString() ?? '';

// // // // //             String day = '';
// // // // //             String time = fullTime;

// // // // //             if (fullTime.contains(',')) {
// // // // //               final parts =
// // // // //                   fullTime.split(',');

// // // // //               day = parts.first.trim();

// // // // //               time = parts
// // // // //                   .sublist(1)
// // // // //                   .join(',')
// // // // //                   .trim();
// // // // //             }

// // // // //             return {
// // // // //               "student_name":
// // // // //                   e['student_name']
// // // // //                           ?.toString() ??
// // // // //                       e['studentName']
// // // // //                           ?.toString() ??
// // // // //                       '',

// // // // //               "course_name":
// // // // //                   e['course_name']
// // // // //                           ?.toString() ??
// // // // //                       e['courseName']
// // // // //                           ?.toString() ??
// // // // //                       '',

// // // // //               "day": day,
// // // // //               "time": time,
// // // // //             };
// // // // //           }).toList();
// // // // //         }
// // // // //       }
// // // // //     } catch (e) {
// // // // //       debugPrint(e.toString());
// // // // //     }

// // // // //     if (mounted) {
// // // // //       setState(() {
// // // // //         _loading = false;
// // // // //       });
// // // // //     }
// // // // //   }

// // // // //   // ================= NAVIGATION =================
// // // // //   void _onItemTapped(int index) {
// // // // //     final teacherName =
// // // // //         widget.teacherName;

// // // // //     if (index == 0) {
// // // // //       Navigator.pushReplacement(
// // // // //         context,
// // // // //         MaterialPageRoute(
// // // // //           builder: (_) => TutorHome(
// // // // //             teacherName:
// // // // //                 teacherName,
// // // // //           ),
// // // // //         ),
// // // // //       );
// // // // //     }

// // // // //     else if (index == 1) {
// // // // //       Navigator.pushReplacement(
// // // // //         context,
// // // // //         MaterialPageRoute(
// // // // //           builder: (_) =>
// // // // //               TutorAddSubject(
// // // // //             teacherName:
// // // // //                 teacherName,
// // // // //           ),
// // // // //         ),
// // // // //       );
// // // // //     }

// // // // //     else if (index == 2) {
// // // // //       Navigator.pushReplacement(
// // // // //         context,
// // // // //         MaterialPageRoute(
// // // // //           builder: (_) =>
// // // // //               TutorStudentRequest(
// // // // //             teacherName:
// // // // //                 teacherName,
// // // // //           ),
// // // // //         ),
// // // // //       );
// // // // //     }

// // // // //     setState(() {
// // // // //       _selectedIndex = index;
// // // // //     });
// // // // //   }

// // // // //   // ================= COMPLETE CLASS =================
// // // // //   void _completeClass(int index) {
// // // // //     setState(() {
// // // // //       classes.removeAt(index);
// // // // //     });

// // // // //     ScaffoldMessenger.of(context)
// // // // //         .showSnackBar(
// // // // //       const SnackBar(
// // // // //         content:
// // // // //             Text("Class Completed"),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   // ================= UI =================
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       backgroundColor:
// // // // //           const Color(0xFFF5F7FA),

// // // // //       // ================= APP BAR =================
// // // // //       appBar: AppBar(
// // // // //         backgroundColor: Colors.white,
// // // // //         elevation: 2,

// // // // //         leading: Builder(
// // // // //           builder: (context) =>
// // // // //               IconButton(
// // // // //             icon: const Icon(
// // // // //               Icons.menu,
// // // // //               color: Colors.teal,
// // // // //             ),

// // // // //             onPressed: () {
// // // // //               Scaffold.of(context)
// // // // //                   .openDrawer();
// // // // //             },
// // // // //           ),
// // // // //         ),

// // // // //         centerTitle: true,

// // // // //         title: Column(
// // // // //           children: [
// // // // //             Image.asset(
// // // // //               'assets/images/logo.png',
// // // // //               height: 40,
// // // // //             ),

// // // // //             const Text(
// // // // //               'House of Tutor',

// // // // //               style: TextStyle(
// // // // //                 color: Colors.teal,
// // // // //                 fontWeight:
// // // // //                     FontWeight.bold,
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),

// // // // //       // ================= TUTOR DRAWER =================
// // // // //       drawer: const TutorDrawer(),

// // // // //       // ================= BODY =================
// // // // //       body: _loading
// // // // //           ? const Center(
// // // // //               child:
// // // // //                   CircularProgressIndicator(),
// // // // //             )
// // // // //           : classes.isEmpty
// // // // //               ? const Center(
// // // // //                   child: Text(
// // // // //                     "No Classes Available",

// // // // //                     style: TextStyle(
// // // // //                       fontSize: 18,
// // // // //                       fontWeight:
// // // // //                           FontWeight.bold,
// // // // //                     ),
// // // // //                   ),
// // // // //                 )
// // // // //               : ListView.builder(
// // // // //                   padding:
// // // // //                       const EdgeInsets.all(
// // // // //                           16),

// // // // //                   itemCount:
// // // // //                       classes.length,

// // // // //                   itemBuilder:
// // // // //                       (context, index) {
// // // // //                     final c =
// // // // //                         classes[index];

// // // // //                     final day =
// // // // //                         c["day"]
// // // // //                                 ?.toString() ??
// // // // //                             '';

// // // // //                     final time =
// // // // //                         c["time"]
// // // // //                                 ?.toString() ??
// // // // //                             '';

// // // // //                     final studentName =
// // // // //                         c["student_name"]
// // // // //                                 ?.toString() ??
// // // // //                             '';

// // // // //                     final courseName =
// // // // //                         c["course_name"]
// // // // //                                 ?.toString() ??
// // // // //                             '';

// // // // //                     return Container(
// // // // //                       margin:
// // // // //                           const EdgeInsets.only(
// // // // //                         bottom: 16,
// // // // //                       ),

// // // // //                       padding:
// // // // //                           const EdgeInsets.all(
// // // // //                               18),

// // // // //                       decoration:
// // // // //                           BoxDecoration(
// // // // //                         color: Colors.white,

// // // // //                         borderRadius:
// // // // //                             BorderRadius
// // // // //                                 .circular(
// // // // //                                     18),

// // // // //                         boxShadow: [
// // // // //                           BoxShadow(
// // // // //                             color: Colors
// // // // //                                 .black
// // // // //                                 .withOpacity(
// // // // //                                     0.05),

// // // // //                             blurRadius: 10,
// // // // //                             offset:
// // // // //                                 const Offset(
// // // // //                                     0, 4),
// // // // //                           ),
// // // // //                         ],
// // // // //                       ),

// // // // //                       child: Column(
// // // // //                         crossAxisAlignment:
// // // // //                             CrossAxisAlignment
// // // // //                                 .start,

// // // // //                         children: [
// // // // //                           // ================= DATE/TIME =================
// // // // //                           Row(
// // // // //                             children: [
// // // // //                               const Icon(
// // // // //                                 Icons.access_time,
// // // // //                                 color:
// // // // //                                     Colors.teal,
// // // // //                               ),

// // // // //                               const SizedBox(
// // // // //                                   width: 8),

// // // // //                               Expanded(
// // // // //                                 child: Text(
// // // // //                                   "$day, $time",

// // // // //                                   style:
// // // // //                                       const TextStyle(
// // // // //                                     fontSize:
// // // // //                                         16,

// // // // //                                     fontWeight:
// // // // //                                         FontWeight
// // // // //                                             .bold,

// // // // //                                     color:
// // // // //                                         Colors
// // // // //                                             .teal,
// // // // //                                   ),
// // // // //                                 ),
// // // // //                               ),
// // // // //                             ],
// // // // //                           ),

// // // // //                           const SizedBox(
// // // // //                               height: 18),

// // // // //                           // ================= STUDENT =================
// // // // //                           Row(
// // // // //                             children: [
// // // // //                               const CircleAvatar(
// // // // //                                 radius: 22,
// // // // //                                 backgroundColor:
// // // // //                                     Color(
// // // // //                                         0xFFE8F5E9),

// // // // //                                 child: Icon(
// // // // //                                   Icons.person,
// // // // //                                   color: Colors
// // // // //                                       .green,
// // // // //                                 ),
// // // // //                               ),

// // // // //                               const SizedBox(
// // // // //                                   width: 12),

// // // // //                               Expanded(
// // // // //                                 child: Column(
// // // // //                                   crossAxisAlignment:
// // // // //                                       CrossAxisAlignment
// // // // //                                           .start,

// // // // //                                   children: [
// // // // //                                     const Text(
// // // // //                                       "Student",

// // // // //                                       style:
// // // // //                                           TextStyle(
// // // // //                                         color:
// // // // //                                             Colors.grey,
// // // // //                                       ),
// // // // //                                     ),

// // // // //                                     Text(
// // // // //                                       studentName,

// // // // //                                       style:
// // // // //                                           const TextStyle(
// // // // //                                         fontSize:
// // // // //                                             16,

// // // // //                                         fontWeight:
// // // // //                                             FontWeight.bold,
// // // // //                                       ),
// // // // //                                     ),
// // // // //                                   ],
// // // // //                                 ),
// // // // //                               ),
// // // // //                             ],
// // // // //                           ),

// // // // //                           const SizedBox(
// // // // //                               height: 14),

// // // // //                           // ================= SUBJECT =================
// // // // //                           Row(
// // // // //                             children: [
// // // // //                               const CircleAvatar(
// // // // //                                 radius: 22,
// // // // //                                 backgroundColor:
// // // // //                                     Color(
// // // // //                                         0xFFE3F2FD),

// // // // //                                 child: Icon(
// // // // //                                   Icons
// // // // //                                       .menu_book,
// // // // //                                   color:
// // // // //                                       Colors
// // // // //                                           .blue,
// // // // //                                 ),
// // // // //                               ),

// // // // //                               const SizedBox(
// // // // //                                   width: 12),

// // // // //                               Expanded(
// // // // //                                 child: Column(
// // // // //                                   crossAxisAlignment:
// // // // //                                       CrossAxisAlignment
// // // // //                                           .start,

// // // // //                                   children: [
// // // // //                                     const Text(
// // // // //                                       "Subject",

// // // // //                                       style:
// // // // //                                           TextStyle(
// // // // //                                         color:
// // // // //                                             Colors.grey,
// // // // //                                       ),
// // // // //                                     ),

// // // // //                                     Text(
// // // // //                                       courseName,

// // // // //                                       style:
// // // // //                                           const TextStyle(
// // // // //                                         fontSize:
// // // // //                                             16,

// // // // //                                         fontWeight:
// // // // //                                             FontWeight.bold,
// // // // //                                       ),
// // // // //                                     ),
// // // // //                                   ],
// // // // //                                 ),
// // // // //                               ),
// // // // //                             ],
// // // // //                           ),

// // // // //                           const SizedBox(
// // // // //                               height: 22),

// // // // //                           // ================= COMPLETE BUTTON =================
// // // // //                           SizedBox(
// // // // //                             width:
// // // // //                                 double.infinity,

// // // // //                             child:
// // // // //                                 ElevatedButton.icon(
// // // // //                               onPressed: () {
// // // // //                                 _completeClass(
// // // // //                                     index);
// // // // //                               },

// // // // //                               style:
// // // // //                                   ElevatedButton.styleFrom(
// // // // //                                 backgroundColor:
// // // // //                                     Colors
// // // // //                                         .teal,

// // // // //                                 padding:
// // // // //                                     const EdgeInsets.symmetric(
// // // // //                                   vertical:
// // // // //                                       14,
// // // // //                                 ),

// // // // //                                 shape:
// // // // //                                     RoundedRectangleBorder(
// // // // //                                   borderRadius:
// // // // //                                       BorderRadius.circular(
// // // // //                                           12),
// // // // //                                 ),
// // // // //                               ),

// // // // //                               icon: const Icon(
// // // // //                                 Icons.check_circle,
// // // // //                                 color: Colors
// // // // //                                     .white,
// // // // //                               ),

// // // // //                               label:
// // // // //                                   const Text(
// // // // //                                 "Mark as Completed",

// // // // //                                 style:
// // // // //                                     TextStyle(
// // // // //                                   color: Colors
// // // // //                                       .white,

// // // // //                                   fontSize: 16,

// // // // //                                   fontWeight:
// // // // //                                       FontWeight.bold,
// // // // //                                 ),
// // // // //                               ),
// // // // //                             ),
// // // // //                           ),
// // // // //                         ],
// // // // //                       ),
// // // // //                     );
// // // // //                   },
// // // // //                 ),

// // // // //       // ================= BOTTOM NAVIGATION =================
// // // // //       bottomNavigationBar:
// // // // //           BottomNavigationBar(
// // // // //         type:
// // // // //             BottomNavigationBarType.fixed,

// // // // //         currentIndex:
// // // // //             _selectedIndex,

// // // // //         onTap: _onItemTapped,

// // // // //         selectedItemColor:
// // // // //             Colors.teal,

// // // // //         unselectedItemColor:
// // // // //             Colors.grey,

// // // // //         items: const [
// // // // //           BottomNavigationBarItem(
// // // // //             icon: Icon(
// // // // //               Icons.calendar_today,
// // // // //             ),
// // // // //             label: 'Schedule',
// // // // //           ),

// // // // //           BottomNavigationBarItem(
// // // // //             icon: Icon(
// // // // //               Icons.subject,
// // // // //             ),
// // // // //             label: 'Add Subject',
// // // // //           ),

// // // // //           BottomNavigationBarItem(
// // // // //             icon: Icon(
// // // // //               Icons.request_page,
// // // // //             ),
// // // // //             label: 'Request',
// // // // //           ),

// // // // //           BottomNavigationBarItem(
// // // // //             icon: Icon(
// // // // //               Icons.class_,
// // // // //             ),
// // // // //             label: 'Today',
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }


























// // // // // import 'dart:convert';

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:house_of_tutor/LoginScreen.dart';
// // // // // import 'package:house_of_tutor/TutorAddSubject.dart';
// // // // // import 'package:house_of_tutor/TutorHome.dart';
// // // // // import 'package:house_of_tutor/TutorStudentRequest.dart';
// // // // // import 'package:house_of_tutor/services/api_client.dart';
// // // // // import 'package:house_of_tutor/services/auth_store.dart';

// // // // // class TutorTodayClasses extends StatefulWidget {
// // // // //   const TutorTodayClasses({super.key, required this.teacherName});

// // // // //   final String teacherName;

// // // // //   @override
// // // // //   State<TutorTodayClasses> createState() => _TutorTodayClassesState();
// // // // // }

// // // // // class _TutorTodayClassesState extends State<TutorTodayClasses> {
// // // // //   int _selectedIndex = 3;
// // // // //   bool _loading = true;
// // // // //   List<Map<String, dynamic>> classes = [];

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _load();
// // // // //   }

// // // // //   Future<void> _load() async {
// // // // //     setState(() => _loading = true);
// // // // //     try {
// // // // //       final res = await ApiClient.get('/api/Tutor/today-classes');
// // // // //       if (res.statusCode == 200) {
// // // // //         final list = jsonDecode(utf8.decode(res.bodyBytes));
// // // // //         if (list is List) {
// // // // //           classes = list
// // // // //               .whereType<Map>()
// // // // //               .map((e) {
// // // // //                 final time = e['time']?.toString() ?? '';
// // // // //                 final parts = time.split(',');
// // // // //                 String day = '';
// // // // //                 String timeOnly = time;
// // // // //                 if (parts.length >= 2) {
// // // // //                   day = parts.first.trim();
// // // // //                   timeOnly = parts.sublist(1).join(',').trim();
// // // // //                 }
// // // // //                 return {
// // // // //                   'day': day,
// // // // //                   'time': timeOnly,
// // // // //                   'name': e['student_name']?.toString() ?? e['studentName']?.toString() ?? '',
// // // // //                   'subject': e['course_name']?.toString() ?? e['courseName']?.toString() ?? '',
// // // // //                 };
// // // // //               })
// // // // //               .toList();
// // // // //         }
// // // // //       }
// // // // //     } catch (_) {}
// // // // //     if (mounted) setState(() => _loading = false);
// // // // //   }

// // // // //   Future<void> _logout() async {
// // // // //     await AuthStore.instance.clear();
// // // // //     if (!mounted) return;
// // // // //     Navigator.pushAndRemoveUntil(
// // // // //       context,
// // // // //       MaterialPageRoute(builder: (_) => const LoginScreen()),
// // // // //       (route) => false,
// // // // //     );
// // // // //   }

// // // // //   void _onItemTapped(int index) {
// // // // //     final name = widget.teacherName;

// // // // //     if (index == 0) {
// // // // //       Navigator.pushReplacement(
// // // // //         context,
// // // // //         MaterialPageRoute(builder: (_) => TutorHome(teacherName: name)),
// // // // //       );
// // // // //     } else if (index == 1) {
// // // // //       Navigator.pushReplacement(
// // // // //         context,
// // // // //         MaterialPageRoute(builder: (_) => TutorAddSubject(teacherName: name)),
// // // // //       );
// // // // //     } else if (index == 2) {
// // // // //       Navigator.pushReplacement(
// // // // //         context,
// // // // //         MaterialPageRoute(builder: (_) => TutorStudentRequest(teacherName: name)),
// // // // //       );
// // // // //     }

// // // // //     setState(() {
// // // // //       _selectedIndex = index;
// // // // //     });
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       backgroundColor: const Color(0xFFF3F5F9),
// // // // //       appBar: AppBar(
// // // // //         backgroundColor: Colors.white,
// // // // //         elevation: 2,
// // // // //         leading: Builder(
// // // // //           builder: (context) => IconButton(
// // // // //             icon: const Icon(Icons.menu, color: Colors.teal),
// // // // //             onPressed: () => Scaffold.of(context).openDrawer(),
// // // // //           ),
// // // // //         ),
// // // // //         centerTitle: true,
// // // // //         title: Column(
// // // // //           children: [
// // // // //             Image.asset('assets/images/logo.png', height: 40),
// // // // //             const Text(
// // // // //               'House of Tutor',
// // // // //               style: TextStyle(
// // // // //                 color: Colors.teal,
// // // // //                 fontWeight: FontWeight.bold,
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //       drawer: Drawer(
// // // // //         child: Column(
// // // // //           children: [
// // // // //             DrawerHeader(
// // // // //               decoration: const BoxDecoration(color: Colors.teal),
// // // // //               child: Column(
// // // // //                 mainAxisAlignment: MainAxisAlignment.center,
// // // // //                 children: [
// // // // //                   Image.asset('assets/images/logo.png', height: 70),
// // // // //                   const SizedBox(height: 10),
// // // // //                   const Text('House of Tutor', style: TextStyle(color: Colors.white)),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //             ListTile(
// // // // //               leading: const Icon(Icons.logout),
// // // // //               title: const Text('Logout'),
// // // // //               onTap: _logout,
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //       body: _loading
// // // // //           ? const Center(child: CircularProgressIndicator())
// // // // //           : classes.isEmpty
// // // // //               ? const Center(child: Text('No Classes Available'))
// // // // //               : ListView.builder(
// // // // //                   padding: const EdgeInsets.all(16),
// // // // //                   itemCount: classes.length,
// // // // //                   itemBuilder: (context, index) {
// // // // //                     final c = classes[index];
// // // // //                     final day = c['day']?.toString() ?? '';
// // // // //                     final time = c['time']?.toString() ?? '';
// // // // //                     final label = day.isEmpty ? time : '$day, $time';

// // // // //                     return Container(
// // // // //                       padding: const EdgeInsets.all(16),
// // // // //                       margin: const EdgeInsets.only(bottom: 16),
// // // // //                       decoration: BoxDecoration(
// // // // //                         color: Colors.white,
// // // // //                         borderRadius: BorderRadius.circular(16),
// // // // //                         boxShadow: [
// // // // //                           BoxShadow(
// // // // //                             color: Colors.black.withOpacity(0.05),
// // // // //                             blurRadius: 10,
// // // // //                           ),
// // // // //                         ],
// // // // //                       ),
// // // // //                       child: Column(
// // // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                         children: [
// // // // //                           Text(
// // // // //                             label,
// // // // //                             style: const TextStyle(
// // // // //                               fontWeight: FontWeight.bold,
// // // // //                               color: Colors.teal,
// // // // //                               fontSize: 16,
// // // // //                             ),
// // // // //                           ),
// // // // //                           const SizedBox(height: 10),
// // // // //                           Row(
// // // // //                             children: [
// // // // //                               const Icon(Icons.person, color: Colors.blue),
// // // // //                               const SizedBox(width: 8),
// // // // //                               Text(c['name']?.toString() ?? ''),
// // // // //                             ],
// // // // //                           ),
// // // // //                           const SizedBox(height: 6),
// // // // //                           Row(
// // // // //                             children: [
// // // // //                               const Icon(Icons.menu_book, color: Colors.blue),
// // // // //                               const SizedBox(width: 8),
// // // // //                               Text(c['subject']?.toString() ?? ''),
// // // // //                             ],
// // // // //                           ),
// // // // //                           const SizedBox(height: 16),
// // // // //                           SizedBox(
// // // // //                             width: double.infinity,
// // // // //                             child: ElevatedButton(
// // // // //                               onPressed: () {
// // // // //                                 setState(() {
// // // // //                                   classes.removeAt(index);
// // // // //                                 });
// // // // //                                 ScaffoldMessenger.of(context).showSnackBar(
// // // // //                                   const SnackBar(content: Text('Class Completed')),
// // // // //                                 );
// // // // //                               },
// // // // //                               style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
// // // // //                               child: const Text('Complete'),
// // // // //                             ),
// // // // //                           ),
// // // // //                         ],
// // // // //                       ),
// // // // //                     );
// // // // //                   },
// // // // //                 ),
// // // // //       bottomNavigationBar: BottomNavigationBar(
// // // // //         type: BottomNavigationBarType.fixed,
// // // // //         currentIndex: _selectedIndex,
// // // // //         onTap: _onItemTapped,
// // // // //         selectedItemColor: Colors.teal,
// // // // //         unselectedItemColor: Colors.grey,
// // // // //         items: const [
// // // // //           BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
// // // // //           BottomNavigationBarItem(icon: Icon(Icons.subject), label: 'Add Subject'),
// // // // //           BottomNavigationBarItem(icon: Icon(Icons.request_page), label: 'Request'),
// // // // //           BottomNavigationBarItem(icon: Icon(Icons.class_), label: 'Today'),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }
