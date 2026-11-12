import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Προεπιλογή: Σκοτεινό θέμα (επειδή έτσι έχεις σχεδιάσει το app ως τώρα)
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Αλλάζει το θέμα και το αποθηκεύει
  void toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    notifyListeners(); // Ειδοποιεί την εφαρμογή να επανασχεδιαστεί

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }

  // Διαβάζει το θέμα κατά την εκκίνηση της εφαρμογής
  _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  // --- ΟΡΙΣΜΟΣ ΤΩΝ THEMES (ΧΡΩΜΑΤΑ) ---

  // Το υπάρχον Σκοτεινό σου Θέμα (Dark Mode)
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), // Το γενικό φόντο
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF1E1F22), // Το χρώμα των κουτιών/καρτών σου
      primary: Colors.tealAccent, // Το βασικό σου χρώμα
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.tealAccent;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return Colors.tealAccent.withOpacity(0.5);
        return Colors.white24;
      }),
    ),
  );

  // Το νέο Φωτεινό σου Θέμα (Light Mode)
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[100], // Ανοιχτό γκρι φόντο
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[100],
      foregroundColor: Colors.black, // Μαύρα γράμματα στο AppBar
      elevation: 0,
    ),
    colorScheme: const ColorScheme.light(
      surface: Colors.white, // Λευκές κάρτες/κουτιά
      primary: Colors.teal, // Ένα πιο σκούρο teal για να φαίνεται στο λευκό
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.teal;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return Colors.teal.withOpacity(0.5);
        return Colors.black26;
      }),
    ),
  );
}
