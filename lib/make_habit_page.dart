import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'manage_habits_page.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

// List of motivational sentences
List<String> motivationalSentences = [
  'Bamboo is waiting.',
  'Time to do work.',
  'Crush your goals today.',
  'Make it happen.',
  'Stay focused.',
  'Keep pushing.',
  'You’ve got this.',
  'Do it for yourself.',
  'Rise and shine.',
  'Success is near.',
  'Take the first step.',
  'You can do it.',
  'Make it count.',
  'Never give up.',
  'Keep moving forward.',
  'Believe in yourself.',
  'Make today great.',
  'Start strong.',
  'Push through.',
  'Achieve your best.',
  'You should start before I tell you.',
  'Get up and get moving.',
  'Why are you still waiting?',
  'Time\'s ticking, get going.',
  'Don\'t waste time, start now.',
  'Stop procrastinating.',
  'Get to work already.',
  'Do it now, not later.',
  'No more excuses.',
  'Just do it.'
];

class MakeHabitPage extends StatefulWidget {
  const MakeHabitPage({super.key});

  @override
  _MakeHabitPageState createState() => _MakeHabitPageState();
}

class _MakeHabitPageState extends State<MakeHabitPage> {
  final TextEditingController _habitController = TextEditingController();
  final TextEditingController _newLocationController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TimeOfDay? _selectedTime;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<String> _locations = [
    'Home',
    'Work',
    'Park',
    'Gym',
    'School',
  ];
  String? _selectedLocation;
  String _selectedSound = 'rain';
  IconData _selectedIcon = Icons.home;
  Map<String, bool> _selectedDays = {
    'Mon': false,
    'Tue': false,
    'Wed': false,
    'Thu': false,
    'Fri': false,
    'Sat': false,
    'Sun': false,
  };

  String _reminderMode = 'Notification';
  bool _vibrate = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadLocations();
    _loadSettings();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tapped logic here
        if (response.payload == 'stop_alarm') {
          await AndroidAlarmManager.cancel(0);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  Future<void> _configureLocalTimeZone() async {
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    // Handle background notification tap logic
    if (response.payload == 'stop_alarm') {
      AndroidAlarmManager.cancel(0);
    }
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _vibrate = prefs.getBool('vibrate') ?? true;
    });
  }

  Future<int> _getNextNotificationId() async {
    final prefs = await SharedPreferences.getInstance();
    int id = prefs.getInt('notification_id') ?? 0;
    prefs.setInt('notification_id', id + 1);
    return id;
  }

  Future<void> _scheduleNotification(
      DateTime scheduledNotificationDateTime, String title, String body) async {
    print(_vibrate);

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'habit_channel_id',
      'habit_channel_name',
      channelDescription: 'Channel for habit reminders',
      importance: _vibrate ? Importance.max : Importance.min,
      priority: _vibrate ? Priority.high : Priority.min,
      playSound: _vibrate,
      enableVibration: _vibrate,
      vibrationPattern: _vibrate ? Int64List.fromList([0, 1000]) : null,
    );

    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    int notificationId = await _getNextNotificationId();

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

    // Save notification ID
    final prefs = await SharedPreferences.getInstance();
    List<String> notificationIds =
        prefs.getStringList('notification_ids') ?? [];
    notificationIds.add(notificationId.toString());
    await prefs.setStringList('notification_ids', notificationIds);

    // Save notification time for future updates
    List<String> notificationTimes =
        prefs.getStringList('notification_times') ?? [];
    notificationTimes.add(scheduledNotificationDateTime.toIso8601String());
    await prefs.setStringList('notification_times', notificationTimes);
  }

  void _alarmCallback() {
    flutterLocalNotificationsPlugin.show(
      0,
      'Alarm',
      'Time to complete your habit!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel_id',
          'alarm_channel_name',
          channelDescription: 'Channel for alarm reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(_selectedSound),
        ),
      ),
      payload: 'stop_alarm',
    );
  }

  Future<void> _scheduleAlarm(
      DateTime scheduledAlarmDateTime, String title, String body) async {
    int alarmId = await _getNextNotificationId();

    // Schedule the alarm
    await AndroidAlarmManager.oneShotAt(
      scheduledAlarmDateTime,
      alarmId,
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    // Save alarm ID and time
    final prefs = await SharedPreferences.getInstance();
    List<String> alarmIds = prefs.getStringList('alarm_ids') ?? [];
    alarmIds.add(alarmId.toString());
    await prefs.setStringList('alarm_ids', alarmIds);

    List<String> alarmTimes = prefs.getStringList('alarm_times') ?? [];
    alarmTimes.add(scheduledAlarmDateTime.toIso8601String());
    await prefs.setStringList('alarm_times', alarmTimes);
  }

  void _addHabit() async {
    if (_formKey.currentState!.validate() && _selectedTime != null) {
      DateTime now = DateTime.now();
      DateTime scheduledTime = DateTime(now.year, now.month, now.day,
          _selectedTime!.hour, _selectedTime!.minute);

      // Schedule reminders for selected days
      for (var day in _selectedDays.keys) {
        if (_selectedDays[day] == true) {
          DateTime nextScheduledTime = _nextInstanceOfDay(day, scheduledTime);
          String title = _habitController.text;

          // Randomly select a motivational sentence
          String body = motivationalSentences[
              Random().nextInt(motivationalSentences.length)];

          if (_reminderMode == 'Notification') {
            _scheduleNotification(nextScheduledTime, title, body);
          } else {
            // DateTime scheduledAlarmDateTime =
            //     DateTime.now().add(const Duration(seconds: 1));
            // _scheduleAlarm(
            //     scheduledAlarmDateTime, "Test Alarm", "This is a test alarm");

            _scheduleAlarm(nextScheduledTime, title, body);
          }
        }
      }

      // Save the habit with the current date, time, icon, and selected days
      final prefs = await SharedPreferences.getInstance();
      List<String> habits = prefs.getStringList('habits') ?? [];
      habits.add(
          '${_habitController.text}|${_selectedTime!.format(context)}|${_selectedLocation ?? ''}|${_selectedIcon.codePoint}|${_selectedDays.keys.where((day) => _selectedDays[day]!).join(',')}|$_reminderMode');
      await prefs.setStringList('habits', habits);

      // Update stats
      int totalHabits = prefs.getInt('totalHabits') ?? 0;
      prefs.setInt('totalHabits', totalHabits + 1);

      // Clear the input fields
      _habitController.clear();
      setState(() {
        _selectedTime = null;
        _selectedIcon = Icons.home;
        _selectedDays = {
          'Mon': false,
          'Tue': false,
          'Wed': false,
          'Thu': false,
          'Fri': false,
          'Sat': false,
          'Sun': false,
        };
      });

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New Habit Created!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Show failure snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DateTime _nextInstanceOfDay(String day, DateTime scheduledTime) {
    int dayOffset = {
      'Mon': DateTime.monday,
      'Tue': DateTime.tuesday,
      'Wed': DateTime.wednesday,
      'Thu': DateTime.thursday,
      'Fri': DateTime.friday,
      'Sat': DateTime.saturday,
      'Sun': DateTime.sunday,
    }[day]!;

    DateTime now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      // If scheduled time is before now, add a day to move to the next instance
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // Find the next instance of the specified day
    while (scheduledTime.weekday != dayOffset) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    return scheduledTime;
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return child!;
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
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
                            .map((location) => Slidable(
                                  key: Key(location),
                                  endActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (context) {
                                          setState(() {
                                            _locations.remove(location);
                                            _saveLocations();
                                          });
                                        },
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete,
                                        label: 'Delete',
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    title: Text(location),
                                    trailing: const Icon(Icons.drag_handle),
                                    onTap: () {
                                      setState(() {
                                        _selectedLocation = location;
                                        _newLocationController.text =
                                            location; // Update the text field
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Location'),
          content: TextField(
            controller: _newLocationController,
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
                if (_newLocationController.text.isNotEmpty &&
                    !_locations.contains(_newLocationController.text)) {
                  setState(() {
                    _locations.add(_newLocationController.text);
                    _selectedLocation = _newLocationController.text;
                    _newLocationController.clear();
                    _saveLocations();
                  });
                  Navigator.of(context).pop();
                } else if (_locations.contains(_newLocationController.text)) {
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

  void _deleteLocation(String location) {
    setState(() {
      _locations.remove(location);
      _saveLocations();
    });
  }

  void _navigateToManageHabitsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageHabitsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Habit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: _formKey,
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
                        labelText: 'Enter a new habit',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a habit';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller:
                          TextEditingController(text: _selectedLocation),
                      decoration: const InputDecoration(
                        labelText: 'Select location',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: _selectLocation,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedTime == null
                                ? 'Time not selected'
                                : 'Selected time: ${_selectedTime!.format(context)}',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _selectTime(context),
                          child: const Text('Pick Time'),
                        ),
                      ],
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
                      items:
                          <String>['Notification', 'Alarm'].map((String value) {
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
                    if (_reminderMode == "Alarm") ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedSound,
                        decoration: const InputDecoration(
                          labelText: 'Alarm Sound',
                          border: OutlineInputBorder(),
                        ),
                        items: ['river', 'bird', 'rain'].map((String sound) {
                          return DropdownMenuItem<String>(
                            value: sound,
                            child: Text(sound),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSound = newValue!;
                          });
                        },
                      ),
                    ] else
                      Container(),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addHabit,
                      child: const Text('Add Habit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
