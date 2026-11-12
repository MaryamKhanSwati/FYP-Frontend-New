// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class StudentNotfications extends StatefulWidget {
  const StudentNotfications({Key? key}) : super(key: key);

  @override
  _StudentNotficationsState createState() => _StudentNotficationsState();
}

class _StudentNotficationsState extends State<StudentNotfications> {
  bool isLoading = true;
  List<dynamic> requestList = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      final response = await ApiClient.get('/api/Student/pre-reschedule-requests');

      if (response.statusCode == 200) {
        final data = await ApiClient.decodeJson(response);
        setState(() {
          requestList = data ?? [];
          isLoading = false;
        });
      } else {
        final message = ApiClient.messageFromBody(response.body) ?? 'Failed to load requests: ${response.statusCode}';
        setState(() {
          errorMessage = message;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  Future<void> handleAccept(int requestId, String requestType) async {
    try {
      String endpoint = requestType.toLowerCase() == 'reschedule'
          ? '/api/Student/accept-reschedule/$requestId'
          : '/api/Student/accept-preschedule/$requestId';

      final response = await ApiClient.post(endpoint, null);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accepted successfully')),
        );
        fetchRequests(); // Refresh list
      } else {
        final message = ApiClient.messageFromBody(response.body) ?? 'Failed to accept request';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> handleReject(int requestId) async {
    try {
      final response = await ApiClient.post('/api/Student/reject-request/$requestId', null);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected successfully')),
        );
        fetchRequests(); // Refresh list
      } else {
        final message = ApiClient.messageFromBody(response.body) ?? 'Failed to reject request';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.school, color: Colors.teal),
            SizedBox(width: 8),
            Text(
              'House of Tutor',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule Requests',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Review and manage class pre-schedule and reschedule requests',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: requestList.isEmpty
                            ? const Center(
                                child: Text(
                                  'No pending schedule requests found.',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              )
                            : ListView.builder(
                                itemCount: requestList.length,
                                itemBuilder: (context, index) {
                                  final req = requestList[index];
                                  final requestType = req['request_type'] ?? 'Request';
                                  final status = req['status'] ?? 'Pending';
                                  final day = req['day'] ?? '';
                                  final time = req['time'] ?? '';
                                  final classDate = req['class_date'] ?? 'Not provided';
                                  final tutorName = req['tutor_name'] ?? 'Not provided';
                                  final courseName = req['course_name'] ?? 'Not provided';
                                  final requestId = req['request_id'];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.teal.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    requestType.toLowerCase() == 'reschedule'
                                                        ? Icons.update
                                                        : Icons.event_available,
                                                    size: 14,
                                                    color: Colors.teal,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    requestType,
                                                    style: const TextStyle(
                                                      color: Colors.teal,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(Icons.circle, size: 8, color: Colors.amber),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Pending',
                                                    style: TextStyle(
                                                      color: Colors.amber,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          '$day, $time',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              _buildDetailRow(Icons.calendar_today_outlined, 'Date:', classDate),
                                              const SizedBox(height: 8),
                                              _buildDetailRow(Icons.person_outline, 'Tutor:', tutorName),
                                              const SizedBox(height: 8),
                                              _buildDetailRow(Icons.book_outlined, 'Course:', courseName),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => handleAccept(requestId, requestType),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.teal,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                                icon: const Icon(Icons.check, size: 16),
                                                label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => handleReject(requestId),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.redAccent,
                                                  side: const BorderSide(color: Colors.redAccent, width: 1),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                                icon: const Icon(Icons.close, size: 16),
                                                label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}



















// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class StudentNotifications extends StatefulWidget {
//   const StudentNotifications({super.key});

//   @override
//   State<StudentNotifications> createState() =>
//       _StudentNotificationsState();
// }

// class _StudentNotificationsState
//     extends State<StudentNotifications> {

//   bool loading = true;

//   List requests = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchRequests();
//   }

//   // ================= FETCH =================

//   Future<void> fetchRequests() async {

//     setState(() {
//       loading = true;
//     });

//     try {

//       final response = await ApiClient.get(
//         "/api/Student/pre-reschedule-requests",
//       );

//       print(response.body);

//       if (response.statusCode == 200) {

//         final data = jsonDecode(
//           utf8.decode(response.bodyBytes),
//         );

//         setState(() {
//           requests = data;
//         });
//       }

//     } catch (e) {

//       print(e);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//         ),
//       );
//     }

//     setState(() {
//       loading = false;
//     });
//   }

//   // ================= ACCEPT =================

//   Future<void> acceptRequest(
//     int requestId,
//     String type,
//   ) async {

//     try {

//       String endpoint = "";

//       if (type == "Preschedule") {

//         endpoint =
//             "/api/Student/accept-preschedule/$requestId";

//       } else {

//         endpoint =
//             "/api/Student/accept-reschedule/$requestId";
//       }

//       final response =
//           await ApiClient.post(endpoint, {});

//       print(response.body);

//       if (response.statusCode == 200) {

//         ScaffoldMessenger.of(context)
//             .showSnackBar(

//           const SnackBar(
//             content:
//                 Text("Request Accepted"),
//           ),
//         );

//         fetchRequests();

//       } else {

//         ScaffoldMessenger.of(context)
//             .showSnackBar(

//           const SnackBar(
//             content:
//                 Text("Accept Failed"),
//           ),
//         );
//       }

//     } catch (e) {

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//         ),
//       );
//     }
//   }

//   // ================= REJECT =================

//   Future<void> rejectRequest(
//     int requestId,
//   ) async {

//     try {

//       final response = await ApiClient.post(
//         "/api/Student/reject-request/$requestId",
//         {},
//       );

//       print(response.body);

//       if (response.statusCode == 200) {

//         ScaffoldMessenger.of(context)
//             .showSnackBar(

//           const SnackBar(
//             content:
//                 Text("Request Rejected"),
//           ),
//         );

//         fetchRequests();

//       } else {

//         ScaffoldMessenger.of(context)
//             .showSnackBar(

//           const SnackBar(
//             content:
//                 Text("Reject Failed"),
//           ),
//         );
//       }

//     } catch (e) {

//       ScaffoldMessenger.of(context)
//           .showSnackBar(

//         SnackBar(
//           content: Text(e.toString()),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(

//       backgroundColor:
//           const Color(0xfff5f5f5),

//       appBar: AppBar(

//         backgroundColor: Colors.white,

//         elevation: 1,

//         leading: IconButton(

//           icon: const Icon(
//             Icons.arrow_back,
//             color: Colors.black,
//           ),

//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),

//         centerTitle: true,

//         title: Column(
//           children: [

//             Image.asset(
//               "assets/images/logo.png",
//               height: 35,
//             ),

//             const SizedBox(height: 4),

//             const Text(

//               "House of Tutor",

//               style: TextStyle(
//                 color: Colors.teal,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),

//       body: loading

//           ? const Center(
//               child:
//                   CircularProgressIndicator(),
//             )

//           : requests.isEmpty

//               ? const Center(

//                   child: Text(
//                     "No Requests Found",
//                     style: TextStyle(
//                       fontSize: 18,
//                     ),
//                   ),
//                 )

//               : ListView.builder(

//                   padding:
//                       const EdgeInsets.all(16),

//                   itemCount: requests.length,

//                   itemBuilder: (context, index) {

//                     final item = requests[index];

//                     return Container(

//                       margin:
//                           const EdgeInsets.only(
//                         bottom: 20,
//                       ),

//                       padding:
//                           const EdgeInsets.all(20),

//                       decoration: BoxDecoration(

//                         color: Colors.white,

//                         borderRadius:
//                             BorderRadius.circular(
//                                 24),

//                         boxShadow: [

//                           BoxShadow(

//                             color: Colors.black
//                                 .withOpacity(0.08),

//                             blurRadius: 8,

//                             offset:
//                                 const Offset(0, 3),
//                           )
//                         ],
//                       ),

//                       child: Column(

//                         crossAxisAlignment:
//                             CrossAxisAlignment.start,

//                         children: [

//                           // ================= TYPE =================

//                           Container(

//                             padding:
//                                 const EdgeInsets.symmetric(
//                               horizontal: 18,
//                               vertical: 8,
//                             ),

//                             decoration: BoxDecoration(

//                               color:
//                                   item["request_type"] ==
//                                           "Reschedule"
//                                       ? Colors.orange
//                                       : Colors.teal,

//                               borderRadius:
//                                   BorderRadius.circular(
//                                       30),
//                             ),

//                             child: Text(

//                               item["request_type"],

//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight:
//                                     FontWeight.bold,
//                               ),
//                             ),
//                           ),

//                           const SizedBox(height: 22),

//                           // ================= TIME =================

//                           Text(

//                             "${item["day"]} , ${item["time"]}",

//                             style: const TextStyle(

//                               fontSize: 30,

//                               color: Colors.teal,

//                               fontWeight:
//                                   FontWeight.bold,
//                             ),
//                           ),

//                           const SizedBox(height: 18),

//                           // ================= DATE =================

//                           Text(

//                             "📅 Date : ${item["class_date"]}",

//                             style: const TextStyle(
//                               fontSize: 18,
//                             ),
//                           ),

//                           const SizedBox(height: 10),

//                           // ================= TUTOR =================

//                           Text(

//                             "🧑‍🏫 Tutor : ${item["tutor_name"]}",

//                             style: const TextStyle(
//                               fontSize: 18,
//                             ),
//                           ),

//                           const SizedBox(height: 10),

//                           // ================= COURSE =================

//                           Text(

//                             "📘 Course : ${item["course_name"]}",

//                             style: const TextStyle(
//                               fontSize: 18,
//                             ),
//                           ),

//                           const SizedBox(height: 18),

//                           const Text(

//                             "• Pending",

//                             style: TextStyle(

//                               color: Colors.orange,

//                               fontSize: 18,

//                               fontWeight:
//                                   FontWeight.bold,
//                             ),
//                           ),

//                           const SizedBox(height: 25),

//                           Row(
//                             children: [

//                               // ================= ACCEPT =================

//                               Expanded(

//                                 child: ElevatedButton(

//                                   style:
//                                       ElevatedButton
//                                           .styleFrom(

//                                     backgroundColor:
//                                         Colors.teal,

//                                     padding:
//                                         const EdgeInsets.symmetric(
//                                       vertical: 16,
//                                     ),

//                                     shape:
//                                         RoundedRectangleBorder(
//                                       borderRadius:
//                                           BorderRadius.circular(
//                                               40),
//                                     ),
//                                   ),

//                                   onPressed: () {

//                                     acceptRequest(

//                                       item["request_id"],

//                                       item["request_type"],
//                                     );
//                                   },

//                                   child: const Text(

//                                     "✓ Accept",

//                                     style: TextStyle(

//                                       color: Colors.white,

//                                       fontSize: 18,

//                                       fontWeight:
//                                           FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ),

//                               const SizedBox(width: 16),

//                               // ================= REJECT =================

//                               Expanded(

//                                 child: OutlinedButton(

//                                   style:
//                                       OutlinedButton
//                                           .styleFrom(

//                                     padding:
//                                         const EdgeInsets.symmetric(
//                                       vertical: 16,
//                                     ),

//                                     side: const BorderSide(
//                                       color: Colors.red,
//                                     ),

//                                     shape:
//                                         RoundedRectangleBorder(
//                                       borderRadius:
//                                           BorderRadius.circular(
//                                               40),
//                                     ),
//                                   ),

//                                   onPressed: () {

//                                     rejectRequest(
//                                       item["request_id"],
//                                     );
//                                   },

//                                   child: const Text(

//                                     "✕ Reject",

//                                     style: TextStyle(

//                                       color: Colors.red,

//                                       fontSize: 18,

//                                       fontWeight:
//                                           FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }