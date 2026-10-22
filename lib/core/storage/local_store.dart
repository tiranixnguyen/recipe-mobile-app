import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Nơi lưu dữ liệu cá nhân trên máy (app không có đăng nhập).
///
/// Mỗi feature tự đặt key có tiền tố tên feature, ví dụ `pantry.items`, để không đụng nhau.
/// Dữ liệu có cấu trúc thì tự encode JSON rồi lưu bằng [writeString].
///
/// State đọc từ store phải `ref.watch(localStoreProvider)` trong `build` (không `ref.read`), để khi
/// [clearLocalDataProvider] xoá dữ liệu thì state đó dựng lại từ store rỗng.
abstract interface class LocalStore {
  String? readString(String key);
  Future<void> writeString(String key, String value);
  List<String> readList(String key);
  Future<void> writeList(String key, List<String> value);
  Future<void> remove(String key);

  /// Xoá toàn bộ dữ liệu đã lưu trên máy (dùng cho "Xoá dữ liệu" trong Cài đặt).
  Future<void> clearAll();
}

class InMemoryLocalStore implements LocalStore {
  final _data = <String, Object>{};

  @override
  String? readString(String key) => _data[key] as String?;

  @override
  Future<void> writeString(String key, String value) async => _data[key] = value;

  @override
  List<String> readList(String key) => (_data[key] as List<String>?) ?? const [];

  @override
  Future<void> writeList(String key, List<String> value) async =>
      _data[key] = List<String>.unmodifiable(value);

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  Future<void> clearAll() async => _data.clear();
}

class SharedPrefsLocalStore implements LocalStore {
  SharedPrefsLocalStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? readString(String key) => _prefs.getString(key);

  @override
  Future<void> writeString(String key, String value) => _prefs.setString(key, value);

  @override
  List<String> readList(String key) => _prefs.getStringList(key) ?? const [];

  @override
  Future<void> writeList(String key, List<String> value) => _prefs.setStringList(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);

  @override
  Future<void> clearAll() => _prefs.clear();
}

/// Mặc định in-memory (dùng cho test); `main.dart` override bằng [SharedPrefsLocalStore].
///
/// Override bằng `overrideWith` (không `overrideWithValue`) để [clearLocalDataProvider] tạo được
/// instance mới và báo cho mọi provider đang watch.
final localStoreProvider = Provider<LocalStore>((ref) => InMemoryLocalStore());

/// Xoá toàn bộ dữ liệu trên máy rồi dựng lại mọi state đang `ref.watch(localStoreProvider)`.
///
/// Màn Xoá dữ liệu gọi `await ref.read(clearLocalDataProvider)()` rồi `go` về Splash.
final clearLocalDataProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(localStoreProvider).clearAll();
    ref.invalidate(localStoreProvider);
  };
});
