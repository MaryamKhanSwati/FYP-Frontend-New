import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class TutorPaymentScreen extends StatefulWidget {
  const TutorPaymentScreen({super.key});

  @override
  State<TutorPaymentScreen> createState() => _TutorPaymentScreenState();
}

class _TutorPaymentScreenState extends State<TutorPaymentScreen> {
  // =========================================================
  // STATE VARIABLES
  // =========================================================

  bool isLoading = false;
  List<dynamic> paymentList = [];

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  // =========================================================
  // FETCH PAYMENT LIST API
  // =========================================================

  Future<void> fetchPayments() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get("/api/Tutor/payment-list");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          setState(() {
            paymentList = decoded;
          });
        } else if (decoded is Map && decoded["data"] != null) {
          setState(() {
            paymentList = decoded["data"];
          });
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load payments (${response.statusCode})"),
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
  // UPDATE PAYMENT STATUS API (Received / NotReceived)
  // =========================================================

  Future<void> updatePaymentStatus(int paymentId, String status) async {
    try {
      final response = await ApiClient.put(
        "/api/Tutor/payment-status",
        {
          "paymentId": paymentId,
          "status": status,
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment status updated to $status"),
            backgroundColor: Colors.green,
          ),
        );
        fetchPayments(); // Refresh list
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update payment status"),
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
  // CALCULATE TOTAL COLLECTED & PENDING
  // =========================================================

  double _calculateTotalCollected() {
    double total = 0;
    for (var item in paymentList) {
      if (item["tutorStatus"] == "Received") {
        total += (item["amount"] ?? 0).toDouble();
      }
    }
    return total;
  }

  double _calculatePendingClearance() {
    double total = 0;
    for (var item in paymentList) {
      if (item["tutorStatus"] != "Received") {
        total += (item["amount"] ?? 0).toDouble();
      }
    }
    return total;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final double totalCollected = _calculateTotalCollected();
    final double pendingClearance = _calculatePendingClearance();

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
                    // HEADER TITLE ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Payment Overview",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "${paymentList.length} Record${paymentList.length == 1 ? '' : 's'}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SUMMARY OVERVIEW CARD
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  "TOTAL COLLECTED",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Rs. ${totalCollected.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF009688),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 35,
                            width: 1,
                            color: Colors.grey.shade200,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  "PENDING CLEARANCE",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Rs. ${pendingClearance.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PAYMENT LIST VIEW
                    Expanded(
                      child: paymentList.isEmpty
                          ? Center(
                              child: Text(
                                "No payment records found",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: paymentList.length,
                              itemBuilder: (context, index) {
                                final item = paymentList[index];

                                final int paymentId = item["paymentId"] ?? 0;
                                final String studentName = item["student"] ?? "Student Name";
                                final String courseTitle = item["course"] ?? "Course Title";
                                final double amount = (item["amount"] ?? 0).toDouble();
                                final String paymentType = item["paymentType"] ?? "Full";
                                final String parentStatus = item["parentStatus"] ?? "Sent";
                                final String tutorStatus = item["tutorStatus"] ?? "NotReceived";
                                final String paymentDate =
                                    item["paymentDate"]?.toString().split("T")[0] ?? "";

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
                                      // TOP ITEM HEADER: Avatar/Name + Amount
                                      Row(
                                        children: [
                                          Container(
                                            height: 45,
                                            width: 45,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF009688),
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 24,
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
                                                  courseTitle,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                "AMOUNT",
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "Rs. ${amount.toStringAsFixed(0)}",
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF009688),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Divider(height: 1),
                                      ),

                                      // DETAILS ROW: Payment Method & Date
                                      _detailRow(
                                        icon: Icons.payment_outlined,
                                        label: "Payment Method",
                                        value: paymentType,
                                      ),
                                      const SizedBox(height: 8),
                                      _detailRow(
                                        icon: Icons.calendar_today_outlined,
                                        label: "Transaction Date",
                                        value: paymentDate,
                                      ),

                                      const SizedBox(height: 12),

                                      // STATUS BADGES ROW
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "PARENT STATUS",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade50,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.circle, size: 8, color: Colors.redAccent),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        parentStatus,
                                                        style: const TextStyle(
                                                          color: Colors.redAccent,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "TUTOR STATUS",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: tutorStatus == "Received"
                                                        ? Colors.teal.shade50
                                                        : Colors.orange.shade50,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.circle,
                                                        size: 8,
                                                        color: tutorStatus == "Received"
                                                            ? const Color(0xFF00695C)
                                                            : Colors.orange,
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        tutorStatus,
                                                        style: TextStyle(
                                                          color: tutorStatus == "Received"
                                                              ? const Color(0xFF00695C)
                                                              : Colors.orange,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // ACTION BUTTONS (Mark Received / Not Received)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF009688),
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: () => updatePaymentStatus(paymentId, "Received"),
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "Mark Received",
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
                                                side: const BorderSide(color: Colors.redAccent),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: () => updatePaymentStatus(paymentId, "NotReceived"),
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 16),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "Not Received",
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

// class TutorPayment extends StatefulWidget {
//   const TutorPayment({super.key});

//   @override
//   State<TutorPayment> createState() => _TutorPaymentState();
// }

// class _TutorPaymentState extends State<TutorPayment> {
//   bool isLoading = true;
//   List payments = [];

//   @override
//   void initState() {
//     super.initState();
//     loadPayments();
//   }

//   // =====================================================
//   // LOAD PAYMENTS
//   // =====================================================

//   Future<void> loadPayments() async {
//     setState(() => isLoading = true);

//     try {
//       final response = await ApiClient.get("/api/Tutor/payment-list");

//       debugPrint("PAYMENTS STATUS : ${response.statusCode}");
//       debugPrint("PAYMENTS BODY : ${response.body}");

//       if (response.statusCode == 200) {
//         setState(() {
//           payments = jsonDecode(utf8.decode(response.bodyBytes));
//         });
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 ApiClient.messageFromBody(response.body) ??
//                     "Unable to load payments.",
//               ),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("PAYMENTS ERROR : $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString())),
//         );
//       }
//     }

//     if (mounted) setState(() => isLoading = false);
//   }

//   // =====================================================
//   // UPDATE PAYMENT STATUS
//   // =====================================================

//   Future<void> updatePaymentStatus(int paymentId, String status) async {
//     try {
//       final response = await ApiClient.put(
//         "/api/Tutor/payment-status",
//         {
//           "paymentId": paymentId,
//           "status": status,
//         },
//       );

//       debugPrint("UPDATE STATUS : ${response.statusCode}");
//       debugPrint("UPDATE BODY : ${response.body}");

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               status == "Received"
//                   ? "Payment marked as Received."
//                   : "Payment marked as Not Received.",
//             ),
//           ),
//         );
//         loadPayments();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               ApiClient.messageFromBody(response.body) ??
//                   "Failed to update payment.",
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint("UPDATE ERROR : $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString())),
//         );
//       }
//     }
//   }

//   // =====================================================
//   // HELPERS
//   // =====================================================

//   String formatDate(String value) {
//     if (value.isEmpty) return "";
//     try {
//       DateTime date = DateTime.parse(value);
//       return "${date.day}/${date.month}/${date.year}";
//     } catch (_) {
//       return value;
//     }
//   }

//   // =====================================================
//   // UI
//   // =====================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xfff4f5f9),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () {
//             if (Navigator.canPop(context)) {
//               Navigator.pop(context);
//             } else {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => TutorHome()),
//               );
//             }
//           },
//         ),
//         centerTitle: true,
//         title: Column(
//           children: [
//             Image.asset(
//               "assets/images/logo.png",
//               height: 45,
//             ),
//             const SizedBox(height: 3),
//             const Text(
//               "House of Tutor",
//               style: TextStyle(
//                 color: Color(0xff00897b),
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: RefreshIndicator(
//         onRefresh: loadPayments,
//         child: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : payments.isEmpty
//                 ? ListView(
//                     children: const [
//                       SizedBox(height: 200),
//                       Center(
//                         child: Text(
//                           "No Payments Found",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   )
//                 : ListView(
//                     padding: const EdgeInsets.all(16),
//                     children: [
//                       const Text(
//                         "Payments",
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 15),
//                       ...payments.map((payment) => paymentCard(payment)),
//                     ],
//                   ),
//       ),
//     );
//   }

//   // =====================================================
//   // PAYMENT CARD
//   // =====================================================

//   Widget paymentCard(dynamic payment) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Container(
//                   height: 64,
//                   width: 64,
//                   decoration: const BoxDecoration(
//                     color: Color(0xff2D8CFF),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.person,
//                     color: Colors.white,
//                     size: 36,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         payment["student"] ?? "",
//                         style: const TextStyle(
//                           fontSize: 19,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         payment["course"] ?? "",
//                         style: TextStyle(
//                           color: Colors.grey.shade600,
//                           fontSize: 17,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Text(
//                   "Rs. ${payment["amount"] ?? 0}",
//                   style: const TextStyle(
//                     color: Colors.green,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 20,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 18),
//             Divider(color: Colors.grey.shade300),
//             const SizedBox(height: 18),
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.orange.shade50,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Icon(Icons.credit_card, color: Colors.orange),
//                 ),
//                 const SizedBox(width: 15),
//                 const Expanded(
//                   child: Text(
//                     "Payment Type",
//                     style: TextStyle(fontSize: 18, color: Colors.grey),
//                   ),
//                 ),
//                 Text(
//                   payment["paymentType"] ?? "",
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Icon(Icons.calendar_month, color: Colors.blue),
//                 ),
//                 const SizedBox(width: 15),
//                 const Expanded(
//                   child: Text(
//                     "Date",
//                     style: TextStyle(fontSize: 18, color: Colors.grey),
//                   ),
//                 ),
//                 Text(
//                   formatDate(payment["paymentDate"] ?? ""),
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 28),
//             const Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     "Parent",
//                     style: TextStyle(fontSize: 18, color: Colors.grey),
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     "Tutor",
//                     style: TextStyle(fontSize: 18, color: Colors.grey),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Expanded(child: statusChip(payment["parentStatus"] ?? "")),
//                 Expanded(child: statusChip(payment["tutorStatus"] ?? "")),
//               ],
//             ),
//             const SizedBox(height: 25),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                       minimumSize: const Size(double.infinity, 56),
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(18),
//                       ),
//                     ),
//                     icon: const Icon(Icons.check_circle),
//                     label: const Text(
//                       "Received",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     onPressed: payment["tutorStatus"] == "Received"
//                         ? null
//                         : () {
//                             updatePaymentStatus(
//                               payment["paymentId"],
//                               "Received",
//                             );
//                           },
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       foregroundColor: Colors.white,
//                       minimumSize: const Size(double.infinity, 56),
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(18),
//                       ),
//                     ),
//                     icon: const Icon(Icons.cancel),
//                     label: const Text(
//                       "Not Received",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     onPressed: payment["tutorStatus"] == "NotReceived"
//                         ? null
//                         : () {
//                             updatePaymentStatus(
//                               payment["paymentId"],
//                               "NotReceived",
//                             );
//                           },
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // =====================================================
//   // STATUS CHIP
//   // =====================================================

//   Widget statusChip(String status) {
//     Color color = Colors.orange;

//     if (status.toLowerCase() == "received") {
//       color = Colors.green;
//     } else if (status.toLowerCase() == "sent" ||
//         status.toLowerCase() == "pending" ||
//         status.toLowerCase() == "notreceived") {
//       color = Colors.red;
//     }

//     String text = status == "NotReceived" ? "Not Received" : status;

//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(30),
//           border: Border.all(color: color, width: 2),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.circle, color: color, size: 10),
//             const SizedBox(width: 8),
//             Text(
//               text,
//               style: TextStyle(
//                 color: color,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


















// // import 'dart:convert';

// // import 'package:flutter/material.dart';
// // import 'package:house_of_tutor/TutorHome.dart';
// // import 'package:house_of_tutor/services/api_client.dart';

// // class TutorPayment extends StatefulWidget {
// //   const TutorPayment({Key? key}) : super(key: key);

// //   @override
// //   State<TutorPayment> createState() => _TutorPaymentState();
// // }

// // class _TutorPaymentState extends State<TutorPayment> {
// //   bool isLoading = true;
// //   List payments = [];

// //   @override
// //   void initState() {
// //     super.initState();
// //     loadPayments();
// //   }

// //   // =====================================================
// //   // LOAD PAYMENTS
// //   // =====================================================

// //   Future<void> loadPayments() async {
// //     setState(() => isLoading = true);

// //     try {
// //       final response = await ApiClient.get("/api/Tutor/payment-list");

// //       debugPrint("PAYMENTS STATUS : ${response.statusCode}");
// //       debugPrint("PAYMENTS BODY : ${response.body}");

// //       if (response.statusCode == 200) {
// //         setState(() {
// //           payments = jsonDecode(utf8.decode(response.bodyBytes));
// //         });
// //       } else {
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text(
// //                 ApiClient.messageFromBody(response.body) ??
// //                     "Unable to load payments.",
// //               ),
// //             ),
// //           );
// //         }
// //       }
// //     } catch (e) {
// //       debugPrint("PAYMENTS ERROR : $e");
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text(e.toString())),
// //         );
// //       }
// //     }

// //     if (mounted) setState(() => isLoading = false);
// //   }

// //   // =====================================================
// //   // UPDATE PAYMENT STATUS
// //   // =====================================================

// //   Future<void> updatePaymentStatus(int paymentId, String status) async {
// //     try {
// //       // ✅ FIX: Map pass karo, jsonEncode nahi
// //       final response = await ApiClient.put(
// //         "/api/Tutor/payment-status",
// //         {
// //           "paymentId": paymentId,
// //           "status": status,
// //         }, body: {},
// //       );

// //       debugPrint("UPDATE STATUS : ${response.statusCode}");
// //       debugPrint("UPDATE BODY : ${response.body}");

// //       if (!mounted) return;

// //       if (response.statusCode == 200) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               status == "Received"
// //                   ? "Payment marked as Received."
// //                   : "Payment marked as Not Received.",
// //             ),
// //           ),
// //         );
// //         loadPayments();
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               ApiClient.messageFromBody(response.body) ??
// //                   "Failed to update payment.",
// //             ),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       debugPrint("UPDATE ERROR : $e");
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text(e.toString())),
// //         );
// //       }
// //     }
// //   }

// //   // =====================================================
// //   // HELPERS
// //   // =====================================================

// //   String formatDate(String value) {
// //     if (value.isEmpty) return "";
// //     try {
// //       DateTime date = DateTime.parse(value);
// //       return "${date.day}/${date.month}/${date.year}";
// //     } catch (_) {
// //       return value;
// //     }
// //   }

// //   // =====================================================
// //   // UI
// //   // =====================================================

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xfff4f5f9),

// //       // ✅ FIX: Drawer hata diya, sirf back arrow
// //       appBar: AppBar(
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back, color: Colors.black),
// //           onPressed: () {
// //             if (Navigator.canPop(context)) {
// //               Navigator.pop(context);
// //             } else {
// //               Navigator.pushReplacement(
// //                 context,
// //                 MaterialPageRoute(builder: (_) => TutorHome()),
// //               );
// //             }
// //           },
// //         ),
// //         centerTitle: true,
// //         title: Column(
// //           children: [
// //             // ✅ FIX: assets/images/logo.png
// //             Image.asset(
// //               "assets/images/logo.png",
// //               height: 45,
// //             ),
// //             const SizedBox(height: 3),
// //             const Text(
// //               "House of Tutor",
// //               style: TextStyle(
// //                 color: Color(0xff00897b),
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 18,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),

// //       body: RefreshIndicator(
// //         onRefresh: loadPayments,
// //         child: isLoading
// //             ? const Center(child: CircularProgressIndicator())
// //             : payments.isEmpty
// //                 ? ListView(
// //                     children: const [
// //                       SizedBox(height: 200),
// //                       Center(
// //                         child: Text(
// //                           "No Payments Found",
// //                           style: TextStyle(
// //                             fontSize: 18,
// //                             fontWeight: FontWeight.w600,
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   )
// //                 : ListView(
// //                     padding: const EdgeInsets.all(16),
// //                     children: [
// //                       const Text(
// //                         "Payments",
// //                         style: TextStyle(
// //                           fontSize: 24,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                       const SizedBox(height: 15),
// //                       ...payments.map((payment) => paymentCard(payment)),
// //                     ],
// //                   ),
// //       ),
// //     );
// //   }

// //   // =====================================================
// //   // PAYMENT CARD
// //   // =====================================================

// //   Widget paymentCard(dynamic payment) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 20),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(24),
// //         boxShadow: const [
// //           BoxShadow(
// //             color: Colors.black12,
// //             blurRadius: 10,
// //             offset: Offset(0, 4),
// //           ),
// //         ],
// //       ),
// //       child: Padding(
// //         padding: const EdgeInsets.all(18),
// //         child: Column(
// //           children: [
// //             // ================================
// //             // HEADER — Student + Course + Amount
// //             // ================================
// //             Row(
// //               children: [
// //                 Container(
// //                   height: 64,
// //                   width: 64,
// //                   decoration: const BoxDecoration(
// //                     color: Color(0xff2D8CFF),
// //                     shape: BoxShape.circle,
// //                   ),
// //                   child: const Icon(
// //                     Icons.person,
// //                     color: Colors.white,
// //                     size: 36,
// //                   ),
// //                 ),
// //                 const SizedBox(width: 16),
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         payment["student"] ?? "",
// //                         style: const TextStyle(
// //                           fontSize: 19,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                       const SizedBox(height: 4),
// //                       Text(
// //                         payment["course"] ?? "",
// //                         style: TextStyle(
// //                           color: Colors.grey.shade600,
// //                           fontSize: 17,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 Text(
// //                   "Rs. ${payment["amount"] ?? 0}",
// //                   style: const TextStyle(
// //                     color: Colors.green,
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 20,
// //                   ),
// //                 ),
// //               ],
// //             ),

// //             const SizedBox(height: 18),
// //             Divider(color: Colors.grey.shade300),
// //             const SizedBox(height: 18),

// //             // ================================
// //             // PAYMENT TYPE
// //             // ================================
// //             Row(
// //               children: [
// //                 Container(
// //                   padding: const EdgeInsets.all(10),
// //                   decoration: BoxDecoration(
// //                     color: Colors.orange.shade50,
// //                     borderRadius: BorderRadius.circular(10),
// //                   ),
// //                   child: const Icon(Icons.credit_card, color: Colors.orange),
// //                 ),
// //                 const SizedBox(width: 15),
// //                 const Expanded(
// //                   child: Text(
// //                     "Payment Type",
// //                     style: TextStyle(fontSize: 18, color: Colors.grey),
// //                   ),
// //                 ),
// //                 Text(
// //                   payment["paymentType"] ?? "",
// //                   style: const TextStyle(
// //                     fontSize: 18,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //               ],
// //             ),

// //             const SizedBox(height: 20),

// //             // ================================
// //             // DATE
// //             // ================================
// //             Row(
// //               children: [
// //                 Container(
// //                   padding: const EdgeInsets.all(10),
// //                   decoration: BoxDecoration(
// //                     color: Colors.blue.shade50,
// //                     borderRadius: BorderRadius.circular(10),
// //                   ),
// //                   child: const Icon(Icons.calendar_month, color: Colors.blue),
// //                 ),
// //                 const SizedBox(width: 15),
// //                 const Expanded(
// //                   child: Text(
// //                     "Date",
// //                     style: TextStyle(fontSize: 18, color: Colors.grey),
// //                   ),
// //                 ),
// //                 Text(
// //                   formatDate(payment["paymentDate"] ?? ""),
// //                   style: const TextStyle(
// //                     fontSize: 18,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //               ],
// //             ),

// //             const SizedBox(height: 28),

// //             // ================================
// //             // STATUS LABELS
// //             // ================================
// //             const Row(
// //               children: [
// //                 Expanded(
// //                   child: Text(
// //                     "Parent",
// //                     style: TextStyle(fontSize: 18, color: Colors.grey),
// //                   ),
// //                 ),
// //                 Expanded(
// //                   child: Text(
// //                     "Tutor",
// //                     style: TextStyle(fontSize: 18, color: Colors.grey),
// //                   ),
// //                 ),
// //               ],
// //             ),

// //             const SizedBox(height: 10),

// //             // ================================
// //             // STATUS CHIPS
// //             // ================================
// //             Row(
// //               children: [
// //                 Expanded(child: statusChip(payment["parentStatus"] ?? "")),
// //                 Expanded(child: statusChip(payment["tutorStatus"] ?? "")),
// //               ],
// //             ),

// //             const SizedBox(height: 25),

// //             // ================================
// //             // BUTTONS
// //             // ================================
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: ElevatedButton.icon(
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.green,
// //                       foregroundColor: Colors.white,
// //                       minimumSize: const Size(double.infinity, 56),
// //                       elevation: 0,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(18),
// //                       ),
// //                     ),
// //                     icon: const Icon(Icons.check_circle),
// //                     label: const Text(
// //                       "Received",
// //                       style: TextStyle(
// //                         fontSize: 18,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                     onPressed: payment["tutorStatus"] == "Received"
// //                         ? null
// //                         : () {
// //                             updatePaymentStatus(
// //                               payment["paymentId"],
// //                               "Received",
// //                             );
// //                           },
// //                   ),
// //                 ),
// //                 const SizedBox(width: 14),
// //                 Expanded(
// //                   child: ElevatedButton.icon(
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.red,
// //                       foregroundColor: Colors.white,
// //                       minimumSize: const Size(double.infinity, 56),
// //                       elevation: 0,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(18),
// //                       ),
// //                     ),
// //                     icon: const Icon(Icons.cancel),
// //                     label: const Text(
// //                       "Not Received",
// //                       style: TextStyle(
// //                         fontSize: 18,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                     onPressed: payment["tutorStatus"] == "NotReceived"
// //                         ? null
// //                         : () {
// //                             updatePaymentStatus(
// //                               payment["paymentId"],
// //                               "NotReceived",
// //                             );
// //                           },
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   // =====================================================
// //   // STATUS CHIP
// //   // =====================================================

// //   Widget statusChip(String status) {
// //     Color color = Colors.orange;

// //     if (status.toLowerCase() == "received") {
// //       color = Colors.green;
// //     } else if (status.toLowerCase() == "sent" ||
// //         status.toLowerCase() == "pending" ||
// //         status.toLowerCase() == "notreceived") {
// //       color = Colors.red;
// //     }

// //     String text = status == "NotReceived" ? "Not Received" : status;

// //     return Align(
// //       alignment: Alignment.centerLeft,
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
// //         decoration: BoxDecoration(
// //           borderRadius: BorderRadius.circular(30),
// //           border: Border.all(color: color, width: 2),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(Icons.circle, color: color, size: 10),
// //             const SizedBox(width: 8),
// //             Text(
// //               text,
// //               style: TextStyle(
// //                 color: color,
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 16,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }





























































// // // import 'dart:convert';

// // // import 'package:flutter/material.dart';
// // // import 'package:house_of_tutor/TutorDrawer.dart';
// // // import 'package:house_of_tutor/TutorHome.dart';
// // // import 'package:house_of_tutor/TutorStudentRequest.dart';
// // // import 'package:house_of_tutor/TutorTodayClasses.dart';
// // // import 'package:house_of_tutor/services/api_client.dart';

// // // class TutorPayment extends StatefulWidget {
// // //   const TutorPayment({Key? key}) : super(key: key);

// // //   @override
// // //   State<TutorPayment> createState() => _TutorPaymentState();
// // // }

// // // class _TutorPaymentState extends State<TutorPayment> {
// // //   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

// // //   bool isLoading = true;
// // //   List payments = [];

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     loadPayments();
// // //   }

// // //   Future<void> loadPayments() async {
// // //     setState(() {
// // //       isLoading = true;
// // //     });

// // //     try {
// // //       final response = await ApiClient.get(
// // //         "/Tutor/payment-list",
// // //       );

// // //       if (response.statusCode == 200) {
// // //         setState(() {
// // //           payments = jsonDecode(response.body);
// // //         });
// // //       } else {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text("Unable to load payments."),
// // //           ),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text(e.toString()),
// // //         ),
// // //       );
// // //     }

// // //     setState(() {
// // //       isLoading = false;
// // //     });
// // //   }

// // //   Future<void> updatePaymentStatus(
// // //       int paymentId,
// // //       String status,
// // //       ) async {
// // //     try {
// // //       final response = await ApiClient.put(
// // //         "/Tutor/payment-status",
// // //         jsonEncode({
// // //           "paymentId": paymentId,
// // //           "status": status,
// // //         }),
// // //       );

// // //       if (response.statusCode == 200) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text(
// // //               status == "Received"
// // //                   ? "Payment marked as Received."
// // //                   : "Payment marked as Not Received.",
// // //             ),
// // //           ),
// // //         );

// // //         loadPayments();
// // //       } else {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text("Failed to update payment."),
// // //           ),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text(e.toString()),
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   Color getStatusColor(String status) {
// // //     switch (status) {
// // //       case "Received":
// // //         return Colors.green;

// // //       case "Sent":
// // //         return Colors.red;

// // //       case "Pending":
// // //         return Colors.red;

// // //       case "NotReceived":
// // //         return Colors.red;

// // //       default:
// // //         return Colors.orange;
// // //     }
// // //   }

// // //   String formatDate(String value) {
// // //     if (value.isEmpty) return "";

// // //     try {
// // //       DateTime date = DateTime.parse(value);

// // //       return "${date.month}/${date.day}/${date.year}";
// // //     } catch (_) {
// // //       return value;
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       key: _scaffoldKey,
// // //       drawer: const TutorDrawer(),
// // //       backgroundColor: const Color(0xfff4f5f9),

// // //       appBar: AppBar(
// // //         backgroundColor: Colors.white,
// // //         elevation: 0,
// // //         leading: IconButton(
// // //           icon: const Icon(
// // //             Icons.arrow_back,
// // //             color: Colors.black,
// // //           ),
// // //           onPressed: () {
// // //             Navigator.pop(context);
// // //           },
// // //         ),
// // //         centerTitle: true,
// // //         title: Column(
// // //           children: [
// // //             Image.asset(
// // //               "assets/logo.png",
// // //               height: 45,
// // //             ),
// // //             const SizedBox(height: 3),
// // //             const Text(
// // //               "House of Tutor",
// // //               style: TextStyle(
// // //                 color: Color(0xff00897b),
// // //                 fontWeight: FontWeight.bold,
// // //                 fontSize: 18,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),

// // //       body: RefreshIndicator(
// // //         onRefresh: loadPayments,
// // //         child: isLoading
// // //             ? const Center(
// // //                 child: CircularProgressIndicator(),
// // //               )
// // //             : payments.isEmpty
// // //                 ? ListView(
// // //                     children: const [
// // //                       SizedBox(height: 200),
// // //                       Center(
// // //                         child: Text(
// // //                           "No Payments Found",
// // //                           style: TextStyle(
// // //                             fontSize: 18,
// // //                             fontWeight: FontWeight.w600,
// // //                           ),
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   )
// // //                 : ListView(
// // //                     padding: const EdgeInsets.all(16),
// // //                     children: [
// // //                       const Text(
// // //                         "Payments",
// // //                         style: TextStyle(
// // //                           fontSize: 24,
// // //                           fontWeight: FontWeight.bold,
// // //                         ),
// // //                       ),

// // //                       const SizedBox(height: 15),

// // //                       ...payments.map(
// // //                         (payment) => paymentCard(payment),
// // //                       ),
// // //                     ],
// // //                   ),
// // //       ),
// // //     );
// // //   }
// // //     Widget paymentCard(dynamic payment) {
// // //     return Container(
// // //       margin: const EdgeInsets.only(bottom: 20),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(24),
// // //         boxShadow: const [
// // //           BoxShadow(
// // //             color: Colors.black12,
// // //             blurRadius: 10,
// // //             offset: Offset(0, 4),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Padding(
// // //         padding: const EdgeInsets.all(18),
// // //         child: Column(
// // //           children: [
// // //             /// Header
// // //             Row(
// // //               children: [
// // //                 Container(
// // //                   height: 64,
// // //                   width: 64,
// // //                   decoration: const BoxDecoration(
// // //                     color: Color(0xff2D8CFF),
// // //                     shape: BoxShape.circle,
// // //                   ),
// // //                   child: const Icon(
// // //                     Icons.person,
// // //                     color: Colors.white,
// // //                     size: 36,
// // //                   ),
// // //                 ),

// // //                 const SizedBox(width: 16),

// // //                 Expanded(
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       Text(
// // //                         payment["student"] ?? "",
// // //                         style: const TextStyle(
// // //                           fontSize: 19,
// // //                           fontWeight: FontWeight.bold,
// // //                         ),
// // //                       ),
// // //                       const SizedBox(height: 4),
// // //                       Text(
// // //                         payment["course"] ?? "",
// // //                         style: TextStyle(
// // //                           color: Colors.grey.shade600,
// // //                           fontSize: 17,
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),

// // //                 Text(
// // //                   "Rs. ${payment["amount"]}",
// // //                   style: const TextStyle(
// // //                     color: Colors.green,
// // //                     fontWeight: FontWeight.bold,
// // //                     fontSize: 20,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),

// // //             const SizedBox(height: 18),

// // //             Divider(
// // //               color: Colors.grey.shade300,
// // //             ),

// // //             const SizedBox(height: 18),

// // //             /// Payment Type
// // //             Row(
// // //               children: [
// // //                 Container(
// // //                   padding: const EdgeInsets.all(10),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.orange.shade50,
// // //                     borderRadius: BorderRadius.circular(10),
// // //                   ),
// // //                   child: const Icon(
// // //                     Icons.credit_card,
// // //                     color: Colors.orange,
// // //                   ),
// // //                 ),

// // //                 const SizedBox(width: 15),

// // //                 const Expanded(
// // //                   child: Text(
// // //                     "Payment Type",
// // //                     style: TextStyle(
// // //                       fontSize: 18,
// // //                       color: Colors.grey,
// // //                     ),
// // //                   ),
// // //                 ),

// // //                 Text(
// // //                   payment["paymentType"] ?? "",
// // //                   style: const TextStyle(
// // //                     fontSize: 18,
// // //                     fontWeight: FontWeight.w600,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),

// // //             const SizedBox(height: 20),

// // //             /// Date
// // //             Row(
// // //               children: [
// // //                 Container(
// // //                   padding: const EdgeInsets.all(10),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.blue.shade50,
// // //                     borderRadius: BorderRadius.circular(10),
// // //                   ),
// // //                   child: const Icon(
// // //                     Icons.calendar_month,
// // //                     color: Colors.blue,
// // //                   ),
// // //                 ),

// // //                 const SizedBox(width: 15),

// // //                 const Expanded(
// // //                   child: Text(
// // //                     "Date",
// // //                     style: TextStyle(
// // //                       fontSize: 18,
// // //                       color: Colors.grey,
// // //                     ),
// // //                   ),
// // //                 ),

// // //                 Text(
// // //                   formatDate(payment["paymentDate"] ?? ""),
// // //                   style: const TextStyle(
// // //                     fontSize: 18,
// // //                     fontWeight: FontWeight.w600,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),

// // //             const SizedBox(height: 28),

// // //             /// Status Labels
// // //             Row(
// // //               children: const [
// // //                 Expanded(
// // //                   child: Text(
// // //                     "Parent",
// // //                     style: TextStyle(
// // //                       fontSize: 18,
// // //                       color: Colors.grey,
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 Expanded(
// // //                   child: Text(
// // //                     "Tutor",
// // //                     style: TextStyle(
// // //                       fontSize: 18,
// // //                       color: Colors.grey,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),

// // //             const SizedBox(height: 10),

// // //             /// Status Chips
// // //             Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: statusChip(
// // //                     payment["parentStatus"] ?? "",
// // //                   ),
// // //                 ),

// // //                 Expanded(
// // //                   child: statusChip(
// // //                     payment["tutorStatus"] ?? "",
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),

// // //             const SizedBox(height: 25),

// // //             /// Buttons
// // //             Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: ElevatedButton.icon(
// // //                     style: ElevatedButton.styleFrom(
// // //                       backgroundColor: Colors.green,
// // //                       foregroundColor: Colors.white,
// // //                       minimumSize: const Size(double.infinity, 56),
// // //                       elevation: 0,
// // //                       shape: RoundedRectangleBorder(
// // //                         borderRadius: BorderRadius.circular(18),
// // //                       ),
// // //                     ),
// // //                     icon: const Icon(Icons.check_circle),
// // //                     label: const Text(
// // //                       "Received",
// // //                       style: TextStyle(
// // //                         fontSize: 18,
// // //                         fontWeight: FontWeight.bold,
// // //                       ),
// // //                     ),
// // //                     onPressed: payment["tutorStatus"] == "Received"
// // //                         ? null
// // //                         : () {
// // //                             updatePaymentStatus(
// // //                               payment["paymentId"],
// // //                               "Received",
// // //                             );
// // //                           },
// // //                   ),
// // //                 ),

// // //                 const SizedBox(width: 14),

// // //                 Expanded(
// // //                   child: ElevatedButton.icon(
// // //                     style: ElevatedButton.styleFrom(
// // //                       backgroundColor: Colors.red,
// // //                       foregroundColor: Colors.white,
// // //                       minimumSize: const Size(double.infinity, 56),
// // //                       elevation: 0,
// // //                       shape: RoundedRectangleBorder(
// // //                         borderRadius: BorderRadius.circular(18),
// // //                       ),
// // //                     ),
// // //                     icon: const Icon(Icons.cancel),
// // //                     label: const Text(
// // //                       "Not Received",
// // //                       style: TextStyle(
// // //                         fontSize: 18,
// // //                         fontWeight: FontWeight.bold,
// // //                       ),
// // //                     ),
// // //                     onPressed: payment["tutorStatus"] == "NotReceived"
// // //                         ? null
// // //                         : () {
// // //                             updatePaymentStatus(
// // //                               payment["paymentId"],
// // //                               "NotReceived",
// // //                             );
// // //                           },
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //     Widget statusChip(String status) {
// // //     final bool isReceived =
// // //         status.toLowerCase() == "received";

// // //     final bool isSent =
// // //         status.toLowerCase() == "sent";

// // //     final bool isPending =
// // //         status.toLowerCase() == "pending";

// // //     final bool isNotReceived =
// // //         status.toLowerCase() == "notreceived";

// // //     Color color = Colors.orange;

// // //     if (isReceived) {
// // //       color = Colors.green;
// // //     } else if (isSent) {
// // //       color = Colors.red;
// // //     } else if (isPending) {
// // //       color = Colors.red;
// // //     } else if (isNotReceived) {
// // //       color = Colors.red;
// // //     }

// // //     String text = status;

// // //     if (status == "NotReceived") {
// // //       text = "Not Received";
// // //     }

// // //     return Align(
// // //       alignment: Alignment.centerLeft,
// // //       child: Container(
// // //         padding: const EdgeInsets.symmetric(
// // //           horizontal: 18,
// // //           vertical: 10,
// // //         ),
// // //         decoration: BoxDecoration(
// // //           borderRadius: BorderRadius.circular(30),
// // //           border: Border.all(
// // //             color: color,
// // //             width: 2,
// // //           ),
// // //         ),
// // //         child: Row(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             Icon(
// // //               Icons.circle,
// // //               color: color,
// // //               size: 10,
// // //             ),
// // //             const SizedBox(width: 8),
// // //             Text(
// // //               text,
// // //               style: TextStyle(
// // //                 color: color,
// // //                 fontWeight: FontWeight.bold,
// // //                 fontSize: 16,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }