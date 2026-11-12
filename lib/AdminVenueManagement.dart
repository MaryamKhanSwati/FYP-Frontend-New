import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:house_of_tutor/services/api_config.dart';
import 'package:house_of_tutor/services/auth_store.dart';

class AdminVenueManagement extends StatefulWidget {
  const AdminVenueManagement({super.key});

  @override
  State<AdminVenueManagement> createState() =>
      _AdminVenueManagementState();
}

class _AdminVenueManagementState extends State<AdminVenueManagement> {
  // ============================================================
  // COLORS
  // ============================================================

  final Color primaryColor = const Color(0xFF1E8E7E);
  final Color backgroundColor = const Color(0xFFF4F4F4);
  final Color textColor = const Color(0xFF333333);
  final Color secondaryColor = const Color(0xFF6A1B9A);

  // ============================================================
  // FORM CONTROLLERS
  // ============================================================

  final TextEditingController roomNameController =
      TextEditingController();

  final TextEditingController capacityController =
      TextEditingController();

  // ============================================================
  // DAYS
  // ============================================================

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final Map<String, bool> selectedDays = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  // ============================================================
  // SCHEDULE FORM
  // ============================================================

  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;

  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  // Each entry represents one LT_Room_Schedule record.
  List<Map<String, dynamic>> schedules = [];

  // ============================================================
  // ROOM DATA
  // ============================================================

  List<dynamic> rooms = [];

  bool isLoadingRooms = false;
  bool isSavingRoom = false;

  int? expandedRoomId;

  @override
  void initState() {
    super.initState();
    loadLTRooms();
  }

  @override
  void dispose() {
    roomNameController.dispose();
    capacityController.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPER: SAFE JSON VALUE
  // Supports camelCase and snake_case property names.
  // ============================================================

  dynamic getValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }

    return null;
  }

  int getInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String getString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  String getToken() {
    return AuthStore.instance.token ?? '';
  }

  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${getToken()}',
    };
  }

  // ============================================================
  // LOAD EXISTING LT ROOMS AND THEIR SCHEDULES
  //
  // API:
  // GET /api/Admin/get-lt-rooms
  // ============================================================

  Future<void> loadLTRooms() async {
    if (!mounted) return;

    setState(() {
      isLoadingRooms = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/Admin/get-lt-rooms'),
        headers: getHeaders(),
      );

      debugPrint('GET LT ROOMS STATUS: ${response.statusCode}');
      debugPrint('GET LT ROOMS RESPONSE: ${response.body}');

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded is Map) {
        final data = Map<String, dynamic>.from(decoded);

        // Supports either { "rooms": [...] } or a direct room list.
        final dynamic roomData = data['rooms'] ??
            data['data'] ??
            data['ltRooms'] ??
            data['LT_Room'];

        if (roomData is List) {
          if (!mounted) return;

          setState(() {
            rooms = roomData;
          });
        } else {
          throw Exception(
            'The API response does not contain a rooms list.',
          );
        }
      } else {
        final message = decoded is Map
            ? getString(
                decoded['message'] ?? decoded['title'],
                fallback: 'Unable to load LT rooms.',
              )
            : 'Unable to load LT rooms.';

        showMessage(message, isError: true);
      }
    } catch (e) {
      debugPrint('GET LT ROOMS ERROR: $e');

      showMessage(
        'Unable to load LT rooms. Check your API connection.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingRooms = false;
        });
      }
    }
  }

  // ============================================================
  // TIME PICKERS
  // ============================================================

  Future<void> selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedStartTime ?? TimeOfDay.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedStartTime = picked;

        // Clear an invalid end time when start time changes.
        if (selectedEndTime != null) {
          final startMinutes =
              picked.hour * 60 + picked.minute;

          final endMinutes = selectedEndTime!.hour * 60 +
              selectedEndTime!.minute;

          if (endMinutes <= startMinutes) {
            selectedEndTime = null;
          }
        }
      });
    }
  }

  Future<void> selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedEndTime ??
          const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedEndTime = picked;
      });
    }
  }

  // ============================================================
  // DATE PICKERS
  // ============================================================

  Future<void> selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedStartDate = picked;

        if (selectedEndDate != null &&
            picked.isAfter(selectedEndDate!)) {
          selectedEndDate = null;
        }
      });
    }
  }

  Future<void> selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          selectedEndDate ?? selectedStartDate ?? DateTime.now(),
      firstDate: selectedStartDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedEndDate = picked;
      });
    }
  }

  // ============================================================
  // FORMAT TIME
  //
  // Example:
  // 8:00-9:00 am
  // 12:00-1:00 pm
  //
  // If the time period changes:
  // 11:00 am - 12:00 pm
  // ============================================================

  String formatClockTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String formatTime(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? 'am' : 'pm';

    return '${formatClockTime(time)} $period';
  }

  String getTimeString() {
    final start = selectedStartTime!;
    final end = selectedEndTime!;

    final startPeriod =
        start.period == DayPeriod.am ? 'am' : 'pm';

    final endPeriod =
        end.period == DayPeriod.am ? 'am' : 'pm';

    if (startPeriod == endPeriod) {
      return '${formatClockTime(start)}-'
          '${formatClockTime(end)} $endPeriod';
    }

    return '${formatTime(start)} - ${formatTime(end)}';
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  // ============================================================
  // ADD SCHEDULE TO TEMPORARY LIST
  //
  // Each selected day creates a separate schedule record.
  // Dates are optional and may be null.
  // ============================================================

  void addSchedule() {
    final selectedDayList = days
        .where((day) => selectedDays[day] == true)
        .toList();

    if (selectedDayList.isEmpty) {
      showMessage('Please select at least one day.',
          isError: true);
      return;
    }

    if (selectedStartTime == null) {
      showMessage('Please select start time.',
          isError: true);
      return;
    }

    if (selectedEndTime == null) {
      showMessage('Please select end time.',
          isError: true);
      return;
    }

    final startMinutes = selectedStartTime!.hour * 60 +
        selectedStartTime!.minute;

    final endMinutes =
        selectedEndTime!.hour * 60 + selectedEndTime!.minute;

    if (endMinutes <= startMinutes) {
      showMessage(
        'End time must be greater than start time.',
        isError: true,
      );
      return;
    }

    if (selectedStartDate != null &&
        selectedEndDate != null &&
        selectedStartDate!.isAfter(selectedEndDate!)) {
      showMessage(
        'Start date cannot be after end date.',
        isError: true,
      );
      return;
    }

    final timeString = getTimeString();

    setState(() {
      for (final day in selectedDayList) {
        schedules.add({
          'day': day,
          'time': timeString,
          'startDate': selectedStartDate != null
              ? formatDate(selectedStartDate!)
              : null,
          'endDate': selectedEndDate != null
              ? formatDate(selectedEndDate!)
              : null,

          // Matches LT_Room_Schedule.status.
          'status': 'Available',
        });

        selectedDays[day] = false;
      }

      selectedStartTime = null;
      selectedEndTime = null;
      selectedStartDate = null;
      selectedEndDate = null;
    });

    showMessage(
      '${selectedDayList.length} schedule(s) added.',
      isError: false,
    );
  }

  // ============================================================
  // DELETE TEMPORARY SCHEDULE
  // ============================================================

  void deleteSchedule(int index) {
    setState(() {
      schedules.removeAt(index);
    });
  }

  // ============================================================
  // SAVE LT ROOM
  //
  // API:
  // POST /api/Admin/add-lt-room
  //
  // Request example:
  // {
  //   "roomName": "LT-1",
  //   "capacity": 10,
  //   "status": "Active",
  //   "schedules": [
  //     {
  //       "day": "Monday",
  //       "time": "8:00-9:00 am",
  //       "startDate": "2026-10-02",
  //       "endDate": "2026-10-07",
  //       "status": "Available"
  //     }
  //   ]
  // }
  //
  // The backend DTO must define these properties and map them
  // to LT_Room and LT_Room_Schedule.
  // ============================================================

  Future<void> addLTRoom() async {
    final roomName = roomNameController.text.trim();

    if (roomName.isEmpty) {
      showMessage('Please enter venue name.',
          isError: true);
      return;
    }

    final capacity =
        int.tryParse(capacityController.text.trim());

    if (capacity == null || capacity <= 0) {
      showMessage('Please enter a valid capacity.',
          isError: true);
      return;
    }

    if (schedules.isEmpty) {
      showMessage('Please add at least one schedule.',
          isError: true);
      return;
    }

    if (getToken().isEmpty) {
      showMessage(
        'Authentication token is missing. Please log in again.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      isSavingRoom = true;
    });

    try {
      // One LT_Room record with multiple schedule records.
      final body = {
        'roomName': roomName,
        'capacity': capacity,

        // Matches LT_Room.status.
        'status': 'Active',

        'schedules': schedules.map((schedule) {
          return {
            'day': schedule['day'],
            'time': schedule['time'],
            'startDate': schedule['startDate'],
            'endDate': schedule['endDate'],

            // Matches LT_Room_Schedule.status.
            'status': schedule['status'] ?? 'Available',
          };
        }).toList(),
      };

      debugPrint('========== ADD LT ROOM ==========');
      debugPrint(jsonEncode(body));
      debugPrint('=================================');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Admin/add-lt-room'),
        headers: getHeaders(),
        body: jsonEncode(body),
      );

      debugPrint('ADD LT ROOM STATUS: ${response.statusCode}');
      debugPrint('ADD LT ROOM RESPONSE: ${response.body}');

      dynamic decoded;

      if (response.body.trim().isNotEmpty) {
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = null;
        }
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final message = decoded is Map
            ? getString(
                decoded['message'],
                fallback: 'LT venue added successfully.',
              )
            : 'LT venue added successfully.';

        if (!mounted) return;

        showMessage(message, isError: false);

        roomNameController.clear();
        capacityController.clear();

        setState(() {
          schedules.clear();

          for (final day in days) {
            selectedDays[day] = false;
          }

          selectedStartTime = null;
          selectedEndTime = null;
          selectedStartDate = null;
          selectedEndDate = null;
        });

        await loadLTRooms();
      } else {
        final message = decoded is Map
            ? getString(
                decoded['message'] ?? decoded['title'],
                fallback:
                    'Unable to add LT venue. Check the backend response.',
              )
            : 'Unable to add LT venue. Check the backend response.';

        showMessage(
          '$message (HTTP ${response.statusCode})',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('ADD LT ROOM ERROR: $e');

      showMessage(
        'Unable to connect with server.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingRoom = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // MAIN SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Venue Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadLTRooms,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildAddVenueCard(),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Existing LT Venues',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: loadLTRooms,
                    icon: const Icon(Icons.refresh),
                    color: primaryColor,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (isLoadingRooms)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (rooms.isEmpty)
                buildEmptyRooms()
              else
                ListView.builder(
                  itemCount: rooms.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final room = rooms[index];

                    if (room is! Map) {
                      return const SizedBox.shrink();
                    }

                    return buildRoomCard(
                      Map<String, dynamic>.from(room),
                    );
                  },
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD VENUE CARD
  // ============================================================

  Widget buildAddVenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.meeting_room,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add LT Venue',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Add a venue and its available schedule.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          buildTextField(
            controller: roomNameController,
            label: 'Venue Name',
            hint: 'e.g. LT-1',
            icon: Icons.meeting_room_outlined,
          ),

          const SizedBox(height: 14),

          buildTextField(
            controller: capacityController,
            label: 'Capacity',
            hint: 'e.g. 10',
            icon: Icons.people_outline,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Icon(Icons.calendar_month, color: secondaryColor),
              const SizedBox(width: 8),
              const Text(
                'LT Schedule',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          const Text(
            'Select days, time and optional date range.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),

          const SizedBox(height: 15),

          const Text(
            'Select Days',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          buildDaysSelection(),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: buildTimeButton(
                  title: 'Start Time',
                  value: selectedStartTime == null
                      ? 'Select time'
                      : formatTime(selectedStartTime!),
                  onTap: selectStartTime,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildTimeButton(
                  title: 'End Time',
                  value: selectedEndTime == null
                      ? 'Select time'
                      : formatTime(selectedEndTime!),
                  onTap: selectEndTime,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: buildDateButton(
                  title: 'Start Date',
                  value: selectedStartDate == null
                      ? 'Optional'
                      : formatDate(selectedStartDate!),
                  onTap: selectStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildDateButton(
                  title: 'End Date',
                  value: selectedEndDate == null
                      ? 'Optional'
                      : formatDate(selectedEndDate!),
                  onTap: selectEndDate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: addSchedule,
              icon: const Icon(Icons.add),
              label: const Text('Add Schedule'),
              style: OutlinedButton.styleFrom(
                foregroundColor: secondaryColor,
                side: BorderSide(color: secondaryColor),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          if (schedules.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Added Schedules',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              schedules.length,
              (index) => buildScheduleCard(
                schedules[index],
                index,
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSavingRoom ? null : addLTRoom,
              icon: isSavingRoom
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                isSavingRoom ? 'Saving Venue...' : 'Save Venue',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  // ============================================================
  // DAY SELECTION
  // ============================================================

  Widget buildDaysSelection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: days.map((day) {
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(day, style: const TextStyle(fontSize: 14)),
            value: selectedDays[day] ?? false,
            activeColor: primaryColor,
            onChanged: (value) {
              setState(() {
                selectedDays[day] = value ?? false;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // TIME BUTTON
  // ============================================================

  Widget buildTimeButton({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 19,
                  color: primaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE BUTTON
  // ============================================================

  Widget buildDateButton({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: secondaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TEMPORARY SCHEDULE CARD
  // ============================================================

  Widget buildScheduleCard(
    Map<String, dynamic> schedule,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: primaryColor,
            child: const Icon(
              Icons.schedule,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule['day'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  schedule['time'] ?? '',
                  style: const TextStyle(fontSize: 13),
                ),
                if (schedule['startDate'] != null ||
                    schedule['endDate'] != null)
                  Text(
                    '${schedule['startDate'] ?? 'No start'}'
                    ' → '
                    '${schedule['endDate'] ?? 'No end'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 3),
                const Text(
                  'Available',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => deleteSchedule(index),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXISTING ROOM CARD
  // ============================================================

  Widget buildRoomCard(Map<String, dynamic> room) {
    final roomId = getInt(
      getValue(room, ['ltRoomId', 'lt_room_id', 'LT_Room_Id']),
    );

    final roomName = getString(
      getValue(room, ['roomName', 'room_name']),
      fallback: 'Unknown Venue',
    );

    final capacity = getInt(room['capacity']);

    final status = getString(
      room['status'],
      fallback: 'Active',
    );

    final rawSchedules = getValue(
      room,
      ['schedules', 'Schedules', 'ltRoomSchedules'],
    );

    final List<dynamic> roomSchedules =
        rawSchedules is List ? rawSchedules : [];

    final isExpanded = expandedRoomId == roomId;

    final isActive = status.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                expandedRoomId =
                    isExpanded ? null : roomId;
              });
            },
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.meeting_room,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roomName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 10,
                          runSpacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Capacity: $capacity',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 19,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Venue Schedule',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (roomSchedules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'No schedule available.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...roomSchedules.map((item) {
                      if (item is! Map) {
                        return const SizedBox.shrink();
                      }

                      return buildSavedSchedule(
                        Map<String, dynamic>.from(item),
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVED SCHEDULE CARD
  //
  // Supports the LT_Room_Schedule sample column names:
  // lt_schedule_id, lt_room_id, day, time, start_date,
  // end_date, status.
  // ============================================================

  Widget buildSavedSchedule(Map<String, dynamic> schedule) {
    final day = getString(
      getValue(schedule, ['day', 'Day']),
      fallback: 'Unknown Day',
    );

    final time = getString(
      getValue(schedule, ['time', 'Time']),
      fallback: 'No time',
    );

    final startDate = getValue(
      schedule,
      ['startDate', 'start_date', 'StartDate'],
    );

    final endDate = getValue(
      schedule,
      ['endDate', 'end_date', 'EndDate'],
    );

    final status = getString(
      schedule['status'],
      fallback: 'Available',
    );

    final isAvailable = status.toLowerCase() == 'available';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.schedule,
              color: secondaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                if (startDate != null || endDate != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${startDate ?? 'No start date'}'
                    ' → '
                    '${endDate ?? 'No end date'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isAvailable
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: isAvailable ? Colors.green : Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY ROOM SCREEN
  // ============================================================

  Widget buildEmptyRooms() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 55,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          const Text(
            'No LT Venues Found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Add your first LT venue above.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}







































// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// import 'package:house_of_tutor/services/api_config.dart';
// import 'package:house_of_tutor/services/auth_store.dart';

// class AdminVenueManagement extends StatefulWidget {
//   const AdminVenueManagement({super.key});

//   @override
//   State<AdminVenueManagement> createState() =>
//       _AdminVenueManagementState();
// }

// class _AdminVenueManagementState extends State<AdminVenueManagement> {
//   // ============================================================
//   // CONTROLLERS
//   // ============================================================

//   final TextEditingController roomNameController =
//       TextEditingController();

//   final TextEditingController capacityController =
//       TextEditingController();

//   // ============================================================
//   // COLORS
//   // ============================================================

//   final Color primaryColor = const Color(0xFF1E8E7E);
//   final Color backgroundColor = const Color(0xFFF4F4F4);
//   final Color textColor = const Color(0xFF333333);
//   final Color secondaryColor = const Color(0xFF6A1B9A);

//   // ============================================================
//   // DAYS
//   // ============================================================

//   final List<String> days = [
//     "Monday",
//     "Tuesday",
//     "Wednesday",
//     "Thursday",
//     "Friday",
//     "Saturday",
//     "Sunday",
//   ];

//   // Selected days
//   final Map<String, bool> selectedDays = {
//     "Monday": false,
//     "Tuesday": false,
//     "Wednesday": false,
//     "Thursday": false,
//     "Friday": false,
//     "Saturday": false,
//     "Sunday": false,
//   };

//   // ============================================================
//   // SCHEDULE DATA
//   // ============================================================

//   TimeOfDay? selectedStartTime;
//   TimeOfDay? selectedEndTime;

//   DateTime? selectedStartDate;
//   DateTime? selectedEndDate;

//   // Temporary schedules before saving venue
//   List<Map<String, dynamic>> schedules = [];

//   // ============================================================
//   // ROOM DATA
//   // ============================================================

//   List<dynamic> rooms = [];

//   bool isLoadingRooms = false;
//   bool isSavingRoom = false;

//   // Which room is expanded
//   int? expandedRoomId;

//   @override
//   void initState() {
//     super.initState();

//     // Load existing LT rooms
//     loadLTRooms();
//   }

//   @override
//   void dispose() {
//     roomNameController.dispose();
//     capacityController.dispose();
//     super.dispose();
//   }

//   // ============================================================
//   // GET TOKEN
//   // ============================================================

//   String getToken() {
//     return AuthStore.instance.token ?? "";
//   }

//   // ============================================================
//   // LOAD LT ROOMS
//   // ============================================================

//   Future<void> loadLTRooms() async {
//     setState(() {
//       isLoadingRooms = true;
//     });

//     try {
//       final token = getToken();

//       final response = await http.get(
//         Uri.parse('$apiBaseUrl/api/Admin/get-lt-rooms'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       debugPrint("GET LT ROOMS STATUS: ${response.statusCode}");
//       debugPrint("GET LT ROOMS RESPONSE: ${response.body}");

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         setState(() {
//           rooms = data['rooms'] ?? [];
//         });
//       } else {
//         showMessage(
//           data['message'] ?? "Unable to load LT Rooms.",
//           isError: true,
//         );
//       }
//     } catch (e) {
//       debugPrint("GET LT ROOMS ERROR: $e");

//       showMessage(
//         "Unable to connect with server.",
//         isError: true,
//       );
//     } finally {
//       setState(() {
//         isLoadingRooms = false;
//       });
//     }
//   }

//   // ============================================================
//   // SELECT START TIME
//   // ============================================================

//   Future<void> selectStartTime() async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: selectedStartTime ?? TimeOfDay.now(),
//     );

//     if (picked != null) {
//       setState(() {
//         selectedStartTime = picked;
//       });
//     }
//   }

//   // ============================================================
//   // SELECT END TIME
//   // ============================================================

//   Future<void> selectEndTime() async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime:
//           selectedEndTime ??
//           const TimeOfDay(hour: 1, minute: 0),
//     );

//     if (picked != null) {
//       setState(() {
//         selectedEndTime = picked;
//       });
//     }
//   }

//   // ============================================================
//   // SELECT START DATE
//   // ============================================================

//   Future<void> selectStartDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedStartDate ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//     );

//     if (picked != null) {
//       setState(() {
//         selectedStartDate = picked;

//         // If end date is before start date, clear it
//         if (selectedEndDate != null &&
//             selectedEndDate!.isBefore(picked)) {
//           selectedEndDate = null;
//         }
//       });
//     }
//   }

//   // ============================================================
//   // SELECT END DATE
//   // ============================================================

//   Future<void> selectEndDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate:
//           selectedEndDate ??
//           selectedStartDate ??
//           DateTime.now(),
//       firstDate:
//           selectedStartDate ??
//           DateTime(2020),
//       lastDate: DateTime(2100),
//     );

//     if (picked != null) {
//       setState(() {
//         selectedEndDate = picked;
//       });
//     }
//   }

//   // ============================================================
//   // FORMAT TIME
//   // ============================================================

//   String formatTime(TimeOfDay time) {
//     final hour = time.hourOfPeriod == 0
//         ? 12
//         : time.hourOfPeriod;

//     final minute = time.minute.toString().padLeft(2, '0');

//     final period = time.period == DayPeriod.am
//         ? "am"
//         : "pm";

//     return "$hour:$minute $period";
//   }

//   // ============================================================
//   // FORMAT DATE
//   // ============================================================

//   String formatDate(DateTime date) {
//     final month =
//         date.month.toString().padLeft(2, '0');

//     final day =
//         date.day.toString().padLeft(2, '0');

//     return "${date.year}-$month-$day";
//   }

//   // ============================================================
//   // CREATE TIME STRING
//   //
//   // Backend expects:
//   // "9:00 am - 10:00 am"
//   // ============================================================

//   String getTimeString() {
//     return "${formatTime(selectedStartTime!)} - "
//         "${formatTime(selectedEndTime!)}";
//   }

//   // ============================================================
//   // ADD SCHEDULE
//   // ============================================================

//   void addSchedule() {
//     // ----------------------------------------------------------
//     // CHECK DAY
//     // ----------------------------------------------------------

//     final selectedDayList = selectedDays.entries
//         .where((entry) => entry.value)
//         .map((entry) => entry.key)
//         .toList();

//     if (selectedDayList.isEmpty) {
//       showMessage(
//         "Please select at least one day.",
//         isError: true,
//       );
//       return;
//     }

//     // ----------------------------------------------------------
//     // CHECK START TIME
//     // ----------------------------------------------------------

//     if (selectedStartTime == null) {
//       showMessage(
//         "Please select start time.",
//         isError: true,
//       );
//       return;
//     }

//     // ----------------------------------------------------------
//     // CHECK END TIME
//     // ----------------------------------------------------------

//     if (selectedEndTime == null) {
//       showMessage(
//         "Please select end time.",
//         isError: true,
//       );
//       return;
//     }

//     // ----------------------------------------------------------
//     // CHECK TIME
//     // ----------------------------------------------------------

//     final startMinutes =
//         selectedStartTime!.hour * 60 +
//         selectedStartTime!.minute;

//     final endMinutes =
//         selectedEndTime!.hour * 60 +
//         selectedEndTime!.minute;

//     if (endMinutes <= startMinutes) {
//       showMessage(
//         "End time must be greater than start time.",
//         isError: true,
//       );
//       return;
//     }

//     // ----------------------------------------------------------
//     // CHECK DATE
//     // ----------------------------------------------------------

//     if (selectedStartDate != null &&
//         selectedEndDate != null &&
//         selectedStartDate!.isAfter(selectedEndDate!)) {
//       showMessage(
//         "Start date cannot be greater than end date.",
//         isError: true,
//       );
//       return;
//     }

//     // ----------------------------------------------------------
//     // TIME STRING
//     // ----------------------------------------------------------

//     final timeString = getTimeString();

//     // ----------------------------------------------------------
//     // ADD EACH SELECTED DAY
//     //
//     // Example:
//     //
//     // Monday + Tuesday selected
//     //
//     // It will create:
//     // Monday  4:00 pm - 5:00 pm
//     // Tuesday 4:00 pm - 5:00 pm
//     // ----------------------------------------------------------

//     setState(() {
//       for (final day in selectedDayList) {
//         schedules.add({
//           "day": day,
//           "time": timeString,
//           "startDate": selectedStartDate != null
//               ? formatDate(selectedStartDate!)
//               : null,
//           "endDate": selectedEndDate != null
//               ? formatDate(selectedEndDate!)
//               : null,
//         });
//       }
//     });

//     // ----------------------------------------------------------
//     // RESET SCHEDULE FORM
//     // ----------------------------------------------------------

//     resetScheduleForm();

//     showMessage(
//       "${selectedDayList.length} schedule added.",
//       isError: false,
//     );
//   }

//   // ============================================================
//   // RESET SCHEDULE FORM
//   // ============================================================

//   void resetScheduleForm() {
//     setState(() {
//       for (final day in days) {
//         selectedDays[day] = false;
//       }

//       selectedStartTime = null;
//       selectedEndTime = null;
//       selectedStartDate = null;
//       selectedEndDate = null;
//     });
//   }

//   // ============================================================
//   // DELETE TEMPORARY SCHEDULE
//   // ============================================================

//   void deleteSchedule(int index) {
//     setState(() {
//       schedules.removeAt(index);
//     });
//   }

//   // ============================================================
//   // SAVE LT ROOM
//   // ============================================================

//   Future<void> addLTRoom() async {
//     // ----------------------------------------------------------
//     // ROOM NAME
//     // ----------------------------------------------------------

//     final roomName =
//         roomNameController.text.trim();

//     if (roomName.isEmpty) {
//       showMessage(
//         "Please enter venue name.",
//         isError: true,
//       );
//       return;
//     }

//     // ----------------------------------------------------------
//     // CAPACITY
//     // ----------------------------------------------------------

//     final capacity =
//         int.tryParse(
//           capacityController.text.trim(),
//         );

//     if (capacity == null || capacity <= 0) {
//       showMessage(
//         "Please enter a valid capacity.",
//         isError: true,
//       );
//       return;
//     }

//     // ----------------------------------------------------------
//     // SCHEDULE
//     // ----------------------------------------------------------

//     if (schedules.isEmpty) {
//       showMessage(
//         "Please add at least one schedule.",
//         isError: true,
//       );
//       return;
//     }

//     setState(() {
//       isSavingRoom = true;
//     });

//     try {
//       final token = getToken();

//       // --------------------------------------------------------
//       // PREPARE SCHEDULES
//       // --------------------------------------------------------

//       final scheduleData = schedules.map((schedule) {
//         return {
//           "day": schedule["day"],
//           "time": schedule["time"],
//           "startDate": schedule["startDate"],
//           "endDate": schedule["endDate"],
//         };
//       }).toList();

//       // --------------------------------------------------------
//       // FINAL REQUEST BODY
//       // --------------------------------------------------------

//       final body = {
//         "roomName": roomName,
//         "capacity": capacity,
//         "schedules": scheduleData,
//       };

//       debugPrint("====================================");
//       debugPrint("ADD LT ROOM");
//       debugPrint(jsonEncode(body));
//       debugPrint("====================================");

//       final response = await http.post(
//         Uri.parse('$apiBaseUrl/api/Admin/add-lt-room'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(body),
//       );

//       debugPrint(
//         "ADD LT ROOM STATUS: ${response.statusCode}",
//       );

//       debugPrint(
//         "ADD LT ROOM RESPONSE: ${response.body}",
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         showMessage(
//           data['message'] ??
//               "LT Venue added successfully.",
//           isError: false,
//         );

//         // Clear form
//         roomNameController.clear();
//         capacityController.clear();

//         setState(() {
//           schedules.clear();
//         });

//         // Reload rooms
//         await loadLTRooms();
//       } else {
//         showMessage(
//           data['message'] ??
//               "Unable to add LT Venue.",
//           isError: true,
//         );
//       }
//     } catch (e) {
//       debugPrint("ADD LT ROOM ERROR: $e");

//       showMessage(
//         "Unable to connect with server.",
//         isError: true,
//       );
//     } finally {
//       setState(() {
//         isSavingRoom = false;
//       });
//     }
//   }

//   // ============================================================
//   // MESSAGE
//   // ============================================================

//   void showMessage(
//     String message, {
//     required bool isError,
//   }) {
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor:
//             isError ? Colors.red : primaryColor,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,

//       appBar: AppBar(
//         title: const Text(
//           "Venue Management",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),

//       body: RefreshIndicator(
//         onRefresh: loadLTRooms,

//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),

//           padding: const EdgeInsets.all(16),

//           child: Column(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,

//             children: [

//               // ==================================================
//               // ADD VENUE CARD
//               // ==================================================

//               Container(
//                 width: double.infinity,

//                 padding: const EdgeInsets.all(18),

//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius:
//                       BorderRadius.circular(16),

//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black
//                           .withOpacity(0.06),
//                       blurRadius: 10,
//                       offset:
//                           const Offset(0, 4),
//                     ),
//                   ],
//                 ),

//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,

//                   children: [

//                     Row(
//                       children: [

//                         Container(
//                           padding:
//                               const EdgeInsets.all(10),

//                           decoration: BoxDecoration(
//                             color:
//                                 primaryColor.withOpacity(
//                               0.1,
//                             ),
//                             borderRadius:
//                                 BorderRadius.circular(10),
//                           ),

//                           child: Icon(
//                             Icons.meeting_room,
//                             color: primaryColor,
//                           ),
//                         ),

//                         const SizedBox(width: 12),

//                         const Expanded(
//                           child: Column(
//                             crossAxisAlignment:
//                                 CrossAxisAlignment.start,

//                             children: [

//                               Text(
//                                 "Add LT Venue",
//                                 style: TextStyle(
//                                   fontSize: 19,
//                                   fontWeight:
//                                       FontWeight.bold,
//                                 ),
//                               ),

//                               SizedBox(height: 3),

//                               Text(
//                                 "Add venue, capacity and teaching schedule.",
//                                 style: TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 13,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 20),

//                     // ==========================================
//                     // VENUE NAME
//                     // ==========================================

//                     buildTextField(
//                       controller:
//                           roomNameController,
//                       label: "Venue Name",
//                       hint:
//                           "e.g. LT-01",
//                       icon:
//                           Icons.meeting_room_outlined,
//                     ),

//                     const SizedBox(height: 14),

//                     // ==========================================
//                     // CAPACITY
//                     // ==========================================

//                     buildTextField(
//                       controller:
//                           capacityController,
//                       label: "Capacity",
//                       hint:
//                           "e.g. 50",
//                       icon:
//                           Icons.people_outline,
//                       keyboardType:
//                           TextInputType.number,
//                     ),

//                     const SizedBox(height: 22),

//                     // ==========================================
//                     // SCHEDULE TITLE
//                     // ==========================================

//                     Row(
//                       children: [

//                         Icon(
//                           Icons.calendar_month,
//                           color: secondaryColor,
//                         ),

//                         const SizedBox(width: 8),

//                         const Text(
//                           "LT Schedule",
//                           style: TextStyle(
//                             fontSize: 17,
//                             fontWeight:
//                                 FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 5),

//                     const Text(
//                       "Select day, time and optional date range.",
//                       style: TextStyle(
//                         color: Colors.grey,
//                         fontSize: 13,
//                       ),
//                     ),

//                     const SizedBox(height: 15),

//                     // ==========================================
//                     // DAYS
//                     // ==========================================

//                     const Text(
//                       "Select Days",
//                       style: TextStyle(
//                         fontWeight:
//                             FontWeight.w600,
//                       ),
//                     ),

//                     const SizedBox(height: 8),

//                     buildDaysSelection(),

//                     const SizedBox(height: 18),

//                     // ==========================================
//                     // TIME
//                     // ==========================================

//                     Row(
//                       children: [

//                         Expanded(
//                           child: buildTimeButton(
//                             title: "Start Time",
//                             value:
//                                 selectedStartTime !=
//                                         null
//                                     ? formatTime(
//                                         selectedStartTime!,
//                                       )
//                                     : "Select time",
//                             onTap:
//                                 selectStartTime,
//                           ),
//                         ),

//                         const SizedBox(width: 10),

//                         Expanded(
//                           child: buildTimeButton(
//                             title: "End Time",
//                             value:
//                                 selectedEndTime !=
//                                         null
//                                     ? formatTime(
//                                         selectedEndTime!,
//                                       )
//                                     : "Select time",
//                             onTap:
//                                 selectEndTime,
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 14),

//                     // ==========================================
//                     // DATES
//                     // ==========================================

//                     Row(
//                       children: [

//                         Expanded(
//                           child:
//                               buildDateButton(
//                             title: "Start Date",
//                             value:
//                                 selectedStartDate !=
//                                         null
//                                     ? formatDate(
//                                         selectedStartDate!,
//                                       )
//                                     : "Optional",
//                             onTap:
//                                 selectStartDate,
//                           ),
//                         ),

//                         const SizedBox(width: 10),

//                         Expanded(
//                           child:
//                               buildDateButton(
//                             title: "End Date",
//                             value:
//                                 selectedEndDate !=
//                                         null
//                                     ? formatDate(
//                                         selectedEndDate!,
//                                       )
//                                     : "Optional",
//                             onTap:
//                                 selectEndDate,
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 16),

//                     // ==========================================
//                     // ADD SCHEDULE BUTTON
//                     // ==========================================

//                     SizedBox(
//                       width: double.infinity,

//                       child: OutlinedButton.icon(
//                         onPressed:
//                             addSchedule,

//                         icon: const Icon(
//                           Icons.add,
//                         ),

//                         label: const Text(
//                           "Add Schedule",
//                         ),

//                         style:
//                             OutlinedButton.styleFrom(
//                           foregroundColor:
//                               secondaryColor,
//                           side: BorderSide(
//                             color:
//                                 secondaryColor,
//                           ),
//                           padding:
//                               const EdgeInsets.symmetric(
//                             vertical: 13,
//                           ),
//                           shape:
//                               RoundedRectangleBorder(
//                             borderRadius:
//                                 BorderRadius.circular(
//                               10,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),

//                     // ==========================================
//                     // TEMPORARY SCHEDULES
//                     // ==========================================

//                     if (schedules.isNotEmpty) ...[
//                       const SizedBox(height: 18),

//                       const Text(
//                         "Added Schedules",
//                         style: TextStyle(
//                           fontWeight:
//                               FontWeight.bold,
//                         ),
//                       ),

//                       const SizedBox(height: 8),

//                       ...List.generate(
//                         schedules.length,
//                         (index) {
//                           return buildScheduleCard(
//                             schedules[index],
//                             index,
//                           );
//                         },
//                       ),
//                     ],

//                     const SizedBox(height: 20),

//                     // ==========================================
//                     // SAVE VENUE
//                     // ==========================================

//                     SizedBox(
//                       width: double.infinity,

//                       child: ElevatedButton.icon(
//                         onPressed:
//                             isSavingRoom
//                                 ? null
//                                 : addLTRoom,

//                         icon: isSavingRoom
//                             ? const SizedBox(
//                                 width: 18,
//                                 height: 18,
//                                 child:
//                                     CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: Colors.white,
//                                 ),
//                               )
//                             : const Icon(
//                                 Icons.save,
//                               ),

//                         label: Text(
//                           isSavingRoom
//                               ? "Saving Venue..."
//                               : "Save Venue",
//                         ),

//                         style:
//                             ElevatedButton.styleFrom(
//                           backgroundColor:
//                               primaryColor,
//                           foregroundColor:
//                               Colors.white,
//                           padding:
//                               const EdgeInsets.symmetric(
//                             vertical: 14,
//                           ),
//                           shape:
//                               RoundedRectangleBorder(
//                             borderRadius:
//                                 BorderRadius.circular(
//                               10,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 25),

//               // ==================================================
//               // EXISTING VENUES
//               // ==================================================

//               Row(
//                 mainAxisAlignment:
//                     MainAxisAlignment.spaceBetween,

//                 children: [

//                   const Text(
//                     "Existing LT Venues",
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight:
//                           FontWeight.bold,
//                     ),
//                   ),

//                   IconButton(
//                     onPressed:
//                         loadLTRooms,
//                     icon: const Icon(
//                       Icons.refresh,
//                     ),
//                     color: primaryColor,
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 8),

//               // ==================================================
//               // LOADING
//               // ==================================================

//               if (isLoadingRooms)
//                 const Padding(
//                   padding:
//                       EdgeInsets.all(30),
//                   child: Center(
//                     child:
//                         CircularProgressIndicator(),
//                   ),
//                 )

//               // ==================================================
//               // NO ROOMS
//               // ==================================================

//               else if (rooms.isEmpty)
//                 buildEmptyRooms()

//               // ==================================================
//               // ROOMS LIST
//               // ==================================================

//               else
//                 ListView.builder(
//                   itemCount: rooms.length,
//                   shrinkWrap: true,
//                   physics:
//                       const NeverScrollableScrollPhysics(),

//                   itemBuilder:
//                       (context, index) {
//                     return buildRoomCard(
//                       rooms[index],
//                     );
//                   },
//                 ),

//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // TEXT FIELD
//   // ============================================================

//   Widget buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//     TextInputType? keyboardType,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,

//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hint,

//         prefixIcon: Icon(
//           icon,
//           color: primaryColor,
//         ),

//         filled: true,
//         fillColor:
//             const Color(0xFFF8F8F8),

//         border: OutlineInputBorder(
//           borderRadius:
//               BorderRadius.circular(10),
//           borderSide:
//               BorderSide.none,
//         ),

//         enabledBorder:
//             OutlineInputBorder(
//           borderRadius:
//               BorderRadius.circular(10),
//           borderSide:
//               BorderSide(
//             color:
//                 Colors.grey.shade300,
//           ),
//         ),

//         focusedBorder:
//             OutlineInputBorder(
//           borderRadius:
//               BorderRadius.circular(10),
//           borderSide:
//               BorderSide(
//             color: primaryColor,
//             width: 1.5,
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // DAYS SELECTION
//   // ============================================================

//   Widget buildDaysSelection() {
//     return Container(
//       padding: const EdgeInsets.all(10),

//       decoration: BoxDecoration(
//         color: const Color(0xFFF8F8F8),
//         borderRadius:
//             BorderRadius.circular(10),
//         border: Border.all(
//           color: Colors.grey.shade300,
//         ),
//       ),

//       child: Column(
//         children: days.map((day) {
//           return CheckboxListTile(
//             contentPadding:
//                 EdgeInsets.zero,

//             dense: true,

//             title: Text(
//               day,
//               style: const TextStyle(
//                 fontSize: 14,
//               ),
//             ),

//             value: selectedDays[day],

//             activeColor:
//                 primaryColor,

//             onChanged: (value) {
//               setState(() {
//                 selectedDays[day] =
//                     value ?? false;
//               });
//             },
//           );
//         }).toList(),
//       ),
//     );
//   }

//   // ============================================================
//   // TIME BUTTON
//   // ============================================================

//   Widget buildTimeButton({
//     required String title,
//     required String value,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,

//       borderRadius:
//           BorderRadius.circular(10),

//       child: Container(
//         padding:
//             const EdgeInsets.all(13),

//         decoration: BoxDecoration(
//           color: const Color(0xFFF8F8F8),
//           borderRadius:
//               BorderRadius.circular(10),
//           border: Border.all(
//             color:
//                 Colors.grey.shade300,
//           ),
//         ),

//         child: Column(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,

//           children: [

//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey,
//               ),
//             ),

//             const SizedBox(height: 5),

//             Row(
//               children: [

//                 Icon(
//                   Icons.access_time,
//                   size: 19,
//                   color: primaryColor,
//                 ),

//                 const SizedBox(width: 6),

//                 Expanded(
//                   child: Text(
//                     value,
//                     style: const TextStyle(
//                       fontSize: 13,
//                       fontWeight:
//                           FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // DATE BUTTON
//   // ============================================================

//   Widget buildDateButton({
//     required String title,
//     required String value,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,

//       borderRadius:
//           BorderRadius.circular(10),

//       child: Container(
//         padding:
//             const EdgeInsets.all(13),

//         decoration: BoxDecoration(
//           color: const Color(0xFFF8F8F8),
//           borderRadius:
//               BorderRadius.circular(10),
//           border: Border.all(
//             color:
//                 Colors.grey.shade300,
//           ),
//         ),

//         child: Column(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,

//           children: [

//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey,
//               ),
//             ),

//             const SizedBox(height: 5),

//             Row(
//               children: [

//                 Icon(
//                   Icons.calendar_today,
//                   size: 18,
//                   color: secondaryColor,
//                 ),

//                 const SizedBox(width: 6),

//                 Expanded(
//                   child: Text(
//                     value,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight:
//                           FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // TEMPORARY SCHEDULE CARD
//   // ============================================================

//   Widget buildScheduleCard(
//     Map<String, dynamic> schedule,
//     int index,
//   ) {
//     return Container(
//       margin:
//           const EdgeInsets.only(bottom: 8),

//       padding:
//           const EdgeInsets.all(12),

//       decoration: BoxDecoration(
//         color:
//             primaryColor.withOpacity(0.06),

//         borderRadius:
//             BorderRadius.circular(10),

//         border: Border.all(
//           color:
//               primaryColor.withOpacity(0.2),
//         ),
//       ),

//       child: Row(
//         children: [

//           CircleAvatar(
//             radius: 19,
//             backgroundColor:
//                 primaryColor,

//             child: const Icon(
//               Icons.schedule,
//               color: Colors.white,
//               size: 20,
//             ),
//           ),

//           const SizedBox(width: 10),

//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,

//               children: [

//                 Text(
//                   schedule["day"] ?? "",
//                   style: const TextStyle(
//                     fontWeight:
//                         FontWeight.bold,
//                   ),
//                 ),

//                 const SizedBox(height: 3),

//                 Text(
//                   schedule["time"] ?? "",
//                   style: const TextStyle(
//                     fontSize: 13,
//                   ),
//                 ),

//                 if (schedule["startDate"] !=
//                         null ||
//                     schedule["endDate"] !=
//                         null)
//                   Text(
//                     "${schedule["startDate"] ?? "No start"}"
//                     " → "
//                     "${schedule["endDate"] ?? "No end"}",
//                     style: const TextStyle(
//                       fontSize: 11,
//                       color: Colors.grey,
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           IconButton(
//             onPressed: () {
//               deleteSchedule(index);
//             },

//             icon: const Icon(
//               Icons.delete_outline,
//               color: Colors.red,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // ROOM CARD
//   // ============================================================

//   Widget buildRoomCard(
//     dynamic room,
//   ) {
//     final int roomId =
//         room["ltRoomId"] ?? 0;

//     final bool isExpanded =
//         expandedRoomId == roomId;

//     final List<dynamic> roomSchedules =
//         room["schedules"] ?? [];

//     return Container(
//       margin:
//           const EdgeInsets.only(bottom: 12),

//       decoration: BoxDecoration(
//         color: Colors.white,

//         borderRadius:
//             BorderRadius.circular(15),

//         boxShadow: [
//           BoxShadow(
//             color: Colors.black
//                 .withOpacity(0.05),
//             blurRadius: 8,
//             offset:
//                 const Offset(0, 3),
//           ),
//         ],
//       ),

//       child: Column(
//         children: [

//           // ==================================================
//           // ROOM HEADER
//           // ==================================================

//           InkWell(
//             onTap: () {
//               setState(() {
//                 if (isExpanded) {
//                   expandedRoomId = null;
//                 } else {
//                   expandedRoomId = roomId;
//                 }
//               });
//             },

//             borderRadius:
//                 BorderRadius.circular(15),

//             child: Padding(
//               padding:
//                   const EdgeInsets.all(15),

//               child: Row(
//                 children: [

//                   Container(
//                     width: 50,
//                     height: 50,

//                     decoration: BoxDecoration(
//                       color:
//                           primaryColor
//                               .withOpacity(0.1),

//                       borderRadius:
//                           BorderRadius.circular(
//                         12,
//                       ),
//                     ),

//                     child: Icon(
//                       Icons.meeting_room,
//                       color:
//                           primaryColor,
//                     ),
//                   ),

//                   const SizedBox(width: 12),

//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment:
//                           CrossAxisAlignment.start,

//                       children: [

//                         Text(
//                           room["roomName"] ??
//                               "Unknown Venue",

//                           style:
//                               const TextStyle(
//                             fontSize: 17,
//                             fontWeight:
//                                 FontWeight.bold,
//                           ),
//                         ),

//                         const SizedBox(height: 5),

//                         Row(
//                           children: [

//                             const Icon(
//                               Icons.people_outline,
//                               size: 17,
//                               color: Colors.grey,
//                             ),

//                             const SizedBox(
//                               width: 5,
//                             ),

//                             Text(
//                               "Capacity: ${room["capacity"] ?? 0}",
//                               style:
//                                   const TextStyle(
//                                 color:
//                                     Colors.grey,
//                                 fontSize: 13,
//                               ),
//                             ),

//                             const SizedBox(
//                               width: 12,
//                             ),

//                             Container(
//                               padding:
//                                   const EdgeInsets
//                                       .symmetric(
//                                 horizontal: 8,
//                                 vertical: 3,
//                               ),

//                               decoration:
//                                   BoxDecoration(
//                                 color:
//                                     Colors.green
//                                         .withOpacity(
//                                   0.1,
//                                 ),
//                                 borderRadius:
//                                     BorderRadius
//                                         .circular(
//                                   20,
//                                 ),
//                               ),

//                               child: Text(
//                                 room["status"] ??
//                                     "Active",
//                                 style:
//                                     const TextStyle(
//                                   color:
//                                       Colors.green,
//                                   fontSize: 11,
//                                   fontWeight:
//                                       FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Dropdown arrow
//                   Icon(
//                     isExpanded
//                         ? Icons
//                             .keyboard_arrow_up
//                         : Icons
//                             .keyboard_arrow_down,

//                     color: primaryColor,
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // ==================================================
//           // SCHEDULE DROPDOWN
//           // ==================================================

//           if (isExpanded)
//             Container(
//               width: double.infinity,

//               padding:
//                   const EdgeInsets.fromLTRB(
//                 15,
//                 0,
//                 15,
//                 15,
//               ),

//               child: Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,

//                 children: [

//                   Divider(
//                     color:
//                         Colors.grey.shade200,
//                   ),

//                   const SizedBox(height: 5),

//                   Row(
//                     children: [

//                       Icon(
//                         Icons.calendar_month,
//                         size: 19,
//                         color:
//                             secondaryColor,
//                       ),

//                       const SizedBox(width: 7),

//                       const Text(
//                         "Venue Schedule",
//                         style: TextStyle(
//                           fontWeight:
//                               FontWeight.bold,
//                           fontSize: 15,
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 10),

//                   if (roomSchedules.isEmpty)
//                     const Padding(
//                       padding:
//                           EdgeInsets.all(10),
//                       child: Text(
//                         "No schedule available.",
//                         style: TextStyle(
//                           color: Colors.grey,
//                         ),
//                       ),
//                     )

//                   else
//                     ...roomSchedules.map(
//                       (schedule) {
//                         return buildSavedSchedule(
//                           schedule,
//                         );
//                       },
//                     ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // SAVED SCHEDULE
//   // ============================================================

//   Widget buildSavedSchedule(
//     dynamic schedule,
//   ) {
//     return Container(
//       margin:
//           const EdgeInsets.only(bottom: 8),

//       padding:
//           const EdgeInsets.all(12),

//       decoration: BoxDecoration(
//         color:
//             const Color(0xFFF8F8F8),

//         borderRadius:
//             BorderRadius.circular(10),

//         border: Border.all(
//           color:
//               Colors.grey.shade200,
//         ),
//       ),

//       child: Row(
//         children: [

//           Container(
//             padding:
//                 const EdgeInsets.all(8),

//             decoration: BoxDecoration(
//               color:
//                   secondaryColor
//                       .withOpacity(0.1),

//               borderRadius:
//                   BorderRadius.circular(8),
//             ),

//             child: Icon(
//               Icons.schedule,
//               color:
//                   secondaryColor,
//               size: 20,
//             ),
//           ),

//           const SizedBox(width: 10),

//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,

//               children: [

//                 Text(
//                   schedule["day"] ??
//                       "Unknown Day",

//                   style:
//                       const TextStyle(
//                     fontWeight:
//                         FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),

//                 const SizedBox(height: 4),

//                 Text(
//                   schedule["time"] ??
//                       "No time",

//                   style:
//                       const TextStyle(
//                     fontSize: 13,
//                     color: Colors.black87,
//                   ),
//                 ),

//                 const SizedBox(height: 3),

//                 if (schedule["startDate"] !=
//                         null ||
//                     schedule["endDate"] !=
//                         null)
//                   Text(
//                     "${schedule["startDate"] ?? "No start date"}"
//                     " → "
//                     "${schedule["endDate"] ?? "No end date"}",

//                     style:
//                         const TextStyle(
//                       fontSize: 11,
//                       color: Colors.grey,
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           // Available status
//           Container(
//             padding:
//                 const EdgeInsets.symmetric(
//               horizontal: 8,
//               vertical: 4,
//             ),

//             decoration:
//                 BoxDecoration(
//               color:
//                   Colors.green.withOpacity(
//                 0.1,
//               ),

//               borderRadius:
//                   BorderRadius.circular(
//                 20,
//               ),
//             ),

//             child: Text(
//               schedule["status"] ??
//                   "Available",

//               style:
//                   const TextStyle(
//                 color: Colors.green,
//                 fontSize: 10,
//                 fontWeight:
//                     FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // EMPTY ROOMS
//   // ============================================================

//   Widget buildEmptyRooms() {
//     return Container(
//       width: double.infinity,

//       padding:
//           const EdgeInsets.all(30),

//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(15),
//       ),

//       child: Column(
//         children: [

//           Icon(
//             Icons.meeting_room_outlined,
//             size: 55,
//             color: Colors.grey.shade400,
//           ),

//           const SizedBox(height: 10),

//           const Text(
//             "No LT Venues Found",
//             style: TextStyle(
//               fontSize: 17,
//               fontWeight:
//                   FontWeight.bold,
//             ),
//           ),

//           const SizedBox(height: 5),

//           const Text(
//             "Add your first LT Venue above.",
//             style: TextStyle(
//               color: Colors.grey,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }