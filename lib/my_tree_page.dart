import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class MyTreePage extends StatefulWidget {
  const MyTreePage({super.key});

  @override
  _MyTreePageState createState() => _MyTreePageState();
}

class _MyTreePageState extends State<MyTreePage> with TickerProviderStateMixin {
  int _completedHabits = 0;
  int _streak = 0;
  int _level = 1;
  String _bambooName = 'My Bamboo';
  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  final Map<int, List<String>> _sentencesByLevel = {
    1: [
      "Goo goo ga ga!",
      "I'm just a baby tree!",
      "I love sunlight!",
      "Where's my water?",
      "I need a nap!",
      "Yummy, nutrients!",
      "I want to grow big!",
      "What's this world?",
      "Everything is new!",
      "I feel safe with you!"
    ],
    2: [
      "Yay! I did it!",
      "Look at me grow!",
      "I'm getting stronger!",
      "Watch me reach for the sky!",
      "I can do it myself!",
      "I'm learning so much!",
      "I like playing!",
      "Isn't this fun?",
      "I want more sunlight!",
      "I'm so happy!"
    ],
    3: [
      "I'm getting bigger!",
      "I love to play and learn!",
      "School is fun!",
      "Look, I'm growing up!",
      "I can do it!",
      "I want to know everything!",
      "I'm becoming smarter!",
      "Friends are the best!",
      "Learning is awesome!",
      "Let's explore the world!"
    ],
    4: [
      "Leave me alone!",
      "You don't understand me!",
      "I'm finding myself!",
      "I can handle this!",
      "Why are you always on my case?",
      "I want my own space!",
      "Stop telling me what to do!",
      "I'm not a kid anymore!",
      "I need some freedom!",
      "Let me make my own choices!"
    ],
    5: [
      "I'm ready to conquer the world!",
      "Let's do this!",
      "I'm full of energy!",
      "The future is mine!",
      "Nothing can stop me!",
      "I'm so excited!",
      "I'm going to achieve great things!",
      "College life is amazing!",
      "I'm learning so much!",
      "I can't wait for what's next!"
    ],
    6: [
      "Keep going, you're doing great!",
      "Hard work pays off!",
      "Focus on your goals!",
      "Every step counts!",
      "You're building something amazing!",
      "Stay disciplined!",
      "You're on the right path!",
      "Success is a journey!",
      "Believe in your abilities!",
      "You're stronger than you think!"
    ],
    7: [
      "Stay focused, you're almost there!",
      "Success is near!",
      "Keep your eyes on the prize!",
      "Perseverance is key!",
      "You've come so far!",
      "Don't lose momentum!",
      "You have the experience!",
      "You're wiser now!",
      "The end goal is in sight!",
      "You're closer than you think!"
    ],
    8: [
      "Wisdom comes with age.",
      "Patience is key to greatness.",
      "You've seen it all.",
      "Calmness is strength.",
      "You know what truly matters.",
      "Experience is the best teacher.",
      "Stay grounded.",
      "You've learned from every step.",
      "Balance is everything.",
      "You're a guiding light."
    ],
    9: [
      "I have seen a lot, and I know what matters.",
      "Calm and steady wins the race.",
      "Every moment is a lesson.",
      "Peace comes from within.",
      "You are a source of wisdom.",
      "Clarity of mind is your power.",
      "You see things as they are.",
      "Simplicity is the ultimate sophistication.",
      "You appreciate the little things.",
      "You inspire others with your wisdom."
    ],
    10: [
      "I'm old and wise, but still learning.",
      "Every day is a new opportunity.",
      "I've seen it all, but I still grow.",
      "Wisdom and knowledge are endless.",
      "I've been through so much.",
      "I cherish every moment.",
      "Age is just a number, growth is eternal.",
      "I'm a fountain of wisdom.",
      "I'm here to share my knowledge.",
      "Life is a beautiful journey."
    ]
  };

  final List<String> _commonSentences = [
    "How are you doing?",
    "Are you done already???",
    "Are you gonna live like this for all your life?",
    "Live like you are gonna die today.",
    "Shut up and make habits!",
    "Push yourself because no one else is going to do it for you.",
    "Don't stop until you're proud.",
    "Dream big and dare to fail.",
    "Do something today that your future self will thank you for.",
    "Success doesn't just find you. You have to go out and get it.",
    "The harder you work for something, the greater you'll feel when you achieve it.",
    "Wake up with determination. Go to bed with satisfaction.",
    "Don't watch the clock; do what it does. Keep going.",
    "Believe you can and you're halfway there.",
    "You don't have to be great to start, but you have to start to be great.",
    "Stop touching me and do the work.",
    "I am happy that you are here.",
    "I like you.",
    "Thanks for a small step.",
    "You can do this!",
    "Keep pushing forward!",
    "Make today count!",
    "Don't give up!",
    "Keep it up!",
    "You are stronger than you think."
  ];

  String _currentSentence = '';

  final List<Color> bambooColors = [
    Colors.green[300]!,
    Colors.green[400]!,
    Colors.green[500]!,
    Colors.green[600]!,
    Colors.green[700]!
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadBambooName();
    _fadeController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 2, end: 0).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: .1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: .1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: .1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: .1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: .1),
    ]).animate(_shakeController);
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedHabits = prefs.getInt('completedHabits') ?? 0;
      _streak = prefs.getInt('streak') ?? 0;
      _calculateLevel();
    });

    // Check if habits were completed today, else reset streak
    DateTime now = DateTime.now();
    String todayKey = 'completed_$now';
    if (prefs.getBool(todayKey) ?? false) {
      // Habits were completed today, increment streak
      setState(() {
        _streak++;
      });
      await prefs.setInt('streak', _streak);
    } else {
      // No habits were completed today, reset streak
      setState(() {
        _streak = 0;
      });
      await prefs.setInt('streak', _streak);
    }
  }

  Future<void> _loadBambooName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bambooName = prefs.getString('bambooName') ?? 'My Bamboo';
    });
  }

  void _calculateLevel() {
    if (_completedHabits >= 300 && _streak >= 100) {
      _level = 10;
    } else if (_completedHabits >= 150 && _streak >= 50) {
      _level = 9;
    } else if (_completedHabits >= 100 && _streak >= 30) {
      _level = 8;
    } else if (_completedHabits >= 80 && _streak >= 30) {
      _level = 7;
    } else if (_completedHabits >= 50 && _streak >= 20) {
      _level = 6;
    } else if (_completedHabits >= 30 && _streak >= 10) {
      _level = 5;
    } else if (_completedHabits >= 30) {
      _level = 4;
    } else if (_completedHabits >= 10) {
      _level = 3;
    } else if (_completedHabits >= 1) {
      _level = 2;
    } else {
      _level = 1;
    }
  }

  double _calculateProgressToNextLevel() {
    if (_level >= 10) {
      return 1.0;
    } else if (_level == 9) {
      return (_completedHabits - 150) / (300 - 150);
    } else if (_level == 8) {
      return (_completedHabits - 100) / (150 - 100);
    } else if (_level == 7) {
      return (_completedHabits - 80) / (100 - 80);
    } else if (_level == 6) {
      return (_completedHabits - 50) / (80 - 50);
    } else if (_level == 5) {
      return (_completedHabits - 30) / (50 - 30);
    } else if (_level == 4) {
      return (_completedHabits - 30) / (30 - 30);
    } else if (_level == 3) {
      return (_completedHabits - 10) / (30 - 10);
    } else if (_level == 2) {
      return (_completedHabits - 1) / (10 - 1);
    } else {
      return _completedHabits / 1.0;
    }
  }

  String _nextLevelRequirements() {
    if (_level >= 10) {
      return "You have reached the maximum level!";
    } else if (_level == 9) {
      return "Achieve 300 completed habits and a 100-day streak to reach the next level.";
    } else if (_level == 8) {
      return "Achieve 150 completed habits and a 50-day streak to reach the next level.";
    } else if (_level == 7) {
      return "Achieve 100 completed habits and a 30-day streak to reach the next level.";
    } else if (_level == 6) {
      return "Achieve 80 completed habits and a 30-day streak to reach the next level.";
    } else if (_level == 5) {
      return "Achieve 50 completed habits and a 20-day streak to reach the next level.";
    } else if (_level == 4) {
      return "Achieve 30 completed habits and a 10-day streak to reach the next level.";
    } else if (_level == 3) {
      return "Achieve 30 completed habits to reach the next level.";
    } else if (_level == 2) {
      return "Achieve 10 completed habits to reach the next level.";
    } else {
      return "Achieve 1 completed habit to reach the next level.";
    }
  }

  void _onScreenTapped() {
    final random = Random();
    setState(() {
      final levelSentences = _sentencesByLevel[_level]!;
      final allSentences = List<String>.from(levelSentences)
        ..addAll(_commonSentences);
      _currentSentence = allSentences[random.nextInt(allSentences.length)];
      _fadeController.reset();
      _fadeController.forward();
      _shakeController.reset();
      _shakeController.forward();
    });
  }

  Widget _buildBamboo() {
    int numSticks = min(
        _level + 1, 10); // Ensure the number of sticks is within a valid range
    int colorIndex =
        (_level - 1) ~/ 2; // Determine the color based on the level

    List<Widget> levels = [];
    // Add a top spacer with the same color as the background to create the "air" effect.
    levels.add(Container(
      height:
          100, // Adjust this height to create more or less space above the bamboo
      width: 100,
      color: Colors.transparent, // Use transparent to blend with the background
    ));

    for (int i = 0; i < numSticks; i++) {
      levels.add(Container(
        height: 40,
        width: 10 + (i >= 4 ? 2 : 0) + (i >= 7 ? 2 : 0),
        color: bambooColors[colorIndex.clamp(0, bambooColors.length - 1)],
        margin: const EdgeInsets.symmetric(vertical: 2.0),
      ));
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: levels,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScreenTapped,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bamboo'),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        Text(
                          'Level: $_level',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _bambooName,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildBamboo(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Flexible(
                      flex: 4,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'Completed Habits: $_completedHabits',
                            style: const TextStyle(fontSize: 20),
                          ),
                          Text(
                            'Current Streak: $_streak',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _nextLevelRequirements(),
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          LinearProgressIndicator(
                            value: _calculateProgressToNextLevel(),
                            minHeight: 20,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                bambooColors[(_level ~/ 2)
                                    .clamp(0, bambooColors.length - 1)]),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: _streak / 100,
                            minHeight: 20,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.green[700]!),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_currentSentence.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _currentSentence,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
