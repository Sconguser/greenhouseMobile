import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../generated/l10n.dart';
import '../../models/device_config_model.dart';
import '../../models/greenhouse_model.dart';
import '../../models/mapping_config_model.dart';
import '../../models/parameter_model.dart';
import '../../models/zone_model.dart';
import '../../providers/device_config_notifier.dart';
import '../../providers/mapping_config_notifier.dart';
import '../../shared/loading_indicator.dart';
import '../error/error_view.dart';

// ─── Utility ──────────────────────────────────────────────────────────────────

T? _firstOrNull<T>(List<T> list, bool Function(T) test) {
  for (final item in list) {
    if (test(item)) return item;
  }
  return null;
}

// ─── Top-level view ───────────────────────────────────────────────────────────

class MappingConfigView extends ConsumerWidget {
  const MappingConfigView({super.key, required this.greenhouse});

  final Greenhouse greenhouse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync =
        ref.watch(mappingConfigNotifierProvider(greenhouse.id!));
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).mappingsTitle(greenhouse.name))),
      body: configAsync.when(
        data: (mappings) => _MappingList(
          greenhouse: greenhouse,
          initial: mappings,
        ),
        error: (e, _) => ErrorScreen(
          error: e,
          onRetry: () =>
              ref.invalidate(mappingConfigNotifierProvider(greenhouse.id!)),
        ),
        loading: () => const LoadingIndicatorWidget(),
      ),
    );
  }
}

// ─── List ─────────────────────────────────────────────────────────────────────

class _MappingList extends ConsumerStatefulWidget {
  const _MappingList({required this.greenhouse, required this.initial});

  final Greenhouse greenhouse;
  final List<MappingConfig> initial;

  @override
  ConsumerState<_MappingList> createState() => _MappingListState();
}

class _MappingListState extends ConsumerState<_MappingList> {
  late List<MappingConfig> _mappings;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _mappings = List.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref
            .watch(deviceConfigNotifierProvider(widget.greenhouse.id!))
            .valueOrNull ??
        [];

    return Column(
      children: [
        Expanded(
          child: _mappings.isEmpty
              ? Center(child: Text(S.of(context).noMappingsYet))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _mappings.length,
                  itemBuilder: (_, i) => _MappingCard(
                    mapping: _mappings[i],
                    greenhouse: widget.greenhouse,
                    devices: devices,
                    onEdit: () => _openForm(i, devices),
                    onDelete: () => setState(() {
                      _mappings.removeAt(i);
                      _isDirty = true;
                    }),
                  ),
                ),
        ),
        if (_isDirty) _UnsavedBanner(message: S.of(context).unsavedChangesHint),
        _buildBottomBar(context, devices),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, List<DeviceConfig> devices) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openForm(null, devices),
                icon: const Icon(Icons.add),
                label: Text(S.of(context).addMapping),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirmSave(context),
                icon: const Icon(Icons.upload_rounded),
                label: Text(S.of(context).saveAndPush),
                style: _isDirty
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(int? editIndex, List<DeviceConfig> devices) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MappingFormPage(
        greenhouse: widget.greenhouse,
        devices: devices,
        initial: editIndex != null ? _mappings[editIndex] : null,
        onSubmit: (mapping) {
          setState(() {
            if (editIndex != null) {
              _mappings[editIndex] = mapping;
            } else {
              _mappings.add(mapping);
            }
            _isDirty = true;
          });
        },
      ),
    ));
  }

  void _confirmSave(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(s.pushMappingConfigTitle),
        content: Text(s.pushMappingConfigContent),
        actions: [
          TextButton(
              child: Text(s.cancel),
              onPressed: () => Navigator.of(dialogCtx).pop()),
          ElevatedButton(
            child: Text(s.saveAndPush),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref
                  .read(mappingConfigNotifierProvider(widget.greenhouse.id!)
                      .notifier)
                  .saveMappingConfig(_mappings);
              setState(() => _isDirty = false);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Unsaved banner ───────────────────────────────────────────────────────────

class _UnsavedBanner extends StatelessWidget {
  const _UnsavedBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _MappingCard extends StatelessWidget {
  const _MappingCard({
    required this.mapping,
    required this.greenhouse,
    required this.devices,
    required this.onEdit,
    required this.onDelete,
  });

  final MappingConfig mapping;
  final Greenhouse greenhouse;
  final List<DeviceConfig> devices;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scopeLabel = _scopeLabel();
    final readLabel = _deviceLabel(mapping.readDeviceId, 'read');
    final writeLabel = mapping.writeDeviceId != null
        ? '${_deviceLabel(mapping.writeDeviceId, 'write')} (${mapping.direction})'
        : null;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.device_hub),
        title: Text('${mapping.paramName} @ $scopeLabel'),
        subtitle: Text(
            [readLabel, writeLabel].where((s) => s != null).join(' · ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _scopeLabel() {
    switch (mapping.scope) {
      case 'zone':
        final zone =
            _firstOrNull(greenhouse.zones, (z) => z.id == mapping.zoneId);
        return zone?.name ?? 'zone ${mapping.zoneId}';
      case 'flowerpot':
        for (final zone in greenhouse.zones) {
          final pot = _firstOrNull(
              zone.flowerpots, (p) => p.id == mapping.flowerpotId);
          if (pot != null) return '${zone.name} / ${pot.name}';
        }
        return 'flowerpot ${mapping.flowerpotId}';
      default:
        return 'greenhouse';
    }
  }

  String? _deviceLabel(int? deviceId, String prefix) {
    if (deviceId == null) return null;
    final device = _firstOrNull(devices, (d) => d.id == deviceId);
    return device != null
        ? '$prefix: ${device.name} (${device.driver}, pin ${device.pin})'
        : '$prefix: device #$deviceId (missing)';
  }
}

// ─── Form page ────────────────────────────────────────────────────────────────

class _MappingFormPage extends StatefulWidget {
  const _MappingFormPage({
    required this.greenhouse,
    required this.devices,
    this.initial,
    required this.onSubmit,
  });

  final Greenhouse greenhouse;
  final List<DeviceConfig> devices;
  final MappingConfig? initial;
  final void Function(MappingConfig) onSubmit;

  @override
  State<_MappingFormPage> createState() => _MappingFormPageState();
}

class _MappingFormPageState extends State<_MappingFormPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  // Scope / parameter selection
  String _scope = 'greenhouse';
  int? _selectedZoneId;
  int? _selectedFlowerpotId;
  String? _selectedParamName;
  bool _paramError = false;

  // Read sensor
  bool _hasRead = false;
  int? _selectedReadDeviceId;

  // Analog scaling
  bool _hasScaling = false;

  // Write actuator
  bool _hasWrite = false;
  int? _selectedWriteDeviceId;

  static const _directions = ['increase', 'decrease'];
  static const _outputModes = ['binary', 'pwm'];

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    if (m == null) return;

    _scope = m.scope;
    _selectedZoneId = m.zoneId;
    _selectedFlowerpotId = m.flowerpotId;
    _selectedParamName = m.paramName;

    _hasRead = m.readDeviceId != null;
    _selectedReadDeviceId = m.readDeviceId;

    _hasScaling = m.mapInMin != null;

    _hasWrite = m.writeDeviceId != null;
    _selectedWriteDeviceId = m.writeDeviceId;
  }

  Zone? get _selectedZone => _firstOrNull(
      widget.greenhouse.zones, (z) => z.id == _selectedZoneId);

  get _selectedFlowerpot {
    final zone = _selectedZone;
    if (zone == null) return null;
    return _firstOrNull(zone.flowerpots, (p) => p.id == _selectedFlowerpotId);
  }

  List<Parameter> get _scopeParameters {
    switch (_scope) {
      case 'zone':
        return _selectedZone?.parameters ?? [];
      case 'flowerpot':
        return _selectedFlowerpot?.parameters ?? [];
      default:
        return widget.greenhouse.parameters;
    }
  }

  DeviceConfig? get _selectedReadDevice =>
      _firstOrNull(widget.devices, (d) => d.id == _selectedReadDeviceId);

  bool get _readIsMux => _selectedReadDevice?.driver == 'muxAnalog';

  List<DeviceConfig> get _writableDevices =>
      widget.devices.where((d) => d.driver == 'digital').toList();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final m = widget.initial;

    return Scaffold(
      appBar: AppBar(
        title: Text(m == null ? s.addMapping : s.editMappingTitle),
        actions: [
          TextButton(
            onPressed: _submit,
            child: Text(s.save,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Parameter ──────────────────────────────────────────────────
              _sectionHeader(s.mappingParameterSection),
              DropdownButtonFormField<String>(
                value: _scope,
                decoration: InputDecoration(
                    labelText: s.scopeLabel,
                    border: const OutlineInputBorder()),
                items: ['greenhouse', 'zone', 'flowerpot']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _scope = v!;
                  _selectedZoneId = null;
                  _selectedFlowerpotId = null;
                  _selectedParamName = null;
                  _paramError = false;
                }),
              ),
              if (_scope == 'zone' || _scope == 'flowerpot') ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: _selectedZoneId,
                  decoration: InputDecoration(
                      labelText: s.selectZone,
                      border: const OutlineInputBorder()),
                  items: widget.greenhouse.zones
                      .where((z) => z.id != null)
                      .map((z) =>
                          DropdownMenuItem(value: z.id, child: Text(z.name)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedZoneId = v;
                    _selectedFlowerpotId = null;
                    _selectedParamName = null;
                    _paramError = false;
                  }),
                ),
              ],
              if (_scope == 'flowerpot' && _selectedZone != null) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: _selectedFlowerpotId,
                  decoration: InputDecoration(
                      labelText: s.selectFlowerpot,
                      border: const OutlineInputBorder()),
                  items: _selectedZone!.flowerpots
                      .where((p) => p.id != null)
                      .map((p) =>
                          DropdownMenuItem(value: p.id, child: Text(p.name)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedFlowerpotId = v;
                    _selectedParamName = null;
                    _paramError = false;
                  }),
                ),
              ],
              const SizedBox(height: 8),
              _buildParamPicker(s),

              const SizedBox(height: 16),
              // ── Read sensor ────────────────────────────────────────────────
              _sectionHeader(s.readSensorSection),
              SwitchListTile(
                value: _hasRead,
                title: Text(s.hasReadSensor),
                onChanged: (v) => setState(() {
                  _hasRead = v;
                  if (!v) _selectedReadDeviceId = null;
                }),
              ),
              if (_hasRead) ...[
                if (widget.devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(s.noDevicesForSensor,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  )
                else ...[
                  DropdownButtonFormField<int>(
                    value: _selectedReadDeviceId,
                    decoration: InputDecoration(
                        labelText: s.selectReadDevice,
                        border: const OutlineInputBorder()),
                    items: widget.devices
                        .where((d) => d.id != null)
                        .map((d) => DropdownMenuItem(
                              value: d.id,
                              child:
                                  Text('${d.name} (${d.driver}, pin ${d.pin})'),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedReadDeviceId = v),
                  ),
                  if (_readIsMux) ...[
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'muxChannel',
                      initialValue: m?.muxChannel?.toString(),
                      decoration: InputDecoration(
                          labelText: s.muxChannelLabel,
                          border: const OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.integer(),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'muxSelPins',
                      initialValue: m?.muxSelPins.isNotEmpty == true
                          ? m!.muxSelPins.join(',')
                          : null,
                      decoration: InputDecoration(
                          labelText: s.selectorPinsLabel,
                          border: const OutlineInputBorder()),
                    ),
                  ],
                ],
              ],

              const SizedBox(height: 16),
              // ── Write actuator ─────────────────────────────────────────────
              _sectionHeader(s.writeActuatorSection),
              SwitchListTile(
                value: _hasWrite,
                title: Text(s.hasWriteActuator),
                onChanged: (v) => setState(() {
                  _hasWrite = v;
                  if (!v) _selectedWriteDeviceId = null;
                }),
              ),
              if (_hasWrite) ...[
                if (_writableDevices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(s.noWritableDevices,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  )
                else
                  DropdownButtonFormField<int>(
                    value: _selectedWriteDeviceId,
                    decoration: InputDecoration(
                        labelText: s.selectWriteDevice,
                        border: const OutlineInputBorder()),
                    items: _writableDevices
                        .where((d) => d.id != null)
                        .map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text('${d.name} (pin ${d.pin})'),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedWriteDeviceId = v),
                  ),
                const SizedBox(height: 8),
                FormBuilderDropdown<String>(
                  name: 'direction',
                  initialValue: m?.direction ?? _directions.first,
                  decoration: InputDecoration(
                      labelText: s.directionLabel,
                      border: const OutlineInputBorder()),
                  items: _directions
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                ),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'hysteresis',
                  initialValue: m?.hysteresis?.toString(),
                  decoration: InputDecoration(
                      labelText: s.hysteresisLabel,
                      border: const OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: false),
                ),
                const SizedBox(height: 8),
                FormBuilderCheckbox(
                  name: 'activeLow',
                  initialValue: m?.activeLow ?? false,
                  title: Text(s.activeLowLabel),
                ),
                const SizedBox(height: 8),
                FormBuilderDropdown<String>(
                  name: 'outputMode',
                  initialValue: m?.outputMode ?? _outputModes.first,
                  decoration: InputDecoration(
                      labelText: s.outputModeLabel,
                      border: const OutlineInputBorder()),
                  items: _outputModes
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'minOnMs',
                      initialValue: m?.minOnMs?.toString(),
                      decoration: InputDecoration(
                          labelText: s.minOnTimeLabel,
                          border: const OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'minOffMs',
                      initialValue: m?.minOffMs?.toString(),
                      decoration: InputDecoration(
                          labelText: s.minOffTimeLabel,
                          border: const OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ]),
              ],

              const SizedBox(height: 16),
              // ── Analog scaling ─────────────────────────────────────────────
              _sectionHeader(s.analogScalingSection),
              SwitchListTile(
                value: _hasScaling,
                title: Text(s.applyAnalogScaling),
                subtitle: Text(s.analogScalingSubtitle),
                onChanged: (v) => setState(() => _hasScaling = v),
              ),
              if (_hasScaling) ...[
                Row(children: [
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'mapInMin',
                      initialValue: m?.mapInMin?.toString(),
                      decoration: InputDecoration(
                          labelText: s.rawMinLabel,
                          border: const OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'mapInMax',
                      initialValue: m?.mapInMax?.toString(),
                      decoration: InputDecoration(
                          labelText: s.rawMaxLabel,
                          border: const OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'mapOutMin',
                      initialValue: m?.mapOutMin?.toString(),
                      decoration: InputDecoration(
                          labelText: s.displayMinLabel,
                          border: const OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'mapOutMax',
                      initialValue: m?.mapOutMax?.toString(),
                      decoration: InputDecoration(
                          labelText: s.displayMaxLabel,
                          border: const OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                ]),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text(m == null ? s.addMapping : s.saveChanges),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParamPicker(S s) {
    if (_scope == 'zone' && _selectedZoneId == null) {
      return const SizedBox.shrink();
    }
    if (_scope == 'flowerpot' &&
        (_selectedZoneId == null || _selectedFlowerpotId == null)) {
      return const SizedBox.shrink();
    }

    final params = _scopeParameters;

    if (params.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(s.noParametersInScope,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
    }

    final validNames = params.map((p) => p.name).toSet();
    final currentValue =
        validNames.contains(_selectedParamName) ? _selectedParamName : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String?>(
          value: currentValue,
          decoration: InputDecoration(
              labelText: s.selectParameter,
              border: const OutlineInputBorder()),
          items: params
              .map((p) => DropdownMenuItem(value: p.name, child: Text(p.name)))
              .toList(),
          onChanged: (v) => setState(() {
            _selectedParamName = v;
            _paramError = false;
          }),
        ),
        if (_paramError && _selectedParamName == null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              s.parameterRequired,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );

  void _submit() {
    if (_scope == 'zone' && _selectedZoneId == null) return;
    if (_scope == 'flowerpot' &&
        (_selectedZoneId == null || _selectedFlowerpotId == null)) return;

    if (_selectedParamName == null) {
      setState(() => _paramError = true);
      _formKey.currentState?.validate();
      return;
    }
    setState(() => _paramError = false);

    _formKey.currentState?.validate();
    if (_formKey.currentState?.isValid != true) return;

    final f = _formKey.currentState!.fields;

    String? raw(String name) {
      final v = f[name]?.value?.toString().trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    final selPinsRaw = raw('muxSelPins');
    final muxSelPins = selPinsRaw != null
        ? selPinsRaw
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toList()
        : <int>[];

    final useMux = _hasRead && _readIsMux;

    widget.onSubmit(MappingConfig(
      scope: _scope,
      zoneId: _selectedZoneId,
      flowerpotId: _selectedFlowerpotId,
      paramName: _selectedParamName!,
      readDeviceId: _hasRead ? _selectedReadDeviceId : null,
      muxChannel: useMux ? int.tryParse(raw('muxChannel') ?? '') : null,
      muxSelPins: useMux ? muxSelPins : [],
      writeDeviceId: _hasWrite ? _selectedWriteDeviceId : null,
      direction: _hasWrite ? f['direction']?.value as String? : null,
      hysteresis:
          _hasWrite ? double.tryParse(raw('hysteresis') ?? '') : null,
      activeLow: _hasWrite ? f['activeLow']?.value as bool? : null,
      outputMode: _hasWrite ? f['outputMode']?.value as String? : null,
      minOnMs: _hasWrite ? int.tryParse(raw('minOnMs') ?? '') : null,
      minOffMs: _hasWrite ? int.tryParse(raw('minOffMs') ?? '') : null,
      mapInMin: _hasScaling ? double.tryParse(raw('mapInMin') ?? '') : null,
      mapInMax: _hasScaling ? double.tryParse(raw('mapInMax') ?? '') : null,
      mapOutMin: _hasScaling ? double.tryParse(raw('mapOutMin') ?? '') : null,
      mapOutMax: _hasScaling ? double.tryParse(raw('mapOutMax') ?? '') : null,
    ));
    Navigator.of(context).pop();
  }
}