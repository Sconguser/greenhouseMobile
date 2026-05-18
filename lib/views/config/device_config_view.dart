import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../models/device_config_model.dart';
import '../../models/greenhouse_model.dart';
import '../../providers/device_config_notifier.dart';
import '../../shared/loading_indicator.dart';
import '../error/error_view.dart';

class DeviceConfigView extends ConsumerWidget {
  const DeviceConfigView({super.key, required this.greenhouse});

  final Greenhouse greenhouse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync =
        ref.watch(deviceConfigNotifierProvider(greenhouse.id!));
    return Scaffold(
      appBar: AppBar(
        title: Text('Devices — ${greenhouse.name}'),
      ),
      body: configAsync.when(
        data: (configs) => _DeviceConfigList(
          greenhouse: greenhouse,
          initial: configs,
        ),
        error: (e, _) => ErrorScreen(
          error: e,
          onRetry: () =>
              ref.invalidate(deviceConfigNotifierProvider(greenhouse.id!)),
        ),
        loading: () => const LoadingIndicatorWidget(),
      ),
    );
  }
}

class _DeviceConfigList extends ConsumerStatefulWidget {
  const _DeviceConfigList(
      {required this.greenhouse, required this.initial});

  final Greenhouse greenhouse;
  final List<DeviceConfig> initial;

  @override
  ConsumerState<_DeviceConfigList> createState() => _DeviceConfigListState();
}

class _DeviceConfigListState extends ConsumerState<_DeviceConfigList> {
  late List<DeviceConfig> _devices;

  static const _drivers = ['digital', 'dht22', 'muxAnalog'];
  static const _types = ['value', 'toggle'];

  @override
  void initState() {
    super.initState();
    _devices = List.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _devices.isEmpty
              ? const Center(child: Text('No devices configured yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _devices.length,
                  itemBuilder: (_, i) => _DeviceCard(
                    device: _devices[i],
                    onEdit: () => _editDevice(i),
                    onDelete: () => setState(() => _devices.removeAt(i)),
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
                onPressed: _addDevice,
                icon: const Icon(Icons.add),
                label: const Text('Add device'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirmSave(context),
                icon: const Icon(Icons.upload_rounded),
                label: const Text('Save & push'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDevice() => _openForm(null);
  void _editDevice(int index) => _openForm(index);

  void _openForm(int? editIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DeviceForm(
        initial: editIndex != null ? _devices[editIndex] : null,
        onSubmit: (device) {
          setState(() {
            if (editIndex != null) {
              _devices[editIndex] = device;
            } else {
              _devices.add(device);
            }
          });
        },
        drivers: _drivers,
        types: _types,
      ),
    );
  }

  void _confirmSave(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Push device config to board'),
        content: const Text(
          'Saving device configuration will push the changes to the board '
          'and trigger a restart. This may take up to 30 seconds.',
        ),
        actions: [
          TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text('Save & push'),
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(deviceConfigNotifierProvider(widget.greenhouse.id!)
                      .notifier)
                  .saveDeviceConfig(_devices);
            },
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard(
      {required this.device,
      required this.onEdit,
      required this.onDelete});

  final DeviceConfig device;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.settings_input_component),
        title: Text(device.name),
        subtitle: Text(
            '${device.driver} · ${device.type} · pin ${device.pin}'
            '${device.minValue != null ? ' · ${device.minValue}–${device.maxValue}' : ''}'),
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
}

class _DeviceForm extends StatefulWidget {
  const _DeviceForm({
    this.initial,
    required this.onSubmit,
    required this.drivers,
    required this.types,
  });

  final DeviceConfig? initial;
  final void Function(DeviceConfig) onSubmit;
  final List<String> drivers;
  final List<String> types;

  @override
  State<_DeviceForm> createState() => _DeviceFormState();
}

class _DeviceFormState extends State<_DeviceForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: SingleChildScrollView(
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.initial == null ? 'Add device' : 'Edit device',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FormBuilderTextField(
                name: 'name',
                initialValue: widget.initial?.name,
                decoration: const InputDecoration(
                    labelText: 'Device name', border: OutlineInputBorder()),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 8),
              FormBuilderDropdown<String>(
                name: 'driver',
                initialValue: widget.initial?.driver ?? widget.drivers.first,
                decoration: const InputDecoration(
                    labelText: 'Driver', border: OutlineInputBorder()),
                items: widget.drivers
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
              ),
              const SizedBox(height: 8),
              FormBuilderDropdown<String>(
                name: 'type',
                initialValue: widget.initial?.type ?? widget.types.first,
                decoration: const InputDecoration(
                    labelText: 'Type', border: OutlineInputBorder()),
                items: widget.types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
              ),
              const SizedBox(height: 8),
              FormBuilderTextField(
                name: 'pin',
                initialValue: widget.initial?.pin.toString(),
                decoration: const InputDecoration(
                    labelText: 'GPIO pin', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.integer(),
                ]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'minValue',
                      initialValue: widget.initial?.minValue?.toString(),
                      decoration: const InputDecoration(
                          labelText: 'Min value (optional)',
                          border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'maxValue',
                      initialValue: widget.initial?.maxValue?.toString(),
                      decoration: const InputDecoration(
                          labelText: 'Max value (optional)',
                          border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: Text(
                    widget.initial == null ? 'Add device' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    _formKey.currentState?.validate();
    if (_formKey.currentState?.isValid != true) return;
    final f = _formKey.currentState!.fields;
    widget.onSubmit(DeviceConfig(
      name: f['name']!.value as String,
      driver: f['driver']!.value as String,
      type: f['type']!.value as String,
      pin: int.parse(f['pin']!.value as String),
      minValue: double.tryParse(f['minValue']?.value ?? ''),
      maxValue: double.tryParse(f['maxValue']?.value ?? ''),
    ));
    Navigator.of(context).pop();
  }
}
