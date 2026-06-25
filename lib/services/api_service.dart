import '../models/bus_model.dart';
import '../data/mock_data.dart';

abstract class BusApiService {
  Future<List<BusModel>> searchBuses({
    required String from,
    required String to,
    required String date,
    required String timeSlot,
  });
}

class MockBusService implements BusApiService {
  @override
  Future<List<BusModel>> searchBuses({
    required String from,
    required String to,
    required String date,
    required String timeSlot,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return getMockBuses();
  }
}

class BusServiceFactory {
  static BusApiService getService() {
    return MockBusService();
  }
}
