import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Προστέθηκε το import του provider
import 'package:parts_app/screens/login_screen.dart';
import 'package:parts_app/screens/main_layout.dart';
import '../providers/theme_provider.dart'; // Το σωστό path για τον ThemeProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    // Τυλίγουμε την εφαρμογή με τον Provider για να είναι διαθέσιμος παντού
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const PartsApp(),
    ),
  );
}

class PartsApp extends StatelessWidget {
  const PartsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Διαβάζουμε το τρέχον theme από τον ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'PartHunt',
      debugShowCheckedModeBanner: false,
      //Εδώ το app αποφασίζει δυναμικά αν θα δείξει το Light ή το Dark mode
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme:
          themeProvider.lightTheme, // Τραβάει το φωτεινό θέμα από το provider
      darkTheme:
          themeProvider.darkTheme, // Τραβάει το σκοτεινό θέμα από το provider
      home: FirebaseAuth.instance.currentUser == null
          ? const LoginScreen()
          : const MainLayout(),
    );
  }
}
