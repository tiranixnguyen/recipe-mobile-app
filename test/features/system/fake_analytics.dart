import 'package:recipe_mobile_app/core/analytics.dart';

/// Ghi lại sự kiện thay vì gửi đi: [events] là tên, [params] là tham số cùng thứ tự.
class FakeAnalytics implements Analytics {
  final events = <String>[];
  final params = <Map<String, Object>?>[];

  @override
  void track(String event, [Map<String, Object>? params]) {
    events.add(event);
    this.params.add(params);
  }
}
