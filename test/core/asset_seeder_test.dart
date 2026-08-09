import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/storage/asset_seeder.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('asset_seeder_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AssetSeeder', () {
    test('seed() copies every bundled mock file into the documents/mock dir', () async {
      await AssetSeeder().seed();

      for (final fileName in AssetSeeder.mockFileNames) {
        final file = File('${tempDir.path}/mock/$fileName');
        expect(await file.exists(), isTrue, reason: '$fileName should have been seeded');
      }
    });

    test('seed() is idempotent — does not overwrite an existing (user-modified) file', () async {
      await AssetSeeder().seed();

      final usersFile = File('${tempDir.path}/mock/users.json');
      await usersFile.writeAsString(jsonEncode({'status': 'success', 'data': []}));

      await AssetSeeder().seed(); // run again, without force

      final content = jsonDecode(await usersFile.readAsString()) as Map<String, dynamic>;
      expect(content['data'], isEmpty); // the user-modified copy survived
    });

    test('seed(force: true) overwrites back to the bundled seed', () async {
      await AssetSeeder().seed();

      final usersFile = File('${tempDir.path}/mock/users.json');
      await usersFile.writeAsString(jsonEncode({'status': 'success', 'data': []}));

      await AssetSeeder().seed(force: true);

      final content = jsonDecode(await usersFile.readAsString()) as Map<String, dynamic>;
      expect(content['data'], isNotEmpty); // restored from the bundled asset
    });
  });
}
