import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class TutorNotification extends StatefulWidget {
  const TutorNotification({super.key});

  @override
  State<TutorNotification> createState() => _TutorNotificationState();
}

class _TutorNotificationState extends State<TutorNotification> {
  // =========================================================
  // STATE VARIABLES
  // =========================================================

  bool isLoading = false;
  List<dynamic> notificationsList = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  // =========================================================
  // FETCH NOTIFICATIONS API
  // =========================================================

  Future<void> fetchNotifications() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get("/api/Tutor/notifications");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          setState(() {
            notificationsList = decoded;
          });
        } else if (decoded is Map && decoded["data"] != null) {
          setState(() {
            notificationsList = decoded["data"];
          });
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load notifications (${response.statusCode})"),
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
  // ACCEPT RE & PRE SCHEDULE REQUEST API
  // =========================================================

  Future<void> acceptRequest(int requestId) async {
    try {
      final response = await ApiClient.put(
        "/api/Tutor/accept-re-and-pre-schedule-request/$requestId",
        {},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request accepted successfully"),
            backgroundColor: Colors.green,
          ),
        );
        fetchNotifications(); // Refresh list
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to accept request"),
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
  // REJECT RE & PRE SCHEDULE REQUEST API
  // =========================================================

  Future<void> rejectRequest(int requestId) async {
    try {
      final response = await ApiClient.put(
        "/api/Tutor/reject-re-and-pre-schedule-request/$requestId",
        {},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request rejected"),
            backgroundColor: Colors.orange,
          ),
        );
        fetchNotifications(); // Refresh list
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to reject request"),
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
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF009688),
                ),
              )
            : notificationsList.isEmpty
                ? Center(
                    child: Text(
                      "No new notifications",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notificationsList.length,
                    itemBuilder: (context, index) {
                      final item = notificationsList[index];

                      final int requestId = item["requestId"] ?? 0;
                      final String requestType = item["requestType"] ?? "Request";
                      final String courseTitle = item["courseTitle"] ?? "Course";
                      final String studentName = item["StudentName"] ?? "Student Name";
                      final String classDate = item["classDate"]?.toString().split("T")[0] ?? "";
                      final String day = item["day"] ?? "";
                      final String time = item["time"] ?? "";

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
                            // REQUEST TYPE PILL
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 13,
                                    color: Color(0xFF00695C),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    requestType,
                                    style: const TextStyle(
                                      color: Color(0xFF00695C),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // COURSE TITLE
                            Text(
                              courseTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // STUDENT NAME
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  studentName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),

                            // CLASS DATE DETAIL
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "CLASS DATE",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    classDate,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // TIME & DAY DETAIL
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_outlined,
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "TIME & DAY",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "$day, $time",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ACCEPT & REJECT BUTTONS
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF009688),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => acceptRequest(requestId),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Accept",
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
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Colors.redAccent,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => rejectRequest(requestId),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.close,
                                          color: Colors.redAccent,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Reject",
                                          style: TextStyle(
                                            color: Colors.redAccent,
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
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}


















// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class TutorNotification extends StatefulWidget {
//   const TutorNotification({super.key});

//   @override
//   State<TutorNotification> createState() => _TutorNotificationState();
// }

// class _TutorNotificationState extends State<TutorNotification> {
//   bool _loading = true;
//   List<Map<String, dynamic>> _items = [];
//   final Set<int> _busyIds = {};

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   // ---------------------------------------------------------------------
//   // DATA
//   // ---------------------------------------------------------------------

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       final res = await ApiClient.get('/api/Tutor/notifications');
//       if (res.statusCode == 200) {
//         final decoded = jsonDecode(utf8.decode(res.bodyBytes));

//         // Handle both a plain list AND a wrapped { data: [...] } response,
//         // same as my-requests does.
//         final list = (decoded is Map && decoded['data'] is List)
//             ? decoded['data']
//             : (decoded is List ? decoded : []);

//         if (mounted) {
//           setState(() {
//             _items = (list as List)
//                 .whereType<Map>()
//                 .map((e) => Map<String, dynamic>.from(e))
//                 .toList();
//           });
//         }
//       } else {
//         if (mounted) {
//           final msg = ApiClient.messageFromBody(res.body) ?? 'Failed to load notifications';
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // ---------------------------------------------------------------------
//   // ACCEPT / REJECT
//   // ---------------------------------------------------------------------

//   Future<void> _respond(int requestId, bool accept) async {
//     setState(() => _busyIds.add(requestId));
//     try {
//       final path = accept
//           ? '/api/Tutor/accept-re-and-pre-schedule-request/$requestId'
//           : '/api/Tutor/reject-re-and-pre-schedule-request/$requestId';

//       final res = await ApiClient.put(path, {}, body: {});

//       if (!mounted) return;

//       if (res.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(accept ? 'Request accepted' : 'Request rejected')),
//         );
//         await _load();
//       } else {
//         final msg = ApiClient.messageFromBody(res.body) ?? 'Action failed (${res.statusCode})';
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Network error: $e')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _busyIds.remove(requestId));
//     }
//   }

//   // ---------------------------------------------------------------------
//   // UI HELPERS
//   // ---------------------------------------------------------------------

//   Widget _labelValue(String label, String value) {
//     if (value.isEmpty) return const SizedBox.shrink();
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(color: Colors.grey, fontSize: 14),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------
//   // UI
//   // ---------------------------------------------------------------------

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.teal,
//         title: const Text(
//           'Notifications',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _items.isEmpty
//               ? RefreshIndicator(
//                   onRefresh: _load,
//                   child: ListView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     children: const [
//                       SizedBox(height: 200),
//                       Center(child: Text('No pending requests')),
//                     ],
//                   ),
//                 )
//               : RefreshIndicator(
//                   onRefresh: _load,
//                   child: ListView.separated(
//                     padding: const EdgeInsets.all(12),
//                     itemCount: _items.length,
//                     separatorBuilder: (_, __) => const SizedBox(height: 14),
//                     itemBuilder: (context, index) {
//                       final item = _items[index];

//                       final requestId = item['requestId'] ?? item['RequestId'];
//                       final id = requestId is int
//                           ? requestId
//                           : int.tryParse(requestId.toString()) ?? -1;
//                       final busy = _busyIds.contains(id);

//                       final type =
//                           (item['requestType'] ?? item['RequestType'] ?? '').toString();
//                       final studentName =
//                           (item['studentName'] ?? item['StudentName'] ?? '').toString();
//                       final courseTitle =
//                           (item['courseTitle'] ?? item['CourseTitle'] ?? '').toString();
//                       final day = (item['day'] ?? item['Day'] ?? '').toString();
//                       final time = (item['time'] ?? item['Time'] ?? '').toString();
//                       final classDate =
//                           (item['classDate'] ?? item['ClassDate'] ?? '').toString();

//                       final isReschedule = type.toLowerCase() == 'reschedule';

//                       return Container(
//                         padding: const EdgeInsets.all(18),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(18),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.05),
//                               blurRadius: 10,
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // ---- Type badge ----
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue.shade50,
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: Text(
//                                 type,
//                                 style: const TextStyle(
//                                   color: Colors.teal,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 16),

//                             _labelValue('Student', studentName),
//                             _labelValue('Course', courseTitle),
//                             _labelValue('Day', day),
//                             _labelValue('Time', time),
//                             _labelValue('Class Date', classDate),

//                             const SizedBox(height: 6),

//                             // ---- Accept / Reject ----
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: ElevatedButton(
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.green,
//                                       foregroundColor: Colors.white,
//                                       padding: const EdgeInsets.symmetric(vertical: 14),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(30),
//                                       ),
//                                     ),
//                                     onPressed: busy || id < 0 ? null : () => _respond(id, true),
//                                     child: busy
//                                         ? const SizedBox(
//                                             width: 18,
//                                             height: 18,
//                                             child: CircularProgressIndicator(
//                                               strokeWidth: 2,
//                                               color: Colors.white,
//                                             ),
//                                           )
//                                         : const Text(
//                                             'Accept',
//                                             style: TextStyle(
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: ElevatedButton(
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.red.shade400,
//                                       foregroundColor: Colors.white,
//                                       padding: const EdgeInsets.symmetric(vertical: 14),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(30),
//                                       ),
//                                     ),
//                                     onPressed: busy || id < 0 ? null : () => _respond(id, false),
//                                     child: const Text(
//                                       'Reject',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//     );
//   }
// }
