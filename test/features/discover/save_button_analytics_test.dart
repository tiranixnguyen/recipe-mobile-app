import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/presentation/save_button_view_model.dart';

class _Events implements Analytics {
  final records = <(String, Map<String, Object>?)>[];
  @override
  void track(String event, [Map<String, Object>? params]) => records.add((event, params));
}

class _FailingStore extends InMemoryLocalStore {
  @override
  Future<void> writeList(String key, List<String> value) =>
      Future.error(StateError('write failed'));
}

void main() {
  test('lưu và bỏ lưu: mỗi lần thành công một event, không gửi id', () async {
    final events = _Events();
    final store = InMemoryLocalStore();
    final container = ProviderContainer(
      overrides: [
        analyticsProvider.overrideWithValue(events),
        localStoreProvider.overrideWith((ref) => store),
      ],
    );
    addTearDown(container.dispose);
    final vm = container.read(saveButtonViewModelProvider.notifier);
    await vm.toggle('private-recipe-id');
    expect(container.read(savedIdsProvider), contains('private-recipe-id'));
    expect(store.readList('discover.saved'), ['private-recipe-id']);
    expect(events.records.map((r) => r.$1), ['save_recipe']);
    expect(events.records.single.$2, {'saved': true});

    await vm.toggle('private-recipe-id');
    expect(container.read(savedIdsProvider), isEmpty);
    expect(store.readList('discover.saved'), isEmpty);
    expect(events.records.map((r) => r.$1), ['save_recipe', 'save_recipe']);
    expect(events.records.last.$2, {'saved': false});
  });

  test('hai lượt bấm nhanh được ghi tuần tự, analytics phản ánh cả hai', () async {
    final events = _Events();
    final store = InMemoryLocalStore();
    final container = ProviderContainer(
      overrides: [
        analyticsProvider.overrideWithValue(events),
        localStoreProvider.overrideWith((ref) => store),
      ],
    );
    addTearDown(container.dispose);
    final vm = container.read(saveButtonViewModelProvider.notifier);
    await Future.wait([vm.toggle('a'), vm.toggle('a')]);
    expect(container.read(savedIdsProvider), isEmpty);
    expect(store.readList('discover.saved'), isEmpty);
    expect(events.records.map((r) => r.$1), ['save_recipe', 'save_recipe']);
    expect(events.records.first.$2, {'saved': true});
    expect(events.records.last.$2, {'saved': false});
  });

  test('ghi dữ liệu thất bại: không đổi state và không phát event', () async {
    final events = _Events();
    final container = ProviderContainer(
      overrides: [
        analyticsProvider.overrideWithValue(events),
        localStoreProvider.overrideWith((ref) => _FailingStore()),
      ],
    );
    addTearDown(container.dispose);
    expect(
      container.read(saveButtonViewModelProvider.notifier).toggle('private-recipe-id'),
      throwsStateError,
    );
    expect(container.read(savedIdsProvider), isEmpty);
    expect(events.records, isEmpty);
  });
}
