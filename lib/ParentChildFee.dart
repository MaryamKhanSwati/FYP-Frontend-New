import 'package:flutter/material.dart';
import 'package:house_of_tutor/ParentChildCourses.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:house_of_tutor/services/api_client.dart';

class ParentChildFee extends StatefulWidget {
  const ParentChildFee({Key? key}) : super(key: key);

  @override
  _ParentChildFeeState createState() => _ParentChildFeeState();
}

class _ParentChildFeeState extends State<ParentChildFee> {
  bool isLoading = true;
  Map<String, dynamic> feeData = {};
  List<dynamic> childrenList = [];
  int? selectedStudentId;

  @override
  void initState() {
    super.initState();
    fetchChildrenFee();
  }

  Future<void> fetchChildrenFee() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get('/api/Parent/children-fee');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          feeData = data;
          childrenList = data['children'] ?? [];
          if (childrenList.isNotEmpty) {
            // Default to first student if not selected
            selectedStudentId ??= childrenList[0]['studentId'];
          }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        final data = json.decode(response.body);
        _showSnackBar(data['message'] ?? "Failed to load fee statement.");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar("An error occurred: $e");
    }
  }

  Future<void> sendPayment(int feeId, double amount) async {
    try {
      final response = await ApiClient.post(
        '/send-payment',
        jsonEncode({
          'feeId': feeId,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _showSnackBar(data['message'] ?? "Payment Sent Successfully.");
        fetchChildrenFee(); // Refresh data
      } else {
        final data = json.decode(response.body);
        _showSnackBar(data['message'] ?? data.toString());
      }
    } catch (e) {
      _showSnackBar("An error occurred: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showPaymentDialog(bool isFullPayment, Map<String, dynamic> selectedChild, dynamic courseFee) {
    final TextEditingController amountController = TextEditingController();
    final double remainingBalance = (courseFee['remaining'] ?? 0).toDouble();

    if (isFullPayment) {
      amountController.text = remainingBalance.toString();
    } else {
      amountController.text = "";
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              Text(
                isFullPayment ? "Full Fee Payment" : "Partial Fee Payment",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                selectedChild['studentName'] ?? '',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Text("Total Balance Due", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      "Rs. ${remainingBalance.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text("Enter Payment Amount", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                enabled: !isFullPayment,
                decoration: InputDecoration(
                  hintText: "0.00",
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final double? enteredAmount = double.tryParse(amountController.text);
                if (enteredAmount == null || enteredAmount <= 0) {
                  _showSnackBar("Please enter a valid amount.");
                  return;
                }
                if (enteredAmount > remainingBalance) {
                  _showSnackBar("Amount exceeds remaining balance.");
                  return;
                }
                Navigator.pop(context);
                sendPayment(courseFee['feeId'], enteredAmount);
              },
              child: const Text("Confirm Payment", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? currentStudent;
    if (childrenList.isNotEmpty) {
      currentStudent = childrenList.firstWhere(
        (child) => child['studentId'] == selectedStudentId,
        orElse: () => childrenList[0],
      );
    }

    final double totalFamilyFee = (feeData['totalFee'] ?? 0).toDouble();
    final double totalFamilyPaid = (feeData['totalPaid'] ?? 0).toDouble();
    final double totalFamilyRemaining = (feeData['totalRemaining'] ?? 0).toDouble();

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
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, color: Colors.teal, size: 24),
            ),
            const SizedBox(width: 8),
            const Text(
              "House of Tutor",
              style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Family Statement",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // Overall Statement Dark Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2430),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "OVERALL STATEMENT",
                              style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 1),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Total Family Balance",
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Rs. ${totalFamilyRemaining.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(color: Colors.white24, height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Paid", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  "Rs. ${totalFamilyPaid.toStringAsFixed(0)}",
                                  style: const TextStyle(fontSize: 15, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(height: 30, width: 1, color: Colors.white24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Remaining", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  "Rs. ${totalFamilyRemaining.toStringAsFixed(0)}",
                                  style: const TextStyle(fontSize: 15, color: Colors.redAccent, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            "Select a student below to view breakdown",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Modern Horizontal Student Selector Chips
                  const Text(
                    "Select Student",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: childrenList.length,
                      itemBuilder: (context, index) {
                        final child = childrenList[index];
                        final bool isSelected = child['studentId'] == selectedStudentId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: ChoiceChip(
                            label: Text(child['studentName'] ?? 'Student'),
                            selected: isSelected,
                            selectedColor: Colors.teal,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                              side: BorderSide(
                                color: isSelected ? Colors.teal : Colors.grey.shade300,
                              ),
                            ),
                            onSelected: (bool selected) {
                              setState(() {
                                selectedStudentId = child['studentId'];
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected Student Breakdown Summary Card
                  if (currentStudent != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${currentStudent['studentName']}'s Breakdown",
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Fee Overview",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Total", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Rs. ${currentStudent['totalFee']}",
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Paid", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Rs. ${currentStudent['totalPaid']}",
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Remaining", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Rs. ${currentStudent['totalRemaining']}",
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Course Breakdown Header
                    const Text(
                      "Course Breakdown",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),

                    // Courses list builder
                    ...(currentStudent['courses'] as List<dynamic>).map((courseFee) {
                      final bool isPaid = (courseFee['remaining'] ?? 0) <= 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  courseFee['course'] ?? 'Course',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isPaid ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isPaid ? "Paid" : "Pending",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isPaid ? Colors.green.shade700 : Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  courseFee['tutor'] ?? 'Instructor',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Total", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text("Rs. ${courseFee['totalFee']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Paid", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text("Rs. ${courseFee['paid']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Remaining", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text("Rs. ${courseFee['remaining']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                                  ],
                                ),
                              ],
                            ),
                            if (!isPaid) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _showPaymentDialog(true, currentStudent!, courseFee),
                                      child: const Text("Pay Full", style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.teal),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _showPaymentDialog(false, currentStudent!, courseFee),
                                      child: const Text("Partial Pay", style: TextStyle(color: Colors.teal, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
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

// class ParentChildFee extends StatefulWidget {
//   final int studentId;

//   const ParentChildFee({
//     Key? key,
//     required this.studentId,
//   }) : super(key: key);

//   @override
//   State<ParentChildFee> createState() => _ParentChildFeeState();
// }

// class _ParentChildFeeState extends State<ParentChildFee> {
//   bool isLoading = true;
//   bool isSending = false;

//   List<FeeModel> feeList = [];

//   @override
//   void initState() {
//     super.initState();
//     loadFees();
//   }

//   //--------------------------------------------
//   // Load Child Fee
//   //--------------------------------------------
//   Future<void> loadFees() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final response = await ApiClient.get(
//         "Parent/child-fee/${widget.studentId}",
//       );

//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);

//         feeList = data
//             .map((e) => FeeModel.fromJson(e))
//             .toList();

//         setState(() {});
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Unable to load fee details"),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//         ),
//       );
//     }

//     setState(() {
//       isLoading = false;
//     });
//   }

//   //--------------------------------------------
//   // Send Payment API
//   //--------------------------------------------
//   Future<void> sendPayment({
//     required int feeId,
//     required double amount,
//   }) async {
//     setState(() {
//       isSending = true;
//     });

//     try {
//       final response = await ApiClient.post(
//         "Parent/send-payment",
//         {
//           "feeId": feeId,
//           "amount": amount,
//         },
//       );

//       if (response.statusCode == 200) {
//         Navigator.pop(context);

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             backgroundColor: Colors.green,
//             content: Text("Payment Sent Successfully"),
//           ),
//         );

//         await loadFees();
//       } else {
//         final body = jsonDecode(response.body);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               body["message"]?.toString() ??
//                   "Unable to send payment",
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//         ),
//       );
//     }

//     setState(() {
//       isSending = false;
//     });
//   }

//   //--------------------------------------------
//   // Currency
//   //--------------------------------------------
//   String formatAmount(num value) {
//     return value.toStringAsFixed(0);
//   }

//   //--------------------------------------------
//   // Payment Dialog
//   //--------------------------------------------
//   //--------------------------------------------
// // Payment Dialog
// //--------------------------------------------
// Future<void> showPaymentDialog(
//   FeeModel fee,
//   bool fullPayment,
// ) async {
//   final TextEditingController amountController =
//       TextEditingController();

//   if (fullPayment) {
//     amountController.text = fee.remaining.toStringAsFixed(0);
//   }

//   await showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (context, setStateDialog) {
//           return AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(18),
//             ),
//             title: Row(
//               children: [
//                 Icon(
//                   fullPayment
//                       ? Icons.payments
//                       : Icons.account_balance_wallet,
//                   color: Colors.teal,
//                 ),
//                 const SizedBox(width: 10),
//                 Text(
//                   fullPayment
//                       ? "Full Payment"
//                       : "Partial Payment",
//                 ),
//               ],
//             ),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [

//                   Text(
//                     "Course",
//                     style: TextStyle(
//                       color: Colors.grey.shade700,
//                     ),
//                   ),

//                   const SizedBox(height: 5),

//                   Text(
//                     fee.course,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),

//                   const SizedBox(height: 18),

//                   Text(
//                     "Remaining Amount",
//                     style: TextStyle(
//                       color: Colors.grey.shade700,
//                     ),
//                   ),

//                   const SizedBox(height: 5),

//                   Text(
//                     "Rs. ${formatAmount(fee.remaining)}",
//                     style: const TextStyle(
//                       color: Colors.deepOrange,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                     ),
//                   ),

//                   const SizedBox(height: 25),

//                   TextField(
//                     controller: amountController,
//                     keyboardType:
//                         const TextInputType.numberWithOptions(
//                       decimal: true,
//                     ),
//                     readOnly: fullPayment,
//                     decoration: InputDecoration(
//                       labelText: "Enter Amount",
//                       hintText: "Amount",
//                       prefixText: "Rs. ",
//                       border: OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [

//               TextButton(
//                 onPressed: isSending
//                     ? null
//                     : () {
//                         Navigator.pop(context);
//                       },
//                 child: const Text("Cancel"),
//               ),

//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.teal,
//                 ),
//                 onPressed: isSending
//                     ? null
//                     : () async {
//                         if (amountController.text
//                             .trim()
//                             .isEmpty) {
//                           ScaffoldMessenger.of(context)
//                               .showSnackBar(
//                             const SnackBar(
//                               content:
//                                   Text("Enter amount"),
//                             ),
//                           );
//                           return;
//                         }

//                         double amount =
//                             double.tryParse(
//                                   amountController.text,
//                                 ) ??
//                                 0;

//                         if (amount <= 0) {
//                           ScaffoldMessenger.of(context)
//                               .showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                   "Invalid amount"),
//                             ),
//                           );
//                           return;
//                         }

//                         if (amount >
//                             fee.remaining) {
//                           ScaffoldMessenger.of(context)
//                               .showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 "Amount cannot exceed Rs. ${formatAmount(fee.remaining)}",
//                               ),
//                             ),
//                           );
//                           return;
//                         }

//                         await sendPayment(
//                           feeId: fee.feeId,
//                           amount: amount,
//                         );
//                       },
//                 child: isSending
//                     ? const SizedBox(
//                         height: 20,
//                         width: 20,
//                         child:
//                             CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : Text(
//                         fullPayment
//                             ? "Send Full Payment"
//                             : "Send Payment",
//                       ),
//               ),
//             ],
//           );
//         },
//       );
//     },
//   );
// }

//  @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     backgroundColor: const Color(0xffF4F6F8),
//     appBar: AppBar(
//       elevation: 0,
//       backgroundColor: Colors.white,
//       centerTitle: true,
//       iconTheme: const IconThemeData(color: Colors.black),
//       title: const Text(
//         "Fee Details",
//         style: TextStyle(
//           color: Colors.teal,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     ),
//     body: isLoading
//         ? const Center(
//             child: CircularProgressIndicator(),
//           )
//         : feeList.isEmpty
//             ? const Center(
//                 child: Text(
//                   "No Fee Found",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               )
//             : RefreshIndicator(
//                 onRefresh: loadFees,
//                 child: ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: feeList.length,
//                   itemBuilder: (context, index) {
//                     final fee = feeList[index];

//                     return Card(
//                       elevation: 6,
//                       margin: const EdgeInsets.only(bottom: 20),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(18),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(18),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [

//                             //------------------------------------
//                             // Course + Status
//                             //------------------------------------

//                             Row(
//                               children: [

//                                 Expanded(
//                                   child: Text(
//                                     fee.course,
//                                     style: const TextStyle(
//                                       fontSize: 22,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),

//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 14,
//                                     vertical: 7,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: fee.remaining == 0
//                                         ? Colors.green
//                                         : Colors.orange,
//                                     borderRadius:
//                                         BorderRadius.circular(25),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Icon(
//                                         fee.remaining == 0
//                                             ? Icons.check_circle
//                                             : Icons.access_time,
//                                         color: Colors.white,
//                                         size: 16,
//                                       ),
//                                       const SizedBox(width: 6),
//                                       Text(
//                                         fee.remaining == 0
//                                             ? "Paid"
//                                             : "Pending",
//                                         style: const TextStyle(
//                                           color: Colors.white,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             const SizedBox(height: 18),

//                             //------------------------------------
//                             // Tutor
//                             //------------------------------------

//                             Row(
//                               children: [

//                                 CircleAvatar(
//                                   radius: 18,
//                                   backgroundColor:
//                                       Colors.teal.withOpacity(.15),
//                                   child: const Icon(
//                                     Icons.person,
//                                     color: Colors.teal,
//                                   ),
//                                 ),

//                                 const SizedBox(width: 10),

//                                 Expanded(
//                                   child: Text(
//                                     fee.tutor,
//                                     style: const TextStyle(
//                                       fontSize: 17,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             const SizedBox(height: 18),

//                             const Divider(),

//                             const SizedBox(height: 8),

//                             //------------------------------------
//                             // Total Fee
//                             //------------------------------------

//                             Row(
//                               children: [

//                                 const Icon(
//                                   Icons.payments,
//                                   color: Colors.grey,
//                                 ),

//                                 const SizedBox(width: 10),

//                                 const Expanded(
//                                   child: Text(
//                                     "Total Fee",
//                                     style: TextStyle(
//                                       color: Colors.grey,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                 ),

//                                 Text(
//                                   "Rs. ${formatAmount(fee.totalFee)}",
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             const SizedBox(height: 15),

//                             //------------------------------------
//                             // Paid
//                             //------------------------------------

//                             Row(
//                               children: [

//                                 const Icon(
//                                   Icons.check_circle,
//                                   color: Colors.green,
//                                 ),

//                                 const SizedBox(width: 10),

//                                 const Expanded(
//                                   child: Text(
//                                     "Paid",
//                                     style: TextStyle(
//                                       color: Colors.grey,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                 ),

//                                 Text(
//                                   "Rs. ${formatAmount(fee.paid)}",
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.green,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             const SizedBox(height: 15),

//                             //------------------------------------
//                             // Remaining
//                             //------------------------------------

//                             Row(
//                               children: [

//                                 const Icon(
//                                   Icons.warning,
//                                   color: Colors.deepOrange,
//                                 ),

//                                 const SizedBox(width: 10),

//                                 const Expanded(
//                                   child: Text(
//                                     "Remaining",
//                                     style: TextStyle(
//                                       color: Colors.grey,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                 ),

//                                 Text(
//                                   "Rs. ${formatAmount(fee.remaining)}",
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.deepOrange,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             const SizedBox(height: 28),

//                             //------------------------------------
//                             // Full Payment Button
//                             //------------------------------------

//                             SizedBox(
//                               width: double.infinity,
//                               height: 52,
//                               child: ElevatedButton.icon(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor:
//                                       const Color(0xff2E7D32),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius:
//                                         BorderRadius.circular(12),
//                                   ),
//                                 ),
//                                 onPressed: fee.remaining == 0
//                                     ? null
//                                     : () {
//                                         showPaymentDialog(
//                                           fee,
//                                           true,
//                                         );
//                                       },
//                                 icon: const Icon(Icons.payments),
//                                 label: const Text(
//                                   "Send Full Payment",
//                                   style: TextStyle(
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ),

//                             const SizedBox(height: 14),

//                             //------------------------------------
//                             // Partial Payment Button
//                             //------------------------------------

//                             SizedBox(
//                               width: double.infinity,
//                               height: 52,
//                               child: ElevatedButton.icon(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.teal,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius:
//                                         BorderRadius.circular(12),
//                                   ),
//                                 ),
//                                 onPressed: fee.remaining == 0
//                                     ? null
//                                     : () {
//                                         showPaymentDialog(
//                                           fee,
//                                           false,
//                                         );
//                                       },
//                                 icon: const Icon(Icons.account_balance_wallet),
//                                 label: const Text(
//                                   "Send Partial Payment",
//                                   style: TextStyle(
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//   );
// }
// }

// //////////////////////////////////////////////////////////////
// // MODEL
// //////////////////////////////////////////////////////////////

// class FeeModel {
//   final int feeId;
//   final int courseId;
//   final String course;
//   final String tutor;
//   final double totalFee;
//   final double paid;
//   final double remaining;

//   FeeModel({
//     required this.feeId,
//     required this.courseId,
//     required this.course,
//     required this.tutor,
//     required this.totalFee,
//     required this.paid,
//     required this.remaining,
//   });

//   factory FeeModel.fromJson(Map<String, dynamic> json) {
//     return FeeModel(
//       feeId: json["feeId"] ?? 0,
//       courseId: json["courseId"] ?? 0,
//       course: json["course"] ?? "",
//       tutor: json["tutor"] ?? "",
//       totalFee: (json["totalFee"] ?? 0).toDouble(),
//       paid: (json["paid"] ?? 0).toDouble(),
//       remaining: (json["remaining"] ?? 0).toDouble(),
//     );
//   }
// }