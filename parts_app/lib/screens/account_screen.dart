import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const AccountScreen({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameController = TextEditingController();
  bool _receiveUpdates = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          if (data.containsKey('screenName')) {
            _nameController.text = data['screenName'];
          }
          if (data.containsKey('receiveUpdates')) {
            setState(() {
              _receiveUpdates = data['receiveUpdates'];
            });
          }
        }
      } catch (e) {
        print('ΣΦΑΛΜΑ ΦΟΡΤΩΣΗΣ: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newName = _nameController.text.trim();

      // 1. Ενημερώνουμε το Firebase Auth και ανανεώνουμε το token/user session
      await user.updateDisplayName(newName);
      await user.reload();

      // 2. Ειδοποίηση του MainLayout για άμεση αλλαγή στο burger menu
      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Το προφίλ ενημερώθηκε επιτυχώς!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      print('ΣΦΑΛΜΑ ΑΠΟΘΗΚΕΥΣΗΣ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Σφάλμα: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.surface,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text
                      : (user?.displayName ?? 'Χρήστης PartHunt'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            'Στοιχεία Λογαριασμού',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Πεδίο Screen Name με εικονίδιο ανθρώπου
          TextField(
            controller: _nameController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Όνομα Χρήστη (Screen Name)',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                Icons.person_outline,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Πεδίο Email (Μη επεξεργάσιμο - για λόγους ασφαλείας / login)
          TextField(
            readOnly: true,
            controller: TextEditingController(
              text: user?.email ?? 'Χωρίς Email',
            ),
            decoration: InputDecoration(
              labelText: 'Email (Λογαριασμού)',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: theme.colorScheme.surface.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),

          // Checkbox / Switch για Updates & Διαφημιστικό Υλικό
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text(
                'Λήψη updates & διαφημιστικού υλικού',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Μάθε πρώτος για νέα χαρακτηριστικά και προσφορές',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              value: _receiveUpdates,
              activeColor: theme.colorScheme.primary,
              onChanged: (val) {
                setState(() {
                  _receiveUpdates = val;
                });
              },
            ),
          ),
          const SizedBox(height: 20),

          // Κουμπί Αποθήκευσης Αλλαγών Προφίλ
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Αποθήκευση Αλλαγών',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
          const SizedBox(height: 24),

          // Subscription Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Κατάσταση Συνδρομής',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Standard Plan (Δωρεάν)',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Οι συνδρομές PRO έρχονται σύντομα!'),
                      ),
                    );
                  },
                  child: const Text('Upgrade'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Delete Account Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text(
              'Διαγραφή Λογαριασμού',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    backgroundColor: theme.colorScheme.surface,
                    title: const Text('Διαγραφή Λογαριασμού'),
                    content: const Text(
                      'Είσαι σίγουρος; Αυτή η ενέργεια είναι μόνιμη και θα διαγράψει όλα τα δεδομένα σου.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    actions: [
                      TextButton(
                        child: const Text(
                          'Ακύρωση',
                          style: TextStyle(color: Colors.grey),
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                      TextButton(
                        child: const Text(
                          'Διαγραφή',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          try {
                            await user?.delete();
                            await GoogleSignIn().signOut();
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Απαιτείται πρόσφατη σύνδεση για διαγραφή: $e',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
