import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../generated/l10n.dart';
import '../../models/greenhouse_model.dart';
import '../../models/mapping_config_model.dart';
import '../../providers/mapping_config_notifier.dart';
import '../../shared/loading_indicator.dart';
import '../error/error_view.dart';

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

// ─── List state ───────────────────────────────────────────────────────────────

class _MappingList extends ConsumerStatefulWidget {
  const _MappingList(
      {required this.greenhouse, required this.initial});

  final Greenhouse greenhouse;
  final List<MappingConfig> initial;

  @override
  ConsumerState<_MappingList> createState() => _MappingListState();
}

class _MappingListState extends ConsumerState<_MappingList> {
  late List<MappingConfig> _mappings;

  @override
  void initState() {
    super.initState();
    _mappings = List.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
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
                    onEdit: () => _openForm(i),
                    onDelete: () =>
                        setState(() => _mappings.removeAt(i)),
                  ),
                ),
        ),
        _buildBottomBar(context),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openForm(null),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(int? editIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MappingFormPage(
        greenhouse: widget.greenhouse,
        initial: editIndex != null ? _mappings[editIndex] : null,
        onSubmit: (mapping) {
          setState(() {
            if (editIndex != null) {
              _mappings[editIndex] = mapping;
            } else {
              _mappings.add(mapping);
            }
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
                  .read(mappingConfigNotifierProvider(
                          widget.greenhouse.id!)
                      .notifier)
                  .saveMappingConfig(_mappings);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Mapping card ─────────────────────────────────────────────────────────────

class _MappingCard extends StatelessWidget {
  const _MappingCard(
      {required this.mapping,
      required this.onEdit,
      required this.onDelete});

  final MappingConfig mapping;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scopeLabel = _scopeLabel(mapping);
    final readLabel = mapping.readDriver != null
        ? 'read: ${mapping.readDriver} pin ${mapping.readPin}'
        : null;
    final writeLabel = mapping.writeDriver != null
        ? 'write: ${mapping.writeDriver} pin ${mapping.writePin} '
            '(${mapping.direction})'
        : null;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.device_hub),
        title: Text('${mapping.paramName} @ $scopeLabel'),
        subtitle: Text([readLabel, writeLabel]
            .where((s) => s != null)
            .join(' · ')),
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

  String _scopeLabel(MappingConfig m) {
    switch (m.scope) {
      case 'zone':
        return 'zone ${m.zoneId}';
      case 'flowerpot':
        return 'flowerpot ${m.flowerpotId}';
      default:
        return 'greenhouse';
    }
  }
}

// ─── Mapping form (full page because it has many fields) ─────────────────────

class _MappingFormPage extends StatefulWidget {
  const _MappingFormPage({
    required this.greenhouse,
    this.initial,
    required this.onSubmit,
  });

  final Greenhouse greenhouse;
  final MappingConfig? initial;
  final void Function(MappingConfig) onSubmit;

  @override
  State<_MappingFormPage> createState() => _MappingFormPageState();
}

class _MappingFormPageState extends State<_MappingFormPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  bool _hasRead = false;
  bool _hasMux = false;
  bool _hasWrite = false;
  bool _hasScaling = false;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    if (m != null) {
      _hasRead = m.readDriver != null;
      _hasMux = m.muxChannel != null;
      _hasWrite = m.writeDriver != null;
      _hasScaling = m.mapInMin != null;
    }
  }

  static const _scopes = ['greenhouse', 'zone', 'flowerpot'];
  static const _readDrivers = ['digital', 'dht22', 'muxAnalog'];
  static const _writeDrivers = ['digital'];
  static const _directions = ['increase', 'decrease'];
  static const _outputModes = ['binary'];

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
              // ── Scope ──────────────────────────────────────────────────────
              _sectionHeader(s.scopeLabel),
              FormBuilderDropdown<String>(
                name: 'scope',
                initialValue: m?.scope ?? 'greenhouse',
                decoration: InputDecoration(
                    labelText: s.scopeLabel, border: const OutlineInputBorder()),
                items: _scopes
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              if (_currentScope == 'zone' || _currentScope == 'flowerpot')
                FormBuilderTextField(
                  name: 'zoneId',
                  initialValue: m?.zoneId?.toString(),
                  decoration: InputDecoration(
                      labelText: s.zoneIdLabel,
                      border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.integer(),
                  ]),
                ),
              if (_currentScope == 'flowerpot') ...[
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'flowerpotId',
                  initialValue: m?.flowerpotId?.toString(),
                  decoration: InputDecoration(
                      labelText: s.flowerpotIdLabel,
                      border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.integer(),
                  ]),
                ),
              ],
              const SizedBox(height: 8),
              FormBuilderTextField(
                name: 'paramName',
                initialValue: m?.paramName,
                decoration: InputDecoration(
                    labelText: s.parameterNameLabel,
                    hintText: s.paramNameHint,
                    border: const OutlineInputBorder()),
                validator: FormBuilderValidators.required(),
              ),

              const SizedBox(height: 16),
              // ── Read sensor ────────────────────────────────────────────────
              _sectionHeader(s.readSensorSection),
              SwitchListTile(
                value: _hasRead,
                title: Text(s.hasReadSensor),
                onChanged: (v) => setState(() {
                  _hasRead = v;
                  if (!v) _hasMux = false;
                }),
              ),
              if (_hasRead) ...[
                FormBuilderDropdown<String>(
                  name: 'readDriver',
                  initialValue:
                      m?.readDriver ?? _readDrivers.first,
                  decoration: InputDecoration(
                      labelText: s.readDriverLabel,
                      border: const OutlineInputBorder()),
                  items: _readDrivers
                      .map((d) =>
                          DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                ),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'readPin',
                  initialValue: m?.readPin?.toString(),
                  decoration: InputDecoration(
                      labelText: s.readPinLabel,
                      border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.integer(),
                  ]),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _hasMux,
                  title: Text(s.usesMux),
                  onChanged: (v) => setState(() => _hasMux = v),
                ),
                if (_hasMux) ...[
                  FormBuilderTextField(
                    name: 'muxChannel',
                    initialValue: m?.muxChannel?.toString(),
                    decoration: InputDecoration(
                        labelText: s.muxChannelLabel,
                        border: const OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.integer(),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  FormBuilderTextField(
                    name: 'muxSelPins',
                    initialValue: m?.muxSelPins.join(','),
                    decoration: InputDecoration(
                        labelText: s.selectorPinsLabel,
                        border: const OutlineInputBorder()),
                    keyboardType: TextInputType.text,
                  ),
                ],
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

              const SizedBox(height: 16),
              // ── Write actuator ─────────────────────────────────────────────
              _sectionHeader(s.writeActuatorSection),
              SwitchListTile(
                value: _hasWrite,
                title: Text(s.hasWriteActuator),
                onChanged: (v) => setState(() => _hasWrite = v),
              ),
              if (_hasWrite) ...[
                FormBuilderDropdown<String>(
                  name: 'writeDriver',
                  initialValue:
                      m?.writeDriver ?? _writeDrivers.first,
                  decoration: InputDecoration(
                      labelText: s.writeDriverLabel,
                      border: const OutlineInputBorder()),
                  items: _writeDrivers
                      .map((d) =>
                          DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                ),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'writePin',
                  initialValue: m?.writePin?.toString(),
                  decoration: InputDecoration(
                      labelText: s.writePinLabel,
                      border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.integer(),
                  ]),
                ),
                const SizedBox(height: 8),
                FormBuilderDropdown<String>(
                  name: 'direction',
                  initialValue: m?.direction ?? _directions.first,
                  decoration: InputDecoration(
                      labelText: s.directionLabel,
                      border: const OutlineInputBorder()),
                  items: _directions
                      .map((d) =>
                          DropdownMenuItem(value: d, child: Text(d)))
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
                      .map((o) =>
                          DropdownMenuItem(value: o, child: Text(o)))
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
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

  String get _currentScope {
    return _formKey.currentState?.fields['scope']?.value as String? ??
        widget.initial?.scope ??
        'greenhouse';
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold)),
      );

  void _submit() {
    _formKey.currentState?.validate();
    if (_formKey.currentState?.isValid != true) return;
    final f = _formKey.currentState!.fields;

    String? raw(String name) =>
        f[name]?.value?.toString().trim().let((s) => s.isEmpty ? null : s);

    final selPinsRaw = raw('muxSelPins');
    final muxSelPins = selPinsRaw != null
        ? selPinsRaw
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toList()
        : <int>[];

    final mapping = MappingConfig(
      scope: f['scope']!.value as String,
      zoneId: int.tryParse(raw('zoneId') ?? ''),
      flowerpotId: int.tryParse(raw('flowerpotId') ?? ''),
      paramName: f['paramName']!.value as String,
      readDriver: _hasRead ? f['readDriver']?.value as String? : null,
      readPin:
          _hasRead ? int.tryParse(raw('readPin') ?? '') : null,
      muxChannel:
          _hasMux ? int.tryParse(raw('muxChannel') ?? '') : null,
      muxSelPins: _hasMux ? muxSelPins : [],
      writeDriver: _hasWrite ? f['writeDriver']?.value as String? : null,
      writePin:
          _hasWrite ? int.tryParse(raw('writePin') ?? '') : null,
      direction:
          _hasWrite ? f['direction']?.value as String? : null,
      hysteresis:
          _hasWrite ? double.tryParse(raw('hysteresis') ?? '') : null,
      activeLow: _hasWrite ? f['activeLow']?.value as bool? : null,
      outputMode: _hasWrite ? f['outputMode']?.value as String? : null,
      minOnMs:
          _hasWrite ? int.tryParse(raw('minOnMs') ?? '') : null,
      minOffMs:
          _hasWrite ? int.tryParse(raw('minOffMs') ?? '') : null,
      mapInMin: _hasScaling
          ? double.tryParse(raw('mapInMin') ?? '')
          : null,
      mapInMax: _hasScaling
          ? double.tryParse(raw('mapInMax') ?? '')
          : null,
      mapOutMin: _hasScaling
          ? double.tryParse(raw('mapOutMin') ?? '')
          : null,
      mapOutMax: _hasScaling
          ? double.tryParse(raw('mapOutMax') ?? '')
          : null,
    );
    widget.onSubmit(mapping);
    Navigator.of(context).pop();
  }
}

// Small utility to avoid nullable-chain verbosity
extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
