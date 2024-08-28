import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class ManageHabitsPage extends StatefulWidget {
  const ManageHabitsPage({super.key});

  @override
  _ManageHabitsPageState createState() => _ManageHabitsPageState();
}

class _ManageHabitsPageState extends State<ManageHabitsPage> {
  List<Map<String, dynamic>> _habits = [];
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadHabits();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _habits = (prefs.getStringList('habits') ?? []).map((habit) {
        List<String> parts = habit.split('|');
        return {
          'name': parts[0],
          'time': parts[1],
          'location': parts[2],
          'icon': parts[3],
          'days': parts[4],
          'reminderMode': parts.length > 5 ? parts[5] : 'Notification',
          'completedDays': parts.length > 6 ? parts[6].split(',') : [],
        };
      }).toList();
      _sortHabits();
    });
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'habits',
      _habits.map((habit) {
        return '${habit['name']}|${habit['time']}|${habit['location']}|${habit['icon']}|${habit['days']}|${habit['reminderMode']}|${(habit['completedDays'] as List).join(',')}';
      }).toList(),
    );
  }

  void _sortHabits() {
    _habits.sort((a, b) => a['time']!.compareTo(b['time']!));
  }

  void _editHabit(Map<String, dynamic> habit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return HabitEditorDialog(
          habit: habit,
          onSave: (Map<String, dynamic> updatedHabit) async {
            setState(() {
              int index = _habits.indexOf(habit);
              _habits[index] = updatedHabit;

              // If the habit was marked as complete but the time hasn't passed, reset completion
              DateTime now = DateTime.now();
              DateTime scheduledTime = _getScheduledTime(updatedHabit['time']);
              if (scheduledTime.isAfter(now)) {
                updatedHabit['completedDays'] = [];
              }

              _saveHabits();
            });

            // Cancel and reschedule notifications with the updated time and settings
            await _cancelAndRescheduleNotification(updatedHabit);
          },
        );
      },
    );
  }

  DateTime _getScheduledTime(String time) {
    final timeParts = time.split(" ");
    final hourMinuteParts = timeParts[0].split(":");
    int hour = int.parse(hourMinuteParts[0]);
    final int minute = int.parse(hourMinuteParts[1]);
    final bool isPM = timeParts[1].toLowerCase() == "pm";

    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    return DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, hour, minute);
  }

  Future<void> _cancelAndRescheduleNotification(
      Map<String, dynamic> habit) async {
    // Cancel existing notifications
    final prefs = await SharedPreferences.getInstance();
    List<String> notificationIds =
        prefs.getStringList('notification_ids') ?? [];
    if (notificationIds.isNotEmpty) {
      for (String id in notificationIds) {
        await flutterLocalNotificationsPlugin.cancel(int.parse(id));
      }
    }

    // Reschedule for the next occurrence if the time is in the future
    DateTime now = DateTime.now();
    DateTime scheduledTime = _getScheduledTime(habit['time']);
    if (scheduledTime.isAfter(now)) {
      await _scheduleNotification(scheduledTime, habit['name'],
          "Time to complete your habit: ${habit['name']}!");
    }
  }

  Future<void> _scheduleNotification(
      DateTime scheduledNotificationDateTime, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'habit_channel_id',
      'habit_channel_name',
      channelDescription: 'Channel for habit reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    final prefs = await SharedPreferences.getInstance();

    List<String> notificationIds =
        prefs.getStringList('notification_ids') ?? [];
    notificationIds.add(notificationId.toString());
    await prefs.setStringList('notification_ids', notificationIds);
  }

  void _deleteHabit(Map<String, dynamic> habit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Habit'),
          content: const Text(
              'Are you sure you want to delete this habit? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _habits.remove(habit);
                  _saveHabits();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Habits'),
      ),
      body: ListView.builder(
        itemCount: _habits.length,
        itemBuilder: (context, index) {
          final habit = _habits[index];
          return ListTile(
            leading: Icon(
              IconData(int.parse(habit['icon']!), fontFamily: 'MaterialIcons'),
              size: 30.0,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(
              habit['name'],
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: Text(
              'Time: ${habit['time']}\nLocation: ${habit['location']}\nDays: ${habit['days']}',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.0,
                  ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: 30.0,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () => _editHabit(habit),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: 30.0,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () => _deleteHabit(habit),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HabitEditorDialog extends StatefulWidget {
  final Map<String, dynamic> habit;
  final Function(Map<String, dynamic>) onSave;

  const HabitEditorDialog({
    required this.habit,
    required this.onSave,
    super.key,
  });

  @override
  _HabitEditorDialogState createState() => _HabitEditorDialogState();
}

class _HabitEditorDialogState extends State<HabitEditorDialog> {
  late TextEditingController _habitController;
  late String _selectedTime;
  late String _selectedLocation;
  late IconData _selectedIcon;
  late Map<String, bool> _selectedDays;
  String _reminderMode = 'Notification';

  List<String> _locations = [
    'Home',
    'Work',
    'Park',
    'Gym',
    'School',
  ];

  @override
  void initState() {
    super.initState();
    _habitController = TextEditingController(text: widget.habit['name']);
    _selectedTime = widget.habit['time'];
    _selectedLocation = widget.habit['location'];
    _selectedIcon =
        IconData(int.parse(widget.habit['icon']), fontFamily: 'MaterialIcons');
    _reminderMode = widget.habit['reminderMode'];

    _selectedDays = {
      'Mon': false,
      'Tue': false,
      'Wed': false,
      'Thu': false,
      'Fri': false,
      'Sat': false,
      'Sun': false,
    };
    for (String day in widget.habit['days'].split(',')) {
      _selectedDays[day] = true;
    }
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locations = prefs.getStringList('locations') ?? _locations;
    });
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('locations', _locations);
  }

  Future<void> _saveHabit() async {
    final Map<String, dynamic> updatedHabit = {
      'name': _habitController.text,
      'time': _selectedTime,
      'location': _selectedLocation,
      'icon': _selectedIcon.codePoint.toString(),
      'days': _selectedDays.keys.where((day) => _selectedDays[day]!).join(','),
      'reminderMode': _reminderMode,
      'completedDays': widget.habit['completedDays'],
    };

    widget.onSave(updatedHabit.cast<String, Object>());
    Navigator.of(context).pop();
  }

  Future<void> _selectTime(BuildContext context) async {
    final timeParts =
        _selectedTime.split(" "); // Splits into ["hh:mm", "AM/PM"]
    final hourMinuteParts = timeParts[0].split(":"); // Splits into ["hh", "mm"]

    int hour = int.parse(hourMinuteParts[0]);
    final int minute = int.parse(hourMinuteParts[1]);
    final bool isPM = timeParts[1].toLowerCase() == "pm";

    if (isPM && hour != 12) {
      hour += 12; // Convert PM hours to 24-hour format
    } else if (!isPM && hour == 12) {
      hour = 0; // Midnight case
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked.format(context); // Save the selected time
      });
    }
  }

  void _selectLocation() async {
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select a location'),
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                width: double.maxFinite,
                child: Column(
                  children: [
                    Expanded(
                      child: ReorderableListView(
                        onReorder: (int oldIndex, int newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final String item = _locations.removeAt(oldIndex);
                            _locations.insert(newIndex, item);
                            _saveLocations();
                          });
                        },
                        children: _locations
                            .map((location) => ListTile(
                                  key: Key(location),
                                  title: Text(location),
                                  trailing: const Icon(Icons.drag_handle),
                                  onTap: () {
                                    setState(() {
                                      _selectedLocation = location;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _showAddLocationDialog(setState);
                      },
                      child: const Text('Add New Location'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {});
  }

  void _showAddLocationDialog(Function setState) {
    TextEditingController newLocationController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Location'),
          content: TextField(
            controller: newLocationController,
            decoration: const InputDecoration(
              labelText: 'Location Name',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (newLocationController.text.isNotEmpty &&
                    !_locations.contains(newLocationController.text)) {
                  setState(() {
                    _locations.add(newLocationController.text);
                    _selectedLocation = newLocationController.text;
                  });
                  _saveLocations(); // Save the updated locations
                  Navigator.of(context).pop();
                } else if (_locations.contains(newLocationController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location already exists!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _selectIcon() async {
    final IconData? icon = await showDialog<IconData>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select an icon'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10.0,
              children: UserIcons.all
                  .map((iconData) => IconButton(
                        icon: Icon(iconData),
                        onPressed: () => Navigator.pop(context, iconData),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
    if (icon != null) {
      setState(() {
        _selectedIcon = icon;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Habit'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: _selectIcon,
              child: Card(
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          _selectedIcon,
                          size: 72.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _habitController,
              decoration: const InputDecoration(
                labelText: 'Enter habit name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: TextEditingController(text: _selectedLocation),
              decoration: const InputDecoration(
                labelText: 'Select location',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: _selectLocation,
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () => _selectTime(context),
                child: Text(_selectedTime),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 5.0,
              children: _selectedDays.keys.map((day) {
                return RawChip(
                  shape: const StadiumBorder(side: BorderSide.none),
                  showCheckmark: false,
                  label: Text(day),
                  selected: _selectedDays[day]!,
                  selectedColor: Colors.green,
                  checkmarkColor: Colors.transparent,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedDays[day] = selected;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _reminderMode,
              decoration: const InputDecoration(
                labelText: 'Reminder Mode',
                border: OutlineInputBorder(),
              ),
              items: <String>['Notification', 'Alarm'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _reminderMode = newValue!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveHabit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class UserIcons {
  static const all = [
    Icons.home,
    Icons.work,
    Icons.park,
    Icons.fitness_center,
    Icons.school,
    Icons.star,
    Icons.favorite,
    Icons.cake,
    Icons.beach_access,
    Icons.directions_bike,
    Icons.directions_run,
    Icons.local_florist,
    Icons.local_cafe,
    Icons.local_dining,
    Icons.local_pizza,
    Icons.local_bar,
  ];
}
