import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class TutorHistory extends StatefulWidget {
  const TutorHistory({super.key});

  @override
  State<TutorHistory> createState() => _TutorHistoryState();
}

class _TutorHistoryState extends State<TutorHistory> {
  // =========================================================
  // STATE VARIABLES
  // =========================================================

  bool isLoading = false;
  List<dynamic> historyList = [];

  @override
  void initState() {
    super.initState();
    fetchTutorHistory();
  }

  // =========================================================
  // FETCH TUTOR CLASS HISTORY API
  // =========================================================

  Future<void> fetchTutorHistory() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get("/api/Tutor/tutor-class-history");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded["data"] != null) {
          setState(() {
            historyList = decoded["data"];
          });
        } else if (decoded is List) {
          setState(() {
            historyList = decoded;
          });
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load history (${response.statusCode})"),
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
  // GET INITIALS FOR AVATAR
  // =========================================================

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "S";
    List<String> parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
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
                    // TITLE & SUBTITLE
                    const Text(
                      "Class History",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Review all your past and completed tutoring sessions",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TOTAL RECORDED SESSIONS BANNER
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified, color: Colors.indigo.shade700, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "Total Recorded Sessions: ${historyList.length}",
                            style: TextStyle(
                              color: Colors.indigo.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // HISTORY LIST VIEW
                    Expanded(
                      child: historyList.isEmpty
                          ? Center(
                              child: Text(
                                "No history records found",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: historyList.length,
                              itemBuilder: (context, index) {
                                final item = historyList[index];

                                final String studentName = item["student_name"] ?? "Student Name";
                                final String courseName = item["course_name"] ?? "Course Name";
                                final String status = item["status"] ?? "Complete";
                                final String requestType = item["request_type"] ?? "Normal";
                                final String rawDate = item["class_date"]?.toString().split("T")[0] ?? "";
                                final String day = item["day"] ?? "";
                                final String time = item["time"] ?? "";

                                final String formattedDate = day.isNotEmpty ? "$rawDate ($day)" : rawDate;

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
                                      // TOP HEADER: AVATAR + NAME + STATUS
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
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.menu_book_outlined,
                                                      size: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      courseName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // STATUS BADGE
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade50,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_circle, size: 12, color: Color(0xFF00695C)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  status,
                                                  style: const TextStyle(
                                                    color: Color(0xFF00695C),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Divider(height: 1),
                                      ),

                                      // DETAIL ROWS (Date, Time, Type)
                                      _detailRow(
                                        icon: Icons.calendar_today_outlined,
                                        label: "Date",
                                        value: formattedDate,
                                      ),
                                      const SizedBox(height: 8),
                                      _detailRow(
                                        icon: Icons.access_time_outlined,
                                        label: "Time",
                                        value: time,
                                      ),
                                      const SizedBox(height: 8),
                                      _detailRow(
                                        icon: Icons.swap_horiz_outlined,
                                        label: "Type",
                                        value: requestType,
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

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}


















// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/TutorHome.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class TutorHistory extends StatefulWidget {
//   const TutorHistory({super.key});

//   @override
//   State<TutorHistory> createState() => _TutorHistoryState();
// }

// class _TutorHistoryState extends State<TutorHistory> {
//   bool loading = true;
//   List<dynamic> history = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchHistory();
//   }

//   void _goBack() {
//     if (Navigator.canPop(context)) {
//       Navigator.pop(context);
//     } else {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => TutorHome()),
//       );
//     }
//   }

//   // =====================================================
//   // FETCH HISTORY
//   // =====================================================

//   Future<void> fetchHistory() async {
//     try {
//       if (mounted) setState(() => loading = true);

//       final response =
//           await ApiClient.get('/api/Tutor/tutor-class-history');

//       debugPrint("HISTORY STATUS : ${response.statusCode}");
//       debugPrint("HISTORY BODY : ${response.body}");

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(utf8.decode(response.bodyBytes));
//         if (decoded["success"] == true) {
//           history = decoded["data"] ?? [];
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               ApiClient.messageFromBody(response.body) ??
//                   "Failed : ${response.statusCode}",
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint("HISTORY ERROR : $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error : $e")),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   // =====================================================
//   // HISTORY CARD
//   // =====================================================

//   Widget historyCard(dynamic data) {
//     final String studentName =
//         data["student_name"]?.toString() ?? "Student";
//     final String courseName =
//         data["course_name"]?.toString() ?? "Course";
//     final String classDate =
//         data["class_date"]?.toString() ?? "";
//     final String time = data["time"]?.toString() ?? "";
//     final String type =
//         data["request_type"]?.toString() ?? "Normal";

//     return Container(
//       margin: const EdgeInsets.only(bottom: 25),
//       padding: const EdgeInsets.all(25),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(30),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   studentName,
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 10,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.green,
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//                 child: const Text(
//                   "Complete",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 25),

//           Row(
//             children: [
//               const Icon(Icons.menu_book, size: 30),
//               const SizedBox(width: 15),
//               Expanded(
//                 child: Text(
//                   courseName,
//                   style: const TextStyle(fontSize: 20),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 20),

//           Row(
//             children: [
//               const Icon(Icons.calendar_month, size: 30),
//               const SizedBox(width: 15),
//               Text(classDate, style: const TextStyle(fontSize: 20)),
//             ],
//           ),

//           const SizedBox(height: 20),

//           Row(
//             children: [
//               const Icon(Icons.access_time, size: 30),
//               const SizedBox(width: 15),
//               Text(time, style: const TextStyle(fontSize: 20)),
//             ],
//           ),

//           const SizedBox(height: 20),

//           Row(
//             children: [
//               const Icon(Icons.compare_arrows, size: 30),
//               const SizedBox(width: 15),
//               Text(type, style: const TextStyle(fontSize: 20)),
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
//       backgroundColor: const Color(0xfff5eff7),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [

//               // ================================
//               // TOP BAR — sirf back arrow
//               // ================================
//               Row(
//                 children: [
//                   // ✅ SIRF BACK BUTTON
//                   IconButton(
//                     onPressed: _goBack,
//                     icon: const Icon(
//                       Icons.arrow_back,
//                       size: 32,
//                       color: Colors.teal,
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               const Text(
//                 "Class History",
//                 style: TextStyle(
//                   fontSize: 40,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // ================================
//               // BODY
//               // ================================
//               Expanded(
//                 child: loading
//                     ? const Center(child: CircularProgressIndicator())
//                     : history.isEmpty
//                         ? const Center(
//                             child: Text(
//                               "No History Found",
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           )
//                         : RefreshIndicator(
//                             onRefresh: fetchHistory,
//                             child: ListView.builder(
//                               itemCount: history.length,
//                               itemBuilder: (context, index) {
//                                 return historyCard(history[index]);
//                               },
//                             ),
//                           ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }






























































// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // //import 'package:house_of_tutor/TutorDrawer.dart';
// // import 'package:house_of_tutor/services/api_client.dart';

// // class TutorHistory extends StatefulWidget {
// //   const TutorHistory({super.key});

// //   @override
// //   State<TutorHistory> createState() => _TutorHistoryState();
// // }

// // class _TutorHistoryState extends State<TutorHistory> {
// //   final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

// //   // STATES
// //   bool loading = true;
// //   List<dynamic> history = [];

// //   // INIT
// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchHistory();
// //   }

// //   // FETCH HISTORY
// //   Future<void> fetchHistory() async {
// //     try {
// //       if (mounted) {
// //         setState(() {
// //           loading = true;
// //         });
// //       }

// //       final response = await ApiClient.get('/api/Tutor/tutor-class-history');

// //       debugPrint("HISTORY STATUS : ${response.statusCode}");
// //       debugPrint("HISTORY BODY : ${response.body}");

// //       // CRITICAL FIX: Ensure widget is still mounted after network request finishes
// //       if (!mounted) return;

// //       if (response.statusCode == 200) {
// //         final body = utf8.decode(response.bodyBytes);
// //         final decoded = jsonDecode(body);

// //         if (decoded["success"] == true) {
// //           history = decoded["data"] ?? [];
// //         }
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text("Failed : ${response.statusCode}"),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       debugPrint("HISTORY ERROR : $e");
      
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text("Error : $e"),
// //           ),
// //         );
// //       }
// //     } finally {
// //       if (mounted) {
// //         setState(() {
// //           loading = false;
// //         });
// //       }
// //     }
// //   }

// //   // HISTORY CARD
// //   Widget historyCard(dynamic data) {
// //     final studentName = data["student_name"]?.toString() ?? "Student";
// //     final courseName = data["course_name"]?.toString() ?? "Course";
// //     final classDate = data["class_date"]?.toString() ?? "";
// //     final time = data["time"]?.toString() ?? "";
// //     final type = data["request_type"]?.toString() ?? "Normal";

// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 25),
// //       padding: const EdgeInsets.all(25),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(30),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.1),
// //             blurRadius: 10,
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // =================================================
// //           // TOP ROW
// //           // =================================================
// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             children: [
// //               Expanded(
// //                 child: Text(
// //                   studentName,
// //                   style: const TextStyle(
// //                     fontSize: 24,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //               ),
// //               Container(
// //                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
// //                 decoration: BoxDecoration(
// //                   color: Colors.green,
// //                   borderRadius: BorderRadius.circular(30),
// //                 ),
// //                 child: const Text(
// //                   "Complete",
// //                   style: TextStyle(
// //                     color: Colors.white,
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 18,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 25),

// //           // =================================================
// //           // SUBJECT
// //           // =================================================
// //           Row(
// //             children: [
// //               const Icon(Icons.menu_book, size: 30),
// //               const SizedBox(width: 15),
// //               Expanded(
// //                 child: Text(
// //                   courseName,
// //                   style: const TextStyle(fontSize: 20),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 20),

// //           // =================================================
// //           // DATE
// //           // =================================================
// //           Row(
// //             children: [
// //               const Icon(Icons.calendar_month, size: 30),
// //               const SizedBox(width: 15),
// //               Text(
// //                 classDate,
// //                 style: const TextStyle(fontSize: 20),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 20),

// //           // =================================================
// //           // TIME
// //           // =================================================
// //           Row(
// //             children: [
// //               const Icon(Icons.access_time, size: 30),
// //               const SizedBox(width: 15),
// //               Text(
// //                 time,
// //                 style: const TextStyle(fontSize: 20),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 20),

// //           // =================================================
// //           // TYPE
// //           // =================================================
// //           Row(
// //             children: [
// //               const Icon(Icons.compare_arrows, size: 30),
// //               const SizedBox(width: 15),
// //               Text(
// //                 type,
// //                 style: const TextStyle(fontSize: 20),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // UI
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       key: scaffoldKey,
// //       backgroundColor: const Color(0xfff5eff7),
// //       //drawer: const TutorDrawer(),
// //       body: SafeArea(
// //         child: Padding(
// //           padding: const EdgeInsets.all(20),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
           
// //               // TOP BAR
             
// //               Row(
// //                 children: [
// //                   IconButton(
// //                     onPressed: () {
// //                       scaffoldKey.currentState?.openDrawer();
// //                     },
// //                     icon: const Icon(Icons.menu, size: 32),
// //                   ),
// //                   IconButton(
// //                     onPressed: () {
// //                       if (Navigator.canPop(context)) {
// //                         Navigator.pop(context);
// //                       }
// //                     },
// //                     icon: const Icon(Icons.arrow_back, size: 32),
// //                   ),
// //                   const Spacer(),
// //                 ],
// //               ),
// //               const SizedBox(height: 10),

// //               // =================================================
// //               // TITLE
// //               // =================================================
// //               const Text(
// //                 "Class History",
// //                 style: TextStyle(
// //                   fontSize: 40,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               const SizedBox(height: 20),

// //               // =================================================
// //               // BODY
// //               // =================================================
// //               Expanded(
// //                 child: loading
// //                     ? const Center(
// //                         child: CircularProgressIndicator(),
// //                       )
// //                     : history.isEmpty
// //                         ? const Center(
// //                             child: Text(
// //                               "No History Found",
// //                               style: TextStyle(
// //                                 fontSize: 20,
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
// //                           )
// //                         : RefreshIndicator(
// //                             onRefresh: fetchHistory,
// //                             child: ListView.builder(
// //                               itemCount: history.length,
// //                               itemBuilder: (context, index) {
// //                                 return historyCard(history[index]);
// //                               },
// //                             ),
// //                           ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }




































// // import 'dart:convert';

// // import 'package:flutter/material.dart';

// // import 'package:house_of_tutor/TutorDrawer.dart';
// // import 'package:house_of_tutor/services/api_client.dart';

// // class TutorHistory extends StatefulWidget {

// //   const TutorHistory({
// //     super.key,
// //   });

// //   @override
// //   State<TutorHistory> createState() =>
// //       _TutorHistoryState();
// // }

// // class _TutorHistoryState
// //     extends State<TutorHistory> {

// //   final GlobalKey<ScaffoldState>
// //       scaffoldKey =
// //       GlobalKey<ScaffoldState>();

// //   // =====================================================
// //   // STATES
// //   // =====================================================

// //   bool loading = true;

// //   List<dynamic> history = [];

// //   // =====================================================
// //   // INIT
// //   // =====================================================

// //   @override
// //   void initState() {
// //     super.initState();

// //     fetchHistory();
// //   }

// //   // =====================================================
// //   // FETCH HISTORY
// //   // =====================================================

// //   Future<void> fetchHistory() async {

// //     try {

// //       setState(() {
// //         loading = true;
// //       });

// //       final response =
// //           await ApiClient.get(
// //         '/api/Tutor/tutor-class-history',
// //       );

// //       debugPrint(
// //         "HISTORY STATUS : ${response.statusCode}",
// //       );

// //       debugPrint(
// //         "HISTORY BODY : ${response.body}",
// //       );

// //       if (response.statusCode == 200) {

// //         final body = utf8.decode(
// //           response.bodyBytes,
// //         );

// //         final decoded =
// //             jsonDecode(body);

// //         if (decoded["success"] ==
// //             true) {

// //           history =
// //               decoded["data"] ?? [];
// //         }

// //       } else {

// //         ScaffoldMessenger.of(context)
// //             .showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               "Failed : ${response.statusCode}",
// //             ),
// //           ),
// //         );
// //       }

// //     } catch (e) {

// //       debugPrint(
// //         "HISTORY ERROR : $e",
// //       );

// //       ScaffoldMessenger.of(context)
// //           .showSnackBar(
// //         SnackBar(
// //           content: Text(
// //             "Error : $e",
// //           ),
// //         ),
// //       );
// //     }

// //     if (mounted) {

// //       setState(() {
// //         loading = false;
// //       });
// //     }
// //   }

// //   // =====================================================
// //   // HISTORY CARD
// //   // =====================================================

// //   Widget historyCard(
// //     dynamic data,
// //   ) {

// //     final studentName =
// //         data["student_name"]
// //                 ?.toString() ??
// //             "Student";

// //     final courseName =
// //         data["course_name"]
// //                 ?.toString() ??
// //             "Course";

// //     final classDate =
// //         data["class_date"]
// //                 ?.toString() ??
// //             "";

// //     final time =
// //         data["time"]
// //                 ?.toString() ??
// //             "";

// //     final type =
// //         data["request_type"]
// //                 ?.toString() ??
// //             "Normal";

// //     return Container(

// //       margin:
// //           const EdgeInsets.only(
// //         bottom: 25,
// //       ),

// //       padding:
// //           const EdgeInsets.all(25),

// //       decoration: BoxDecoration(

// //         color: Colors.white,

// //         borderRadius:
// //             BorderRadius.circular(30),

// //         boxShadow: [

// //           BoxShadow(
// //             color: Colors.black
// //                 .withOpacity(0.1),

// //             blurRadius: 10,
// //           ),
// //         ],
// //       ),

// //       child: Column(

// //         crossAxisAlignment:
// //             CrossAxisAlignment.start,

// //         children: [

// //           // =================================================
// //           // TOP ROW
// //           // =================================================

// //           Row(

// //             mainAxisAlignment:
// //                 MainAxisAlignment
// //                     .spaceBetween,

// //             children: [

// //               Expanded(

// //                 child: Text(

// //                   studentName,

// //                   style:
// //                       const TextStyle(

// //                     fontSize: 24,

// //                     fontWeight:
// //                         FontWeight.bold,
// //                   ),
// //                 ),
// //               ),

// //               Container(

// //                 padding:
// //                     const EdgeInsets
// //                         .symmetric(

// //                   horizontal: 20,

// //                   vertical: 10,
// //                 ),

// //                 decoration:
// //                     BoxDecoration(

// //                   color: Colors.green,

// //                   borderRadius:
// //                       BorderRadius.circular(
// //                           30),
// //                 ),

// //                 child: const Text(

// //                   "Complete",

// //                   style: TextStyle(

// //                     color:
// //                         Colors.white,

// //                     fontWeight:
// //                         FontWeight.bold,

// //                     fontSize: 18,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),

// //           const SizedBox(height: 25),

// //           // =================================================
// //           // SUBJECT
// //           // =================================================

// //           Row(
// //             children: [

// //               const Icon(
// //                 Icons.menu_book,
// //                 size: 30,
// //               ),

// //               const SizedBox(width: 15),

// //               Expanded(
// //                 child: Text(

// //                   courseName,

// //                   style:
// //                       const TextStyle(
// //                     fontSize: 20,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),

// //           const SizedBox(height: 20),

// //           // =================================================
// //           // DATE
// //           // =================================================

// //           Row(
// //             children: [

// //               const Icon(
// //                 Icons.calendar_month,
// //                 size: 30,
// //               ),

// //               const SizedBox(width: 15),

// //               Text(

// //                 classDate,

// //                 style:
// //                     const TextStyle(
// //                   fontSize: 20,
// //                 ),
// //               ),
// //             ],
// //           ),

// //           const SizedBox(height: 20),

// //           // =================================================
// //           // TIME
// //           // =================================================

// //           Row(
// //             children: [

// //               const Icon(
// //                 Icons.access_time,
// //                 size: 30,
// //               ),

// //               const SizedBox(width: 15),

// //               Text(

// //                 time,

// //                 style:
// //                     const TextStyle(
// //                   fontSize: 20,
// //                 ),
// //               ),
// //             ],
// //           ),

// //           const SizedBox(height: 20),

// //           // =================================================
// //           // TYPE
// //           // =================================================

// //           Row(
// //             children: [

// //               const Icon(
// //                 Icons.compare_arrows,
// //                 size: 30,
// //               ),

// //               const SizedBox(width: 15),

// //               Text(

// //                 type,

// //                 style:
// //                     const TextStyle(
// //                   fontSize: 20,
// //                 ),
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

// //       key: scaffoldKey,

// //       backgroundColor:
// //           const Color(0xfff5eff7),

// //       drawer: const TutorDrawer(),

// //       body: SafeArea(

// //         child: Padding(

// //           padding:
// //               const EdgeInsets.all(
// //             20,
// //           ),

// //           child: Column(

// //             crossAxisAlignment:
// //                 CrossAxisAlignment
// //                     .start,

// //             children: [

// //               // =================================================
// //               // TOP BAR
// //               // =================================================

// //               Row(

// //                 children: [

// //                   // MENU

// //                   IconButton(

// //                     onPressed: () {

// //                       scaffoldKey
// //                           .currentState
// //                           ?.openDrawer();
// //                     },

// //                     icon: const Icon(
// //                       Icons.menu,
// //                       size: 32,
// //                     ),
// //                   ),

// //                   // BACK

// //                   IconButton(

// //                     onPressed: () {

// //                       if (Navigator.canPop(
// //                           context)) {

// //                         Navigator.pop(
// //                             context);
// //                       }
// //                     },

// //                     icon: const Icon(
// //                       Icons.arrow_back,
// //                       size: 32,
// //                     ),
// //                   ),

// //                   const Spacer(),
// //                 ],
// //               ),

// //               const SizedBox(
// //                   height: 10),

// //               // =================================================
// //               // TITLE
// //               // =================================================

// //               const Text(

// //                 "Class History",

// //                 style: TextStyle(

// //                   fontSize: 40,

// //                   fontWeight:
// //                       FontWeight.bold,
// //                 ),
// //               ),

// //               const SizedBox(
// //                   height: 20),

// //               // =================================================
// //               // BODY
// //               // =================================================

// //               Expanded(

// //                 child: loading

// //                     ? const Center(
// //                         child:
// //                             CircularProgressIndicator(),
// //                       )

// //                     : history.isEmpty

// //                         ? const Center(
// //                             child: Text(

// //                               "No History Found",

// //                               style: TextStyle(

// //                                 fontSize: 20,

// //                                 fontWeight:
// //                                     FontWeight.bold,
// //                               ),
// //                             ),
// //                           )

// //                         : RefreshIndicator(

// //                             onRefresh:
// //                                 fetchHistory,

// //                             child:
// //                                 ListView.builder(

// //                               itemCount:
// //                                   history.length,

// //                               itemBuilder:
// //                                   (context,
// //                                       index) {

// //                                 return historyCard(
// //                                   history[index],
// //                                 );
// //                               },
// //                             ),
// //                           ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }