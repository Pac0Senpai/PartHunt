import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manual_search_screen.dart';
import 'vin_scanner_screen.dart';
import '../services/vin_api_service.dart';

class VehicleSetupScreen extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> vehicleData;
  final String userId;

  const VehicleSetupScreen({
    Key? key,
    required this.vehicleId,
    required this.vehicleData,
    required this.userId,
  }) : super(key: key);

  @override
  State<VehicleSetupScreen> createState() => _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends State<VehicleSetupScreen> {
  final TextEditingController _vinController = TextEditingController();

  @override
  void dispose() {
    _vinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.vehicleData['brand'] ?? '';
    final model = widget.vehicleData['model'] ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ταυτοποίηση Οχήματος')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Για να σου βρούμε τα ακριβή ανταλλακτικά, βοήθησέ μας να εντοπίσουμε την ακριβή έκδοση του $brand $model σου.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Επιλογή 1: Γρήγορη εύρεση',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _vinController,
              decoration: InputDecoration(
                labelText: 'Εισαγωγή αριθμού πλαισίου (VIN)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: theme.colorScheme.surface, // Δυναμικό φόντο πεδίου
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.camera_alt,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () async {
                    final scannedVin = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VinScannerScreen(),
                      ),
                    );

                    if (scannedVin != null &&
                        scannedVin.toString().trim().isNotEmpty) {
                      final vinString = scannedVin.toString().trim();

                      setState(() {
                        _vinController.text = vinString;
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Αναζήτηση στοιχείων οχήματος...'),
                            backgroundColor: Colors.blueGrey,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }

                      final vehicleDetails = await VinApiService.decodeVin(
                        vinString,
                      );

                      final updateData = <String, dynamic>{'vin': vinString};

                      if (vehicleDetails != null) {
                        updateData['brand'] = vehicleDetails['make'];
                        updateData['model'] = vehicleDetails['model'];
                        updateData['year'] = vehicleDetails['year'];
                        updateData['engine'] = vehicleDetails['engine'];
                      }

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userId)
                          .collection('vehicles')
                          .doc(widget.vehicleId)
                          .update(updateData);

                      if (context.mounted) {
                        Navigator.pop(context);

                        final successMessage = vehicleDetails != null
                            ? 'Βρέθηκε: ${vehicleDetails['make']} ${vehicleDetails['model']}!'
                            : 'Το VIN αποθηκεύτηκε επιτυχώς (χωρίς αυτόματη ανάλυση).';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(successMessage),
                            backgroundColor: theme.colorScheme.primary,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              onSubmitted: (value) async {
                final vinString = value.trim();
                if (vinString.isNotEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Αναζήτηση στοιχείων οχήματος...'),
                        backgroundColor: Colors.blueGrey,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  final vehicleDetails = await VinApiService.decodeVin(
                    vinString,
                  );

                  final updateData = <String, dynamic>{'vin': vinString};

                  if (vehicleDetails != null) {
                    updateData['brand'] = vehicleDetails['make'];
                    updateData['model'] = vehicleDetails['model'];
                    updateData['year'] = vehicleDetails['year'];
                    updateData['engine'] = vehicleDetails['engine'];
                  }

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userId)
                      .collection('vehicles')
                      .doc(widget.vehicleId)
                      .update(updateData);

                  if (context.mounted) {
                    Navigator.pop(context);

                    final successMessage = vehicleDetails != null
                        ? 'Βρέθηκε: ${vehicleDetails['make']} ${vehicleDetails['model']}!'
                        : 'Το VIN αποθηκεύτηκε επιτυχώς.';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(successMessage),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    );
                  }
                }
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text('— Ή —', style: TextStyle(color: Colors.grey)),
              ),
            ),

            const Text(
              'Επιλογή 2: Χειροκίνητη επιλογή',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textTheme.bodyLarge?.color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                ),
                icon: const Icon(Icons.filter_list),
                label: const Text(
                  'Χρήση δυναμικών φίλτρων',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManualSearchScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
