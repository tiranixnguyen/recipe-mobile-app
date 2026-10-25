import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/presentation/search/search_view_model.dart';

class RecordingAnalytics implements Analytics {
  final events = <(String, Map<String, Object>?)>[];
  @override
  void track(String event, [Map<String, Object>? params]) => events.add((event, params));
}

void main() {
  test('query và bộ lọc cập nhật kết quả; analytics không chứa query', () async {
    final analytics = RecordingAnalytics();
    final container = ProviderContainer(
      overrides: [
        analyticsProvider.overrideWithValue(analytics),
        ingredientsProvider.overrideWith((ref) async => const <Ingredient>[]),
        recipesProvider.overrideWith((ref) async => const <Recipe>[]),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(searchViewModelProvider, (_, _) {});
    final vm = container.read(searchViewModelProvider.notifier);
    vm.initialize(query: 'trứng', maxMinutes: 15, tool: Tool.rice);
    expect(subscription.read().query, 'trứng');
    expect(subscription.read().maxMinutes, 15);
    vm.toggleMinutes(15);
    expect(subscription.read().maxMinutes, isNull);
    vm.submit();
    expect(analytics.events.single.$1, 'search');
    expect(analytics.events.single.$2, {'has_query': true, 'filtered': true});
    expect(analytics.events.single.$2.toString(), isNot(contains('trứng')));
    vm.setQuery('');
    vm.toggleTool(Tool.rice);
    vm.submit();
    expect(analytics.events.last.$2, {'has_query': false, 'filtered': false});
  });
}
