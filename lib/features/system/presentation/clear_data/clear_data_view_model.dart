import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

/// Dòng gợi ý dưới ô xác nhận.
enum ClearDataHint { locked, mismatch, matched }

class ClearDataState {
  const ClearDataState({this.typed = '', this.clearing = false});

  /// Chữ người dùng đang gõ vào ô xác nhận.
  final String typed;

  /// Đang xoá — View khoá nút để không bấm hai lần.
  final bool clearing;

  /// Gõ đúng [SystemStrings.clearDataPhrase] (bỏ qua khoảng trắng hai đầu) thì mới mở nút Xoá hết.
  bool get matched => typed.trim() == SystemStrings.clearDataPhrase;

  ClearDataHint get hint => matched
      ? ClearDataHint.matched
      : typed.isEmpty
      ? ClearDataHint.locked
      : ClearDataHint.mismatch;
}

class ClearDataViewModel extends Notifier<ClearDataState> {
  @override
  ClearDataState build() => const ClearDataState();

  void type(String text) => state = ClearDataState(typed: text, clearing: state.clearing);

  /// Xoá toàn bộ dữ liệu trên máy. Không làm gì khi chưa gõ khớp. View tự điều hướng sau khi xong.
  Future<void> clear() async {
    if (!state.matched || state.clearing) return;
    state = ClearDataState(typed: state.typed, clearing: true);
    await ref.read(clearLocalDataProvider)();
  }
}

final clearDataViewModelProvider = NotifierProvider.autoDispose<ClearDataViewModel, ClearDataState>(
  ClearDataViewModel.new,
);
