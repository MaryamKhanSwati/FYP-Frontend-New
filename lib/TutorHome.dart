import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/TutorDrawer.dart';
import 'package:house_of_tutor/TutorStudentRequest.dart';
import 'package:house_of_tutor/TutorTodayClasses.dart';
import 'package:house_of_tutor/TutorAddSubject.dart';
import 'package:house_of_tutor/TutorNotification.dart';
import 'package:house_of_tutor/services/api_client.dart';

class TutorHome extends StatefulWidget {
  const TutorHome({super.key});

  @override
  State<TutorHome> createState() => _TutorHomeState();
}

class _TutorHomeState extends State<TutorHome> {
  
  final List<String> days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun",];

  final List<String> times = ["8:00-9:00 am","9:00-10:00 am","10:00-11:00 am",
    "11:00-12:00 pm","12:00-1:00 pm", "1:00-2:00 pm","2:00-3:00 pm","3:00-4:00 pm",
    "4:00-5:00 pm","5:00-6:00 pm","6:00-7:00 pm","7:00-8:00 pm","8:00-9:00 pm","9:00-10:00 pm",];
  
  Set<String> selectedKeys = {};//mean schdeule storing
  Map<String, dynamic> scheduleData = {};

  bool isLoading = false;
  bool isSaving = false;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadSchedule();
  }
  // LOAD SCHEDULE
  Future<void> loadSchedule() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get("/api/Tutor/get-schedule",);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final Set<String> loadedSelectedKeys = {};
        final Map<String, dynamic> loadedScheduleData = {};

        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) continue;

            final String day =
                item["day"]?.toString().trim() ?? "";

            final String time =
                item["time"]?.toString().trim() ?? "";

            if (day.isEmpty || time.isEmpty) {
              continue;
            }

            final String key = "${day}_$time";

            final Map<String, dynamic> scheduleItem =
                Map<String, dynamic>.from(item);

            loadedScheduleData[key] = scheduleItem;

            final String status =
                scheduleItem["slot_status"]
                        ?.toString()
                        .toLowerCase() ??
                    "";

            // Booked / Rescheduled slots are NOT selected.
            // Only available slots are selected.
            if (status != "red" && status != "yellow") {
              loadedSelectedKeys.add(key);
            }
          }
        }

        if (!mounted) return;

        setState(() {
          selectedKeys = loadedSelectedKeys;
          scheduleData = loadedScheduleData;
        });
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Unable to load schedule (${response.statusCode})",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error loading schedule: $e",
          ),
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

  void onSlotTap(String day, String time) {
    final String key = "${day}_$time";

    final String status =
        scheduleData[key]?["slot_status"]
                ?.toString()
                .toLowerCase() ??
            "";

    // BOOKED
    if (status == "red") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "This slot is already booked",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // RESCHEDULED
    if (status == "yellow") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "This slot is currently rescheduled",
          ),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    // SELECT / UNSELECT
    setState(() {
      if (selectedKeys.contains(key)) {
        selectedKeys.remove(key);
      } else {
        selectedKeys.add(key);
      }
    });
  }
//slot color
  Color getSlotColor(String day, String time) {
    final String key = "${day}_$time";

    final String status =
        scheduleData[key]?["slot_status"]
                ?.toString()
                .toLowerCase() ??
            "";

    // Booked
    if (status == "red") {
      return Colors.red;
    }

    // Rescheduled
    if (status == "yellow") {
      return Colors.amber;
    }

    // Available / selected
    if (selectedKeys.contains(key)) {
      return Colors.green;
    }

    // Empty
    return Colors.grey.shade300;
  }
//sloticon
  Widget? getSlotIcon(String day, String time) {
    final String key = "${day}_$time";

    final String status =
        scheduleData[key]?["slot_status"]
                ?.toString()
                .toLowerCase() ??
            "";

    if (status == "red") {
      return const Icon(
        Icons.lock,
        color: Colors.white,
        size: 15,
      );
    }

    if (status == "yellow") {
      return const Icon(
        Icons.schedule,
        color: Colors.white,
        size: 15,
      );
    }

    if (selectedKeys.contains(key)) {
      return const Icon(
        Icons.check,
        color: Colors.white,
        size: 16,
      );
    }

    return null;
  }

  Future<void> saveSchedule() async {
    if (isSaving) return;

    final List<Map<String, String>> slots = [];

    for (final String key in selectedKeys) {
      final int separatorIndex = key.indexOf("_");

      if (separatorIndex == -1) {
        continue;
      }

      final String day =
          key.substring(0, separatorIndex);

      final String time =
          key.substring(separatorIndex + 1);

      if (day.isEmpty || time.isEmpty) {
        continue;
      }

      // Do not send booked / rescheduled slots
      final String status =
          scheduleData[key]?["slot_status"]
                  ?.toString()
                  .toLowerCase() ??
              "";

      if (status == "red" || status == "yellow") {
        continue;
      }

      slots.add({
        "day": day,
        "time": time,
      });
    }

    // VALIDATION
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select at least one available slot",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Map<String, dynamic> body = {
      "slots": slots,
    };

    setState(() {
      isSaving = true;
    });

    try {
      final response = await ApiClient.post(
        "/api/Tutor/save-schedule",
        body,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Schedule Saved Successfully",
            ),
            backgroundColor: Colors.green,
          ),
        );

        await loadSchedule();
      } else {
        if (!mounted) return;

        String message = "Failed to save schedule";

        try {
          if (response.body.isNotEmpty) {
            final decoded = jsonDecode(response.body);

            if (decoded is Map) {
              if (decoded["message"] != null) {
                message =
                    decoded["message"].toString();
              } else if (decoded["error"] != null) {
                message =
                    decoded["error"].toString();
              } else if (decoded["title"] != null) {
                message =
                    decoded["title"].toString();
              }
            } else if (decoded is String) {
              message = decoded;
            }
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            message = response.body;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "$message\nStatus: ${response.statusCode}",
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error saving schedule: $e",
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void clearAll() {
    if (isSaving) return;

    setState(() {
      selectedKeys.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Selected slots cleared",
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }
  void openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TutorNotification(),
      ),
    );
  }

  // BOTTOM NAVIGATION
  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Schedule (Current Screen)
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TutorStudentRequest(),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TutorTodayClasses(),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TutorAddSubject(),
          ),
        );
        break;
    }
  }

  Widget buildLogo() {
    return Image.asset(
      "assets/images/logo.png",
      height: 34,
      width: 34,
      fit: BoxFit.contain,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.school,
            color: Color(0xFF00695C),
            size: 23,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        // MENU
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.black87,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),

        // LOGO + TITLE
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildLogo(),

            const SizedBox(width: 8),

            const Text(
              "House of Tutor",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        // NOTIFICATION
        actions: [
          IconButton(
            tooltip: "Notifications",
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.black87,
              size: 27,
            ),
            onPressed: openNotifications,
          ),
        ],
      ),

      drawer: const TutorDrawer(),
//body
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),

            // TITLE
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Availability",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap slots to update your weekly teaching schedule.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  _legendItem(
                    color: Colors.green,
                    label: "Available",
                  ),
                  const SizedBox(width: 13),
                  _legendItem(
                    color: Colors.red,
                    label: "Booked",
                  ),
                  const SizedBox(width: 13),
                  _legendItem(
                    color: Colors.amber,
                    label: "Rescheduled",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(16),
                    child: isLoading
                        ? const Center(
                            child:
                                CircularProgressIndicator(
                              color: Color(0xFF009688),
                            ),
                          )
                        : LayoutBuilder(
                            builder:
                                (context, constraints) {
                              final double totalWidth =
                                  constraints.maxWidth;

                              final double timeWidth =
                                  totalWidth * 0.19;

                              final double dayWidth =
                                  (totalWidth -
                                          timeWidth) /
                                      7;

                              return SingleChildScrollView(
                                scrollDirection:
                                    Axis.vertical,
                                child: Table(
                                  border:
                                      TableBorder.all(
                                    color: Colors
                                        .grey
                                        .shade200,
                                    width: 0.8,
                                  ),
                                  columnWidths: {
                                    0: FixedColumnWidth(
                                      timeWidth,
                                    ),
                                    1: FixedColumnWidth(
                                      dayWidth,
                                    ),
                                    2: FixedColumnWidth(
                                      dayWidth,
                                    ),
                                    3: FixedColumnWidth(
                                      dayWidth,
                                    ),
                                    4: FixedColumnWidth(
                                      dayWidth,
                                    ),
                                    5: FixedColumnWidth(
                                      dayWidth,
                                    ),
                                    6: FixedColumnWidth(
                                      dayWidth,
                                    ),
                                    7: FixedColumnWidth(
                                      dayWidth,
                                    ),
                                  },

                                  children: [
                                    // HEADER
                                    TableRow(
                                      decoration:
                                          const BoxDecoration(
                                        color:
                                            Color(0xFFFAFAFA),
                                      ),
                                      children: [
                                        const SizedBox(
                                          height: 45,
                                        ),
                                        ...days.map(
                                          (day) {
                                            return Container(
                                              height: 45,
                                              alignment:
                                                  Alignment
                                                      .center,
                                              child: Text(
                                                day,
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight
                                                          .bold,
                                                  fontSize: 11,
                                                  color:
                                                      Colors
                                                          .black87,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),

                                    // TIME ROWS
                                    ...times.map(
                                      (time) {
                                        return TableRow(
                                          children: [
                                            // TIME
                                            Container(
                                              height: 46,
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 3,
                                              ),
                                              alignment:
                                                  Alignment
                                                      .center,
                                              child: Text(
                                                time,
                                                textAlign:
                                                    TextAlign
                                                        .center,
                                                style:
                                                    const TextStyle(
                                                  fontSize: 8.5,
                                                  color:
                                                      Colors
                                                          .black54,
                                                ),
                                              ),
                                            ),

                                            // DAYS
                                            ...days.map(
                                              (day) {
                                                return _buildSlot(
                                                  day,
                                                  time,
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ).toList(),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                14,
              ),
              child: Row(
                children: [
                  // SAVE
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          isSaving ? null : saveSchedule,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF009688),
                        disabledBackgroundColor:
                            Colors.grey.shade400,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Icon(
                                  Icons
                                      .check_circle_outline,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Save Schedule",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // CLEAR ALL
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed:
                          isSaving ? null : clearAll,
                      style:
                          OutlinedButton.styleFrom(
                        side: BorderSide(
                          color:
                              Colors.grey.shade300,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      child: const Text(
                        "Clear All",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor:
            const Color(0xFF009688),
        unselectedItemColor:
            Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_today,
            ),
            label: "Schedule",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.people_outline,
            ),
            label: "Request",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.school_outlined,
            ),
            label: "Today",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle_outline,
            ),
            label: "Subject",
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(String day, String time) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSlotTap(day, time),
      child: Container(
        height: 46,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: getSlotColor(day, time),
          borderRadius:
              BorderRadius.circular(5),
        ),
        child: Center(
          child: getSlotIcon(day, time),
        ),
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}