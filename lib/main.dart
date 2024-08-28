import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'theme.dart';
import 'theme_notifier.dart';
import 'make_habit_page.dart';
import 'my_habits_page.dart';
import 'my_page.dart';
import 'my_tree_page.dart';
import 'manage_habits_page.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isDarkTheme = prefs.getBool('isDarkTheme') ?? false;

  // Initialize timezone database
  await _configureLocalTimeZone();

  // Initialize notification settings
  await _initializeNotifications();

  // Initialize Android Alarm Manager
  await AndroidAlarmManager.initialize();

  // Request notification permissions
  await _requestPermissions();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeNotifier(isDarkTheme),
      child: const HabitGardenApp(),
    ),
  );
}

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
          onDidReceiveLocalNotification: onDidReceiveLocalNotification);
  const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(defaultActionName: 'Open notification');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
    linux: initializationSettingsLinux,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
}

Future<void> _requestPermissions() async {
  if (await Permission.notification.isDenied) {
    PermissionStatus status = await Permission.notification.request();
    if (status != PermissionStatus.granted) {
      print('Notification permissions are not granted.');
    }
  }

  final AndroidFlutterLocalNotificationsPlugin? androidNotificationPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidNotificationPlugin!.requestNotificationsPermission();
  await androidNotificationPlugin.requestExactAlarmsPermission();
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) {
  // Handle notification tap here if needed
}

void onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  // Handle iOS notification tapped logic here
}

class HabitGardenApp extends StatelessWidget {
  const HabitGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HabitGarden',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 2;
  final List<Widget> _pages = [
    const MakeHabitPage(),
    const ManageHabitsPage(),
    const MyHabitsPage(),
    const MyTreePage(),
    const MyPage(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_outlined),
            label: 'Make Habit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Manage Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'My Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_florist),
            label: 'My Bamboo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'My Page',
          ),
        ],
      ),
    );
  }
}
