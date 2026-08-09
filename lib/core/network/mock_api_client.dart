// core/network/mock_api_client.dart
import '../storage/local_json_store.dart';

class MockApiClient {
  final LocalJsonStore _store;

  MockApiClient({required LocalJsonStore store}) : _store = store;

  Future<Map<String, dynamic>> load(String assetPath,
      {int latencyMs = 600}) async {
    await Future.delayed(Duration(milliseconds: latencyMs));
    return _store.read(assetPath);
  }

  Future<void> save(String assetPath, Map<String, dynamic> data,
      {int latencyMs = 300}) async {
    await Future.delayed(Duration(milliseconds: latencyMs));
    return _store.write(assetPath, data);
  }
}
