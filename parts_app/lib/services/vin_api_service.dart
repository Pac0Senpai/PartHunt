import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class VinApiService {
  static const String _baseUrl =
      'https://vpic.nhtsa.dot.gov/api/vehicles/decodevin/';

  static Future<Map<String, String>?> decodeVin(String vin) async {
    try {
      final url = Uri.parse('$_baseUrl$vin?format=json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['Results'] as List<dynamic>;

        String make = '';
        String model = '';
        String year = '';
        String engineCC = '';
        String engineL = '';

        for (var item in results) {
          final variable = item['Variable']?.toString();
          final value = item['Value']?.toString();

          if (value != null && value != 'null' && value.isNotEmpty) {
            if (variable == 'Make') make = value;
            if (variable == 'Model') model = value;
            if (variable == 'Model Year') year = value;
            if (variable == 'Displacement (CC)') engineCC = value;
            if (variable == 'Displacement (L)') engineL = value;
          }
        }

        // Στρογγυλοποίηση και μορφοποίηση του κινητήρα (π.χ. 1255)
        String finalEngine = '';
        if (engineCC.isNotEmpty) {
          double? cc = double.tryParse(engineCC);
          if (cc != null) {
            finalEngine = '${cc.round()}';
          } else {
            finalEngine = engineCC;
          }
        } else if (engineL.isNotEmpty) {
          double? l = double.tryParse(engineL);
          if (l != null) {
            finalEngine = '${(l * 1000).round()}';
          } else {
            finalEngine = engineL;
          }
        }

        if (make.isNotEmpty && model.isNotEmpty) {
          return {
            'make': make,
            'model': model,
            'year': year,
            'engine': finalEngine,
          };
        }
      } else {
        debugPrint("Σφάλμα HTTP: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Σφάλμα κατά την αποκωδικοποίηση του VIN: $e");
    }

    return null;
  }
}
