import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManualSearchScreen extends StatefulWidget {
  const ManualSearchScreen({Key? key}) : super(key: key);

  @override
  State<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends State<ManualSearchScreen> {
  // 1. Μάρκα
  String? selectedMakerId;
  String? selectedMakerName;

  // 2. Μοντέλο
  String? selectedModelName;

  // 3. Αμάξωμα / Σασί
  String? selectedBodyChassis;

  // 4. Έτος
  String? selectedYear;
  String?
  finalModelId; // Το πραγματικό Document ID του μοντέλου από το Firestore

  // 5. Κινητήρας
  String? selectedEngineId;
  String? selectedEngineName;

  // Helper για τη μορφοποίηση του Αμαξώματος & Σασί
  String _formatBodyChassis(Map<String, dynamic> data) {
    final body = data['body_style']?.toString() ?? '';
    final chassis = data['chassis_code']?.toString() ?? '';
    if (body.isEmpty && chassis.isEmpty) return 'Standard';
    if (body.isEmpty) return '($chassis)';
    if (chassis.isEmpty) return body;
    return '$body ($chassis)';
  }

  // Helper για τη μορφοποίηση του Κινητήρα
  String _formatEngine(Map<String, dynamic> data) {
    final type = data['engine_type']?.toString() ?? '';
    final cc = data['displacement_cc']?.toString() ?? '';
    final hp = data['horsepower']?.toString() ?? '';
    final code = data['engine_code']?.toString() ?? '';

    List<String> parts = [];
    if (type.isNotEmpty) parts.add(type);
    if (cc.isNotEmpty) parts.add(cc);
    if (hp.isNotEmpty) parts.add(hp);

    String result = parts.join(' - ');
    if (code.isNotEmpty) result += ' ($code)';
    if (result.trim().isEmpty) return 'Άγνωστη Έκδοση';
    return result;
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required bool isEnabled,
    required Function(String?) onChanged,
    required bool isLoading,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: isLoading ? '$label (Φόρτωση...)' : label,
          labelStyle: TextStyle(
            color: isEnabled ? Colors.grey : Colors.grey.withOpacity(0.4),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface, // Δυναμικό φόντο πεδίου
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabled: isEnabled && !isLoading,
        ),
        dropdownColor: theme.colorScheme.surface,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            : Icon(
                Icons.arrow_drop_down,
                color: isEnabled
                    ? theme.colorScheme.primary
                    : Colors.grey.withOpacity(0.4),
              ),
        items: isEnabled ? items : [],
        onChanged: isEnabled && !isLoading ? onChanged : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isSearchReady =
        selectedMakerId != null &&
        finalModelId != null &&
        selectedEngineId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Χειροκίνητη Αναζήτηση')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Βρες ανταλλακτικά βήμα-βήμα',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Επίλεξε τα χαρακτηριστικά του οχήματος για να εντοπίσεις τον ακριβή κατάλογο EPC.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                children: [
                  // --- ΒΗΜΑ 1: ΜΑΡΚΑ ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('catalog_makers')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      List<DropdownMenuItem<String>> items = [];
                      bool isLoading =
                          snapshot.connectionState == ConnectionState.waiting;

                      if (snapshot.hasData) {
                        items = snapshot.data!.docs.map((doc) {
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(doc['name']),
                          );
                        }).toList();
                      }

                      return _buildDropdown(
                        context: context,
                        label: '1. Μάρκα',
                        value: selectedMakerId,
                        items: items,
                        isEnabled: true,
                        isLoading: isLoading,
                        onChanged: (val) {
                          final name =
                              items
                                      .firstWhere((item) => item.value == val)
                                      .child
                                  as Text;
                          setState(() {
                            selectedMakerId = val;
                            selectedMakerName = name.data;
                            // Reset όλα τα επόμενα
                            selectedModelName = null;
                            selectedBodyChassis = null;
                            selectedYear = null;
                            finalModelId = null;
                            selectedEngineId = null;
                            selectedEngineName = null;
                          });
                        },
                      );
                    },
                  ),

                  // --- ΒΗΜΑΤΑ 2, 3, 4 ---
                  StreamBuilder<QuerySnapshot>(
                    stream: selectedMakerId != null
                        ? FirebaseFirestore.instance
                              .collection('catalog_models')
                              .where('maker_id', isEqualTo: selectedMakerId)
                              .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      bool isLoading =
                          snapshot.connectionState == ConnectionState.waiting &&
                          selectedMakerId != null;
                      List<QueryDocumentSnapshot> modelsDocs = snapshot.hasData
                          ? snapshot.data!.docs
                          : [];

                      // Λίστα για Βήμα 2 (Μοντέλα)
                      List<String> modelNames =
                          modelsDocs
                              .map((d) => d['model_name'] as String)
                              .toSet()
                              .toList()
                            ..sort();

                      // Λίστα για Βήμα 3 (Αμάξωμα/Σασί)
                      List<String> bodyChassisList = selectedModelName != null
                          ? (modelsDocs
                                .where(
                                  (d) => d['model_name'] == selectedModelName,
                                )
                                .map(
                                  (d) => _formatBodyChassis(
                                    d.data() as Map<String, dynamic>,
                                  ),
                                )
                                .toSet()
                                .toList()
                              ..sort())
                          : [];

                      // Λίστα για Βήμα 4 (Έτος)
                      List<String> yearsList = selectedBodyChassis != null
                          ? (modelsDocs
                                .where(
                                  (d) =>
                                      d['model_name'] == selectedModelName &&
                                      _formatBodyChassis(
                                            d.data() as Map<String, dynamic>,
                                          ) ==
                                          selectedBodyChassis,
                                )
                                .map((d) {
                                  String y = d['year']?.toString() ?? '';
                                  return y.isEmpty ? 'Όλα τα έτη' : y;
                                })
                                .toSet()
                                .toList()
                              ..sort())
                          : [];

                      return Column(
                        children: [
                          // 2. Dropdown Μοντέλου
                          _buildDropdown(
                            context: context,
                            label: '2. Μοντέλο',
                            value: selectedModelName,
                            items: modelNames
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            isEnabled: selectedMakerId != null,
                            isLoading: isLoading,
                            onChanged: (val) {
                              setState(() {
                                selectedModelName = val;
                                selectedBodyChassis = null;
                                selectedYear = null;
                                finalModelId = null;
                                selectedEngineId = null;
                                selectedEngineName = null;
                              });
                            },
                          ),

                          // 3. Dropdown Αμαξώματος/Σασί
                          _buildDropdown(
                            context: context,
                            label: '3. Αμάξωμα / Κωδικός',
                            value: selectedBodyChassis,
                            items: bodyChassisList
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            isEnabled: selectedModelName != null,
                            isLoading: false,
                            onChanged: (val) {
                              setState(() {
                                selectedBodyChassis = val;
                                selectedYear = null;
                                finalModelId = null;
                                selectedEngineId = null;
                                selectedEngineName = null;
                              });
                            },
                          ),

                          // 4. Dropdown Έτους
                          _buildDropdown(
                            context: context,
                            label: '4. Έτος',
                            value: selectedYear,
                            items: yearsList
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            isEnabled: selectedBodyChassis != null,
                            isLoading: false,
                            onChanged: (val) {
                              final doc = modelsDocs.firstWhere((d) {
                                String y = d['year']?.toString() ?? '';
                                String displayY = y.isEmpty ? 'Όλα τα έτη' : y;
                                return d['model_name'] == selectedModelName &&
                                    _formatBodyChassis(
                                          d.data() as Map<String, dynamic>,
                                        ) ==
                                        selectedBodyChassis &&
                                    displayY == val;
                              });

                              setState(() {
                                selectedYear = val;
                                finalModelId = doc.id;
                                selectedEngineId = null;
                                selectedEngineName = null;
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  // --- ΒΗΜΑ 5: ΚΙΝΗΤΗΡΑΣ ---
                  StreamBuilder<QuerySnapshot>(
                    stream: finalModelId != null
                        ? FirebaseFirestore.instance
                              .collection('catalog_engines')
                              .where('model_id', isEqualTo: finalModelId)
                              .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      List<DropdownMenuItem<String>> items = [];
                      bool isLoading =
                          snapshot.connectionState == ConnectionState.waiting &&
                          finalModelId != null;

                      if (snapshot.hasData) {
                        items = snapshot.data!.docs.map((doc) {
                          String engineDisplay = _formatEngine(
                            doc.data() as Map<String, dynamic>,
                          );
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(engineDisplay),
                          );
                        }).toList();
                      }

                      return _buildDropdown(
                        context: context,
                        label: '5. Κινητήρας / Έκδοση',
                        value: selectedEngineId,
                        items: items,
                        isEnabled: finalModelId != null,
                        isLoading: isLoading,
                        onChanged: (val) {
                          final name =
                              items
                                      .firstWhere((item) => item.value == val)
                                      .child
                                  as Text;
                          setState(() {
                            selectedEngineId = val;
                            selectedEngineName = name.data;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSearchReady
                      ? theme.colorScheme.primary
                      : (theme.brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[300]),
                  foregroundColor: isSearchReady
                      ? (theme.brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white)
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.search),
                label: const Text(
                  'Άνοιγμα Καταλόγου',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: isSearchReady
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Αναζήτηση: $selectedMakerName $selectedModelName\nΑμάξωμα: $selectedBodyChassis, Έτος: $selectedYear\nΚινητήρας: $selectedEngineName',
                            ),
                            backgroundColor: theme.colorScheme.primary,
                          ),
                        );
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
