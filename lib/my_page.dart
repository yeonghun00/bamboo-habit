// https://chatgpt.com/c/39f5692b-a1a4-4641-a738-806b84d19365


import 'dart:typed_data';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final TextEditingController _bambooNameController = TextEditingController();
  bool _isDarkTheme = false;
  double _volume = 0.5;
  bool _vibrate = true;
  String? _alarmSound;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSettings();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tapped logic here
      },
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bambooNameController.text = prefs.getString('bambooName') ?? '';
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
      _volume = prefs.getDouble('volume') ?? 0.5;
      _vibrate = prefs.getBool('vibrate') ?? true;
      _alarmSound = prefs.getString('alarmSound');
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bambooName', _bambooNameController.text);
    await prefs.setBool('isDarkTheme', _isDarkTheme);
    await prefs.setDouble('volume', _volume);
    await prefs.setBool('vibrate', _vibrate);
    if (_alarmSound != null) {
      await prefs.setString('alarmSound', _alarmSound!);
    }

    // Update all notifications with the new vibration setting
    List<String> notificationIds =
        prefs.getStringList('notification_ids') ?? [];
    for (String id in notificationIds) {
      await _updateNotificationVibration(int.parse(id), _vibrate);
    }
  }

  Future<void> _updateNotificationVibration(int id, bool vibrate) async {
    print(vibrate);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'habit_channel_id',
      'habit_channel_name',
      channelDescription: 'Channel for habit reminders',
      importance: vibrate ? Importance.max : Importance.defaultImportance,
      priority: vibrate ? Priority.high : Priority.defaultPriority,
      playSound: true,
      enableVibration: vibrate,
      silent: vibrate ? false : true,
      vibrationPattern: vibrate ? Int64List.fromList([0, 1000]) : null,
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Retrieve the scheduled notification time from the current notification
    final prefs = await SharedPreferences.getInstance();
    List<String>? notificationTimes = prefs.getStringList('notification_times');
    if (notificationTimes != null && notificationTimes.length > id) {
      DateTime scheduledNotificationTime =
          DateTime.parse(notificationTimes[id]);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Habit Reminder',
        'Updated vibration setting for your habit reminder.',
        tz.TZDateTime.from(scheduledNotificationTime, tz.local),
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _bambooNameController,
              decoration: const InputDecoration(
                labelText: 'Enter your bamboo garden name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _saveSettings();
              },
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text(
                'Dark Theme',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              value: _isDarkTheme,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (bool value) {
                setState(() {
                  _isDarkTheme = value;
                  if (value) {
                    themeNotifier.switchToDark();
                  } else {
                    themeNotifier.switchToLight();
                  }
                });
                _saveSettings();
              },
            ),
            ListTile(
              title: Text(
                'Alarm Sound',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: DropdownButton<String>(
                value: _alarmSound,
                items:
                    <String>['Sound1', 'Sound2', 'Sound3'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _alarmSound = newValue;
                  });
                  _saveSettings();
                },
              ),
            ),
            ListTile(
              title: Text(
                'Volume',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Slider(
                value: _volume,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (double value) {
                  setState(() {
                    _volume = value;
                  });
                  _saveSettings();
                },
              ),
            ),
            SwitchListTile(
              title: Text(
                'Vibrate',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              value: _vibrate,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (bool value) {
                setState(() {
                  _vibrate = value;
                });
                _saveSettings();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
