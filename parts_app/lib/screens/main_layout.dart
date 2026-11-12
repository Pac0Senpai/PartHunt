import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'garage_screen.dart';
import 'oem_search_screen.dart';
import 'saved_parts_screen.dart';
import 'account_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Συνάρτηση που ανανεώνει ακαριαία το MainLayout (και το Burger Menu)
  void _updateProfile() {
    setState(() {});
  }

  late final List<Widget> _screens = [
    const GarageScreen(),
    const OemSearchScreen(),
    const SavedPartsScreen(),
    AccountScreen(onProfileUpdated: _updateProfile),
  ];

  final List<String> _titles = [
    'Το Γκαράζ μου',
    'Αναζήτηση OEM',
    'Αποθηκευμένα Parts',
    'Ο Λογαριασμός μου',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.surface),
              accountName: Text(
                FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty ==
                        true
                    ? FirebaseAuth.instance.currentUser!.displayName!
                    : 'Χρήστης PartHunt',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              accountEmail: Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                backgroundImage:
                    FirebaseAuth.instance.currentUser?.photoURL != null
                    ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                    : null,
                child: FirebaseAuth.instance.currentUser?.photoURL == null
                    ? Icon(Icons.person, color: theme.colorScheme.primary)
                    : null,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.directions_car,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Γκαράζ'),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: Icon(Icons.search, color: theme.colorScheme.primary),
              title: const Text('Αναζήτηση OEM'),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: Icon(Icons.bookmark, color: theme.colorScheme.primary),
              title: const Text('Αποθηκευμένα Parts'),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: Icon(Icons.person, color: theme.colorScheme.primary),
              title: const Text('Λογαριασμός'),
              onTap: () => _onItemTapped(3),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: Icon(Icons.settings, color: theme.colorScheme.primary),
              title: const Text('Ρυθμίσεις'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Αποσύνδεση',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () async {
                await GoogleSignIn().signOut();
                await FirebaseAuth.instance.signOut();

                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
    );
  }
}
