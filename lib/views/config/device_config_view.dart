import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../generated/l10n.dart';
import '../../models/device_config_model.dart';
import '../../models/greenhouse_model.dart';
import '../../providers/device_config_notifier.dart';
import '../../shared/help.dart';
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
        title: Text(S.of(context).devicesTitle(greenhouse.name)),
        actions: [
          HelpButton(
            title: S.of(context).devicesHelpTitle,
            body: S.of(context).devicesHelpBody,
          ),
        ],
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
  bool _isDirty = false;

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
              ? Center(child: Text(S.of(context).noDevicesYet))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _devices.length,
                  itemBuilder: (_, i) => _DeviceCard(
                    device: _devices[i],
                    onEdit: () => _editDevice(i),
                    onDelete: () => setState(() {
                      _devices.removeAt(i);
                      _isDirty = true;
                    }),
                  ),
                ),
        ),
        if (_isDirty) _UnsavedBanner(message: S.of(context).unsavedChangesHint),
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
                label: Text(S.of(context).addDevice),
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
            _isDirty = true;
          });
        },
        drivers: _drivers,
        types: _types,
      ),
    );
  }

  void _confirmSave(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(s.pushDeviceConfigTitle),
        content: Text(s.pushDeviceConfigContent),
        actions: [
          TextButton(
              child: Text(s.cancel),
              onPressed: () => Navigator.of(dialogCtx).pop()),
          ElevatedButton(
            child: Text(s.saveAndPush),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              // Adopt the server response so local state carries the assigned
              // ids; otherwise mappings built next would reference id-less
              // devices and silently fail to bind on the board.
              final saved = await ref
                  .read(deviceConfigNotifierProvider(widget.greenhouse.id!)
                      .notifier)
                  .saveDeviceConfig(_devices);
              if (!mounted) return;
              setState(() {
                _devices = saved;
                _isDirty = false;
              });
            },
          ),
        ],
      ),
    );
  }
}

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
    final extra = StringBuffer('${device.driver} · pin ${device.pin}');
    if (device.driver == 'digital') extra.write(' · ${device.type}');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.settings_input_component),
        title: Text(device.name),
        subtitle: Text(extra.toString()),
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
  late String _selectedDriver;

  @override
  void initState() {
    super.initState();
    _selectedDriver = widget.initial?.driver ?? widget.drivers.first;
  }

  bool get _isDigital => _selectedDriver == 'digital';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
                widget.initial == null ? s.addDevice : s.editDeviceFormTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FormBuilderTextField(
                name: 'name',
                initialValue: widget.initial?.name,
                decoration: InputDecoration(
                    labelText: s.deviceNameLabel,
                    border: const OutlineInputBorder()),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 8),
              FormBuilderDropdown<String>(
                name: 'driver',
                initialValue: _selectedDriver,
                decoration: InputDecoration(
                    labelText: s.driverLabel,
                    border: const OutlineInputBorder()),
                items: widget.drivers
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedDriver = v ?? widget.drivers.first),
              ),
              const SizedBox(height: 8),
              // Type only relevant for digital (value vs toggle)
              if (_isDigital) ...[
                FormBuilderDropdown<String>(
                  name: 'type',
                  initialValue: widget.initial?.type ?? widget.types.first,
                  decoration: InputDecoration(
                      labelText: s.typeLabel,
                      border: const OutlineInputBorder()),
                  items: widget.types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
              FormBuilderTextField(
                name: 'pin',
                initialValue: widget.initial?.pin.toString(),
                decoration: InputDecoration(
                    labelText: s.gpioPinLabel,
                    border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.integer(),
                ]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: Text(
                    widget.initial == null ? s.addDevice : s.saveChanges),
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
      driver: _selectedDriver,
      type: _isDigital ? f['type']!.value as String : 'value',
      pin: int.parse(f['pin']!.value as String),
    ));
    Navigator.of(context).pop();
  }
}
