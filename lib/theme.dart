import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(0xFF4CAF50), // Green
      scaffoldBackgroundColor:
          const Color(0xFFF1F8E9), // Very light green background
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32), // Dark Green
        ),
        titleLarge: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Color(0xFF388E3C), // Medium Green
        ),
        bodyMedium: TextStyle(
          fontSize: 16.0,
          color: Colors.black, // Black text for light theme
        ),
      ),
      appBarTheme: const AppBarTheme(
        color: Color(0xFF4CAF50), // Green
        titleTextStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0.0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF4CAF50), // Green
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(8.0), // Smaller radius for a sharper look
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(const Color(0xFF4CAF50)), // Green
        trackColor:
            WidgetStateProperty.all(const Color(0xFF81C784)), // Light Green
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          borderSide: BorderSide(
            color: Color(0xFF4CAF50), // Green
          ),
        ),
        labelStyle: TextStyle(
          color: Color(0xFF388E3C), // Medium Green
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF4CAF50), // Green
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardTheme(
        color: Colors.white,
        elevation: 2.0, // Lower elevation for a cleaner look
        margin: EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF2E7D32), // Dark Green
        unselectedItemColor: Color(0xFF81C784), // Light Green
        backgroundColor: Color(0xFFF1F8E9), // Very light green
      ),
      iconTheme: const IconThemeData(
          color: Colors.black), // Icon color for light theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[300]!,
        selectedColor: const Color(0xFF4CAF50),
        secondarySelectedColor: const Color(0xFF388E3C),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        labelStyle: const TextStyle(
          color: Colors.black,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
        ),
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: const MaterialColor(
          0xFF4CAF50,
          {
            50: Color(0xFFE8F5E9),
            100: Color(0xFFC8E6C9),
            200: Color(0xFFF1F8E9),
            300: Color(0xFF81C784),
            400: Color(0xFF66BB6A),
            500: Color(0xFF4CAF50),
            600: Color(0xFF43A047),
            700: Color(0xFF388E3C),
            800: Color(0xFF2E7D32),
            900: Color(0xFF1B5E20),
          },
        ),
      ).copyWith(
        secondary: const Color(0xFF81C784), // Light Green for accents
        surface: const Color(
            0xFFF1F8E9), // Very light green background for simplicity
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF388E3C), // Dark Green
      scaffoldBackgroundColor: const Color.fromARGB(
          255, 0, 46, 15), // Dark background for simplicity
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: Color(0xFFA5D6A7), // Light Green
        ),
        titleLarge: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Color(0xFF81C784), // Light Green
        ),
        bodyMedium: TextStyle(
          fontSize: 16.0,
          color: Colors.white, // White text for dark theme
        ),
      ),
      appBarTheme: const AppBarTheme(
        color: Color(0xFF388E3C), // Dark Green
        titleTextStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0.0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF388E3C), // Dark Green
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(8.0), // Smaller radius for a sharper look
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor:
            WidgetStateProperty.all(const Color(0xFF388E3C)), // Dark Green
        trackColor:
            WidgetStateProperty.all(const Color(0xFF66BB6A)), // Medium Green
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          borderSide: BorderSide(
            color: Color(0xFF388E3C), // Dark Green
          ),
        ),
        labelStyle: TextStyle(
          color: Color(0xFF66BB6A), // Medium Green
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF388E3C), // Dark Green
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardTheme(
        color: Color(0xFF2C2C2C), // Slightly lighter dark color
        elevation: 2.0, // Lower elevation for a cleaner look
        margin: EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF66BB6A), // Light Green
        unselectedItemColor: Color(0xFFA5D6A7), // Light Green
        backgroundColor: Color(0xFF121212), // Dark background
      ),
      iconTheme:
          const IconThemeData(color: Colors.white), // Icon color for dark theme
      chipTheme: const ChipThemeData(
        backgroundColor:
            Color.fromARGB(255, 21, 21, 21), // Slightly lighter dark color
        selectedColor: Color(0xFF388E3C),
        secondarySelectedColor: Color(0xFF66BB6A),
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        labelStyle: TextStyle(
          color: Colors.white, // Ensure white text for dark theme
        ),
        secondaryLabelStyle: TextStyle(
          color: Colors.black,
        ),
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: const MaterialColor(
          0xFF388E3C,
          {
            50: Color(0xFFE8F5E9),
            100: Color(0xFFC8E6C9),
            200: Color(0xFFA5D6A7),
            300: Color(0xFF81C784),
            400: Color(0xFF66BB6A),
            500: Color(0xFF388E3C),
            600: Color(0xFF2E7D32),
            700: Color(0xFF1B5E20),
            800: Color(0xFF004D40),
            900: Color(0xFF00251A),
          },
        ),
      ).copyWith(
        secondary: const Color(0xFF66BB6A), // Light Green for accents
        surface: const Color(0xFF121212), // Dark background for simplicity
      ),
    );
  }
}
