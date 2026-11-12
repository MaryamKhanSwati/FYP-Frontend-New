import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:house_of_tutor/StudentDrawer.dart'; 
import 'services/api_client.dart';

class StudentTodayClasses extends StatefulWidget {
  const StudentTodayClasses({super.key});

  @override
  State<StudentTodayClasses> createState() => _StudentTodayClassesState();
}

class _StudentTodayClassesState extends State<StudentTodayClasses> {
  bool loading = false;
  List<TodayClass> classes = [];

  @override
  void initState() {
    super.initState();
    fetchTodayClasses();
  }

  Future<void> fetchTodayClasses() async {
    try {
      if (mounted) {
        setState(() {
          loading = true;
        });
      }

      final response = await ApiClient.get(
        "/api/Student/today-classes",
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        List list = json["data"] ?? [];

        classes = list.map((e) => TodayClass.fromJson(e)).toList();

        if (mounted) {
          setState(() {});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ApiClient.messageFromBody(response.body) ?? "Unable to load classes",
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error : $e"),
          ),
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

  //--------------------------------------------------------
  // RESCHEDULE DIALOG
  //--------------------------------------------------------
  Future<void> openRescheduleDialog(TodayClass item) async {
    DateTime? selectedDate;
    final dayController = TextEditingController();
    final timeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Re-Schedule Class"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2035),
                              );

                              if (picked != null) {
                                selectedDate = picked;
                                dayController.text = _dayName(picked.weekday);
                                setDialogState(() {});
                              }
                            },
                            label: const Text("Select Date"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.access_time),
                            onPressed: () async {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );

                              if (pickedTime != null) {
                                if (mounted) {
                                  timeController.text = pickedTime.format(context);
                                }
                                setDialogState(() {});
                              }
                            },
                            label: const Text("Select Time"),
                          ),
                        ),
                      ],
                    ),
                    if (selectedDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: Text(
                          "Selected Date: ${selectedDate!.toString().split(" ")[0]}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dayController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Day",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: timeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Time",
                        hintText: "Click 'Select Time' above",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDate == null || timeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Fill all fields")),
                      );
                      return;
                    }

                    await createReschedule(
                      parentRequestId: item.requestId,
                      newDate: selectedDate!,
                      day: dayController.text,
                      time: timeController.text,
                    );

                    if (mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text("Send"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //--------------------------------------------------------
  // PRE SCHEDULE DIALOG
  //--------------------------------------------------------
  Future<void> openPreScheduleDialog(TodayClass item) async {
    DateTime? selectedDate;
    final dayController = TextEditingController();
    final timeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Pre-Schedule Class"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2035),
                              );

                              if (picked != null) {
                                selectedDate = picked;
                                dayController.text = _dayName(picked.weekday);
                                setDialogState(() {});
                              }
                            },
                            label: const Text("Select Date"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.access_time),
                            onPressed: () async {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );

                              if (pickedTime != null) {
                                if (mounted) {
                                  timeController.text = pickedTime.format(context);
                                }
                                setDialogState(() {});
                              }
                            },
                            label: const Text("Select Time"),
                          ),
                        ),
                      ],
                    ),
                    if (selectedDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: Text(
                          "Selected Date: ${selectedDate!.toString().split(" ")[0]}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dayController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Day",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: timeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Time",
                        hintText: "Click 'Select Time' above",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDate == null || timeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Fill all fields")),
                      );
                      return;
                    }

                    await createPreSchedule(
                      parentRequestId: item.requestId,
                      newDate: selectedDate!,
                      day: dayController.text,
                      time: timeController.text,
                    );

                    if (mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text("Send"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> createReschedule({
    required int parentRequestId,
    required DateTime newDate,
    required String day,
    required String time,
  }) async {
    try {
      final response = await ApiClient.post(
        "/api/Student/create-reschedule",
        {
          "parentRequestId": parentRequestId,
          "newClassDate": newDate.toIso8601String(),
          "day": day,
          "time": time,
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Reschedule request sent successfully")),
          );
          fetchTodayClasses();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ApiClient.messageFromBody(response.body) ?? "Failed"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$e")),
        );
      }
    }
  }

  Future<void> createPreSchedule({
    required int parentRequestId,
    required DateTime newDate,
    required String day,
    required String time,
  }) async {
    try {
      final response = await ApiClient.post(
        "/api/Student/create-preschedule",
        {
          "parentRequestId": parentRequestId,
          "newClassDate": newDate.toIso8601String(),
          "day": day,
          "time": time,
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pre-schedule request sent successfully")),
          );
          fetchTodayClasses();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ApiClient.messageFromBody(response.body) ?? "Failed"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$e")),
        );
      }
    }
  }

  String _dayName(int weekday) {
    switch (weekday) {
      case 1: return "Monday";
      case 2: return "Tuesday";
      case 3: return "Wednesday";
      case 4: return "Thursday";
      case 5: return "Friday";
      case 6: return "Saturday";
      default: return "Sunday";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Classes"),
        centerTitle: true,
        backgroundColor: Colors.teal,
        // --- FIXED: ADDED WORKABLE BACK ARROW BUTTON ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // This safely takes the user back
          },
        ),
      ),
      //drawer: const StudentDrawer(), 
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : classes.isEmpty
              ? const Center(child: Text("No classes today"))
              : RefreshIndicator(
                  onRefresh: fetchTodayClasses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final item = classes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.courseName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 18, color: Colors.teal),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(item.tutorName)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month, size: 18, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(item.classDate),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.today, size: 18, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(item.day),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(item.time),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.info, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(item.status),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => openRescheduleDialog(item),
                                      child: const Text("Re-Schedule"),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => openPreScheduleDialog(item),
                                      child: const Text("Pre-Schedule"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class TodayClass {
  final int requestId;
  final int tutorId;
  final String tutorName;
  final int courseId;
  final String courseName;
  final String classDate;
  final String day;
  final String time;
  final String requestType;
  final String status;
  final String requestDate;

  TodayClass({
    required this.requestId,
    required this.tutorId,
    required this.tutorName,
    required this.courseId,
    required this.courseName,
    required this.classDate,
    required this.day,
    required this.time,
    required this.requestType,
    required this.status,
    required this.requestDate,
  });

  factory TodayClass.fromJson(Map<String, dynamic> json) {
    return TodayClass(
      requestId: json["request_id"] ?? 0,
      tutorId: json["tutor_id"] ?? 0,
      tutorName: json["tutor_name"] ?? "",
      courseId: json["course_id"] ?? 0,
      courseName: json["course_name"] ?? "",
      classDate: json["class_date"]?.toString() ?? "",
      day: json["day"] ?? "",
      time: json["time"] ?? "",
      requestType: json["request_type"] ?? "",
      status: json["status"] ?? "",
      requestDate: json["request_date"]?.toString() ?? "",
    );
  }
}









































































// import 'dart:convert';
// import 'package:flutter/material.dart';
// // --- ADDED IMPORT FOR DRAWER ---
// import 'package:house_of_tutor/StudentDrawer.dart'; 
// import 'services/api_client.dart';

// class StudentTodayClasses extends StatefulWidget {
//   const StudentTodayClasses({super.key});

//   @override
//   State<StudentTodayClasses> createState() => _StudentTodayClassesState();
// }

// class _StudentTodayClassesState extends State<StudentTodayClasses> {
//   bool loading = false;
//   List<TodayClass> classes = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchTodayClasses();
//   }

//   //--------------------------------------------------------
//   // GET TODAY CLASSES
//   //--------------------------------------------------------
//   Future<void> fetchTodayClasses() async {
//     try {
//       if (mounted) {
//         setState(() {
//           loading = true;
//         });
//       }

//       final response = await ApiClient.get(
//         "/api/Student/today-classes",
//       );

//       if (response.statusCode == 200) {
//         final json = jsonDecode(utf8.decode(response.bodyBytes));
//         List list = json["data"] ?? [];

//         classes = list.map((e) => TodayClass.fromJson(e)).toList();

//         if (mounted) {
//           setState(() {});
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 ApiClient.messageFromBody(response.body) ?? "Unable to load classes",
//               ),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error : $e"),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           loading = false;
//         });
//       }
//     }
//   }

//   //--------------------------------------------------------
//   // RESCHEDULE DIALOG
//   //--------------------------------------------------------
//   Future<void> openRescheduleDialog(TodayClass item) async {
//     DateTime? selectedDate;
//     final dayController = TextEditingController();
//     final timeController = TextEditingController();

//     await showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               title: const Text("Re-Schedule Class"),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             icon: const Icon(Icons.calendar_month),
//                             onPressed: () async {
//                               DateTime? picked = await showDatePicker(
//                                 context: context,
//                                 initialDate: DateTime.now(),
//                                 firstDate: DateTime.now(),
//                                 lastDate: DateTime(2035),
//                               );

//                               if (picked != null) {
//                                 selectedDate = picked;
//                                 dayController.text = _dayName(picked.weekday);
//                                 setDialogState(() {});
//                               }
//                             },
//                             label: const Text("Select Date"),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             icon: const Icon(Icons.access_time),
//                             onPressed: () async {
//                               TimeOfDay? pickedTime = await showTimePicker(
//                                 context: context,
//                                 initialTime: TimeOfDay.now(),
//                               );

//                               if (pickedTime != null) {
//                                 if (mounted) {
//                                   timeController.text = pickedTime.format(context);
//                                 }
//                                 setDialogState(() {});
//                               }
//                             },
//                             label: const Text("Select Time"),
//                           ),
//                         ),
//                       ],
//                     ),
//                     if (selectedDate != null)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 12, bottom: 12),
//                         child: Text(
//                           "Selected Date: ${selectedDate!.toString().split(" ")[0]}",
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     const SizedBox(height: 10),
//                     TextField(
//                       controller: dayController,
//                       readOnly: true,
//                       decoration: const InputDecoration(
//                         labelText: "Day",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: timeController,
//                       readOnly: true, // Made read-only to accept picker input nicely
//                       decoration: const InputDecoration(
//                         labelText: "Time",
//                         hintText: "Click 'Select Time' above",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(dialogContext),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     if (selectedDate == null || timeController.text.isEmpty) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text("Fill all fields")),
//                       );
//                       return;
//                     }

//                     await createReschedule(
//                       parentRequestId: item.requestId,
//                       newDate: selectedDate!,
//                       day: dayController.text,
//                       time: timeController.text,
//                     );

//                     if (mounted) {
//                       Navigator.pop(dialogContext);
//                     }
//                   },
//                   child: const Text("Send"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   //--------------------------------------------------------
//   // PRE SCHEDULE DIALOG
//   //--------------------------------------------------------
//   Future<void> openPreScheduleDialog(TodayClass item) async {
//     DateTime? selectedDate;
//     final dayController = TextEditingController();
//     final timeController = TextEditingController();

//     await showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               title: const Text("Pre-Schedule Class"),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             icon: const Icon(Icons.calendar_month),
//                             onPressed: () async {
//                               DateTime? picked = await showDatePicker(
//                                 context: context,
//                                 initialDate: DateTime.now(),
//                                 firstDate: DateTime.now(),
//                                 lastDate: DateTime(2035),
//                               );

//                               if (picked != null) {
//                                 selectedDate = picked;
//                                 dayController.text = _dayName(picked.weekday);
//                                 setDialogState(() {});
//                               }
//                             },
//                             label: const Text("Select Date"),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             icon: const Icon(Icons.access_time),
//                             onPressed: () async {
//                               TimeOfDay? pickedTime = await showTimePicker(
//                                 context: context,
//                                 initialTime: TimeOfDay.now(),
//                               );

//                               if (pickedTime != null) {
//                                 if (mounted) {
//                                   timeController.text = pickedTime.format(context);
//                                 }
//                                 setDialogState(() {});
//                               }
//                             },
//                             label: const Text("Select Time"),
//                           ),
//                         ),
//                       ],
//                     ),
//                     if (selectedDate != null)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 12, bottom: 12),
//                         child: Text(
//                           "Selected Date: ${selectedDate!.toString().split(" ")[0]}",
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     const SizedBox(height: 10),
//                     TextField(
//                       controller: dayController,
//                       readOnly: true,
//                       decoration: const InputDecoration(
//                         labelText: "Day",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: timeController,
//                       readOnly: true,
//                       decoration: const InputDecoration(
//                         labelText: "Time",
//                         hintText: "Click 'Select Time' above",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(dialogContext),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     if (selectedDate == null || timeController.text.isEmpty) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text("Fill all fields")),
//                       );
//                       return;
//                     }

//                     await createPreSchedule(
//                       parentRequestId: item.requestId,
//                       newDate: selectedDate!,
//                       day: dayController.text,
//                       time: timeController.text,
//                     );

//                     if (mounted) {
//                       Navigator.pop(dialogContext);
//                     }
//                   },
//                   child: const Text("Send"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   //--------------------------------------------------------
//   // POST API CALLS
//   //--------------------------------------------------------
//   Future<void> createReschedule({
//     required int parentRequestId,
//     required DateTime newDate,
//     required String day,
//     required String time,
//   }) async {
//     try {
//       final response = await ApiClient.post(
//         "/api/Student/create-reschedule",
//         {
//           "parentRequestId": parentRequestId,
//           "newClassDate": newDate.toIso8601String(),
//           "day": day,
//           "time": time,
//         },
//       );

//       if (response.statusCode == 200) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Reschedule request sent successfully")),
//           );
//           fetchTodayClasses();
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(ApiClient.messageFromBody(response.body) ?? "Failed"),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("$e")),
//         );
//       }
//     }
//   }

//   Future<void> createPreSchedule({
//     required int parentRequestId,
//     required DateTime newDate,
//     required String day,
//     required String time,
//   }) async {
//     try {
//       final response = await ApiClient.post(
//         "/api/Student/create-preschedule",
//         {
//           "parentRequestId": parentRequestId,
//           "newClassDate": newDate.toIso8601String(),
//           "day": day,
//           "time": time,
//         },
//       );

//       if (response.statusCode == 200) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Pre-schedule request sent successfully")),
//           );
//           fetchTodayClasses();
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(ApiClient.messageFromBody(response.body) ?? "Failed"),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("$e")),
//         );
//       }
//     }
//   }

//   String _dayName(int weekday) {
//     switch (weekday) {
//       case 1: return "Monday";
//       case 2: return "Tuesday";
//       case 3: return "Wednesday";
//       case 4: return "Thursday";
//       case 5: return "Friday";
//       case 6: return "Saturday";
//       default: return "Sunday";
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Today's Classes"),
//         centerTitle: true,
//         backgroundColor: Colors.teal,
//       ),
//       // --- ADDED THE DRAWER PROPERTY HERE ---
//       drawer: const StudentDrawer(), 
//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : classes.isEmpty
//               ? const Center(child: Text("No classes today"))
//               : RefreshIndicator(
//                   onRefresh: fetchTodayClasses,
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(15),
//                     itemCount: classes.length,
//                     itemBuilder: (context, index) {
//                       final item = classes[index];
//                       return Card(
//                         margin: const EdgeInsets.only(bottom: 15),
//                         elevation: 4,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(15),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(15),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 item.courseName,
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   const Icon(Icons.person, size: 18, color: Colors.teal),
//                                   const SizedBox(width: 8),
//                                   Expanded(child: Text(item.tutorName)),
//                                 ],
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   const Icon(Icons.calendar_month, size: 18, color: Colors.blue),
//                                   const SizedBox(width: 8),
//                                   Text(item.classDate),
//                                 ],
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   const Icon(Icons.today, size: 18, color: Colors.orange),
//                                   const SizedBox(width: 8),
//                                   Text(item.day),
//                                 ],
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   const Icon(Icons.access_time, size: 18, color: Colors.red),
//                                   const SizedBox(width: 8),
//                                   Text(item.time),
//                                 ],
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   const Icon(Icons.info, size: 18, color: Colors.grey),
//                                   const SizedBox(width: 8),
//                                   Text(item.status),
//                                 ],
//                               ),
//                               const SizedBox(height: 20),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: ElevatedButton(
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.orange,
//                                         foregroundColor: Colors.white,
//                                       ),
//                                       onPressed: () => openRescheduleDialog(item),
//                                       child: const Text("Re-Schedule"),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: ElevatedButton(
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.green,
//                                         foregroundColor: Colors.white,
//                                       ),
//                                       onPressed: () => openPreScheduleDialog(item),
//                                       child: const Text("Pre-Schedule"),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//     );
//   }
// }

// ////////////////////////////////////////////////////////////
// /// MODEL
// ////////////////////////////////////////////////////////////
// class TodayClass {
//   final int requestId;
//   final int tutorId;
//   final String tutorName;
//   final int courseId;
//   final String courseName;
//   final String classDate;
//   final String day;
//   final String time;
//   final String requestType;
//   final String status;
//   final String requestDate;

//   TodayClass({
//     required this.requestId,
//     required this.tutorId,
//     required this.tutorName,
//     required this.courseId,
//     required this.courseName,
//     required this.classDate,
//     required this.day,
//     required this.time,
//     required this.requestType,
//     required this.status,
//     required this.requestDate,
//   });

//   factory TodayClass.fromJson(Map<String, dynamic> json) {
//     return TodayClass(
//       requestId: json["request_id"] ?? 0,
//       tutorId: json["tutor_id"] ?? 0,
//       tutorName: json["tutor_name"] ?? "",
//       courseId: json["course_id"] ?? 0,
//       courseName: json["course_name"] ?? "",
//       classDate: json["class_date"]?.toString() ?? "",
//       day: json["day"] ?? "",
//       time: json["time"] ?? "",
//       requestType: json["request_type"] ?? "",
//       status: json["status"] ?? "",
//       requestDate: json["request_date"]?.toString() ?? "",
//     );
//   }
// }




















































// /// import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'services/api_client.dart';

// // class StudentTodayClasses extends StatefulWidget {
// //   const StudentTodayClasses({super.key});

// //   @override
// //   State<StudentTodayClasses> createState() => _StudentTodayClassesState();
// // }

// // class _StudentTodayClassesState extends State<StudentTodayClasses> {
// //   bool loading = false;
// //   List<TodayClass> classes = [];

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchTodayClasses();
// //   }

// //   //--------------------------------------------------------
// //   // GET TODAY CLASSES
// //   //--------------------------------------------------------
// //   Future<void> fetchTodayClasses() async {
// //     try {
// //       if (mounted) {
// //         setState(() {
// //           loading = true;
// //         });
// //       }

// //       final response = await ApiClient.get(
// //         "/api/Student/today-classes",
// //       );

// //       if (response.statusCode == 200) {
// //         final json = jsonDecode(utf8.decode(response.bodyBytes));
// //         List list = json["data"] ?? [];

// //         classes = list.map((e) => TodayClass.fromJson(e)).toList();

// //         if (mounted) {
// //           setState(() {});
// //         }
// //       } else {
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text(
// //                 ApiClient.messageFromBody(response.body) ?? "Unable to load classes",
// //               ),
// //             ),
// //           );
// //         }
// //       }
// //     } catch (e) {
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

// //   //--------------------------------------------------------
// //   // RESCHEDULE DIALOG
// //   //--------------------------------------------------------
// //   Future<void> openRescheduleDialog(TodayClass item) async {
// //     DateTime? selectedDate;
// //     final dayController = TextEditingController();
// //     final timeController = TextEditingController();

// //     await showDialog(
// //       context: context,
// //       builder: (dialogContext) {
// //         return StatefulBuilder(
// //           builder: (context, setDialogState) {
// //             return AlertDialog(
// //               title: const Text("Re-Schedule Class"),
// //               content: SingleChildScrollView(
// //                 child: Column(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     ElevatedButton(
// //                       onPressed: () async {
// //                         DateTime? picked = await showDatePicker(
// //                           context: context,
// //                           initialDate: DateTime.now(),
// //                           firstDate: DateTime.now(),
// //                           lastDate: DateTime(2035),
// //                         );

// //                         if (picked != null) {
// //                           selectedDate = picked;
// //                           dayController.text = _dayName(picked.weekday);
// //                           setDialogState(() {});
// //                         }
// //                       },
// //                       child: const Text("Select Date"),
// //                     ),
// //                     if (selectedDate != null)
// //                       Padding(
// //                         padding: const EdgeInsets.only(top: 8),
// //                         child: Text(selectedDate!.toString().split(" ")[0]),
// //                       ),
// //                     const SizedBox(height: 15),
// //                     TextField(
// //                       controller: dayController,
// //                       readOnly: true,
// //                       decoration: const InputDecoration(
// //                         labelText: "Day",
// //                         border: OutlineInputBorder(),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 15),
// //                     TextField(
// //                       controller: timeController,
// //                       decoration: const InputDecoration(
// //                         labelText: "Time",
// //                         hintText: "04:00 PM",
// //                         border: OutlineInputBorder(),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               actions: [
// //                 TextButton(
// //                   onPressed: () => Navigator.pop(dialogContext),
// //                   child: const Text("Cancel"),
// //                 ),
// //                 ElevatedButton(
// //                   onPressed: () async {
// //                     if (selectedDate == null || timeController.text.isEmpty) {
// //                       ScaffoldMessenger.of(context).showSnackBar(
// //                         const SnackBar(content: Text("Fill all fields")),
// //                       );
// //                       return;
// //                     }

// //                     await createReschedule(
// //                       parentRequestId: item.requestId,
// //                       newDate: selectedDate!,
// //                       day: dayController.text,
// //                       time: timeController.text,
// //                     );

// //                     if (mounted) {
// //                       Navigator.pop(dialogContext);
// //                     }
// //                   },
// //                   child: const Text("Send"),
// //                 ),
// //               ],
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }

// //   //--------------------------------------------------------
// //   // PRE SCHEDULE DIALOG
// //   //--------------------------------------------------------
// //   Future<void> openPreScheduleDialog(TodayClass item) async {
// //     DateTime? selectedDate;
// //     final dayController = TextEditingController();
// //     final timeController = TextEditingController();

// //     await showDialog(
// //       context: context,
// //       builder: (dialogContext) {
// //         return StatefulBuilder(
// //           builder: (context, setDialogState) {
// //             return AlertDialog(
// //               title: const Text("Pre-Schedule Class"),
// //               content: SingleChildScrollView(
// //                 child: Column(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     ElevatedButton(
// //                       onPressed: () async {
// //                         DateTime? picked = await showDatePicker(
// //                           context: context,
// //                           initialDate: DateTime.now(),
// //                           firstDate: DateTime.now(),
// //                           lastDate: DateTime(2035),
// //                         );

// //                         if (picked != null) {
// //                           selectedDate = picked;
// //                           dayController.text = _dayName(picked.weekday);
// //                           setDialogState(() {});
// //                         }
// //                       },
// //                       child: const Text("Select Date"),
// //                     ),
// //                     if (selectedDate != null)
// //                       Padding(
// //                         padding: const EdgeInsets.only(top: 8),
// //                         child: Text(selectedDate!.toString().split(" ")[0]),
// //                       ),
// //                     const SizedBox(height: 15),
// //                     TextField(
// //                       controller: dayController,
// //                       readOnly: true,
// //                       decoration: const InputDecoration(
// //                         labelText: "Day",
// //                         border: OutlineInputBorder(),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 15),
// //                     TextField(
// //                       controller: timeController,
// //                       decoration: const InputDecoration(
// //                         labelText: "Time",
// //                         hintText: "04:00 PM",
// //                         border: OutlineInputBorder(),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               actions: [
// //                 TextButton(
// //                   onPressed: () => Navigator.pop(dialogContext),
// //                   child: const Text("Cancel"),
// //                 ),
// //                 ElevatedButton(
// //                   onPressed: () async {
// //                     if (selectedDate == null || timeController.text.isEmpty) {
// //                       ScaffoldMessenger.of(context).showSnackBar(
// //                         const SnackBar(content: Text("Fill all fields")),
// //                       );
// //                       return;
// //                     }

// //                     await createPreSchedule(
// //                       parentRequestId: item.requestId,
// //                       newDate: selectedDate!,
// //                       day: dayController.text,
// //                       time: timeController.text,
// //                     );

// //                     if (mounted) {
// //                       Navigator.pop(dialogContext);
// //                     }
// //                   },
// //                   child: const Text("Send"),
// //                 ),
// //               ],
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }

// //   //--------------------------------------------------------
// //   // POST API CALLS
// //   //--------------------------------------------------------
// //   Future<void> createReschedule({
// //     required int parentRequestId,
// //     required DateTime newDate,
// //     required String day,
// //     required String time,
// //   }) async {
// //     try {
// //       final response = await ApiClient.post(
// //         "/api/Student/create-reschedule",
// //         {
// //           "parentRequestId": parentRequestId,
// //           "newClassDate": newDate.toIso8601String(),
// //           "day": day,
// //           "time": time,
// //         },
// //       );

// //       if (response.statusCode == 200) {
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             const SnackBar(content: Text("Reschedule request sent successfully")),
// //           );
// //           fetchTodayClasses();
// //         }
// //       } else {
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text(ApiClient.messageFromBody(response.body) ?? "Failed"),
// //             ),
// //           );
// //         }
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("$e")),
// //         );
// //       }
// //     }
// //   }

// //   Future<void> createPreSchedule({
// //     required int parentRequestId,
// //     required DateTime newDate,
// //     required String day,
// //     required String time,
// //   }) async {
// //     try {
// //       final response = await ApiClient.post(
// //         "/api/Student/create-preschedule",
// //         {
// //           "parentRequestId": parentRequestId,
// //           "newClassDate": newDate.toIso8601String(),
// //           "day": day,
// //           "time": time,
// //         },
// //       );

// //       if (response.statusCode == 200) {
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             const SnackBar(content: Text("Pre-schedule request sent successfully")),
// //           );
// //           fetchTodayClasses();
// //         }
// //       } else {
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text(ApiClient.messageFromBody(response.body) ?? "Failed"),
// //             ),
// //           );
// //         }
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("$e")),
// //         );
// //       }
// //     }
// //   }

// //   String _dayName(int weekday) {
// //     switch (weekday) {
// //       case 1: return "Monday";
// //       case 2: return "Tuesday";
// //       case 3: return "Wednesday";
// //       case 4: return "Thursday";
// //       case 5: return "Friday";
// //       case 6: return "Saturday";
// //       default: return "Sunday";
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Today's Classes"),
// //         backgroundColor: Colors.teal,
// //       ),
// //       body: loading
// //           ? const Center(child: CircularProgressIndicator())
// //           : classes.isEmpty
// //               ? const Center(child: Text("No classes today"))
// //               : RefreshIndicator(
// //                   onRefresh: fetchTodayClasses,
// //                   child: ListView.builder(
// //                     padding: const EdgeInsets.all(15),
// //                     itemCount: classes.length,
// //                     itemBuilder: (context, index) {
// //                       final item = classes[index];
// //                       return Card(
// //                         margin: const EdgeInsets.only(bottom: 15),
// //                         elevation: 4,
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(15),
// //                         ),
// //                         child: Padding(
// //                           padding: const EdgeInsets.all(15),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 item.courseName,
// //                                 style: const TextStyle(
// //                                   fontSize: 18,
// //                                   fontWeight: FontWeight.bold,
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 10),
// //                               Row(
// //                                 children: [
// //                                   const Icon(Icons.person, size: 18),
// //                                   const SizedBox(width: 8),
// //                                   Expanded(child: Text(item.tutorName)),
// //                                 ],
// //                               ),
// //                               const SizedBox(height: 8),
// //                               Row(
// //                                 children: [
// //                                   const Icon(Icons.calendar_month, size: 18),
// //                                   const SizedBox(width: 8),
// //                                   Text(item.classDate),
// //                                 ],
// //                               ),
// //                               const SizedBox(height: 8),
// //                               Row(
// //                                 children: [
// //                                   const Icon(Icons.today, size: 18),
// //                                   const SizedBox(width: 8),
// //                                   Text(item.day),
// //                                 ],
// //                               ),
// //                               const SizedBox(height: 8),
// //                               Row(
// //                                 children: [
// //                                   const Icon(Icons.access_time, size: 18),
// //                                   const SizedBox(width: 8),
// //                                   Text(item.time),
// //                                 ],
// //                               ),
// //                               const SizedBox(height: 8),
// //                               Row(
// //                                 children: [
// //                                   const Icon(Icons.info, size: 18),
// //                                   const SizedBox(width: 8),
// //                                   Text(item.status),
// //                                 ],
// //                               ),
// //                               const SizedBox(height: 20),
// //                               Row(
// //                                 children: [
// //                                   Expanded(
// //                                     child: ElevatedButton(
// //                                       style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
// //                                       onPressed: () => openRescheduleDialog(item),
// //                                       child: const Text("Re-Schedule"),
// //                                     ),
// //                                   ),
// //                                   const SizedBox(width: 10),
// //                                   Expanded(
// //                                     child: ElevatedButton(
// //                                       style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
// //                                       onPressed: () => openPreScheduleDialog(item),
// //                                       child: const Text("Pre-Schedule"),
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                 ),
// //     );
// //   }
// // }

// // ////////////////////////////////////////////////////////////
// // /// MODEL
// // ////////////////////////////////////////////////////////////
// // class TodayClass {
// //   final int requestId;
// //   final int tutorId;
// //   final String tutorName;
// //   final int courseId;
// //   final String courseName;
// //   final String classDate;
// //   final String day;
// //   final String time;
// //   final String requestType;
// //   final String status;
// //   final String requestDate;

// //   TodayClass({
// //     required this.requestId,
// //     required this.tutorId,
// //     required this.tutorName,
// //     required this.courseId,
// //     required this.courseName,
// //     required this.classDate,
// //     required this.day,
// //     required this.time,
// //     required this.requestType,
// //     required this.status,
// //     required this.requestDate,
// //   });

// //   factory TodayClass.fromJson(Map<String, dynamic> json) {
// //     return TodayClass(
// //       requestId: json["request_id"],
// //       tutorId: json["tutor_id"],
// //       tutorName: json["tutor_name"] ?? "",
// //       courseId: json["course_id"],
// //       courseName: json["course_name"] ?? "",
// //       classDate: json["class_date"].toString(),
// //       day: json["day"] ?? "",
// //       time: json["time"] ?? "",
// //       requestType: json["request_type"] ?? "",
// //       status: json["status"] ?? "",
// //       requestDate: json["request_date"].toString(),
// //     );
// //   }
// // }