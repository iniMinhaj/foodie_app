import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'local_api_client.dart';

/// [LocalApiClient] backed by a seeded mock JSON file living in the app's
/// documents directory — never touches `assets/mock/` directly, that's
/// [AssetSeeder]'s job.
class JsonLocalApiClient implements LocalApiClient {
  Future<Directory> _mockDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/mock');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _fileFor(String fileName) async {
    final dir = await _mockDir();
    return File('${dir.path}/$fileName');
  }

  @override
  Future<List<Map<String, dynamic>>> readCollection(String fileName) async {
    try {
      final file = await _fileFor(fileName);
      final raw = await file.readAsString();
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final data = envelope['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map<String, dynamic>) {
        return [data];
      }
      throw JsonStorageException('Unexpected "data" shape in $fileName');
    } on JsonStorageException {
      rethrow;
    } catch (e) {
      throw JsonStorageException('Failed to read $fileName: $e');
    }
  }

  /// Rewrites the whole file, preserving its existing envelope
  /// (`status`/`message`/`meta`) but replacing `data` with [data].
  @override
  Future<void> writeCollection(String fileName, List<Map<String, dynamic>> data) async {
    try {
      final file = await _fileFor(fileName);
      Map<String, dynamic> envelope;
      if (await file.exists()) {
        final raw = await file.readAsString();
        envelope = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        envelope = {'status': 'success', 'message': fileName};
      }
      envelope['data'] = data;
      await file.writeAsString(jsonEncode(envelope));
    } catch (e) {
      throw JsonStorageException('Failed to write $fileName: $e');
    }
  }
}
