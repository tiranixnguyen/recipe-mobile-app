import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Nơi lưu dữ liệu cá nhân trên máy (app không có đăng nhập).
///
/// Mỗi feature tự đặt key có tiền tố tên feature, ví dụ `favorites.ids`, để không đụng nhau.
abstract interface class LocalStore {
  List<String> readList(String key);
  Future<void> writeList(String key, List<String> value);
}

class InMemoryLocalStore implements LocalStore {
  final _data = <String, List<String>>{};

  @override
  List<String> readList(String key) => _data[key] ?? const [];

  @override
  Future<void> writeList(String key, List<String> value) async => _data[key] = value;
}

class SharedPrefsLocalStore implements LocalStore {
  SharedPrefsLocalStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  List<String> readList(String key) => _prefs.getStringList(key) ?? const [];

  @override
  Future<void> writeList(String key, List<String> value) => _prefs.setStringList(key, value);
}

/// Mặc định in-memory (dùng cho test); `main.dart` override bằng [SharedPrefsLocalStore].
final localStoreProvider = Provider<LocalStore>((ref) => InMemoryLocalStore());
