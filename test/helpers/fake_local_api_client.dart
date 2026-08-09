import 'package:foodie_app/core/storage/local_api_client.dart';

/// Pure-Dart in-memory fake for datasource/repository tests — no Flutter,
/// no path_provider faking, no real file I/O. Seed collections up front or
/// via `writeCollection`; use [peek] to assert what a datasource wrote.
class FakeLocalApiClient implements LocalApiClient {
  FakeLocalApiClient([Map<String, List<Map<String, dynamic>>>? seed])
      : _collections = {
          for (final entry in (seed ?? const {}).entries) entry.key: List.of(entry.value),
        };

  final Map<String, List<Map<String, dynamic>>> _collections;

  @override
  Future<List<Map<String, dynamic>>> readCollection(String fileName) async {
    final data = _collections[fileName];
    if (data == null) {
      throw JsonStorageException('No such collection: $fileName');
    }
    return List.of(data);
  }

  @override
  Future<void> writeCollection(String fileName, List<Map<String, dynamic>> data) async {
    _collections[fileName] = List.of(data);
  }

  /// Test-only accessor for asserting what got written, without touching disk.
  List<Map<String, dynamic>>? peek(String fileName) => _collections[fileName];
}
