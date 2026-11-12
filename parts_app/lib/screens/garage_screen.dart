import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_detail_screen.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({Key? key}) : super(key: key);

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  String _getBrandLogoUrl(String brand) {
    String formattedBrand = brand.toLowerCase().trim();
    formattedBrand = formattedBrand.replaceAll(RegExp(r'\s+'), '-');
    return 'https://vl.imgix.net/img/$formattedBrand-logo.png';
  }

  void _showAddVehicleModal(BuildContext context, ThemeData theme) {
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface, // Δυναμικό φόντο modal
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Vehicle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: brandController,
                decoration: const InputDecoration(
                  labelText: 'Μάρκα (π.χ. Chevrolet, Audi)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Μοντέλο (π.χ. Aveo, A3)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Έτος (π.χ. 2012)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final brand = brandController.text.trim();
                    final model = modelController.text.trim();
                    final year = yearController.text.trim();

                    if (brand.isNotEmpty && model.isNotEmpty) {
                      Navigator.pop(context);

                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        () async {
                          final querySnapshot = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('vehicles')
                              .get();

                          bool isFirst = querySnapshot.docs.isEmpty;

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('vehicles')
                              .add({
                                'brand': brand,
                                'model': model,
                                'year': year.isNotEmpty ? year : '2000',
                                'vin': '',
                                'bodyStyle': '',
                                'country': '',
                                'engineDesc': '',
                                'engineSerial': '',
                                'engineType': '',
                                'engine': '',
                                'modelCode': '',
                                'notes': '',
                                'isActive': isFirst,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                        }();
                      }
                    }
                  },
                  child: const Text(
                    'Αποθήκευση Οχήματος',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      body: user == null
          ? const Center(child: Text('Παρακαλώ συνδεθείτε.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('vehicles')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Σφάλμα φόρτωσης',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    const Text(
                      'Vehicles',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (docs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Δεν υπάρχουν οχήματα στο γκαράζ.\nΠάτησε "Add Vehicle" παρακάτω.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                      ),

                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final docId = doc.id;
                      final bool isActive = data['isActive'] ?? false;
                      final logoUrl = _getBrandLogoUrl(data['brand'] ?? '');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme
                              .colorScheme
                              .surface, // Δυναμικό φόντο κάρτας
                          borderRadius: BorderRadius.circular(16),
                          border: isActive
                              ? Border.all(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.5,
                                  ),
                                  width: 1.5,
                                )
                              : Border.all(color: Colors.transparent, width: 1),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            if (!isActive) {
                              final batch = FirebaseFirestore.instance.batch();
                              final querySnapshot = await FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('vehicles')
                                  .get();
                              for (var document in querySnapshot.docs) {
                                batch.update(document.reference, {
                                  'isActive': false,
                                });
                              }
                              final selectedDocRef = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('vehicles')
                                  .doc(docId);
                              batch.update(selectedDocRef, {'isActive': true});
                              await batch.commit();
                            }
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isActive
                                      ? theme.colorScheme.primary
                                      : Colors.grey.withOpacity(0.4),
                                  width: 2,
                                ),
                                color: theme.brightness == Brightness.dark
                                    ? Colors.black26
                                    : Colors.grey[200],
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.network(
                                    logoUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => Icon(
                                      Icons.directions_car,
                                      color: isActive
                                          ? theme.colorScheme.primary
                                          : Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              '${data['brand']} ${data['model']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${data['year']} ${data['brand']} ${data['model']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VehicleDetailScreen(
                                      vehicleId: docId,
                                      vehicleData: data,
                                      userId: user.uid,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Add Vehicle',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Icon(
                          Icons.add,
                          color: theme.colorScheme.primary,
                        ),
                        onTap: () => _showAddVehicleModal(context, theme),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
