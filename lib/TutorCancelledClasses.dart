import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class TutorCancelledClasses extends StatefulWidget {
  const TutorCancelledClasses({super.key});

  @override
  State<TutorCancelledClasses> createState() => _TutorCancelledClassesState();
}

class _TutorCancelledClassesState extends State<TutorCancelledClasses> {
  // =========================================================
  // STATE VARIABLES
  // =========================================================

  bool isLoading = false;
  List<dynamic> cancelledClassesList = [];

  @override
  void initState() {
    super.initState();
    fetchCancelledClasses();
  }

  // =========================================================
  // FETCH CANCELLED CLASSES API
  // =========================================================

  Future<void> fetchCancelledClasses() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get("/api/Tutor/cancel-classes");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["success"] == true) {
          setState(() {
            cancelledClassesList = decoded["data"] ?? [];
          });
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load cancelled classes (${response.statusCode})"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
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
  // RESCHEDULE CLASS API
  // =========================================================

  Future<void> rescheduleClass(int requestId) async {
    try {
      final response = await ApiClient.post(
        "/api/Tutor/reschedule",
        {
          "requestId": requestId,
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final message = decoded["message"] ?? "Class rescheduled successfully.";

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        fetchCancelledClasses(); // Refresh list
      } else {
        final decoded = jsonDecode(response.body);
        final message = decoded["message"] ?? "Failed to reschedule class";
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // GET INITIALS FOR AVATAR
  // =========================================================

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "S";
    List<String> parts = name.trim().split(" ");
    if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return "S";
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
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
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF009688),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER TITLE & SUBTITLE
                    const Text(
                      "Cancelled Classes",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Manage and reschedule missed sessions",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CANCELLED CLASSES LIST VIEW
                    Expanded(
                      child: cancelledClassesList.isEmpty
                          ? Center(
                              child: Text(
                                "No cancelled classes found",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: cancelledClassesList.length,
                              itemBuilder: (context, index) {
                                final item = cancelledClassesList[index];

                                final int requestId = item["request_id"] ?? 0;
                                final String studentName = item["student_name"] ?? "Student Name";
                                final String courseName = item["course_name"] ?? "Course Name";
                                final String rawDate = item["class_date"]?.toString().split("T")[0] ?? "";
                                final String day = item["day"] ?? "";
                                final String time = item["time"] ?? "";
                                final String requestType = item["request_type"] ?? "Reschedule";
                                final String status = item["status"] ?? "Cancelled";

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
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
                                      // TOP HEADER: AVATAR + NAME + STATUS BADGE
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
                                                const SizedBox(height: 2),
                                                Text(
                                                  courseName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // STATUS BADGE
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status,
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),

                                      // DATE & TIME CHIPS ROW
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade700),
                                                const SizedBox(width: 6),
                                                Text(
                                                  rawDate,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade800,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.access_time_outlined, size: 13, color: Colors.grey.shade700),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      "$day, $time",
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade800,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // REQUEST TYPE CHIP
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.bookmark_border, size: 13, color: Colors.grey.shade700),
                                            const SizedBox(width: 6),
                                            Text(
                                              requestType,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade800,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Divider(height: 1),
                                      ),

                                      // RESCHEDULE CLASS BUTTON
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF5C6BC0),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () => rescheduleClass(requestId),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.refresh, color: Colors.white, size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                "Reschedule Class",
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
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}


















  // import 'dart:convert';

  // import 'package:flutter/material.dart';
  // import 'package:house_of_tutor/TutorDrawer.dart';
  // import 'package:house_of_tutor/TutorHome.dart';
  // import 'package:house_of_tutor/services/api_client.dart';

  // class TutorCancelledClasses extends StatefulWidget {
  //   const TutorCancelledClasses({super.key});

  //   @override
  //   State<TutorCancelledClasses> createState() =>
  //       _TutorCancelledClassesState();
  // }

  // class _TutorCancelledClassesState extends State<TutorCancelledClasses> {
  //   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  //   bool loading = true;
  //   List<Map<String, dynamic>> classes = [];

  //   @override
  //   void initState() {
  //     super.initState();
  //     fetchCancelledClasses();
  //   }

  //   // =====================================================
  //   // FETCH CANCELLED CLASSES
  //   // =====================================================

  //   Future<void> fetchCancelledClasses() async {
  //     setState(() => loading = true);

  //     try {
  //       final response =
  //           await ApiClient.get('/api/Tutor/cancelled-classes');

  //       debugPrint("CANCELLED STATUS : ${response.statusCode}");
  //       debugPrint("CANCELLED BODY : ${response.body}");

  //       classes = [];

  //       if (response.statusCode == 200) {
  //         final decoded = jsonDecode(utf8.decode(response.bodyBytes));

  //         if (decoded is Map && decoded["data"] is List) {
  //           final List rawList = decoded["data"] as List;
  //           classes = rawList
  //               .whereType<Map>()
  //               .map((e) => Map<String, dynamic>.from(e))
  //               .toList();
  //         } else if (decoded is List) {
  //           classes = decoded
  //               .whereType<Map>()
  //               .map((e) => Map<String, dynamic>.from(e))
  //               .toList();
  //         }

  //         debugPrint("TOTAL CANCELLED : ${classes.length}");
  //       } else {
  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(
  //               content: Text(
  //                 ApiClient.messageFromBody(response.body) ??
  //                     "Unable to load cancelled classes",
  //               ),
  //             ),
  //           );
  //         }
  //       }
  //     } catch (e) {
  //       debugPrint("CANCELLED ERROR : $e");
  //       classes = [];
  //     }

  //     if (mounted) setState(() => loading = false);
  //   }

  //   // =====================================================
  //   // AUTO SCHEDULE
  //   // =====================================================

  //   Future<void> autoSchedule({
  //     required int requestId,
  //     required String endpoint,
  //     required String requestType,
  //   }) async {
  //     try {
  //       setState(() => loading = true);

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
  //           fetchCancelledClasses();
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
  //                       "No common slot found. Pick a day, date and time.",
  //                       style: TextStyle(color: Colors.grey, fontSize: 13),
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
  //                         contentPadding:
  //                             EdgeInsets.symmetric(horizontal: 12),
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
  //                           lastDate: DateTime.now()
  //                               .add(const Duration(days: 365)),
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
  //   // MANUAL SCHEDULE API CALL
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
  //         "/api/Tutor/manual-schedule",
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
  //         fetchCancelledClasses();
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
  //   // UI
  //   // =====================================================

  //   @override
  //   Widget build(BuildContext context) {
  //     return Scaffold(
  //       key: _scaffoldKey,
  //       drawer: const TutorDrawer(),
  //       backgroundColor: const Color(0xffF3F5FB),

  //       appBar: AppBar(
  //         backgroundColor: Colors.white,
  //         elevation: 1,
  //         leading: IconButton(
  //           icon: const Icon(Icons.menu, color: Colors.teal),
  //           onPressed: () => _scaffoldKey.currentState?.openDrawer(),
  //         ),
  //         centerTitle: true,
  //         title: const Text(
  //           "Cancelled Classes",
  //           style: TextStyle(
  //             color: Colors.teal,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         actions: [
  //           IconButton(
  //             icon: const Icon(Icons.arrow_back, color: Colors.teal),
  //             onPressed: () {
  //               if (Navigator.canPop(context)) {
  //                 Navigator.pop(context);
  //               } else {
  //                 Navigator.pushReplacement(
  //                   context,
  //                   MaterialPageRoute(builder: (_) => const TutorHome()),
  //                 );
  //               }
  //             },
  //           ),
  //         ],
  //       ),

  //       body: loading
  //           ? const Center(child: CircularProgressIndicator())
  //           : RefreshIndicator(
  //               onRefresh: fetchCancelledClasses,
  //               child: classes.isEmpty
  //                   ? ListView(
  //                       children: const [
  //                         SizedBox(height: 150),
  //                         Center(
  //                           child: Text(
  //                             "No Cancelled Classes Found",
  //                             style: TextStyle(
  //                               fontSize: 16,
  //                               color: Colors.grey,
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     )
  //                   : ListView.builder(
  //                       padding: const EdgeInsets.all(16),
  //                       itemCount: classes.length,
  //                       itemBuilder: (context, index) {
  //                         return cancelledCard(classes[index]);
  //                       },
  //                     ),
  //             ),
  //     );
  //   }

  //   // =====================================================
  //   // CANCELLED CLASS CARD
  //   // =====================================================

  //   Widget cancelledCard(Map<String, dynamic> item) {
  //     final int requestId =
  //         (item["requestId"] as num?)?.toInt() ?? 0;
  //     final String student = item["student"]?.toString() ?? "";
  //     final String course = item["course"]?.toString() ?? "";
  //     final String day = item["day"]?.toString() ?? "";
  //     final String time = item["time"]?.toString() ?? "";
  //     final String classDate = item["classDate"]?.toString() ?? "";

  //     return Container(
  //       margin: const EdgeInsets.only(bottom: 16),
  //       padding: const EdgeInsets.all(18),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(18),
  //         border: const Border(
  //           left: BorderSide(color: Colors.red, width: 5),
  //         ),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.05),
  //             blurRadius: 8,
  //             offset: const Offset(0, 3),
  //           ),
  //         ],
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [

  //           // ================================
  //           // STUDENT + CANCELLED BADGE
  //           // ================================
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: Text(
  //                   student,
  //                   style: const TextStyle(
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //               Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 12,
  //                   vertical: 5,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: Colors.red.shade50,
  //                   borderRadius: BorderRadius.circular(20),
  //                   border: Border.all(color: Colors.red),
  //                 ),
  //                 child: const Text(
  //                   "Cancelled",
  //                   style: TextStyle(
  //                     color: Colors.red,
  //                     fontWeight: FontWeight.bold,
  //                     fontSize: 13,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),

  //           const SizedBox(height: 8),

  //           Text(
  //             course,
  //             style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
  //           ),

  //           const SizedBox(height: 12),

  //           // ================================
  //           // INFO ROWS
  //           // ================================
  //           _infoRow(Icons.calendar_today,
  //               classDate.isNotEmpty ? classDate : "N/A"),
  //           _infoRow(Icons.event_note, day.isNotEmpty ? day : "N/A"),
  //           _infoRow(Icons.access_time, time.isNotEmpty ? time : "N/A"),

  //           const SizedBox(height: 16),

  //           // ================================
  //           // RE-SCHEDULE BUTTON
  //           // ================================
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: ElevatedButton.icon(
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: const Color(0xff2F80ED),
  //                     foregroundColor: Colors.white,
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                   ),
  //                   icon: const Icon(Icons.autorenew, size: 18),
  //                   label: const Text(
  //                     "Re-Schedule",
  //                     style: TextStyle(fontWeight: FontWeight.bold),
  //                   ),
  //                   onPressed: requestId == 0
  //                       ? null
  //                       : () => autoSchedule(
  //                             requestId: requestId,
  //                             endpoint: "/api/Tutor/reschedule",
  //                             requestType: "Reschedule",
  //                           ),
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //             ],
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   Widget _infoRow(IconData icon, String text) {
  //     return Padding(
  //       padding: const EdgeInsets.only(bottom: 6),
  //       child: Row(
  //         children: [
  //           Icon(icon, size: 16, color: Colors.grey.shade600),
  //           const SizedBox(width: 8),
  //           Text(
  //             text,
  //             style: TextStyle(color: Colors.grey.shade700),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }