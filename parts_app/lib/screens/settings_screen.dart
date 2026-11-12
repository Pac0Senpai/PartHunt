import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart'; // Το path για τον Provider

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Διαβάζουμε το τρέχον θέμα (ώστε να πάρουμε τα δυναμικά χρώματα)
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ρυθμίσεις Εφαρμογής')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Εμφάνιση',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme
                  .colorScheme
                  .surface, // Δυναμικό φόντο (αντί για 0xFF1E1F22)
              borderRadius: BorderRadius.circular(16),
            ),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  // Το κείμενο παίρνει αυτόματα το σωστό χρώμα (Μαύρο στο Light, Λευκό στο Dark)
                  title: const Text('Σκοτεινή Λειτουργία (Dark Mode)'),
                  subtitle: const Text(
                    'Αλλάζει την εμφάνιση της εφαρμογής',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  value: themeProvider.isDarkMode,
                  activeColor: theme.colorScheme.primary, // Δυναμικό teal
                  onChanged: (val) {
                    themeProvider.toggleTheme(val);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Δεδομένα',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(
                Icons.cleaning_services,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Εκκαθάριση προσωρινής μνήμης (Cache)'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Η μνήμη cache εκκαθαρίστηκε επιτυχώς!',
                    ),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ΝΕΑ ΚΑΤΗΓΟΡΙΑ: Βοήθεια & Υποστήριξη
          const Text(
            'Βοήθεια και Υποστήριξη',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.help_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Συχνές Ερωτήσεις (FAQ)'),
                  onTap: () {
                    // TODO: Να ανοίγει η οθόνη FAQ
                  },
                ),
                // Δυναμική διαχωριστική γραμμή
                Divider(
                  color: Colors.grey.withOpacity(0.2),
                  height: 1,
                  indent: 50,
                ),
                ListTile(
                  leading: Icon(
                    Icons.bug_report_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Επικοινωνία & Αναφορά Σφαλμάτων'),
                  onTap: () {
                    // TODO: Να ανοίγει φόρμα ή email
                  },
                ),
              ],
            ),
          ),

          // Στοιχείο Έκδοσης στο κάτω μέρος
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'Έκδοση 1.0.0 (Version)',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
