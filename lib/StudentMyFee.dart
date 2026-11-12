import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:house_of_tutor/services/api_client.dart';

class StudentMyFee extends StatefulWidget {
  const StudentMyFee({super.key});

  @override
  State<StudentMyFee> createState() => _StudentMyFeeState();
}

class _StudentMyFeeState extends State<StudentMyFee> {
  // =====================================================
  // VARIABLES
  // =====================================================

  bool isLoading = true;
  bool isPaying = false;

  String? errorMessage;

  int? studentId;
  String studentName = '';

  String feeResponsibility = '';

  double totalFee = 0;
  double totalPaid = 0;
  double totalRemaining = 0;

  List<Map<String, dynamic>> courses = [];

  // =====================================================
  // COLORS
  //
  // Matched to the "My Fee Statement" design:
  // dark navy balance card + teal accents.
  // =====================================================

  final Color primaryColor = const Color(0xFF0D9488); // teal accent
  final Color darkCardColor = const Color(0xFF10192E); // navy balance card
  final Color backgroundColor = const Color(0xFFF6F7FB);
  final Color paidColor = const Color(0xFF16A34A);
  final Color remainingColor = const Color(0xFFDC2626);
  final Color pendingBadgeColor = const Color(0xFFF59E0B);

  // =====================================================
  // API PATH
  // =====================================================

  static const String studentFeeApi =
      '/api/Student/student-fee';

  static const String studentPaymentApi =
      '/api/Student/student-send-payment';

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    loadStudentFee();
  }

  // =====================================================
  // LOAD STUDENT FEE
  // =====================================================

  Future<void> loadStudentFee() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiClient.get(
        studentFeeApi,
      );

      debugPrint('========================================');
      debugPrint('GET STUDENT FEE');
      debugPrint('URL: /api/Student/student-fee');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('========================================');

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final message =
            messageFromBody(response.body);

        throw Exception(
          message ??
              'Unable to load student fee. '
                  'Status Code: ${response.statusCode}',
        );
      }

      final decodedData = decodeJson(response);

      if (decodedData is! Map) {
        throw Exception(
          'Invalid response received from student fee API.',
        );
      }

      final data =
          Map<String, dynamic>.from(decodedData);

      List<Map<String, dynamic>> loadedCourses = [];

      if (data['courses'] is List) {
        loadedCourses =
            (data['courses'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      Map<String, dynamic>.from(item),
                )
                .toList();
      }

      if (!mounted) return;

      setState(() {
        studentId = _toInt(
          data['studentId'],
        );

        studentName =
            data['studentName']?.toString() ?? '';

        feeResponsibility =
            data['feeResponsibility']
                    ?.toString() ??
                '';

        totalFee = _toDouble(
          data['totalFee'],
        );

        totalPaid = _toDouble(
          data['totalPaid'],
        );

        totalRemaining = _toDouble(
          data['totalRemaining'],
        );

        courses = loadedCourses;

        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'Student Fee Error: $e',
      );

      setState(() {
        isLoading = false;

        errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // =====================================================
  // DECODE JSON
  // =====================================================

  static dynamic decodeJson(
    http.Response response,
  ) {
    if (response.body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(
        utf8.decode(
          response.bodyBytes,
        ),
      );
    } catch (e) {
      debugPrint(
        'JSON Decode Error: $e',
      );

      return null;
    }
  }

  // =====================================================
  // GET MESSAGE FROM API ERROR
  // =====================================================

  static String? messageFromBody(
    String body,
  ) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is String) {
        return decoded;
      }

      if (decoded is! Map) {
        return null;
      }

      if (decoded['message'] != null) {
        return decoded['message'].toString();
      }

      if (decoded['Message'] != null) {
        return decoded['Message'].toString();
      }

      if (decoded['title'] != null) {
        return decoded['title'].toString();
      }

      if (decoded['detail'] != null) {
        return decoded['detail'].toString();
      }

      if (decoded['error'] != null) {
        return decoded['error'].toString();
      }

      if (decoded['errors'] is Map) {
        final errors =
            decoded['errors'] as Map;

        for (final value in errors.values) {
          if (value is List &&
              value.isNotEmpty) {
            return value.first.toString();
          }

          if (value != null) {
            return value.toString();
          }
        }
      }
    } catch (_) {
      if (body.trim().isNotEmpty) {
        return body.trim();
      }
    }

    return null;
  }

  // =====================================================
  // CONVERT TO DOUBLE
  // =====================================================

  double _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  // =====================================================
  // CONVERT TO INT
  // =====================================================

  int? _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // =====================================================
  // FORMAT MONEY
  // =====================================================

  String money(
    double value,
  ) {
    return 'Rs. ${value.toStringAsFixed(0)}';
  }

  // =====================================================
  // SHOW PARTIAL PAYMENT DIALOG
  // =====================================================

  Future<void> showPartialPaymentDialog(
    Map<String, dynamic> course,
  ) async {
    final feeId = _toInt(
      course['feeId'],
    );

    final remaining = _toDouble(
      course['remaining'],
    );

    if (feeId == null) {
      showMessage(
        'Fee ID is missing.',
        isError: true,
      );

      return;
    }

    if (remaining <= 0) {
      showMessage(
        'No remaining amount available.',
        isError: true,
      );

      return;
    }

    final controller =
        TextEditingController();

    bool paymentStarted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              title: const Text(
                'Partially Pay',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining Fee: ${money(remaining)}',
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  TextField(
                    controller:
                        controller,
                    enabled:
                        !paymentStarted,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        InputDecoration(
                      labelText:
                          'Enter Amount',
                      hintText:
                          'e.g. 5000',
                      prefixText:
                          'Rs. ',
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      paymentStarted
                          ? null
                          : () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },
                  child:
                      const Text(
                    'Cancel',
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      paymentStarted
                          ? null
                          : () async {
                              final amount =
                                  double.tryParse(
                                controller.text
                                    .trim(),
                              );

                              if (amount ==
                                      null ||
                                  amount <= 0) {
                                ScaffoldMessenger
                                    .of(
                                  dialogContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text(
                                      'Please enter a valid amount.',
                                    ),
                                  ),
                                );

                                return;
                              }

                              if (amount >
                                  remaining) {
                                ScaffoldMessenger
                                    .of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text(
                                      'Amount cannot exceed ${money(remaining)}.',
                                    ),
                                  ),
                                );

                                return;
                              }

                              setDialogState(() {
                                paymentStarted =
                                    true;
                              });

                              await makePayment(
                                feeId: feeId,
                                amount: amount,
                                closeDialog: true,
                                dialogContext:
                                    dialogContext,
                              );

                              if (mounted &&
                                  Navigator.of(
                                    dialogContext,
                                  ).canPop()) {
                                setDialogState(() {
                                  paymentStarted =
                                      false;
                                });
                              }
                            },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        primaryColor,
                    foregroundColor:
                        Colors.white,
                  ),
                  child: paymentStarted
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'Pay',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  // =====================================================
  // FULL PAYMENT
  // =====================================================

  Future<void> makeFullPayment(
    Map<String, dynamic> course,
  ) async {
    final feeId = _toInt(
      course['feeId'],
    );

    final remaining = _toDouble(
      course['remaining'],
    );

    if (feeId == null) {
      showMessage(
        'Fee ID is missing.',
        isError: true,
      );

      return;
    }

    if (remaining <= 0) {
      showMessage(
        'This fee is already fully paid.',
        isError: true,
      );

      return;
    }

    if (isPaying) {
      return;
    }

    final confirm =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
          title: const Text(
            'Fully Pay',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: Text(
            'Do you want to pay ${money(remaining)}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryColor,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Pay Now',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await makePayment(
      feeId: feeId,
      amount: remaining,
      closeDialog: false,
    );
  }

  // =====================================================
  // SEND PAYMENT
  // =====================================================

  Future<void> makePayment({
    required int feeId,
    required double amount,
    required bool closeDialog,
    BuildContext? dialogContext,
  }) async {
    if (isPaying) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isPaying = true;
    });

    try {
      final response = await ApiClient.post(
        studentPaymentApi,
        {
          'feeId': feeId,
          'amount': amount,
        },
      );

      debugPrint('========================================');
      debugPrint(
        'SEND STUDENT PAYMENT',
      );
      debugPrint(
        'URL: /api/Student/student-send-payment',
      );
      debugPrint(
        'Status: ${response.statusCode}',
      );
      debugPrint(
        'Body: ${response.body}',
      );
      debugPrint('========================================');

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          messageFromBody(
                response.body,
              ) ??
              'Unable to send payment. '
                  'Status Code: ${response.statusCode}',
        );
      }

      final decodedData =
          decodeJson(response);

      Map<String, dynamic> paymentData =
          {};

      if (decodedData is Map) {
        paymentData =
            Map<String, dynamic>.from(
          decodedData,
        );
      }

      final paymentType =
          paymentData['paymentType']
                  ?.toString() ??
              '';

      if (closeDialog &&
          dialogContext != null &&
          Navigator.of(
            dialogContext,
          ).canPop()) {
        Navigator.of(
          dialogContext,
        ).pop();
      }

      if (!mounted) return;

      setState(() {
        isPaying = false;
      });

      showMessage(
        paymentType.isNotEmpty
            ? 'Payment Sent Successfully.\n'
                'Type: $paymentType'
            : 'Payment Sent Successfully.',
      );

      await loadStudentFee();
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint(
        'Payment Error: $e',
      );

      setState(() {
        isPaying = false;
      });

      showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  // =====================================================
  // SHOW MESSAGE
  // =====================================================

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor:
            isError
                ? Colors.red.shade700
                : Colors.green.shade700,
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(
          16,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      // =================================================
      // APP BAR — logo + "House of Tutor"
      // =================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            // -----------------------------------------
            // LOGO ASSET
            //
            // Update the path below to match wherever
            // your logo is registered in pubspec.yaml,
            // e.g. assets/images/logo.png
            // -----------------------------------------
            SizedBox(
              height: 24,
              width: 24,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder:
                    (context, error, stackTrace) {
                  return Icon(
                    Icons.school,
                    color: primaryColor,
                    size: 22,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text(
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

      body:
          RefreshIndicator(
        onRefresh:
            loadStudentFee,
        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : errorMessage !=
                    null
                ? buildError()
                : buildFeeScreen(),
      ),
    );
  }

  // =====================================================
  // ERROR SCREEN
  // =====================================================

  Widget buildError() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
              MediaQuery.of(
                    context,
                  ).size.height *
                  0.25,
        ),
        const Icon(
          Icons.error_outline,
          size: 70,
          color: Colors.red,
        ),
        const SizedBox(
          height: 15,
        ),
        const Center(
          child: Text(
            'Unable to Load Fee',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 30,
          ),
          child: Text(
            errorMessage ??
                'Something went wrong.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Center(
          child:
              ElevatedButton(
            onPressed:
                loadStudentFee,
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  primaryColor,
              foregroundColor:
                  Colors.white,
            ),
            child:
                const Text(
              'Try Again',
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // MAIN FEE SCREEN
  // =====================================================

  Widget buildFeeScreen() {
    if (feeResponsibility
            .toLowerCase()
            .replaceAll(
              ' ',
              '',
            ) ==
        'byparent') {
      return buildByParentMessage();
    }

    return buildByMeFee();
  }

  // =====================================================
  // BY PARENT MESSAGE
  // =====================================================

  Widget buildByParentMessage() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(
        20,
      ),
      children: [
        const SizedBox(
          height: 60,
        ),
        Container(
          padding:
              const EdgeInsets.all(
            25,
          ),
          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              22,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withOpacity(
                  0.06,
                ),
                blurRadius: 15,
                offset:
                    const Offset(
                  0,
                  5,
                ),
              ),
            ],
          ),
          child:
              Column(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.orange.shade50,
                  shape:
                      BoxShape.circle,
                ),
                child:
                    Icon(
                  Icons
                      .family_restroom,
                  size: 42,
                  color:
                      Colors.orange
                          .shade700,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Fee Managed By Parent',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 14,
              ),
              Text(
                'Fee concern are discuss with your parent because you select ByParent',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color:
                      Colors.grey
                          .shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // BY ME FEE SCREEN
  // =====================================================

  Widget buildByMeFee() {
    // Global Pay Full / Pay Partial actions on the dark
    // balance card only make sense when there is exactly
    // one course fee record (matches the screenshot).
    final bool hasSingleCourse = courses.length == 1;

    final Map<String, dynamic>? singleCourse =
        hasSingleCourse ? courses.first : null;

    final bool singleCourseFullyPaid =
        singleCourse != null &&
            _toDouble(singleCourse['remaining']) <= 0;

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24,
      ),
      children: [
        // =================================================
        // PAGE TITLE
        // =================================================

        const Text(
          'My Fee Statement',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Manage and track your course fees',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 20),

        // =================================================
        // DARK BALANCE CARD
        // =================================================

        buildBalanceCard(
          hasSingleCourse: hasSingleCourse,
          singleCourse: singleCourse,
          singleCourseFullyPaid:
              singleCourseFullyPaid,
        ),

        const SizedBox(height: 26),

        // =================================================
        // COURSE FEES HEADER
        // =================================================

        Row(
          children: [
            const Text(
              'Course Fees',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${courses.length}',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 3),

        Text(
          'Your enrolled course payments',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 14),

        if (courses.isEmpty)
          buildNoFee(),

        ...courses.map(
          (course) => buildCourseFeeCard(
            course,
            // Hide the redundant per-card payment buttons
            // when the global card above already handles
            // payment for the only course.
            showActions: !(hasSingleCourse &&
                !singleCourseFullyPaid),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // DARK BALANCE CARD
  //
  // Matches the "Total Balance" card in the design:
  // navy background, Paid | Remaining split, fee
  // responsibility pill, Pay Full / Pay Partial actions.
  // =====================================================

  Widget buildBalanceCard({
    required bool hasSingleCourse,
    required Map<String, dynamic>? singleCourse,
    required bool singleCourseFullyPaid,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkCardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkCardColor.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OVERALL STATEMENT',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            money(totalFee),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          // =============================================
          // PAID | REMAINING
          // =============================================

          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        money(totalPaid),
                        style: TextStyle(
                          color: paidColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white24,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Remaining',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        money(totalRemaining),
                        style: TextStyle(
                          color: totalRemaining > 0
                              ? const Color(0xFFEF6B6B)
                              : paidColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // =============================================
          // FEE RESPONSIBILITY PILL
          // =============================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fee Responsibility',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  feeResponsibility.isEmpty
                      ? 'By Me'
                      : feeResponsibility,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          // =============================================
          // GLOBAL PAY ACTIONS (single course only)
          // =============================================

          if (hasSingleCourse &&
              singleCourse != null &&
              !singleCourseFullyPaid) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isPaying
                        ? null
                        : () {
                            makeFullPayment(singleCourse);
                          },
                    icon: const Icon(
                      Icons.check,
                      size: 18,
                    ),
                    label: const Text('Pay Full'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isPaying
                        ? null
                        : () {
                            showPartialPaymentDialog(
                              singleCourse,
                            );
                          },
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Pay Partial',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.white54,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (totalRemaining <= 0) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: paidColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: paidColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'All Fees Paid',
                    style: TextStyle(
                      color: paidColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // COURSE FEE CARD
  //
  // Matches the "Computer Science" card in the design:
  // avatar initial, status badge, tutor row, then
  // Total | Paid | Remaining values.
  // =====================================================

  Widget buildCourseFeeCard(
    Map<String, dynamic> course, {
    required bool showActions,
  }) {
    final feeId = _toInt(
      course['feeId'],
    );

    final courseName =
        course['course']
                ?.toString() ??
            'Course';

    final tutor =
        course['tutor']
                ?.toString() ??
            'Unknown Tutor';

    final total =
        _toDouble(
      course['totalFee'],
    );

    final paid =
        _toDouble(
      course['paid'],
    );

    final remaining =
        _toDouble(
      course['remaining'],
    );

    final bool isFullyPaid =
        remaining <= 0;

    final String tutorInitial =
        tutor.trim().isNotEmpty
            ? tutor.trim()[0].toUpperCase()
            : 'T';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================================
            // COURSE HEADER + STATUS BADGE
            // =========================================

            Row(
              children: [
                Expanded(
                  child: Text(
                    courseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isFullyPaid
                        ? paidColor.withOpacity(0.12)
                        : pendingBadgeColor
                            .withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    isFullyPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      color: isFullyPaid
                          ? paidColor
                          : pendingBadgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // =========================================
            // TUTOR ROW
            // =========================================

            Row(
              children: [
                Container(
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      tutorInitial,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tutor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // =========================================
            // TOTAL | PAID | REMAINING
            // =========================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                buildFeeDetail(
                  'Total',
                  money(total),
                ),
                buildFeeDetail(
                  'Paid',
                  money(paid),
                  valueColor: paidColor,
                ),
                buildFeeDetail(
                  'Remaining',
                  money(remaining),
                  valueColor:
                      isFullyPaid ? paidColor : remainingColor,
                ),
              ],
            ),

            // =========================================
            // PAYMENT BUTTONS
            //
            // Only shown when there is more than one
            // course fee (the global card above handles
            // payment for the single-course case).
            // =========================================

            if (showActions) ...[
              const SizedBox(height: 16),
              if (isFullyPaid)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: paidColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: paidColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Fully Paid',
                        style: TextStyle(
                          color: paidColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (feeId == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Payment unavailable: Fee ID missing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isPaying
                            ? null
                            : () {
                                makeFullPayment(course);
                              },
                        icon: const Icon(
                          Icons.done_all,
                          size: 18,
                        ),
                        label: const Text('Pay Full'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isPaying
                            ? null
                            : () {
                                showPartialPaymentDialog(
                                  course,
                                );
                              },
                        icon: Icon(
                          Icons.payments_outlined,
                          size: 18,
                          color: primaryColor,
                        ),
                        label: Text(
                          'Pay Partial',
                          style: TextStyle(
                            color: primaryColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          side: BorderSide(
                            color: primaryColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  // =====================================================
  // FEE DETAIL
  // =====================================================

  Widget buildFeeDetail(
    String title,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // NO FEE
  // =====================================================

  Widget buildNoFee() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No Fee Record Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'There is no fee record available for your courses.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}




























// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// import 'package:house_of_tutor/services/api_client.dart';

// class StudentMyFee extends StatefulWidget {
//   const StudentMyFee({super.key});

//   @override
//   State<StudentMyFee> createState() => _StudentMyFeeState();
// }

// class _StudentMyFeeState extends State<StudentMyFee> {
//   // =====================================================
//   // VARIABLES
//   // =====================================================

//   bool isLoading = true;
//   bool isPaying = false;

//   String? errorMessage;

//   int? studentId;
//   String studentName = '';

//   String feeResponsibility = '';

//   double totalFee = 0;
//   double totalPaid = 0;
//   double totalRemaining = 0;

//   List<Map<String, dynamic>> courses = [];

//   // =====================================================
//   // COLORS
//   //
//   // Change colors here if you want
//   // =====================================================

//   final Color primaryColor = const Color(0xFF1565C0);
//   final Color secondaryColor = const Color(0xFF42A5F5);
//   final Color backgroundColor = const Color(0xFFF5F7FB);

//   // =====================================================
//   // API PATH
//   //
//   // IMPORTANT:
//   //
//   // Your console showed:
//   //
//   // http://192.168.137.1:5254/Student/student-fee
//   //
//   // Backend controller APIs normally use:
//   //
//   // /api/Student/student-fee
//   //
//   // So /api is added here.
//   // =====================================================

//   static const String studentFeeApi =
//       '/api/Student/student-fee';

//   static const String studentPaymentApi =
//       '/api/Student/student-send-payment';

//   // =====================================================
//   // INIT
//   // =====================================================

//   @override
//   void initState() {
//     super.initState();

//     loadStudentFee();
//   }

//   // =====================================================
//   // LOAD STUDENT FEE
//   //
//   // GET:
//   // /api/Student/student-fee
//   // =====================================================

//   Future<void> loadStudentFee() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     try {
//       // =================================================
//       // CALL API
//       // =================================================

//       final response = await ApiClient.get(
//         studentFeeApi,
//       );

//       // =================================================
//       // DEBUG
//       // =================================================

//       debugPrint('========================================');
//       debugPrint('GET STUDENT FEE');
//       debugPrint('URL: /api/Student/student-fee');
//       debugPrint('Status: ${response.statusCode}');
//       debugPrint('Body: ${response.body}');
//       debugPrint('========================================');

//       // =================================================
//       // CHECK RESPONSE
//       // =================================================

//       if (response.statusCode < 200 ||
//           response.statusCode >= 300) {
//         final message =
//             messageFromBody(response.body);

//         throw Exception(
//           message ??
//               'Unable to load student fee. '
//                   'Status Code: ${response.statusCode}',
//         );
//       }

//       // =================================================
//       // DECODE JSON
//       // =================================================

//       final decodedData = decodeJson(response);

//       if (decodedData is! Map) {
//         throw Exception(
//           'Invalid response received from student fee API.',
//         );
//       }

//       final data =
//           Map<String, dynamic>.from(decodedData);

//       // =================================================
//       // GET COURSES
//       // =================================================

//       List<Map<String, dynamic>> loadedCourses = [];

//       if (data['courses'] is List) {
//         loadedCourses =
//             (data['courses'] as List)
//                 .whereType<Map>()
//                 .map(
//                   (item) =>
//                       Map<String, dynamic>.from(item),
//                 )
//                 .toList();
//       }

//       // =================================================
//       // UPDATE SCREEN
//       // =================================================

//       if (!mounted) return;

//       setState(() {
//         studentId = _toInt(
//           data['studentId'],
//         );

//         studentName =
//             data['studentName']?.toString() ?? '';

//         feeResponsibility =
//             data['feeResponsibility']
//                     ?.toString() ??
//                 '';

//         totalFee = _toDouble(
//           data['totalFee'],
//         );

//         totalPaid = _toDouble(
//           data['totalPaid'],
//         );

//         totalRemaining = _toDouble(
//           data['totalRemaining'],
//         );

//         courses = loadedCourses;

//         isLoading = false;
//         errorMessage = null;
//       });
//     } catch (e) {
//       if (!mounted) return;

//       debugPrint(
//         'Student Fee Error: $e',
//       );

//       setState(() {
//         isLoading = false;

//         errorMessage = e
//             .toString()
//             .replaceFirst(
//               'Exception: ',
//               '',
//             );
//       });
//     }
//   }

//   // =====================================================
//   // DECODE JSON
//   // =====================================================

//   static dynamic decodeJson(
//     http.Response response,
//   ) {
//     if (response.body.trim().isEmpty) {
//       return null;
//     }

//     try {
//       return jsonDecode(
//         utf8.decode(
//           response.bodyBytes,
//         ),
//       );
//     } catch (e) {
//       debugPrint(
//         'JSON Decode Error: $e',
//       );

//       return null;
//     }
//   }

//   // =====================================================
//   // GET MESSAGE FROM API ERROR
//   // =====================================================

//   static String? messageFromBody(
//     String body,
//   ) {
//     if (body.trim().isEmpty) {
//       return null;
//     }

//     try {
//       final decoded = jsonDecode(body);

//       // ===============================================
//       // String response
//       // ===============================================

//       if (decoded is String) {
//         return decoded;
//       }

//       if (decoded is! Map) {
//         return null;
//       }

//       // ===============================================
//       // message
//       // ===============================================

//       if (decoded['message'] != null) {
//         return decoded['message'].toString();
//       }

//       // ===============================================
//       // Message
//       // ===============================================

//       if (decoded['Message'] != null) {
//         return decoded['Message'].toString();
//       }

//       // ===============================================
//       // title
//       // ===============================================

//       if (decoded['title'] != null) {
//         return decoded['title'].toString();
//       }

//       // ===============================================
//       // detail
//       // ===============================================

//       if (decoded['detail'] != null) {
//         return decoded['detail'].toString();
//       }

//       // ===============================================
//       // error
//       // ===============================================

//       if (decoded['error'] != null) {
//         return decoded['error'].toString();
//       }

//       // ===============================================
//       // errors
//       // ===============================================

//       if (decoded['errors'] is Map) {
//         final errors =
//             decoded['errors'] as Map;

//         for (final value in errors.values) {
//           if (value is List &&
//               value.isNotEmpty) {
//             return value.first.toString();
//           }

//           if (value != null) {
//             return value.toString();
//           }
//         }
//       }
//     } catch (_) {
//       // ===============================================
//       // API may return plain text
//       // ===============================================

//       if (body.trim().isNotEmpty) {
//         return body.trim();
//       }
//     }

//     return null;
//   }

//   // =====================================================
//   // CONVERT TO DOUBLE
//   // =====================================================

//   double _toDouble(
//     dynamic value,
//   ) {
//     if (value == null) {
//       return 0;
//     }

//     if (value is num) {
//       return value.toDouble();
//     }

//     return double.tryParse(
//           value.toString(),
//         ) ??
//         0;
//   }

//   // =====================================================
//   // CONVERT TO INT
//   // =====================================================

//   int? _toInt(
//     dynamic value,
//   ) {
//     if (value == null) {
//       return null;
//     }

//     if (value is int) {
//       return value;
//     }

//     if (value is num) {
//       return value.toInt();
//     }

//     return int.tryParse(
//       value.toString(),
//     );
//   }

//   // =====================================================
//   // FORMAT MONEY
//   // =====================================================

//   String money(
//     double value,
//   ) {
//     return 'Rs. ${value.toStringAsFixed(0)}';
//   }

//   // =====================================================
//   // SHOW PARTIAL PAYMENT DIALOG
//   // =====================================================

//   Future<void> showPartialPaymentDialog(
//     Map<String, dynamic> course,
//   ) async {
//     final feeId = _toInt(
//       course['feeId'],
//     );

//     final remaining = _toDouble(
//       course['remaining'],
//     );

//     // =================================================
//     // CHECK FEE
//     // =================================================

//     if (feeId == null) {
//       showMessage(
//         'Fee ID is missing.',
//         isError: true,
//       );

//       return;
//     }

//     if (remaining <= 0) {
//       showMessage(
//         'No remaining amount available.',
//         isError: true,
//       );

//       return;
//     }

//     final controller =
//         TextEditingController();

//     bool paymentStarted = false;

//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (
//             context,
//             setDialogState,
//           ) {
//             return AlertDialog(
//               shape:
//                   RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(
//                   18,
//                 ),
//               ),

//               // =========================================
//               // TITLE
//               // =========================================

//               title: const Text(
//                 'Partially Pay',
//                 style: TextStyle(
//                   fontWeight:
//                       FontWeight.bold,
//                 ),
//               ),

//               // =========================================
//               // CONTENT
//               // =========================================

//               content: Column(
//                 mainAxisSize:
//                     MainAxisSize.min,
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Remaining Fee: ${money(remaining)}',
//                     style: TextStyle(
//                       color:
//                           Colors.grey.shade700,
//                       fontWeight:
//                           FontWeight.w600,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   TextField(
//                     controller:
//                         controller,

//                     enabled:
//                         !paymentStarted,

//                     keyboardType:
//                         const TextInputType
//                             .numberWithOptions(
//                       decimal: true,
//                     ),

//                     decoration:
//                         InputDecoration(
//                       labelText:
//                           'Enter Amount',

//                       hintText:
//                           'e.g. 5000',

//                       prefixText:
//                           'Rs. ',

//                       border:
//                           OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius
//                                 .circular(
//                           12,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               // =========================================
//               // BUTTONS
//               // =========================================

//               actions: [
//                 TextButton(
//                   onPressed:
//                       paymentStarted
//                           ? null
//                           : () {
//                               Navigator.pop(
//                                 dialogContext,
//                               );
//                             },
//                   child:
//                       const Text(
//                     'Cancel',
//                   ),
//                 ),

//                 ElevatedButton(
//                   onPressed:
//                       paymentStarted
//                           ? null
//                           : () async {
//                               // =================================
//                               // GET AMOUNT
//                               // =================================

//                               final amount =
//                                   double.tryParse(
//                                 controller.text
//                                     .trim(),
//                               );

//                               // =================================
//                               // VALIDATE
//                               // =================================

//                               if (amount ==
//                                       null ||
//                                   amount <= 0) {
//                                 ScaffoldMessenger
//                                     .of(
//                                   dialogContext,
//                                 ).showSnackBar(
//                                   const SnackBar(
//                                     content:
//                                         Text(
//                                       'Please enter a valid amount.',
//                                     ),
//                                   ),
//                                 );

//                                 return;
//                               }

//                               // =================================
//                               // CHECK REMAINING
//                               // =================================

//                               if (amount >
//                                   remaining) {
//                                 ScaffoldMessenger
//                                     .of(
//                                   dialogContext,
//                                 ).showSnackBar(
//                                   SnackBar(
//                                     content:
//                                         Text(
//                                       'Amount cannot exceed ${money(remaining)}.',
//                                     ),
//                                   ),
//                                 );

//                                 return;
//                               }

//                               // =================================
//                               // START LOADING
//                               // =================================

//                               setDialogState(() {
//                                 paymentStarted =
//                                     true;
//                               });

//                               // =================================
//                               // SEND PAYMENT
//                               //
//                               // Do NOT manually pop here.
//                               // makePayment will close the
//                               // dialog after successful payment.
//                               // =================================

//                               await makePayment(
//                                 feeId: feeId,
//                                 amount: amount,
//                                 closeDialog: true,
//                                 dialogContext:
//                                     dialogContext,
//                               );

//                               // =================================
//                               // IF PAYMENT FAILED
//                               //
//                               // Enable dialog again.
//                               // =================================

//                               if (mounted &&
//                                   Navigator.of(
//                                     dialogContext,
//                                   ).canPop()) {
//                                 setDialogState(() {
//                                   paymentStarted =
//                                       false;
//                                 });
//                               }
//                             },

//                   style:
//                       ElevatedButton.styleFrom(
//                     backgroundColor:
//                         primaryColor,
//                     foregroundColor:
//                         Colors.white,
//                   ),

//                   child: paymentStarted
//                       ? const SizedBox(
//                           width: 18,
//                           height: 18,
//                           child:
//                               CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color:
//                                 Colors.white,
//                           ),
//                         )
//                       : const Text(
//                           'Pay',
//                         ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );

//     controller.dispose();
//   }

//   // =====================================================
//   // FULL PAYMENT
//   // =====================================================

//   Future<void> makeFullPayment(
//     Map<String, dynamic> course,
//   ) async {
//     final feeId = _toInt(
//       course['feeId'],
//     );

//     final remaining = _toDouble(
//       course['remaining'],
//     );

//     // =================================================
//     // CHECK FEE
//     // =================================================

//     if (feeId == null) {
//       showMessage(
//         'Fee ID is missing.',
//         isError: true,
//       );

//       return;
//     }

//     if (remaining <= 0) {
//       showMessage(
//         'This fee is already fully paid.',
//         isError: true,
//       );

//       return;
//     }

//     // =================================================
//     // PREVENT DUPLICATE PAYMENT
//     // =================================================

//     if (isPaying) {
//       return;
//     }

//     // =================================================
//     // CONFIRM PAYMENT
//     // =================================================

//     final confirm =
//         await showDialog<bool>(
//       context: context,
//       builder:
//           (dialogContext) {
//         return AlertDialog(
//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(
//               18,
//             ),
//           ),

//           title: const Text(
//             'Fully Pay',
//             style: TextStyle(
//               fontWeight:
//                   FontWeight.bold,
//             ),
//           ),

//           content: Text(
//             'Do you want to pay ${money(remaining)}?',
//           ),

//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                   false,
//                 );
//               },
//               child:
//                   const Text(
//                 'Cancel',
//               ),
//             ),

//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                   true,
//                 );
//               },

//               style:
//                   ElevatedButton.styleFrom(
//                 backgroundColor:
//                     primaryColor,
//                 foregroundColor:
//                     Colors.white,
//               ),

//               child:
//                   const Text(
//                 'Pay Now',
//               ),
//             ),
//           ],
//         );
//       },
//     );

//     // =================================================
//     // CANCELLED
//     // =================================================

//     if (confirm != true) {
//       return;
//     }

//     // =================================================
//     // SEND PAYMENT
//     // =================================================

//     await makePayment(
//       feeId: feeId,
//       amount: remaining,
//       closeDialog: false,
//     );
//   }

//   // =====================================================
//   // SEND PAYMENT
//   //
//   // POST:
//   // /api/Student/student-send-payment
//   //
//   // BODY:
//   // {
//   //   "feeId": feeId,
//   //   "amount": amount
//   // }
//   // =====================================================

//   Future<void> makePayment({
//     required int feeId,
//     required double amount,
//     required bool closeDialog,
//     BuildContext? dialogContext,
//   }) async {
//     // =================================================
//     // PREVENT MULTIPLE PAYMENTS
//     // =================================================

//     if (isPaying) {
//       return;
//     }

//     if (!mounted) {
//       return;
//     }

//     setState(() {
//       isPaying = true;
//     });

//     bool paymentSuccess = false;

//     try {
//       // =================================================
//       // CALL PAYMENT API
//       // =================================================

//       final response = await ApiClient.post(
//         studentPaymentApi,
//         {
//           'feeId': feeId,
//           'amount': amount,
//         },
//       );

//       // =================================================
//       // DEBUG
//       // =================================================

//       debugPrint('========================================');
//       debugPrint(
//         'SEND STUDENT PAYMENT',
//       );
//       debugPrint(
//         'URL: /api/Student/student-send-payment',
//       );
//       debugPrint(
//         'Status: ${response.statusCode}',
//       );
//       debugPrint(
//         'Body: ${response.body}',
//       );
//       debugPrint('========================================');

//       // =================================================
//       // CHECK RESPONSE
//       // =================================================

//       if (response.statusCode < 200 ||
//           response.statusCode >= 300) {
//         throw Exception(
//           messageFromBody(
//                 response.body,
//               ) ??
//               'Unable to send payment. '
//                   'Status Code: ${response.statusCode}',
//         );
//       }

//       // =================================================
//       // DECODE RESPONSE
//       // =================================================

//       final decodedData =
//           decodeJson(response);

//       Map<String, dynamic> paymentData =
//           {};

//       if (decodedData is Map) {
//         paymentData =
//             Map<String, dynamic>.from(
//           decodedData,
//         );
//       }

//       // =================================================
//       // PAYMENT TYPE
//       //
//       // Backend returns:
//       // Full
//       // Partial
//       // =================================================

//       final paymentType =
//           paymentData['paymentType']
//                   ?.toString() ??
//               '';

//       paymentSuccess = true;

//       // =================================================
//       // CLOSE PARTIAL DIALOG
//       // =================================================

//       if (closeDialog &&
//           dialogContext != null &&
//           Navigator.of(
//             dialogContext,
//           ).canPop()) {
//         Navigator.of(
//           dialogContext,
//         ).pop();
//       }

//       // =================================================
//       // STOP LOADING
//       // =================================================

//       if (!mounted) return;

//       setState(() {
//         isPaying = false;
//       });

//       // =================================================
//       // SUCCESS MESSAGE
//       // =================================================

//       showMessage(
//         paymentType.isNotEmpty
//             ? 'Payment Sent Successfully.\n'
//                 'Type: $paymentType'
//             : 'Payment Sent Successfully.',
//       );

//       // =================================================
//       // RELOAD FEE
//       // =================================================

//       await loadStudentFee();
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       debugPrint(
//         'Payment Error: $e',
//       );

//       // =================================================
//       // STOP LOADING
//       // =================================================

//       setState(() {
//         isPaying = false;
//       });

//       // =================================================
//       // SHOW ERROR
//       // =================================================

//       showMessage(
//         e.toString().replaceFirst(
//               'Exception: ',
//               '',
//             ),
//         isError: true,
//       );
//     }
//   }

//   // =====================================================
//   // SHOW MESSAGE
//   // =====================================================

//   void showMessage(
//     String message, {
//     bool isError = false,
//   }) {
//     if (!mounted) {
//       return;
//     }

//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//         ),

//         backgroundColor:
//             isError
//                 ? Colors.red.shade700
//                 : Colors.green.shade700,

//         behavior:
//             SnackBarBehavior.floating,

//         margin:
//             const EdgeInsets.all(
//           16,
//         ),

//         shape:
//             RoundedRectangleBorder(
//           borderRadius:
//               BorderRadius.circular(
//             12,
//           ),
//         ),
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
//           backgroundColor,

//       // =================================================
//       // APP BAR
//       // =================================================

//       appBar: AppBar(
//         title:
//             const Text(
//           'My Fee',
//           style: TextStyle(
//             fontWeight:
//                 FontWeight.bold,
//           ),
//         ),

//         centerTitle: true,

//         backgroundColor:
//             primaryColor,

//         foregroundColor:
//             Colors.white,

//         elevation: 0,
//       ),

//       // =================================================
//       // BODY
//       // =================================================

//       body:
//           RefreshIndicator(
//         onRefresh:
//             loadStudentFee,

//         child: isLoading
//             ? const Center(
//                 child:
//                     CircularProgressIndicator(),
//               )
//             : errorMessage !=
//                     null
//                 ? buildError()
//                 : buildFeeScreen(),
//       ),
//     );
//   }

//   // =====================================================
//   // ERROR SCREEN
//   // =====================================================

//   Widget buildError() {
//     return ListView(
//       physics:
//           const AlwaysScrollableScrollPhysics(),

//       children: [
//         SizedBox(
//           height:
//               MediaQuery.of(
//                     context,
//                   ).size.height *
//                   0.25,
//         ),

//         const Icon(
//           Icons.error_outline,
//           size: 70,
//           color: Colors.red,
//         ),

//         const SizedBox(
//           height: 15,
//         ),

//         const Center(
//           child: Text(
//             'Unable to Load Fee',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight:
//                   FontWeight.bold,
//             ),
//           ),
//         ),

//         const SizedBox(
//           height: 10,
//         ),

//         Padding(
//           padding:
//               const EdgeInsets.symmetric(
//             horizontal: 30,
//           ),

//           child: Text(
//             errorMessage ??
//                 'Something went wrong.',

//             textAlign:
//                 TextAlign.center,

//             style: TextStyle(
//               color:
//                   Colors.grey.shade700,
//             ),
//           ),
//         ),

//         const SizedBox(
//           height: 20,
//         ),

//         Center(
//           child:
//               ElevatedButton(
//             onPressed:
//                 loadStudentFee,

//             style:
//                 ElevatedButton.styleFrom(
//               backgroundColor:
//                   primaryColor,
//               foregroundColor:
//                   Colors.white,
//             ),

//             child:
//                 const Text(
//               'Try Again',
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // =====================================================
//   // MAIN FEE SCREEN
//   // =====================================================

//   Widget buildFeeScreen() {
//     // =================================================
//     // BY PARENT
//     // =================================================

//     if (feeResponsibility
//             .toLowerCase()
//             .replaceAll(
//               ' ',
//               '',
//             ) ==
//         'byparent') {
//       return buildByParentMessage();
//     }

//     // =================================================
//     // BY ME
//     // =================================================

//     return buildByMeFee();
//   }

//   // =====================================================
//   // BY PARENT MESSAGE
//   // =====================================================

//   Widget buildByParentMessage() {
//     return ListView(
//       physics:
//           const AlwaysScrollableScrollPhysics(),

//       padding:
//           const EdgeInsets.all(
//         20,
//       ),

//       children: [
//         const SizedBox(
//           height: 60,
//         ),

//         Container(
//           padding:
//               const EdgeInsets.all(
//             25,
//           ),

//           decoration:
//               BoxDecoration(
//             color: Colors.white,

//             borderRadius:
//                 BorderRadius.circular(
//               22,
//             ),

//             boxShadow: [
//               BoxShadow(
//                 color:
//                     Colors.black
//                         .withOpacity(
//                   0.06,
//                 ),

//                 blurRadius: 15,

//                 offset:
//                     const Offset(
//                   0,
//                   5,
//                 ),
//               ),
//             ],
//           ),

//           child:
//               Column(
//             children: [
//               Container(
//                 height: 80,
//                 width: 80,

//                 decoration:
//                     BoxDecoration(
//                   color:
//                       Colors.orange.shade50,

//                   shape:
//                       BoxShape.circle,
//                 ),

//                 child:
//                     Icon(
//                   Icons
//                       .family_restroom,

//                   size: 42,

//                   color:
//                       Colors.orange
//                           .shade700,
//                 ),
//               ),

//               const SizedBox(
//                 height: 20,
//               ),

//               const Text(
//                 'Fee Managed By Parent',

//                 textAlign:
//                     TextAlign.center,

//                 style:
//                     TextStyle(
//                   fontSize: 21,
//                   fontWeight:
//                       FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(
//                 height: 14,
//               ),

//               Text(
//                 'Fee concern are discuss with your parent because you select ByParent',

//                 textAlign:
//                     TextAlign.center,

//                 style:
//                     TextStyle(
//                   fontSize: 15,
//                   height: 1.5,
//                   color:
//                       Colors.grey
//                           .shade700,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // =====================================================
//   // BY ME FEE SCREEN
//   // =====================================================

//   Widget buildByMeFee() {
//     return ListView(
//       physics:
//           const AlwaysScrollableScrollPhysics(),

//       padding:
//           const EdgeInsets.all(
//         16,
//       ),

//       children: [
//         // =================================================
//         // STUDENT HEADER
//         // =================================================

//         Container(
//           padding:
//               const EdgeInsets.all(
//             18,
//           ),

//           decoration:
//               BoxDecoration(
//             gradient:
//                 LinearGradient(
//               colors: [
//                 primaryColor,
//                 secondaryColor,
//               ],
//             ),

//             borderRadius:
//                 BorderRadius.circular(
//               20,
//             ),

//             boxShadow: [
//               BoxShadow(
//                 color:
//                     primaryColor
//                         .withOpacity(
//                   0.2,
//                 ),

//                 blurRadius: 12,

//                 offset:
//                     const Offset(
//                   0,
//                   5,
//                 ),
//               ),
//             ],
//           ),

//           child:
//               Row(
//             children: [
//               Container(
//                 height: 55,
//                 width: 55,

//                 decoration:
//                     BoxDecoration(
//                   color:
//                       Colors.white
//                           .withOpacity(
//                     0.2,
//                   ),

//                   shape:
//                       BoxShape.circle,
//                 ),

//                 child:
//                     const Icon(
//                   Icons.person,

//                   color:
//                       Colors.white,

//                   size: 30,
//                 ),
//               ),

//               const SizedBox(
//                 width: 14,
//               ),

//               Expanded(
//                 child:
//                     Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment
//                           .start,

//                   children: [
//                     const Text(
//                       'Student Fee',

//                       style:
//                           TextStyle(
//                         color:
//                             Colors.white70,
//                         fontSize:
//                             13,
//                       ),
//                     ),

//                     const SizedBox(
//                       height: 3,
//                     ),

//                     Text(
//                       studentName
//                               .isEmpty
//                           ? 'Student'
//                           : studentName,

//                       maxLines: 1,

//                       overflow:
//                           TextOverflow
//                               .ellipsis,

//                       style:
//                           const TextStyle(
//                         color:
//                             Colors.white,
//                         fontSize:
//                             20,
//                         fontWeight:
//                             FontWeight
//                                 .bold,
//                       ),
//                     ),

//                     const SizedBox(
//                       height: 4,
//                     ),

//                     const Text(
//                       'Fee Responsibility: ByMe',

//                       style:
//                           TextStyle(
//                         color:
//                             Colors.white,
//                         fontSize:
//                             12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(
//           height: 16,
//         ),

//         // =================================================
//         // SUMMARY
//         // =================================================

//         Row(
//           children: [
//             Expanded(
//               child:
//                   buildSummaryCard(
//                 title:
//                     'Total Fee',
//                 amount:
//                     totalFee,
//                 icon:
//                     Icons
//                         .account_balance_wallet,
//                 iconColor:
//                     Colors.blue,
//               ),
//             ),

//             const SizedBox(
//               width: 10,
//             ),

//             Expanded(
//               child:
//                   buildSummaryCard(
//                 title:
//                     'Paid',
//                 amount:
//                     totalPaid,
//                 icon:
//                     Icons
//                         .check_circle,
//                 iconColor:
//                     Colors.green,
//               ),
//             ),

//             const SizedBox(
//               width: 10,
//             ),

//             Expanded(
//               child:
//                   buildSummaryCard(
//                 title:
//                     'Remaining',
//                 amount:
//                     totalRemaining,
//                 icon:
//                     Icons.pending,
//                 iconColor:
//                     Colors.orange,
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(
//           height: 25,
//         ),

//         const Text(
//           'Course Fees',

//           style:
//               TextStyle(
//             fontSize: 20,
//             fontWeight:
//                 FontWeight.bold,
//           ),
//         ),

//         const SizedBox(
//           height: 12,
//         ),

//         if (courses.isEmpty)
//           buildNoFee(),

//         ...courses.map(
//           (course) =>
//               buildCourseFeeCard(
//             course,
//           ),
//         ),
//       ],
//     );
//   }

//   // =====================================================
//   // SUMMARY CARD
//   // =====================================================

//   Widget buildSummaryCard({
//     required String title,
//     required double amount,
//     required IconData icon,
//     required Color iconColor,
//   }) {
//     return Container(
//       padding:
//           const EdgeInsets.all(
//         12,
//       ),

//       decoration:
//           BoxDecoration(
//         color:
//             Colors.white,

//         borderRadius:
//             BorderRadius.circular(
//           16,
//         ),

//         boxShadow: [
//           BoxShadow(
//             color:
//                 Colors.black
//                     .withOpacity(
//               0.04,
//             ),

//             blurRadius: 8,

//             offset:
//                 const Offset(
//               0,
//               3,
//             ),
//           ),
//         ],
//       ),

//       child:
//           Column(
//         crossAxisAlignment:
//             CrossAxisAlignment
//                 .start,

//         children: [
//           Icon(
//             icon,
//             color:
//                 iconColor,
//             size: 24,
//           ),

//           const SizedBox(
//             height: 8,
//           ),

//           Text(
//             title,

//             style:
//                 TextStyle(
//               fontSize: 11,
//               color:
//                   Colors.grey
//                       .shade600,
//             ),
//           ),

//           const SizedBox(
//             height: 3,
//           ),

//           FittedBox(
//             fit:
//                 BoxFit.scaleDown,

//             alignment:
//                 Alignment
//                     .centerLeft,

//             child:
//                 Text(
//               money(amount),

//               style:
//                   const TextStyle(
//                 fontSize: 15,
//                 fontWeight:
//                     FontWeight
//                         .bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // =====================================================
//   // COURSE FEE CARD
//   // =====================================================

//   Widget buildCourseFeeCard(
//     Map<String, dynamic> course,
//   ) {
//     final feeId = _toInt(
//       course['feeId'],
//     );

//     final courseName =
//         course['course']
//                 ?.toString() ??
//             'Course';

//     final tutor =
//         course['tutor']
//                 ?.toString() ??
//             'Unknown Tutor';

//     final total =
//         _toDouble(
//       course['totalFee'],
//     );

//     final paid =
//         _toDouble(
//       course['paid'],
//     );

//     final remaining =
//         _toDouble(
//       course['remaining'],
//     );

//     final bool isFullyPaid =
//         remaining <= 0;

//     // =================================================
//     // PROGRESS
//     // =================================================

//     double progress = 0;

//     if (total > 0) {
//       progress =
//           paid / total;

//       if (progress > 1) {
//         progress = 1;
//       }

//       if (progress < 0) {
//         progress = 0;
//       }
//     }

//     return Container(
//       margin:
//           const EdgeInsets.only(
//         bottom: 15,
//       ),

//       decoration:
//           BoxDecoration(
//         color:
//             Colors.white,

//         borderRadius:
//             BorderRadius.circular(
//           18,
//         ),

//         boxShadow: [
//           BoxShadow(
//             color:
//                 Colors.black
//                     .withOpacity(
//               0.05,
//             ),

//             blurRadius: 10,

//             offset:
//                 const Offset(
//               0,
//               4,
//             ),
//           ),
//         ],
//       ),

//       child:
//           Padding(
//         padding:
//             const EdgeInsets.all(
//           16,
//         ),

//         child:
//             Column(
//           crossAxisAlignment:
//               CrossAxisAlignment
//                   .start,

//           children: [
//             // =============================================
//             // COURSE HEADER
//             // =============================================

//             Row(
//               children: [
//                 Container(
//                   height: 45,
//                   width: 45,

//                   decoration:
//                       BoxDecoration(
//                     color:
//                         primaryColor
//                             .withOpacity(
//                       0.1,
//                     ),

//                     borderRadius:
//                         BorderRadius
//                             .circular(
//                       12,
//                     ),
//                   ),

//                   child:
//                       Icon(
//                     Icons
//                         .menu_book,
//                     color:
//                         primaryColor,
//                   ),
//                 ),

//                 const SizedBox(
//                   width: 12,
//                 ),

//                 Expanded(
//                   child:
//                       Column(
//                     crossAxisAlignment:
//                         CrossAxisAlignment
//                             .start,

//                     children: [
//                       Text(
//                         courseName,

//                         maxLines: 2,

//                         overflow:
//                             TextOverflow
//                                 .ellipsis,

//                         style:
//                             const TextStyle(
//                           fontSize:
//                               17,
//                           fontWeight:
//                               FontWeight
//                                   .bold,
//                         ),
//                       ),

//                       const SizedBox(
//                         height: 3,
//                       ),

//                       Text(
//                         'Tutor: $tutor',

//                         maxLines: 1,

//                         overflow:
//                             TextOverflow
//                                 .ellipsis,

//                         style:
//                             TextStyle(
//                           fontSize:
//                               12,
//                           color:
//                               Colors
//                                   .grey
//                                   .shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(
//               height: 18,
//             ),

//             // =============================================
//             // PROGRESS
//             // =============================================

//             ClipRRect(
//               borderRadius:
//                   BorderRadius.circular(
//                 10,
//               ),

//               child:
//                   LinearProgressIndicator(
//                 value:
//                     progress,

//                 minHeight:
//                     8,

//                 backgroundColor:
//                     Colors
//                         .grey
//                         .shade200,

//                 valueColor:
//                     AlwaysStoppedAnimation<
//                         Color>(
//                   isFullyPaid
//                       ? Colors
//                           .green
//                       : primaryColor,
//                 ),
//               ),
//             ),

//             const SizedBox(
//               height: 15,
//             ),

//             // =============================================
//             // FEE DETAILS
//             // =============================================

//             Row(
//               mainAxisAlignment:
//                   MainAxisAlignment
//                       .spaceBetween,

//               children: [
//                 buildFeeDetail(
//                   'Total',
//                   money(total),
//                 ),

//                 buildFeeDetail(
//                   'Paid',
//                   money(paid),
//                   valueColor:
//                       Colors
//                           .green
//                           .shade700,
//                 ),

//                 buildFeeDetail(
//                   'Remaining',
//                   money(
//                     remaining,
//                   ),
//                   valueColor:
//                       isFullyPaid
//                           ? Colors
//                               .green
//                               .shade700
//                           : Colors
//                               .orange
//                               .shade700,
//                 ),
//               ],
//             ),

//             const SizedBox(
//               height: 18,
//             ),

//             // =============================================
//             // PAYMENT BUTTONS
//             // =============================================

//             if (isFullyPaid)
//               Container(
//                 width:
//                     double.infinity,

//                 padding:
//                     const EdgeInsets
//                         .symmetric(
//                   vertical: 12,
//                 ),

//                 decoration:
//                     BoxDecoration(
//                   color:
//                       Colors
//                           .green
//                           .shade50,

//                   borderRadius:
//                       BorderRadius
//                           .circular(
//                     12,
//                   ),
//                 ),

//                 child:
//                     Row(
//                   mainAxisAlignment:
//                       MainAxisAlignment
//                           .center,

//                   children: [
//                     Icon(
//                       Icons
//                           .check_circle,

//                       color:
//                           Colors
//                               .green
//                               .shade700,

//                       size: 20,
//                     ),

//                     const SizedBox(
//                       width: 7,
//                     ),

//                     Text(
//                       'Fully Paid',

//                       style:
//                           TextStyle(
//                         color:
//                             Colors
//                                 .green
//                                 .shade700,

//                         fontWeight:
//                             FontWeight
//                                 .bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//             else if (feeId == null)
//               Container(
//                 width:
//                     double.infinity,

//                 padding:
//                     const EdgeInsets
//                         .symmetric(
//                   vertical: 12,
//                 ),

//                 decoration:
//                     BoxDecoration(
//                   color:
//                       Colors
//                           .red
//                           .shade50,

//                   borderRadius:
//                       BorderRadius
//                           .circular(
//                     12,
//                   ),
//                 ),

//                 child:
//                     Text(
//                   'Payment unavailable: Fee ID missing.',

//                   textAlign:
//                       TextAlign.center,

//                   style:
//                       TextStyle(
//                     color:
//                         Colors
//                             .red
//                             .shade700,

//                     fontWeight:
//                         FontWeight
//                             .w600,
//                   ),
//                 ),
//               )
//             else
//               Row(
//                 children: [
//                   // =======================================
//                   // FULL PAYMENT
//                   // =======================================

//                   Expanded(
//                     child:
//                         ElevatedButton
//                             .icon(
//                       onPressed:
//                           isPaying
//                               ? null
//                               : () {
//                                   makeFullPayment(
//                                     course,
//                                   );
//                                 },

//                       icon:
//                           const Icon(
//                         Icons.done_all,
//                         size: 18,
//                       ),

//                       label:
//                           const Text(
//                         'Fully Pay',
//                       ),

//                       style:
//                           ElevatedButton
//                               .styleFrom(
//                         backgroundColor:
//                             primaryColor,

//                         foregroundColor:
//                             Colors.white,

//                         padding:
//                             const EdgeInsets
//                                 .symmetric(
//                           vertical:
//                               12,
//                         ),

//                         shape:
//                             RoundedRectangleBorder(
//                           borderRadius:
//                               BorderRadius
//                                   .circular(
//                             12,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(
//                     width: 10,
//                   ),

//                   // =======================================
//                   // PARTIAL PAYMENT
//                   // =======================================

//                   Expanded(
//                     child:
//                         OutlinedButton
//                             .icon(
//                       onPressed:
//                           isPaying
//                               ? null
//                               : () {
//                                   showPartialPaymentDialog(
//                                     course,
//                                   );
//                                 },

//                       icon:
//                           Icon(
//                         Icons
//                             .payments_outlined,

//                         size: 18,

//                         color:
//                             primaryColor,
//                       ),

//                       label:
//                           Text(
//                         'Partially Pay',

//                         style:
//                             TextStyle(
//                           color:
//                               primaryColor,
//                         ),
//                       ),

//                       style:
//                           OutlinedButton
//                               .styleFrom(
//                         padding:
//                             const EdgeInsets
//                                 .symmetric(
//                           vertical:
//                               12,
//                         ),

//                         side:
//                             BorderSide(
//                           color:
//                               primaryColor,
//                         ),

//                         shape:
//                             RoundedRectangleBorder(
//                           borderRadius:
//                               BorderRadius
//                                   .circular(
//                             12,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // =====================================================
//   // FEE DETAIL
//   // =====================================================

//   Widget buildFeeDetail(
//     String title,
//     String value, {
//     Color? valueColor,
//   }) {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment
//               .start,

//       children: [
//         Text(
//           title,

//           style:
//               TextStyle(
//             fontSize: 11,
//             color:
//                 Colors
//                     .grey
//                     .shade600,
//           ),
//         ),

//         const SizedBox(
//           height: 4,
//         ),

//         Text(
//           value,

//           style:
//               TextStyle(
//             fontSize: 13,
//             fontWeight:
//                 FontWeight.bold,

//             color:
//                 valueColor ??
//                     Colors
//                         .black87,
//           ),
//         ),
//       ],
//     );
//   }

//   // =====================================================
//   // NO FEE
//   // =====================================================

//   Widget buildNoFee() {
//     return Container(
//       padding:
//           const EdgeInsets.all(
//         30,
//       ),

//       decoration:
//           BoxDecoration(
//         color:
//             Colors.white,

//         borderRadius:
//             BorderRadius.circular(
//           18,
//         ),
//       ),

//       child:
//           Column(
//         children: [
//           Icon(
//             Icons
//                 .receipt_long_outlined,

//             size: 60,

//             color:
//                 Colors
//                     .grey
//                     .shade400,
//           ),

//           const SizedBox(
//             height: 12,
//           ),

//           const Text(
//             'No Fee Record Found',

//             style:
//                 TextStyle(
//               fontSize: 18,
//               fontWeight:
//                   FontWeight
//                       .bold,
//             ),
//           ),

//           const SizedBox(
//             height: 5,
//           ),

//           Text(
//             'There is no fee record available for your courses.',

//             textAlign:
//                 TextAlign.center,

//             style:
//                 TextStyle(
//               color:
//                   Colors
//                       .grey
//                       .shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
