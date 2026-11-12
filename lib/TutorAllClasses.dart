import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/TutorDrawer.dart';
import 'package:house_of_tutor/TutorHome.dart';
import 'package:house_of_tutor/services/api_client.dart';


class TutorClassModel {
  final int requestId;
  final int studentId;
  final String studentName;
  final int courseId;
  final String courseName;
  final String? classDate;
  final String day;
  final String time;
  final String requestType;
  final String status;
  final String? requestDate;

  TutorClassModel({
    required this.requestId,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.classDate,
    required this.day,
    required this.time,
    required this.requestType,
    required this.status,
    required this.requestDate,
  });

  factory TutorClassModel.fromJson(Map<String, dynamic> json) {
    return TutorClassModel(
      requestId: json["request_id"] ?? json["requestId"] ?? 0,
      studentId: json["student_id"] ?? json["studentId"] ?? 0,
      studentName: json["student_name"] ?? json["studentName"] ?? "",
      courseId: json["course_id"] ?? json["courseId"] ?? 0,
      courseName: json["course_name"] ?? json["courseName"] ?? "",
      classDate: json["class_date"]?.toString() ?? json["classDate"]?.toString(),
      day: json["day"] ?? "",
      time: json["time"] ?? "",
      requestType: json["request_type"] ?? json["requestType"] ?? "",
      status: json["status"] ?? "",
      requestDate: json["request_date"]?.toString() ?? json["requestDate"]?.toString(),
    );
  }
}

/// Tutor All Classes Screen

class TutorAllClasses extends StatefulWidget {
  const TutorAllClasses({super.key});

  @override
  State<TutorAllClasses> createState() => _TutorAllClassesState();
}

class _TutorAllClassesState extends State<TutorAllClasses> {
  bool loading = true;

  List<TutorClassModel> classes = [];

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TutorHome()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }
  // FETCH ALL CLASSES
 
  Future<void> fetchClasses() async {
    try {
      if (mounted) {
        setState(() {
          loading = true;
        });
      }

      final response = await ApiClient.get("/api/Tutor/all-classes");
      debugPrint("ALL CLASSES STATUS : ${response.statusCode}");
      debugPrint("ALL CLASSES BODY : ${response.body}");
      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final List data = json["data"] ?? [];
        classes = data.map((e) => TutorClassModel.fromJson(e)).toList();
        if (mounted) setState(() {});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ApiClient.messageFromBody(response.body) ??
                    "Unable to load classes",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("ALL CLASSES ERROR : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error : $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }
  // COMPLETE CLASS

  Future<void> completeClass(TutorClassModel item) async {
    try {
      final response = await ApiClient.put(
        "/api/Tutor/complete-class/${item.requestId}",
        {},
      );

      debugPrint("COMPLETE CLASS : ${response.body}");

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Class marked as complete")),
          );
        }
        fetchClasses();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ApiClient.messageFromBody(response.body) ??
                    "Unable to complete class",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("COMPLETE CLASS ERROR : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error : $e")),
        );
      }
    }
  }

  // CANCEL CLASS

  Future<void> cancelClass(TutorClassModel item) async {
    try {
      final response = await ApiClient.put(
        "/api/Tutor/cancel-class/${item.requestId}",
        {},
      );
      debugPrint("CANCEL CLASS : ${response.body}");
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Class cancelled successfully")),
          );
        }
        fetchClasses();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ApiClient.messageFromBody(response.body) ??
                    "Unable to cancel class",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("CANCEL CLASS ERROR : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error : $e")),
        );
      }
    }
  }

  // RESCHEDULE (AUTO)

  Future<void> rescheduleClass(TutorClassModel item) async {
    await autoSchedule(
      item: item,
      endpoint: "/api/Tutor/reschedule",
      requestType: "Reschedule",
    );
  }

  // PRESCHEDULE (AUTO)
 

  Future<void> prescheduleClass(TutorClassModel item) async {
    await autoSchedule(
      item: item,
      endpoint: "/api/Tutor/preschedule",
      requestType: "Preschedule",
    );
  }

  Future<void> autoSchedule({
    required TutorClassModel item,
    required String endpoint,
    required String requestType,
  }) async {
    try {
      setState(() {
        loading = true;
      });

      final response = await ApiClient.post(endpoint, {
        "requestId": item.requestId,
      });

      debugPrint("AUTO SCHEDULE : ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final bool autoScheduled = json["autoScheduled"] ?? false;
        final bool manualRequired = json["manualRequired"] ?? false;

        if (autoScheduled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  json["message"] ?? "Class $requestType successful",
                ),
              ),
            );
          }
          fetchClasses();
        } else if (manualRequired) {
          if (mounted) {
            setState(() {
              loading = false;
            });
            openManualScheduleDialog(item, requestType);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ApiClient.messageFromBody(response.body) ??
                    "Unable to $requestType class",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("AUTO SCHEDULE ERROR : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error : $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // MANUAL SCHEDULE
 
  Future<void> manualSchedule({
    required TutorClassModel item,
    required String requestType,
    required String day,
    required String time,
    required DateTime date,
  }) async {
    try {
      final response = await ApiClient.post(
        "/api/Tutor/manual-schedule",
        {
          "requestId": item.requestId,
          "day": day,
          "time": time,
          "classDate": date.toIso8601String(),
          "requestType": requestType,
        },
      );

      debugPrint("MANUAL SCHEDULE : ${response.body}");

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Schedule request sent to student successfully"),
            ),
          );
        }
        fetchClasses();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ApiClient.messageFromBody(response.body) ??
                    "Unable to submit schedule request",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("MANUAL SCHEDULE ERROR : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error : $e")),
        );
      }
    }
  }

  void openManualScheduleDialog(TutorClassModel item, String requestType) {
    final days = [
      "Monday", "Tuesday", "Wednesday",
      "Thursday", "Friday", "Saturday", "Sunday",
    ];

    String selectedDay = days.first;
    TimeOfDay selectedTime = TimeOfDay.now();
    DateTime selectedDate = DateTime.now();

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
              title: const Text("No common slot found"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Please pick a day, date and time to send a manual request to the student.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    const Text("Day", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: days
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDay = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    const Text("Date", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        child: Text(
                          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text("Time", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                  onPressed: () {
                    manualSchedule(
                      item: item,
                      requestType: requestType,
                      day: selectedDay,
                      time: selectedTime.format(context),
                      date: selectedDate,
                    );
                  },
                  child: const Text("Send Request"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void confirmCancel(TutorClassModel item) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text("Cancel Class"),
          content: const Text("Are you sure you want to cancel this class?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                cancelClass(item);
              },
              child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void confirmComplete(TutorClassModel item) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text("Complete Class"),
          content: const Text("Mark this class as completed?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                completeClass(item);
              },
              child: const Text("Complete"),
            ),
          ],
        );
      },
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: const TutorDrawer(),
      backgroundColor: const Color(0xffF3F5FB),
      body: SafeArea(
        child: Column(
          children: [
            //================ HEADER =================
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Row(
                children: [
                  // ✅ FIXED BACK BUTTON
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back, size: 30),
                  ),
                  const Spacer(),
                  const Text(
                    "All Classes",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff16897F),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: openDrawer,
                    icon: const Icon(Icons.menu, size: 30),
                  ),
                ],
              ),
            ),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : classes.isEmpty
                      ? const Center(
                          child: Text(
                            "No Classes Found",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: fetchClasses,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: classes.length,
                            itemBuilder: (context, index) {
                              return classCard(classes[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "accepted":
        return Colors.green;
      case "complete":
        return Colors.blue;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget classCard(TutorClassModel item) {
    final bool isLocked =
        item.status.toLowerCase() == "complete" ||
        item.status.toLowerCase() == "cancelled";

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  item.studentName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor(item.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: statusColor(item.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            item.courseName,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              infoChip(
                Icons.calendar_today,
                item.classDate == null || item.classDate == "null"
                    ? "N/A"
                    : item.classDate!,
              ),
              infoChip(Icons.access_time, item.time),
              infoChip(Icons.event_note, item.day),
              infoChip(Icons.label, item.requestType),
            ],
          ),

          const SizedBox(height: 16),

          if (!isLocked)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                actionButton(
                  label: "Complete",
                  icon: Icons.check_circle,
                  color: const Color(0xff2DB55D),
                  onTap: () => confirmComplete(item),
                ),
                actionButton(
                  label: "Re-Schedule",
                  icon: Icons.autorenew,
                  color: const Color(0xff2F80ED),
                  onTap: () => rescheduleClass(item),
                ),
                actionButton(
                  label: "Pre-Schedule",
                  icon: Icons.schedule,
                  color: const Color(0xff9B51E0),
                  onTap: () => prescheduleClass(item),
                ),
                actionButton(
                  label: "Cancel",
                  icon: Icons.cancel,
                  color: Colors.red,
                  onTap: () => confirmCancel(item),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
