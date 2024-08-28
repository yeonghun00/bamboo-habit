import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class MyHabitsPage extends StatefulWidget {
  const MyHabitsPage({super.key});

  @override
  _MyHabitsPageState createState() => _MyHabitsPageState();
}

class _MyHabitsPageState extends State<MyHabitsPage> {
  List<Map<String, dynamic>> _habits = [];
  String _selectedDay = '';
  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadHabits();
    int todayIndex = DateTime.now().weekday - 1;
    _selectedDay = _weekDays[todayIndex];
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

  List<Map<String, dynamic>> _getHabitsForSelectedDay() {
    return _habits.where((habit) {
      List<String> days = habit['days'].split(',');
      return days.contains(_selectedDay) &&
          !(habit['completedDays'] as List).contains(_selectedDay);
    }).toList();
  }

  Future<void> _markHabitAsCompleted(Map<String, dynamic> habit) async {
    setState(() {
      (habit['completedDays'] as List).add(_selectedDay);
    });
    final prefs = await SharedPreferences.getInstance();
    int completedHabits = prefs.getInt('completedHabits') ?? 0;
    prefs.setInt('completedHabits', completedHabits + 1);

    DateTime now = DateTime.now();
    String todayKey = 'completed_${now.year}-${now.month}-${now.day}';
    await prefs.setBool(todayKey, true);

    _saveHabits();

    // Cancel today's notification and reschedule for the next day
    await _cancelAndRescheduleNotification(habit);
  }

  Future<void> _cancelAndRescheduleNotification(
      Map<String, dynamic> habit) async {
    // Cancel today's notification
    final prefs = await SharedPreferences.getInstance();
    List<String> notificationIds =
        prefs.getStringList('notification_ids') ?? [];
    if (notificationIds.isNotEmpty) {
      for (String id in notificationIds) {
        await flutterLocalNotificationsPlugin.cancel(int.parse(id));
      }
    }

    // Reschedule for the next occurrence
    DateTime now = DateTime.now();
    String nextDay = _getNextDay(_selectedDay);
    DateTime scheduledTime = _nextInstanceOfDay(nextDay, habit['time']);
    await _scheduleNotification(scheduledTime, habit['name'],
        "Time to complete your habit: ${habit['name']}!");
  }

  String _getNextDay(String currentDay) {
    int index = _weekDays.indexOf(currentDay);
    return _weekDays[(index + 1) % _weekDays.length];
  }

  DateTime _nextInstanceOfDay(String day, String time) {
    int dayOffset = {
      'Mon': DateTime.monday,
      'Tue': DateTime.tuesday,
      'Wed': DateTime.wednesday,
      'Thu': DateTime.thursday,
      'Fri': DateTime.friday,
      'Sat': DateTime.saturday,
      'Sun': DateTime.sunday,
    }[day]!;

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

    DateTime scheduledTime = DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, hour, minute);

    while (scheduledTime.weekday != dayOffset) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    return scheduledTime;
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

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> habitsForSelectedDay =
        _getHabitsForSelectedDay();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Habits'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              'Today\'s Habits',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: habitsForSelectedDay.length,
                itemBuilder: (context, index) {
                  return _buildHabitCard(habitsForSelectedDay[index]);
                },
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 5.0,
                  children: _weekDays.take(5).map((day) {
                    return RawChip(
                      shape: const StadiumBorder(side: BorderSide.none),
                      showCheckmark: false,
                      label: Text(day),
                      selected: _selectedDay == day,
                      selectedColor: Colors.green,
                      checkmarkColor: Colors.transparent,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedDay = day;
                        });
                      },
                    );
                  }).toList(),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 5.0,
                  children: _weekDays.skip(5).map((day) {
                    return RawChip(
                      shape: const StadiumBorder(side: BorderSide.none),
                      showCheckmark: false,
                      label: Text(day),
                      selected: _selectedDay == day,
                      selectedColor: Colors.green,
                      checkmarkColor: Colors.transparent,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedDay = day;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(Map<String, dynamic> habit) {
    DateTime now = DateTime.now();
    int todayIndex = now.weekday - 1;
    String todayDay = _weekDays[todayIndex];

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              IconData(int.parse(habit['icon']!), fontFamily: 'MaterialIcons'),
              size: 30.0,
              color: Theme.of(context).iconTheme.color,
            ),
            const SizedBox(height: 8.0),
            Text(
              habit['name']!,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Location: ${habit['location']}',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.0,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Time: ${habit['time']}',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.0,
                  ),
            ),
            const SizedBox(height: 8.0),
            if (_selectedDay == todayDay)
              ElevatedButton(
                onPressed: () async {
                  _markHabitAsCompleted(habit);
                },
                child: const Text('Mark as Completed'),
              ),
          ],
        ),
      ),
    );
  }
}
