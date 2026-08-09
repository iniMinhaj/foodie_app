import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../../../core/storage/local_api_client.dart';
import '../../models/user_model.dart';

/// Demo-grade salted hash — good enough to prove "never store plaintext"
/// in a portfolio project, not a production password scheme.
const _demoSalt = 'foodie_demo_salt_v1';

class AuthLocalDataSource {
  final LocalApiClient storage;
  static const _fileName = 'users.json';

  const AuthLocalDataSource(this.storage);

  Future<List<UserModel>> getAllUsers() async {
    final raw = await storage.readCollection(_fileName);
    return raw.map(UserModel.fromJson).toList();
  }

  Future<void> saveAllUsers(List<UserModel> users) {
    return storage.writeCollection(_fileName, users.map((u) => u.toJson()).toList());
  }

  String hashPassword(String password) {
    return sha256.convert(utf8.encode('$_demoSalt$password')).toString();
  }
}
