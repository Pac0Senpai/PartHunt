import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vin_scanner_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> vehicleData;
  final String userId;

  const VehicleDetailScreen({
    Key? key,
    required this.vehicleId,
    required this.vehicleData,
    required this.userId,
  }) : super(key: key);

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late TextEditingController _vinController;
  late TextEditingController _bodyStyleController;
  late TextEditingController _countryController;
  late TextEditingController _engineDescController;
  late TextEditingController _engineSerialController;
  late TextEditingController _engineTypeController;
  late TextEditingController _engineController;
  late TextEditingController _modelCodeController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final d = widget.vehicleData;
    _vinController = TextEditingController(text: d['vin'] ?? '');
    _bodyStyleController = TextEditingController(text: d['bodyStyle'] ?? '');
    _countryController = TextEditingController(text: d['country'] ?? '');
    _engineDescController = TextEditingController(text: d['engineDesc'] ?? '');
    _engineSerialController = TextEditingController(
      text: d['engineSerial'] ?? '',
    );
    _engineTypeController = TextEditingController(text: d['engineType'] ?? '');
    _engineController = TextEditingController(text: d['engine'] ?? '');
    _modelCodeController = TextEditingController(text: d['modelCode'] ?? '');
    _notesController = TextEditingController(text: d['notes'] ?? '');
  }

  @override
  void dispose() {
    _vinController.dispose();
    _bodyStyleController.dispose();
    _countryController.dispose();
    _engineDescController.dispose();
    _engineSerialController.dispose();
    _engineTypeController.dispose();
    _engineController.dispose();
    _modelCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String hint = '',
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          filled: true,
          fillColor: theme.colorScheme.surface, // Δυναμικό φόντο πεδίου
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.vehicleData;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('${car['brand']} ${car['model']}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface, // Δυναμικό φόντο κάρτας
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car['brand']} ${car['model']} (${car['year']})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          theme.colorScheme.primary, // Δυναμικό primary χρώμα
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Στοιχεία Οχήματος (EPC Data). Συμπληρώνονται αυτόματα μέσω VIN ή χειροκίνητα.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildField(
              context,
              'Αριθμός Πλαισίου (VIN)',
              _vinController,
              suffixIcon: IconButton(
                icon: Icon(Icons.camera_alt, color: theme.colorScheme.primary),
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

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('vehicles')
                        .doc(widget.vehicleId)
                        .update({'vin': vinString});

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Το VIN σαρώθηκε και αποθηκεύτηκε!',
                          ),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );
                    }
                  }
                },
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    context,
                    'Body Style',
                    _bodyStyleController,
                    hint: 'π.χ. 48',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    context,
                    'Country',
                    _countryController,
                    hint: 'π.χ. IT',
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    context,
                    'Engine Type',
                    _engineTypeController,
                    hint: 'π.χ. A12XER',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    context,
                    'Κυβισμός (API)',
                    _engineController,
                    hint: 'π.χ. 1.2L',
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    context,
                    'Model Code',
                    _modelCodeController,
                    hint: 'π.χ. J,1JH48',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    context,
                    'Engine Serial',
                    _engineSerialController,
                    hint: 'π.χ. 19WU9277',
                  ),
                ),
              ],
            ),

            _buildField(
              context,
              'Engine Description',
              _engineDescController,
              hint: 'π.χ. ENGINE GAS, 4 CYL',
            ),

            const SizedBox(height: 12),
            const Text(
              'Πρόσθετα',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            _buildField(
              context,
              'Σημειώσεις / Extra',
              _notesController,
              maxLines: 2,
            ),

            const SizedBox(height: 24),

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
              onPressed: () {
                FocusScope.of(context).unfocus();

                FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .collection('vehicles')
                    .doc(widget.vehicleId)
                    .update({
                      'vin': _vinController.text.trim(),
                      'bodyStyle': _bodyStyleController.text.trim(),
                      'country': _countryController.text.trim(),
                      'engineDesc': _engineDescController.text.trim(),
                      'engineSerial': _engineSerialController.text.trim(),
                      'engineType': _engineTypeController.text.trim(),
                      'engine': _engineController.text.trim(),
                      'modelCode': _modelCodeController.text.trim(),
                      'notes': _notesController.text.trim(),
                    });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Οι αλλαγές αποθηκεύτηκαν!'),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                );

                Navigator.pop(context);
              },
              child: const Text(
                'Αποθήκευση Αλλαγών',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text(
                'Διαγραφή Οχήματος',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      backgroundColor: theme.colorScheme.surface,
                      title: const Text('Διαγραφή Οχήματος'),
                      content: Text(
                        'Είσαι σίγουρος ότι θες να διαγράψεις το ${car['brand']} ${car['model']};',
                        style: const TextStyle(color: Colors.grey),
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
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.userId)
                                .collection('vehicles')
                                .doc(widget.vehicleId)
                                .delete();
                            Navigator.pop(dialogContext);
                            Navigator.pop(context);
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
      ),
    );
  }
}
