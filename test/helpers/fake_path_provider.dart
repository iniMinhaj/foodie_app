import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Redirects `getApplicationDocumentsDirectory()` to a throwaway temp
/// directory, so storage tests never touch a real device path.
class FakePathProviderPlatform extends PathProviderPlatform {
  final Directory tempDir;

  FakePathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;
}
