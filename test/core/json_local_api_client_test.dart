import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/storage/json_local_api_client.dart';
import 'package:foodie_app/core/storage/local_api_client.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late JsonLocalApiClient storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('json_storage_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir);
    storage = JsonLocalApiClient();

    final mockDir = Directory('${tempDir.path}/mock')..createSync(recursive: true);
    File('${mockDir.path}/things.json').writeAsStringSync(jsonEncode({
      'status': 'success',
      'message': 'seed',
      'data': [
        {'id': '1', 'name': 'first'},
      ],
    }));
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('JsonLocalApiClient', () {
    test('readCollection returns the "data" array', () async {
      final result = await storage.readCollection('things.json');

      expect(result, [
        {'id': '1', 'name': 'first'},
      ]);
    });

    test('readCollection throws JsonStorageException for a missing file', () async {
      expect(
        () => storage.readCollection('nope.json'),
        throwsA(isA<JsonStorageException>()),
      );
    });

    test('writeCollection rewrites "data" while preserving the rest of the envelope', () async {
      await storage.writeCollection('things.json', [
        {'id': '2', 'name': 'second'},
      ]);

      final file = File('${tempDir.path}/mock/things.json');
      final envelope = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      expect(envelope['status'], 'success');
      expect(envelope['message'], 'seed');
      expect(envelope['data'], [
        {'id': '2', 'name': 'second'},
      ]);
    });

    test('a write is immediately visible to a subsequent read', () async {
      await storage.writeCollection('things.json', [
        {'id': '3', 'name': 'third'},
      ]);

      final result = await storage.readCollection('things.json');

      expect(result.single['id'], '3');
    });
  });
}
