import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/analytics_model.dart';
import '../../models/flowerpot_model.dart';
import '../../models/plant_alert_model.dart';
import '../../models/greenhouse_model.dart';
import '../../models/parameter_model.dart';
import '../../models/zone_model.dart';
import '../../generated/l10n.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/analytics_target_provider.dart';
import '../../providers/greenhouse_notifier.dart';
import '../../providers/plant_alert_provider.dart';

// ─── Colour palette for multi-line charts ─────────────────────────────────────

const _chartColors = [
  Color(0xFF2196F3), // blue
  Color(0xFF4CAF50), // green
  Color(0xFFFF5722), // deep-orange
  Color(0xFF9C27B0), // purple
  Color(0xFFFF9800), // amber
  Color(0xFF00BCD4), // cyan
  Color(0xFFE91E63), // pink
  Color(0xFF795548), // brown
];

Color _colorFor(int index) => _chartColors[index % _chartColors.length];

String _rangeLabel(BuildContext context, AnalyticsRange r) {
  final s = S.of(context);
  return switch (r) {
    AnalyticsRange.last24h => s.analyticsRangeLast24h,
    AnalyticsRange.last7d => s.analyticsRangeLast7d,
    AnalyticsRange.last30d => s.analyticsRangeLast30d,
  };
}

// ─── Top-level view ───────────────────────────────────────────────────────────

class AnalyticsView extends ConsumerStatefulWidget {
  const AnalyticsView({super.key});

  @override
  ConsumerState<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends ConsumerState<AnalyticsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // ── Selection state ──────────────────────────────────────────────────────────
  int? _selectedGreenhouseId;
  EntityLevel _level = EntityLevel.greenhouse;
  int? _selectedEntityId; // zone or flowerpot id when level != greenhouse
  Set<int> _selectedParamIds = {};
  AnalyticsRange _range = AnalyticsRange.last24h;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ─── Refresh ─────────────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    await ref.read(greenhouseNotifierProvider.notifier).silentRefresh();
    for (final id in _selectedParamIds) {
      ref.invalidate(
          parameterHistoryProvider(parameterId: id, range: _range));
    }
    if (_selectedGreenhouseId != null) {
      ref.invalidate(greenhouseEventsProvider(
          greenhouseId: _selectedGreenhouseId!, range: _range));
      ref.invalidate(greenhouseStatsProvider(
          greenhouseId: _selectedGreenhouseId!, range: _range));
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Greenhouse? _selectedGreenhouse(List<Greenhouse> ghs) =>
      ghs.where((g) => g.id == _selectedGreenhouseId).firstOrNull;

  List<Zone> _zones(Greenhouse? gh) => gh?.zones ?? [];

  List<Flowerpot> _flowerpots(Greenhouse? gh) =>
      gh?.zones.expand((z) => z.flowerpots).toList() ?? [];

  /// Returns the parameter list for the currently selected level + entity.
  List<Parameter> _currentParameters(Greenhouse? gh) {
    if (gh == null) return [];
    switch (_level) {
      case EntityLevel.greenhouse:
        return gh.parameters;
      case EntityLevel.zone:
        if (_selectedEntityId == null) return [];
        return gh.zones
                .where((z) => z.id == _selectedEntityId)
                .firstOrNull
                ?.parameters ??
            [];
      case EntityLevel.flowerpot:
        if (_selectedEntityId == null) return [];
        for (final zone in gh.zones) {
          final fp =
              zone.flowerpots.where((f) => f.id == _selectedEntityId).firstOrNull;
          if (fp != null) return fp.parameters;
        }
        return [];
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ghAsync = ref.watch(greenhouseNotifierProvider);

    // Honour a deep-link request (e.g. from the plant-alert badge "View all"):
    // select the requested greenhouse + tab, then clear the one-shot target.
    final target = ref.watch(analyticsTargetProvider);
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedGreenhouseId = target.greenhouseId);
        if (target.tabIndex >= 0 && target.tabIndex < _tabs.length) {
          _tabs.animateTo(target.tabIndex);
        }
        ref.read(analyticsTargetProvider.notifier).clear();
      });
    }

    return ghAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(S.of(context).error(e))),
      data: (greenhouses) {
        // Auto-select the first greenhouse on initial load
        if (_selectedGreenhouseId == null && greenhouses.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedGreenhouseId = greenhouses.first.id);
          });
        }
        final gh = _selectedGreenhouse(greenhouses);

        // Read the master analytics-enabled flag so both data tabs can react.
        final settingsAsync = ref.watch(analyticsSettingsNotifierProvider);
        final analyticsEnabled =
            settingsAsync.valueOrNull?.analyticsEnabled ?? true;

        return Column(
          children: [
            _GreenhouseSelector(
              greenhouses: greenhouses,
              selectedId: _selectedGreenhouseId,
              onChanged: (id) => setState(() {
                _selectedGreenhouseId = id;
                _selectedEntityId = null;
                _selectedParamIds = {};
              }),
            ),
            _LevelAndEntitySelector(
              level: _level,
              zones: _zones(gh),
              flowerpots: _flowerpots(gh),
              selectedEntityId: _selectedEntityId,
              onLevelChanged: (l) => setState(() {
                _level = l;
                _selectedEntityId = null;
                _selectedParamIds = {};
              }),
              onEntityChanged: (id) => setState(() {
                _selectedEntityId = id;
                _selectedParamIds = {};
              }),
            ),
            _RangeChips(
              selected: _range,
              onChanged: (r) => setState(() => _range = r),
              onRefresh: _refresh,
            ),
            _buildTabBar(context),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ParametersTab(
                    parameters: _currentParameters(gh),
                    selectedParamIds: _selectedParamIds,
                    range: _range,
                    analyticsEnabled: analyticsEnabled,
                    onSelectionChanged: (ids) =>
                        setState(() => _selectedParamIds = ids),
                  ),
                  _EventsTab(
                    greenhouseId: _selectedGreenhouseId,
                    range: _range,
                    analyticsEnabled: analyticsEnabled,
                  ),
                  _LogsTab(greenhouseId: _selectedGreenhouseId),
                  _PlantHealthTab(greenhouseId: _selectedGreenhouseId),
                  const _SettingsTab(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final s = S.of(context);
    return TabBar(
      controller: _tabs,
      isScrollable: true,
      tabs: [
        Tab(icon: const Icon(Icons.show_chart), text: s.analyticsTabParameters),
        Tab(icon: const Icon(Icons.history), text: s.analyticsTabEvents),
        Tab(icon: const Icon(Icons.terminal), text: s.analyticsTabLogs),
        Tab(icon: const Icon(Icons.local_florist), text: s.analyticsTabPlants),
        Tab(icon: const Icon(Icons.settings), text: s.analyticsTabSettings),
      ],
    );
  }
}

// ─── Greenhouse selector ──────────────────────────────────────────────────────

class _GreenhouseSelector extends StatelessWidget {
  const _GreenhouseSelector({
    required this.greenhouses,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Greenhouse> greenhouses;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (greenhouses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(S.of(context).analyticsNoGreenhouses,
            style: const TextStyle(color: Colors.grey)),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DropdownButtonFormField<int>(
        decoration: InputDecoration(
          labelText: S.of(context).analyticsGreenhouse,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        value: selectedId,
        items: greenhouses
            .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Level + entity selector ──────────────────────────────────────────────────

class _LevelAndEntitySelector extends StatelessWidget {
  const _LevelAndEntitySelector({
    required this.level,
    required this.zones,
    required this.flowerpots,
    required this.selectedEntityId,
    required this.onLevelChanged,
    required this.onEntityChanged,
  });

  final EntityLevel level;
  final List<Zone> zones;
  final List<Flowerpot> flowerpots;
  final int? selectedEntityId;
  final ValueChanged<EntityLevel> onLevelChanged;
  final ValueChanged<int?> onEntityChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level chips
          Row(
            children: EntityLevel.values.map((l) {
              final label = switch (l) {
                EntityLevel.greenhouse => S.of(context).analyticsGreenhouse,
                EntityLevel.zone => S.of(context).analyticsZone,
                EntityLevel.flowerpot => S.of(context).analyticsFlowerpot,
              };
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: level == l,
                  onSelected: (_) => onLevelChanged(l),
                ),
              );
            }).toList(),
          ),
          // Entity dropdown (only shown when level ≠ greenhouse)
          if (level == EntityLevel.zone && zones.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: S.of(context).analyticsZone,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              value: selectedEntityId,
              hint: Text(S.of(context).analyticsSelectZone),
              items: zones
                  .map((z) => DropdownMenuItem(value: z.id, child: Text(z.name)))
                  .toList(),
              onChanged: onEntityChanged,
            ),
          ],
          if (level == EntityLevel.flowerpot && flowerpots.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: S.of(context).analyticsFlowerpot,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              value: selectedEntityId,
              hint: Text(S.of(context).analyticsSelectFlowerpot),
              items: flowerpots
                  .map((fp) => DropdownMenuItem(value: fp.id, child: Text(fp.name)))
                  .toList(),
              onChanged: onEntityChanged,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Range chips ──────────────────────────────────────────────────────────────

class _RangeChips extends StatelessWidget {
  const _RangeChips({
    required this.selected,
    required this.onChanged,
    this.onRefresh,
  });

  final AnalyticsRange selected;
  final ValueChanged<AnalyticsRange> onChanged;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          ...AnalyticsRange.values.map((r) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_rangeLabel(context, r)),
                  selected: r == selected,
                  onSelected: (_) => onChanged(r),
                ),
              )),
          const Spacer(),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              iconSize: 22,
              tooltip: S.of(context).analyticsRefresh,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

// ─── Parameters tab ───────────────────────────────────────────────────────────

class _ParametersTab extends StatelessWidget {
  const _ParametersTab({
    required this.parameters,
    required this.selectedParamIds,
    required this.range,
    required this.analyticsEnabled,
    required this.onSelectionChanged,
  });

  final List<Parameter> parameters;
  final Set<int> selectedParamIds;
  final AnalyticsRange range;
  final bool analyticsEnabled;
  final ValueChanged<Set<int>> onSelectionChanged;

  bool get _allSelected =>
      parameters.every((p) => p.id != null && selectedParamIds.contains(p.id));

  @override
  Widget build(BuildContext context) {
    if (!analyticsEnabled) return const _DisabledBanner();

    if (parameters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            S.of(context).analyticsNoParameters,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Parameter filter bar ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              // "All" toggle
              FilterChip(
                label: Text(S.of(context).analyticsAll),
                selected: _allSelected,
                onSelected: (on) {
                  if (on) {
                    onSelectionChanged(
                        parameters.where((p) => p.id != null).map((p) => p.id!).toSet());
                  } else {
                    onSelectionChanged({});
                  }
                },
              ),
              const SizedBox(width: 6),
              // Individual parameter chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: parameters.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      if (p.id == null) return const SizedBox.shrink();
                      final selected = selectedParamIds.contains(p.id);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(p.name),
                          selected: selected,
                          selectedColor: _colorFor(i).withValues(alpha: 0.25),
                          checkmarkColor: _colorFor(i),
                          side: BorderSide(
                            color: selected ? _colorFor(i) : Colors.grey.shade300,
                            width: selected ? 1.5 : 1,
                          ),
                          onSelected: (on) {
                            final next = Set<int>.from(selectedParamIds);
                            on ? next.add(p.id!) : next.remove(p.id!);
                            onSelectionChanged(next);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Charts ───────────────────────────────────────────────────────────
        Expanded(
          child: selectedParamIds.isEmpty
              ? Center(
                  child: Text(
                    S.of(context).analyticsSelectParameters,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: selectedParamIds.map((pid) {
                    // Find the color index by matching parameter order
                    final colorIdx =
                        parameters.indexWhere((p) => p.id == pid);
                    return _ParameterChartCard(
                      parameterId: pid,
                      range: range,
                      color: _colorFor(colorIdx < 0 ? 0 : colorIdx),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

// ─── Single-parameter chart card ─────────────────────────────────────────────

class _ParameterChartCard extends ConsumerWidget {
  const _ParameterChartCard({
    required this.parameterId,
    required this.range,
    required this.color,
  });

  final int parameterId;
  final AnalyticsRange range;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histAsync = ref.watch(
        parameterHistoryProvider(parameterId: parameterId, range: range));

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: histAsync.when(
          loading: () => const SizedBox(
              height: 180, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SizedBox(
              height: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(S.of(context).error(e),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(parameterHistoryProvider(
                        parameterId: parameterId, range: range)),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(S.of(context).retry),
                  ),
                ],
              )),
          data: (hist) => _buildContent(context, hist),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ParameterHistoryResponse hist) {
    final unit = hist.unit ?? '';
    final title = unit.isEmpty ? hist.parameterName : '${hist.parameterName}  ($unit)';

    if (hist.points.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 24),
          Center(
              child: Text(S.of(context).analyticsNoDataInRange,
                  style: const TextStyle(color: Colors.grey))),
          const SizedBox(height: 16),
        ],
      );
    }

    final values = hist.points.map((p) => p.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final avgV = values.reduce((a, b) => a + b) / values.length;
    final baseMs =
        hist.points.first.timestamp.millisecondsSinceEpoch.toDouble();
    final totalSec =
        (hist.points.last.timestamp.millisecondsSinceEpoch - baseMs) / 1000.0;

    final spots = hist.points.map((p) {
      final x = (p.timestamp.millisecondsSinceEpoch - baseMs) / 1000.0;
      return FlSpot(x, p.value);
    }).toList();

    final padding = (maxV - minV).abs() * 0.1 + 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + stats row
        Row(
          children: [
            Expanded(
              child: Text(title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            ),
            _MiniStat(label: S.of(context).analyticsStatMin, value: minV, unit: unit, color: Colors.blueGrey),
            const SizedBox(width: 8),
            _MiniStat(label: S.of(context).analyticsStatAvg, value: avgV, unit: unit, color: Colors.green),
            const SizedBox(width: 8),
            _MiniStat(label: S.of(context).analyticsStatMax, value: maxV, unit: unit, color: Colors.orange),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minY: minV - padding,
              maxY: maxV + padding,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: color,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: 0.12),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (val, _) => Text(
                      val.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: totalSec > 0 ? totalSec / 4 : 1,
                    getTitlesWidget: (val, _) {
                      final dt = DateTime.fromMillisecondsSinceEpoch(
                          (baseMs + val * 1000).toInt());
                      final fmt = totalSec > 86400
                          ? DateFormat('MM-dd')
                          : DateFormat('HH:mm');
                      return Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(fmt.format(dt),
                            style: const TextStyle(fontSize: 9)),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final dt = DateTime.fromMillisecondsSinceEpoch(
                        (baseMs + s.x * 1000).toInt());
                    return LineTooltipItem(
                      '${s.y.toStringAsFixed(2)} $unit\n'
                      '${DateFormat('HH:mm:ss').format(dt)}',
                      const TextStyle(fontSize: 11),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Events tab ───────────────────────────────────────────────────────────────

class _EventsTab extends ConsumerWidget {
  const _EventsTab({
    required this.greenhouseId,
    required this.range,
    required this.analyticsEnabled,
  });

  final int? greenhouseId;
  final AnalyticsRange range;
  final bool analyticsEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!analyticsEnabled) return const _DisabledBanner();
    final s = S.of(context);

    if (greenhouseId == null) {
      return Center(
          child: Text(s.plantAlertsSelectGreenhouse,
              style: const TextStyle(color: Colors.grey)));
    }

    final statsAsync = ref.watch(
        greenhouseStatsProvider(greenhouseId: greenhouseId!, range: range));
    final eventsAsync = ref.watch(
        greenhouseEventsProvider(greenhouseId: greenhouseId!, range: range));

    return Column(
      children: [
        statsAsync.when(
          loading: () => const SizedBox(
              height: 80, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(s.analyticsStatsError(e),
                      style:
                          const TextStyle(color: Colors.red, fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: () => ref.invalidate(greenhouseStatsProvider(
                      greenhouseId: greenhouseId!, range: range)),
                  icon: const Icon(Icons.refresh, size: 14),
                  label: Text(s.retry),
                ),
              ],
            ),
          ),
          data: (stats) => _buildStatsRow(context, stats),
        ),
        const Divider(height: 1),
        Expanded(
          child: eventsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.error(e),
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(
                          greenhouseEventsProvider(
                              greenhouseId: greenhouseId!, range: range)),
                      icon: const Icon(Icons.refresh),
                      label: Text(s.retry),
                    ),
                  ],
                )),
            data: (events) => events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 48, color: Colors.green),
                        const SizedBox(height: 12),
                        Text(s.analyticsNoEventsInRange(_rangeLabel(context, range)),
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: events.length,
                    itemBuilder: (ctx, i) => _EventTile(event: events[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, GreenhouseStats stats) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCard(
            icon: Icons.power_settings_new,
            label: s.analyticsStatBoots,
            value: stats.bootCount.toString(),
            color: Colors.green,
          ),
          _StatCard(
            icon: Icons.warning_amber_rounded,
            label: s.analyticsStatCrashes,
            value: stats.crashCount.toString(),
            color: Colors.red,
          ),
          _StatCard(
            icon: Icons.calendar_today,
            label: s.analyticsStatPeriod,
            value: _rangeLabel(context, range),
            color: Colors.blueGrey,
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final GreenhouseEvent event;

  @override
  Widget build(BuildContext context) {
    final isBoot = event.eventType == 'BOOT';
    final color = isBoot ? Colors.green : Colors.red;
    final icon = isBoot ? Icons.power_settings_new : Icons.warning_amber_rounded;
    final label = isBoot
        ? S.of(context).analyticsEventBoot
        : S.of(context).analyticsEventCrash;
    final timeStr =
        DateFormat('yyyy-MM-dd  HH:mm:ss').format(event.occurredAt.toLocal());

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      subtitle: Text(timeStr,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: event.details != null
          ? Tooltip(
              message: event.details!,
              child:
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
            )
          : null,
    );
  }
}

// ─── Plant health tab ──────────────────────────────────────────────────────────

class _PlantHealthTab extends ConsumerStatefulWidget {
  const _PlantHealthTab({required this.greenhouseId});

  final int? greenhouseId;

  @override
  ConsumerState<_PlantHealthTab> createState() => _PlantHealthTabState();
}

class _PlantHealthTabState extends ConsumerState<_PlantHealthTab> {
  bool _includeResolved = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final id = widget.greenhouseId;
    if (id == null) {
      return Center(
          child: Text(s.plantAlertsSelectGreenhouse,
              style: const TextStyle(color: Colors.grey)));
    }

    final alertsAsync = ref.watch(plantAlertsProvider(
        greenhouseId: id, includeResolved: _includeResolved));

    void refresh() {
      ref.invalidate(plantAlertsProvider(
          greenhouseId: id, includeResolved: _includeResolved));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.local_florist, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              Text(s.plantHealthTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(s.plantAlertsHistory, style: const TextStyle(fontSize: 12)),
              Switch(
                value: _includeResolved,
                onChanged: (on) => setState(() => _includeResolved = on),
              ),
              IconButton(
                onPressed: refresh,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: s.plantAlertsRefresh,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: alertsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.error(e), style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: refresh,
                    icon: const Icon(Icons.refresh),
                    label: Text(s.retry),
                  ),
                ],
              ),
            ),
            data: (alerts) => alerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 48, color: Colors.green),
                        const SizedBox(height: 12),
                        Text(
                          _includeResolved
                              ? s.plantAlertsEmptyAll
                              : s.plantAlertsEmptyActive,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: alerts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) => _PlantAlertTile(
                        alert: alerts[i],
                        greenhouseId: id,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PlantAlertTile extends ConsumerWidget {
  const _PlantAlertTile({required this.alert, required this.greenhouseId});

  final PlantAlert alert;
  final int greenhouseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final resolved = alert.isResolved;
    final color = resolved ? Colors.green : Colors.red;
    final icon = resolved ? Icons.check_circle_outline : Icons.warning_amber_rounded;
    final ts = alert.raisedAt ?? alert.lastSeenAt ?? alert.firstDetectedAt;
    final timeStr = ts != null
        ? DateFormat('yyyy-MM-dd  HH:mm').format(ts.toLocal())
        : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        alert.message ??
            s.plantAlertFallback(
                alert.plantName ?? s.plantAlertGenericName,
                alert.requirementName ?? ''),
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        '${resolved ? s.plantAlertStatusResolved : s.plantAlertStatusActive}'
        '${timeStr.isNotEmpty ? '  ·  $timeStr' : ''}',
        style: TextStyle(fontSize: 12, color: color),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 18),
        tooltip: s.plantAlertsDismiss,
        onPressed: () => ref.read(dismissPlantAlertProvider(
          alertId: alert.id,
          greenhouseId: greenhouseId,
        ).future),
      ),
    );
  }
}

// ─── Logs tab (serial-monitor feed) ───────────────────────────────────────────

class _LogsTab extends ConsumerStatefulWidget {
  const _LogsTab({required this.greenhouseId});

  final int? greenhouseId;

  @override
  ConsumerState<_LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends ConsumerState<_LogsTab> {
  static const _refreshInterval = Duration(seconds: 4);
  Timer? _timer;
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_autoRefresh) return;
    _timer = Timer.periodic(_refreshInterval, (_) => _invalidate());
  }

  void _invalidate() {
    final id = widget.greenhouseId;
    if (id != null) {
      ref.invalidate(deviceLogsProvider(greenhouseId: id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final id = widget.greenhouseId;
    if (id == null) {
      return Center(
          child: Text(s.plantAlertsSelectGreenhouse,
              style: const TextStyle(color: Colors.grey)));
    }

    final logsAsync = ref.watch(deviceLogsProvider(greenhouseId: id));

    return Column(
      children: [
        // Toolbar: auto-refresh toggle + manual refresh
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.terminal, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(s.analyticsDeviceLogs,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(s.analyticsAuto, style: const TextStyle(fontSize: 12)),
              Switch(
                value: _autoRefresh,
                onChanged: (on) {
                  setState(() => _autoRefresh = on);
                  _startTimer();
                  if (on) _invalidate();
                },
              ),
              IconButton(
                onPressed: _invalidate,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: s.analyticsRefreshNow,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.error(e),
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _invalidate,
                    icon: const Icon(Icons.refresh),
                    label: Text(s.retry),
                  ),
                ],
              ),
            ),
            data: (logs) => logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_outlined,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(s.analyticsNoLogs,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _invalidate(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 12, endIndent: 12),
                      itemBuilder: (ctx, i) => _LogTile(log: logs[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final DeviceLog log;

  Color get _levelColor => switch (log.level) {
        'ERROR' => Colors.red,
        'WARN' => Colors.orange,
        _ => Colors.blueGrey,
      };

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MM-dd HH:mm:ss').format(log.timestamp.toLocal());
    final isEvent = log.source == 'EVENT';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level chip
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _levelColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              log.level,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _levelColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(time,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                    if (log.code != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          log.code!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: isEvent ? _levelColor : Colors.indigo),
                        ),
                      ),
                    ],
                  ],
                ),
                if (log.message != null && log.message!.isNotEmpty)
                  Text(log.message!,
                      style: const TextStyle(
                          fontSize: 13, fontFamily: 'monospace')),
                if (log.freeHeap != null)
                  Text(
                      S.of(context).analyticsLogHeap(log.freeHeap!) +
                          (log.deviceUptime != null
                              ? '  ·  ${S.of(context).analyticsLogUptime(log.deviceUptime!)}'
                              : ''),
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings tab ─────────────────────────────────────────────────────────────

class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab();

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  // Local copies of each field while the user is editing
  int? _historyDays;
  int? _eventsDays;
  int? _logsDays;
  int? _debounceMin;
  int? _intervalHours;

  static const _historyOptions = [7, 30, 60, 90, 180, 365];
  static const _eventsOptions = [30, 90, 180, 365, 9999]; // 9999 = "Forever"
  static const _logsOptions = [1, 3, 7, 14, 30]; // days
  static const _debounceOptions = [0, 5, 10, 20, 30, 60]; // minutes; 0 = immediate
  static const _intervalOptions = [1, 6, 12, 24, 48, 168]; // hours

  String _debounceLabel(BuildContext context, int v) {
    final s = S.of(context);
    return v == 0 ? s.analyticsImmediate : s.analyticsMinutesLabel(v);
  }

  String _eventsLabel(BuildContext context, int v) => v == 9999
      ? S.of(context).analyticsForever
      : S.of(context).analyticsDaysLabel(v);

  String _intervalLabel(BuildContext context, int v) {
    final s = S.of(context);
    return v < 24 ? s.analyticsHoursLabel(v) : s.analyticsDaysLabel(v ~/ 24);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync =
        ref.watch(analyticsSettingsNotifierProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text(S.of(context).analyticsSettingsLoadError(e),
              style: const TextStyle(color: Colors.red))),
      data: (settings) {
        // Initialise local state once from server values
        _historyDays ??= _nearestOption(settings.historyRetentionDays, _historyOptions);
        _eventsDays ??= _nearestOption(settings.eventsRetentionDays, _eventsOptions);
        _logsDays ??= _nearestOption(settings.logsRetentionDays, _logsOptions);
        _debounceMin ??=
            _nearestOption(settings.plantCheckDebounceMinutes, _debounceOptions);
        _intervalHours ??=
            _nearestOption(settings.cleanupIntervalHours, _intervalOptions);

        final dark = Theme.of(context).brightness == Brightness.dark;
        final enabled = settings.analyticsEnabled;
        final accent = enabled ? Colors.green : Colors.orange;
        final cardColor = (dark ? accent.shade900 : accent.shade50)
            .withValues(alpha: dark ? 0.30 : 1.0);
        final titleColor = dark ? accent.shade200 : accent.shade800;
        final s = S.of(context);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Master enable / disable toggle ────────────────────────────
            Card(
              elevation: 1,
              color: cardColor,
              child: SwitchListTile(
                secondary: Icon(
                  enabled ? Icons.analytics : Icons.analytics_outlined,
                  color: accent,
                ),
                title: Text(
                  enabled ? s.analyticsEnabledTitle : s.analyticsDisabledTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  '${enabled ? s.analyticsEnabledSubtitle : s.analyticsDisabledSubtitle}'
                  '\n${s.analyticsAutoSaveHint}',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
                value: enabled,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.orange,
                onChanged: (on) async {
                  await ref
                      .read(analyticsSettingsNotifierProvider.notifier)
                      .save(settings.copyWith(analyticsEnabled: on));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(on
                            ? s.analyticsEnabledTitle
                            : s.analyticsDisabledTitle),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── Parameter history retention ───────────────────────────────
            _SettingsCard(
              icon: Icons.show_chart,
              title: s.analyticsHistoryRetentionTitle,
              subtitle: s.analyticsHistoryRetentionSubtitle,
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  labelText: s.analyticsKeepDataFor,
                ),
                menuMaxHeight: 220,
                value: _historyDays,
                items: _historyOptions
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text(s.analyticsDaysLabel(v)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _historyDays = v),
              ),
            ),
            const SizedBox(height: 12),

            // ── Event log retention ───────────────────────────────────────
            _SettingsCard(
              icon: Icons.history,
              title: s.analyticsEventRetentionTitle,
              subtitle: s.analyticsEventRetentionSubtitle,
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  labelText: s.analyticsKeepEventsFor,
                ),
                menuMaxHeight: 220,
                value: _eventsDays,
                items: _eventsOptions
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text(_eventsLabel(context, v)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _eventsDays = v),
              ),
            ),
            const SizedBox(height: 12),

            // ── Device log retention ──────────────────────────────────────
            _SettingsCard(
              icon: Icons.terminal,
              title: s.analyticsLogRetentionTitle,
              subtitle: s.analyticsLogRetentionSubtitle,
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  labelText: s.analyticsKeepLogsFor,
                ),
                menuMaxHeight: 220,
                value: _logsDays,
                items: _logsOptions
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text(s.analyticsDaysLabel(v)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _logsDays = v),
              ),
            ),
            const SizedBox(height: 12),

            // ── Plant alert delay (debounce) ──────────────────────────────
            _SettingsCard(
              icon: Icons.local_florist,
              title: s.analyticsPlantDelayTitle,
              subtitle: s.analyticsPlantDelaySubtitle,
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  labelText: s.analyticsAlertAfter,
                ),
                menuMaxHeight: 220,
                value: _debounceMin,
                items: _debounceOptions
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text(_debounceLabel(context, v)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _debounceMin = v),
              ),
            ),
            const SizedBox(height: 12),

            // ── Cleanup interval ──────────────────────────────────────────
            _SettingsCard(
              icon: Icons.cleaning_services,
              title: s.analyticsCleanupIntervalTitle,
              subtitle: s.analyticsCleanupIntervalSubtitle,
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  labelText: s.analyticsRunEvery,
                ),
                menuMaxHeight: 220,
                value: _intervalHours,
                items: _intervalOptions
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text(_intervalLabel(context, v)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _intervalHours = v),
              ),
            ),
            const SizedBox(height: 12),

            // ── Last cleanup info ─────────────────────────────────────────
            if (settings.lastCleanup != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  s.analyticsLastCleanup(DateFormat('yyyy-MM-dd HH:mm')
                      .format(settings.lastCleanup!.toLocal())),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            const SizedBox(height: 16),

            // ── Save button ───────────────────────────────────────────────
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: Text(s.analyticsSaveSettings),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: (_historyDays == null ||
                      _eventsDays == null ||
                      _logsDays == null ||
                      _debounceMin == null ||
                      _intervalHours == null)
                  ? null
                  : () async {
                          await ref
                              .read(analyticsSettingsNotifierProvider.notifier)
                              .save(settings.copyWith(
                                // analyticsEnabled is saved immediately via the
                                // toggle above; preserve its current value here.
                                historyRetentionDays: _historyDays!,
                                eventsRetentionDays: _eventsDays!,
                                logsRetentionDays: _logsDays!,
                                plantCheckDebounceMinutes: _debounceMin!,
                                cleanupIntervalHours: _intervalHours!,
                              ));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(s.analyticsSettingsSaved),
                                  duration: const Duration(seconds: 2)),
                            );
                          }
                        },
            ),
          ],
        );
      },
    );
  }

  /// Returns the nearest value from [options] to [target].
  int _nearestOption(int target, List<int> options) {
    return options.reduce((a, b) =>
        (a - target).abs() < (b - target).abs() ? a : b);
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Tiny helpers ─────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label,
      required this.value,
      required this.unit,
      required this.color});

  final String label;
  final double value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        Text('${value.toStringAsFixed(1)} $unit',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Disabled banner ──────────────────────────────────────────────────────────

/// Full-tab placeholder shown when the analytics master switch is off.
class _DisabledBanner extends StatelessWidget {
  const _DisabledBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined,
                size: 56, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            Text(
              S.of(context).analyticsDisabledBannerTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).analyticsDisabledBannerBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}