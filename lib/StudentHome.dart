import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/StudentAddCourses.dart';
import 'package:house_of_tutor/StudentAddFriend.dart';
import 'package:house_of_tutor/StudentAllClasses.dart';
import 'package:house_of_tutor/StudentCourses.dart';
import 'package:house_of_tutor/StudentDrawer.dart';
import 'package:house_of_tutor/StudentNotfications.dart';
import 'package:house_of_tutor/services/api_client.dart';

class StudentHome extends StatefulWidget {
const StudentHome({super.key});

@override
State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
final GlobalKey<ScaffoldState> scaffoldKey =
GlobalKey<ScaffoldState>();

int selectedIndex = 0;

bool loading = true;
bool saving = false;

final List<String> days = [
"Mon",
"Tue",
"Wed",
"Thu",
"Fri",
"Sat",
"Sun",
];

final List<String> times = [
"8:00-9:00 am",
"9:00-10:00 am",
"10:00-11:00 am",
"11:00-12:00 pm",
"12:00-1:00 pm",
"1:00-2:00 pm",
"2:00-3:00 pm",
"3:00-4:00 pm",
"4:00-5:00 pm",
"5:00-6:00 pm",
"6:00-7:00 pm",
"7:00-8:00 pm",
"8:00-9:00 pm",
"9:00-10:00 pm",
];

final Map<String, bool> selectedSlots = {};

int get selectedCount {
return selectedSlots.values
.where((value) => value == true)
.length;
}

@override
void initState() {
super.initState();
fetchSchedule();
}

// ============================================================
// FETCH STUDENT SCHEDULE
// ============================================================

Future<void> fetchSchedule() async {
setState(() {
loading = true;
});


try {
  final response = await ApiClient.get(
    "/api/Student/get-student-schedules",
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    selectedSlots.clear();

    if (data is List && data.isNotEmpty) {
      for (var item in data) {
        String day = item["day"];
        String time = item["time"];

        String key = "${day}_$time";

        selectedSlots[key] = true;
      }
    }
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
      ),
    );
  }
}

if (mounted) {
  setState(() {
    loading = false;
  });
}


}

// ============================================================
// SAVE STUDENT SCHEDULE
// ============================================================

Future<void> saveSchedule() async {
if (selectedSlots.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text("Please select schedule slots"),
),
);


  return;
}

setState(() {
  saving = true;
});

try {
  List<Map<String, dynamic>> slots = [];

  selectedSlots.forEach((key, value) {
    if (value == true) {
      List<String> parts = key.split("_");

      slots.add({
        "day": parts[0],
        "time": parts[1],
      });
    }
  });

  final body = {
    "slots": slots,
  };

  final response = await ApiClient.post(
    "/api/Student/save-student-schedule",
    body,
  );

  if (response.statusCode == 200) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Schedule Saved Successfully",
          ),
        ),
      );
    }

    fetchSchedule();
  } else {
    final data = jsonDecode(response.body);

    String errorMessage =
        data["error"]?.toString() ??
        data["message"]?.toString() ??
        "Save Failed";

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
      ),
    );
  }
}

if (mounted) {
  setState(() {
    saving = false;
  });
}


}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

void onTapBottom(int index) {
setState(() {
selectedIndex = index;
});


// Add Courses
if (index == 1) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const StudentAddCourses(),
    ),
  );
}

// Courses
else if (index == 2) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const StudentCourses(),
    ),
  );
}

// Classes
else if (index == 3) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const StudentAllClasses(),
    ),
  );
}


}

// ============================================================
// SELECT / DESELECT SLOT
// ============================================================

void selectSlot(String day, String time) {
String key = "${day}_$time";


bool isSelected = selectedSlots[key] ?? false;

setState(() {
  if (isSelected) {
    selectedSlots.remove(key);
  } else {
    selectedSlots[key] = true;
  }
});


}

// ============================================================
// CLEAR ALL
// ============================================================

void clearAllSlots() {
setState(() {
selectedSlots.clear();
});
}

// // ============================================================
// // ADD FRIEND NAVIGATION
// // ============================================================

void openAddFriend() {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const StudentAddFriend(),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
key: scaffoldKey,


  backgroundColor: const Color(0xfff5f5f5),

  // ==========================================================
  // APP BAR
  // ==========================================================

  appBar: AppBar(
    backgroundColor: Colors.white,
    elevation: 1,

    // MENU BUTTON
    leading: IconButton(
      icon: const Icon(
        Icons.menu,
        color: Colors.black87,
      ),
      onPressed: () {
        scaffoldKey.currentState!.openDrawer();
      },
    ),

    centerTitle: true,

    // APP BAR TITLE
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          "assets/images/logo.png",
          height: 32,
        ),

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

    // ========================================================
    // APP BAR ACTIONS
    // ========================================================

    actions: [
      // ======================================================
      // ADD FRIEND ICON
      // ======================================================

      IconButton(
        icon: const Icon(
          Icons.person_add_alt_1,
          color: Colors.black87,
          size: 25,
        ),

        // When clicked -> StudentAddFriend
        onPressed: openAddFriend,
      ),

      // ======================================================
      // NOTIFICATION ICON
      // ======================================================

      IconButton(
        icon: const Icon(
          Icons.notifications_none,
          color: Colors.black87,
          size: 26,
        ),

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const StudentNotfications(),
            ),
          );
        },
      ),
    ],
  ),

  drawer: const StudentDrawer(),

  // ==========================================================
  // BODY
  // ==========================================================

  body: loading
      ? const Center(
          child: CircularProgressIndicator(),
        )
      : SafeArea(
          child: Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  8,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Manage Availability",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "Select the time slots you are available for learning",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            Colors.teal.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$selectedCount Selected",
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // SCHEDULE TABLE
              // ==================================================

              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.06),
                          blurRadius: 8,
                          offset:
                              const Offset(0, 2),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [
                        // TABLE HEADER
                        Row(
                          children: [
                            const Text(
                              "WEEKLY SCHEDULE",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),

                            const Spacer(),

                            Text(
                              "Tap to select/deselect",
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // SCHEDULE TABLE
                        Table(
                          columnWidths: const {
                            0: FixedColumnWidth(46),
                            1: FlexColumnWidth(),
                            2: FlexColumnWidth(),
                            3: FlexColumnWidth(),
                            4: FlexColumnWidth(),
                            5: FlexColumnWidth(),
                            6: FlexColumnWidth(),
                            7: FlexColumnWidth(),
                          },

                          children: [
                            // DAYS HEADER
                            TableRow(
                              children: [
                                const SizedBox(),

                                ...days.map(
                                  (day) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        vertical: 6,
                                      ),
                                      child: Center(
                                        child: Text(
                                          day,
                                          style:
                                              const TextStyle(
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            // TIME SLOTS
                            ...times.map(
                              (time) {
                                return TableRow(
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        time.replaceAll(
                                          ' ',
                                          '\n',
                                        ),
                                        style:
                                            const TextStyle(
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),

                                    ...days.map(
                                      (day) {
                                        String key =
                                            "${day}_$time";

                                        bool selected =
                                            selectedSlots[
                                                    key] ??
                                                false;

                                        return Padding(
                                          padding:
                                              const EdgeInsets
                                                  .all(2),
                                          child:
                                              GestureDetector(
                                            onTap: () {
                                              selectSlot(
                                                day,
                                                time,
                                              );
                                            },
                                            child:
                                                AspectRatio(
                                              aspectRatio: 1,
                                              child:
                                                  Container(
                                                decoration:
                                                    BoxDecoration(
                                                  color:
                                                      selected
                                                          ? Colors.teal
                                                          : Colors.grey.shade200,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    8,
                                                  ),
                                                ),
                                                child: selected
                                                    ? const Icon(
                                                        Icons.check,
                                                        color:
                                                            Colors.white,
                                                        size: 16,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ==================================================
              // BUTTONS
              // ==================================================

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // CLEAR BUTTON
                    Expanded(
                      child: OutlinedButton(
                        style:
                            OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),
                          ),
                        ),
                        onPressed: clearAllSlots,
                        child: const Text(
                          "Clear All",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // SAVE BUTTON
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.teal,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),
                          ),
                        ),
                        onPressed: saving
                            ? null
                            : saveSchedule,
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),

                                  SizedBox(width: 8),

                                  Text(
                                    "Save Schedule",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  bottomNavigationBar:
      BottomNavigationBar(
    currentIndex: selectedIndex,

    type: BottomNavigationBarType.fixed,

    selectedItemColor: Colors.teal,

    unselectedItemColor: Colors.grey,

    onTap: onTapBottom,

    items: const [
      // Schedule
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: "Schedule",
      ),

      // Add Courses
      BottomNavigationBarItem(
        icon: Icon(Icons.add_box),
        label: "Add Courses",
      ),

      // Courses
      BottomNavigationBarItem(
        icon: Icon(Icons.request_page),
        label: "Request",
      ),

      // Classes
      BottomNavigationBarItem(
        icon: Icon(Icons.class_),
        label: "Classes",
      ),
    ],
  ),
);
}
}