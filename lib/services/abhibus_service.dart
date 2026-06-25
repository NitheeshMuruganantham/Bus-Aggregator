import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bus_model.dart';
import '../data/mock_data.dart';
import 'api_service.dart';

class AbhiBusService implements BusApiService {
  static const String baseUrl = 'https://api.abhibus.com/v1';
  static const String apiKey = 'YOUR_ABHIBUS_API_KEY_HERE';

  @override
  Future<List<BusModel>> searchBuses({
    required String from,
    required String to,
    required String date,
    required String timeSlot,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/buses/search?from=$from&to=$to&date=$date',
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List busList = data['buses'] ?? [];
        return busList.map((bus) => BusModel.fromJson(bus)).toList();
      } else {
        return getMockBuses();
      }
    } catch (e) {
      return getMockBuses();
    }
  }
}
