import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_setup_screen.dart';
import 'manual_search_screen.dart';

class OemSearchScreen extends StatelessWidget {
  const OemSearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Διαβάζουμε το τρέχον θέμα
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const SizedBox(height: 10),
        const Text(
          'Πώς θέλεις να αναζητήσεις ανταλλακτικά;',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            // Αφαιρέθηκε το Colors.white για να προσαρμόζεται αυτόματα
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Επίλεξε τον τρόπο που σε εξυπηρετεί καλύτερα.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 30),

        _buildSearchOptionCard(
          context,
          icon: Icons.tag,
          title: 'Αναζήτηση με Κωδικό',
          subtitle: 'Εισαγωγή κωδικού OEM ή Aftermarket',
          onTap: () {},
          theme: theme,
        ),

        _buildSearchOptionCard(
          context,
          icon: Icons.directions_car,
          title: 'Επιλογή από το Γκαράζ',
          subtitle: 'Βρες ανταλλακτικά συμβατά με τα οχήματά σου',
          isPrimary: true,
          theme: theme,
          onTap: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;

            final snapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('vehicles')
                .where('isActive', isEqualTo: true)
                .limit(1)
                .get();
            if (!context.mounted) return;

            if (snapshot.docs.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Παρακαλώ επίλεξε ένα ενεργό όχημα στο Γκαράζ σου.',
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }

            final vehicleData = snapshot.docs.first.data();
            final vehicleId = snapshot.docs.first.id;

            final vin = vehicleData['vin'] ?? '';

            if (vin.toString().trim().isEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VehicleSetupScreen(
                    vehicleId: vehicleId,
                    vehicleData: vehicleData,
                    userId: user.uid,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Φόρτωση blueprints για VIN: $vin...'),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
            }
          },
        ),

        _buildSearchOptionCard(
          context,
          icon: Icons.tune,
          title: 'Χειροκίνητη Αναζήτηση',
          subtitle: 'Αναζήτηση μέσω φίλτρων',
          theme: theme,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManualSearchScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isPrimary = false,
  }) {
    // Χρησιμοποιούμε το χρώμα primary (Teal) αν είναι isPrimary, αλλιώς το default χρώμα κειμένου
    final primaryColor = theme.colorScheme.primary;
    final defaultTextColor = theme.textTheme.bodyLarge?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Δυναμικό φόντο κάρτας
        borderRadius: BorderRadius.circular(16),
        border: isPrimary
            ? Border.all(color: primaryColor.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1), // Δυναμικό γκρι
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isPrimary ? primaryColor : defaultTextColor,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isPrimary
                              ? primaryColor
                              : null, // Το null παίρνει το αυτόματο
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
