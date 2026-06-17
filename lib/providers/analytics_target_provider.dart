import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_target_provider.g.dart';

/// A one-shot request to open the Analytics screen at a specific greenhouse and
/// tab (e.g. from the plant-alert badge "View all" link). [AnalyticsView] reads
/// it on build, applies it, then clears it.
typedef AnalyticsTargetState = ({int greenhouseId, int tabIndex});

@riverpod
class AnalyticsTarget extends _$AnalyticsTarget {
  @override
  AnalyticsTargetState? build() => null;

  void set(int greenhouseId, int tabIndex) =>
      state = (greenhouseId: greenhouseId, tabIndex: tabIndex);

  void clear() => state = null;
}
