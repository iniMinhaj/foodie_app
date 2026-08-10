/// Thrown by a [LocalApiClient] implementation on any read/write failure —
/// callers translate this into a typed [Failure] at the datasource
/// boundary, never let it leak as a generic [Exception].
class JsonStorageException implements Exception {
  final String message;
  const JsonStorageException(this.message);

  @override
  String toString() => 'JsonStorageException: $message';
}

/// Reads/writes the `data` array of a named collection
/// (`{status, message, meta?, data: [...]}` envelope). Named like a real
/// API client on purpose — today it's backed by local JSON files
/// ([JsonLocalApiClient]), but nothing above this boundary should care how
/// a given implementation actually stores or fetches the data.
abstract class LocalApiClient {
  Future<List<Map<String, dynamic>>> readCollection(String fileName);

  Future<void> writeCollection(String fileName, List<Map<String, dynamic>> data);
}
