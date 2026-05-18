import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:maker_greenhouse/models/has_parameters.dart';
import 'package:maker_greenhouse/models/has_plants.dart';
import 'package:maker_greenhouse/providers/greenhouse_notifier.dart';
import 'package:maker_greenhouse/providers/plant_list_controller_provider.dart';
import 'package:maker_greenhouse/shared/ui_constants.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../generated/l10n.dart';
import '../../models/entity_marker.dart';
import '../../models/greenhouse_model.dart';
import '../../models/greenhouse_status_model.dart';
import '../../models/has_parametrized_children.dart';
import '../../models/parameter_model.dart';
import '../../models/parameter_type.dart';
import '../../models/zone_model.dart';
import '../../models/plant_model.dart';
import '../../models/flowerpot_model.dart';
import '../../shared/loading_indicator.dart';
import '../error/error_view.dart';

// ─── Status indicator ─────────────────────────────────────────────────────────

class GreenhouseStatusIndicator extends StatelessWidget {
  const GreenhouseStatusIndicator({super.key, required this.greenhouseStatus});

  final Status greenhouseStatus;

  @override
  Widget build(BuildContext context) {
    switch (greenhouseStatus) {
      case Status.ON:
        return const Icon(Icons.signal_cellular_4_bar, color: Colors.green);
      case Status.OFF:
        return const Icon(Icons.signal_cellular_0_bar, color: Colors.red);
      case Status.NOT_RESPONSIVE:
        return const Icon(
            Icons.signal_cellular_connected_no_internet_0_bar,
            color: Colors.blue);
    }
  }
}

// ─── Entity tile ──────────────────────────────────────────────────────────────

class EntityTile extends ConsumerWidget {
  const EntityTile({
    super.key,
    required this.entity,
    required this.elevation,
    this.onAddChild,
    this.onEdit,
    this.onDelete,
    this.onPushToBoard,
    this.onConfigureDevices,
    this.onConfigureMapping,
    this.onAddParameter,
    this.onDeleteParameter,
    this.onRemovePlant,
  });

  final EntityMarker entity;
  final double elevation;

  final void Function(EntityMarker parent, BuildContext ctx, WidgetRef ref)?
      onAddChild;
  final void Function(EntityMarker entity, BuildContext ctx, WidgetRef ref)?
      onEdit;
  final void Function(EntityMarker entity, BuildContext ctx, WidgetRef ref)?
      onDelete;
  final void Function(Greenhouse gh, BuildContext ctx, WidgetRef ref)?
      onPushToBoard;
  final void Function(Greenhouse gh, BuildContext ctx, WidgetRef ref)?
      onConfigureDevices;
  final void Function(Greenhouse gh, BuildContext ctx, WidgetRef ref)?
      onConfigureMapping;
  final Future<void> Function(EntityMarker entity, Parameter param)?
      onAddParameter;
  final Future<void> Function(Parameter param)? onDeleteParameter;
  final void Function(Plant plant, HasPlants parent)? onRemovePlant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGreenhouse = entity is Greenhouse;
    final greenhouse = isGreenhouse ? entity as Greenhouse : null;

    return Card(
      color: Colors.white,
      elevation: elevation,
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        leading: isGreenhouse
            ? GreenhouseStatusIndicator(
                greenhouseStatus: greenhouse!.status)
            : null,
        title: Text(
          entity.getName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: isGreenhouse && greenhouse!.lastUpdate != null
            ? Text(
                _formatLastUpdate(greenhouse.lastUpdate!),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )
            : null,
        trailing: _buildTrailingMenu(context, ref),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Column(
              children: [
                if (entity is HasParameters)
                  ParametersControlPanel(
                    parameters: (entity as HasParameters).parameterList,
                    onAddParameter: onAddParameter != null
                        ? (param) => onAddParameter!(entity, param)
                        : null,
                    onDeleteParameter: onDeleteParameter,
                  ),
                if (entity is HasParametrizedChildren)
                  ...((entity as HasParametrizedChildren)
                      .parametrizedChildren
                      .map((child) => EntityTile(
                            entity: child,
                            elevation: 2,
                            onAddChild: onAddChild,
                            onEdit: onEdit,
                            onDelete: onDelete,
                            onAddParameter: onAddParameter,
                            onDeleteParameter: onDeleteParameter,
                            onRemovePlant: onRemovePlant,
                          ))),
              ],
            ),
          ),
          if (entity is HasPlants)
            ...(entity as HasPlants).plantList.map((plant) => PlantTile(
                  plant: plant,
                  onRemove: onRemovePlant != null
                      ? () => onRemovePlant!(plant, entity as HasPlants)
                      : null,
                )),
          if (onAddChild != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () => onAddChild!(entity, context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(_addChildLabel()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrailingMenu(BuildContext context, WidgetRef ref) {
    final items = <PopupMenuEntry<String>>[];

    if (entity is Greenhouse) {
      if (onEdit != null) {
        items.add(const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ));
      }
      if (onPushToBoard != null) {
        items.add(const PopupMenuItem(
          value: 'push',
          child: ListTile(
            leading: Icon(Icons.upload_rounded),
            title: Text('Push to board'),
            contentPadding: EdgeInsets.zero,
          ),
        ));
      }
      if (onConfigureDevices != null) {
        items.add(const PopupMenuItem(
          value: 'devices',
          child: ListTile(
            leading: Icon(Icons.settings_input_component),
            title: Text('Configure devices'),
            contentPadding: EdgeInsets.zero,
          ),
        ));
      }
      if (onConfigureMapping != null) {
        items.add(const PopupMenuItem(
          value: 'mapping',
          child: ListTile(
            leading: Icon(Icons.device_hub),
            title: Text('Configure mappings'),
            contentPadding: EdgeInsets.zero,
          ),
        ));
      }
    } else if (entity is Flowerpot) {
      if (onEdit != null) {
        items.add(const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rename'),
            contentPadding: EdgeInsets.zero,
          ),
        ));
      }
    }

    if (onDelete != null) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider());
      items.add(PopupMenuItem(
        value: 'delete',
        child: ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: Text('Delete ${entity.getName}',
              style: const TextStyle(color: Colors.red)),
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      itemBuilder: (_) => items,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call(entity, context, ref);
          case 'delete':
            onDelete?.call(entity, context, ref);
          case 'push':
            if (entity is Greenhouse) {
              onPushToBoard?.call(entity as Greenhouse, context, ref);
            }
          case 'devices':
            if (entity is Greenhouse) {
              onConfigureDevices?.call(entity as Greenhouse, context, ref);
            }
          case 'mapping':
            if (entity is Greenhouse) {
              onConfigureMapping?.call(entity as Greenhouse, context, ref);
            }
        }
      },
    );
  }

  String _addChildLabel() {
    if (entity is Greenhouse) return 'Add zone';
    if (entity is Zone) return 'Add flowerpot';
    if (entity is HasPlants) return 'Add plant';
    return 'Add';
  }

  String _formatLastUpdate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Parameters control panel ─────────────────────────────────────────────────

class ParametersControlPanel extends ConsumerStatefulWidget {
  const ParametersControlPanel({
    super.key,
    required this.parameters,
    this.onAddParameter,
    this.onDeleteParameter,
  });

  final List<Parameter> parameters;
  // null = feature disabled (e.g., during entity creation flow)
  final Future<void> Function(Parameter param)? onAddParameter;
  final Future<void> Function(Parameter param)? onDeleteParameter;

  @override
  ConsumerState<ParametersControlPanel> createState() =>
      _ParametersControlPanelState();
}

class _ParametersControlPanelState
    extends ConsumerState<ParametersControlPanel> {
  late List<Parameter> _temp;
  final List<Parameter> _changed = [];

  @override
  void initState() {
    super.initState();
    _temp = widget.parameters.map((p) => p.copyWith()).toList();
  }

  @override
  void didUpdateWidget(ParametersControlPanel old) {
    super.didUpdateWidget(old);
    if (old.parameters != widget.parameters) {
      _temp = widget.parameters.map((p) => p.copyWith()).toList();
      _changed.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ExpansionTile(
          title: Text(
            S.of(context).controlsControlPanel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            Column(
              children: [
                ..._temp.map((p) => _buildParameterRow(p)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildConfirmButton(context),
                    _buildResetButton(context),
                  ],
                ),
                if (widget.onAddParameter != null)
                  ExpansionTile(
                    title: const Text('Add parameter'),
                    children: [
                      ParameterForm(
                        onSubmit: (param) async {
                          await widget.onAddParameter!(param);
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(Parameter parameter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(parameter.name,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            if (widget.onDeleteParameter != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                iconSize: 20,
                tooltip: 'Delete parameter',
                onPressed: () => _confirmDeleteParameter(parameter),
              ),
          ],
        ),
        Text('Current: ${parameter.currentValue} ${parameter.unit ?? ''}',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text('Requested: ${parameter.requestedValue}',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          children: [
            Expanded(child: _buildControlWidget(parameter)),
            Text(parameter.unit ?? ''),
          ],
        ),
        const Divider(),
      ],
    );
  }

  void _confirmDeleteParameter(Parameter parameter) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete parameter'),
        content: Text(
            'Delete "${parameter.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDeleteParameter?.call(parameter);
            },
          ),
        ],
      ),
    );
  }

  ElevatedButton _buildResetButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _temp = widget.parameters.map((p) => p.copyWith()).toList();
          _changed.clear();
        });
      },
      child: Text(S.of(context).controlsResetChange),
    );
  }

  ElevatedButton _buildConfirmButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(S.of(context).controlsDialogTitle),
            content: Text(S.of(context).controlsDialogContent),
            actions: [
              TextButton(
                child: Text(S.of(context).controlsDialogReject),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(S.of(context).controlsDialogAccept),
                onPressed: () {
                  ref
                      .read(greenhouseNotifierProvider.notifier)
                      .updateParameters(_changed);
                },
              ),
            ],
          ),
          barrierDismissible: true,
        );
      },
      child: Text(S.of(context).controlsConfirmChange),
    );
  }

  Widget _buildControlWidget(Parameter parameter) {
    switch (parameter.parameterType) {
      case ParameterType.TOGGLE:
        return Checkbox(
          value: parameter.requestedValue == 1,
          onChanged: parameter.mutable
              ? (newVal) {
                  setState(() {
                    final idx = _temp.indexWhere((p) => p.id == parameter.id);
                    if (idx != -1) {
                      final dbl = newVal == true ? 1.0 : 0.0;
                      _changed.removeWhere((p) => p.id == parameter.id);
                      _temp[idx] = _temp[idx].copyWith(requestedValue: dbl);
                      _changed.add(_temp[idx]);
                    }
                  });
                }
              : null,
        );
      case ParameterType.VALUE:
        return FlutterSlider(
          disabled: !parameter.mutable,
          tooltip:
              FlutterSliderTooltip(rightSuffix: Text(parameter.unit ?? '')),
          values: [parameter.requestedValue],
          max: parameter.max,
          min: parameter.min,
          onDragging: (_, lower, __) {
            setState(() {
              final idx = _temp.indexWhere((p) => p.id == parameter.id);
              if (idx != -1) {
                _changed.removeWhere((p) => p.id == parameter.id);
                _temp[idx] = _temp[idx].copyWith(requestedValue: lower);
                _changed.add(_temp[idx]);
              }
            });
          },
        );
    }
  }
}

// ─── Parameter form (used in creation modals and add-to-existing) ─────────────

class ParameterForm extends ConsumerStatefulWidget {
  const ParameterForm({super.key, required this.onSubmit});

  final void Function(Parameter parameter) onSubmit;

  @override
  ConsumerState<ParameterForm> createState() => _ParameterFormState();
}

class _ParameterFormState extends ConsumerState<ParameterForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: BoxConstraints(maxWidth: width * 0.9),
            padding: const EdgeInsets.only(top: 5),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  FormBuilderTextField(
                    name: 'name',
                    decoration: const InputDecoration(
                      labelText: 'Parameter name',
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                        errorText: S.of(context).authThisFieldCannotBeEmpty),
                  ),
                  buildSizedBoxBetweenInputs(),
                  FormBuilderRangeSlider(
                    name: 'minMaxRange',
                    min: -1000,
                    max: 1000,
                    initialValue: const RangeValues(-10, 10),
                    decoration: const InputDecoration(
                        labelText: 'Value range',
                        border: OutlineInputBorder()),
                  ),
                  buildSizedBoxBetweenInputs(),
                  FormBuilderTextField(
                    name: 'unit',
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 8,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  ),
                  buildSizedBoxBetweenInputs(),
                  FormBuilderRadioGroup<String>(
                    name: 'parameterType',
                    decoration: const InputDecoration(
                      labelText: 'Parameter type',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: 'VALUE',
                    options: const [
                      FormBuilderFieldOption(value: 'VALUE', child: Text('Value')),
                      FormBuilderFieldOption(
                          value: 'TOGGLE', child: Text('Toggle')),
                    ],
                  ),
                  buildSizedBoxBetweenInputs(),
                  FormBuilderCheckbox(
                    name: 'mutable',
                    title: const Text('Is mutable (user can change value)'),
                    initialValue: true,
                  ),
                  buildSizedBoxBetweenInputs(),
                ],
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _formKey.currentState?.validate();
            if (_formKey.currentState?.isValid == true) {
              final fields = _formKey.currentState!.fields;
              final range =
                  fields['minMaxRange']!.value as RangeValues;
              widget.onSubmit(Parameter(
                name: fields['name']!.value as String,
                mutable: fields['mutable']!.value as bool? ?? true,
                unit: fields['unit']!.value as String?,
                parameterType: ParameterType.values
                    .byName((fields['parameterType']!.value as String)),
                min: range.start.truncateToDouble(),
                max: range.end.truncateToDouble(),
                currentValue: -1,
                requestedValue: -1,
              ));
            }
          },
          child: const Text('Add parameter'),
        ),
      ],
    );
  }
}

// ─── Parameter list (used in creation modals) ─────────────────────────────────

class ParameterList extends StatefulWidget {
  const ParameterList({
    super.key,
    required this.parameterList,
    required this.onAdd,
    required this.onDelete,
  });

  final List<Parameter> parameterList;
  final void Function(Parameter) onAdd;
  final void Function(Parameter) onDelete;

  @override
  State<ParameterList> createState() => _ParameterListState();
}

class _ParameterListState extends State<ParameterList> {
  late List<Parameter> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.parameterList.map((p) => p.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Parameters:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        Flexible(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _items.length + 1,
            itemBuilder: (context, index) {
              if (index == _items.length) {
                return ExpansionTile(
                  title: const Text('Add new parameter'),
                  children: [
                    ParameterForm(
                      onSubmit: (param) {
                        widget.onAdd(param);
                        setState(() => _items.add(param));
                      },
                    ),
                  ],
                );
              }
              return ParameterCard(
                parameter: _items[index],
                onDelete: (param) {
                  widget.onDelete(param);
                  setState(() => _items.remove(param));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ParameterCard extends StatelessWidget {
  const ParameterCard({super.key, required this.parameter, required this.onDelete});

  final Parameter parameter;
  final void Function(Parameter) onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${parameter.getName}'),
                Text('Mutable: ${parameter.mutable}'),
                Text(
                    'Range: ${parameter.min.truncateToDouble()} — '
                    '${parameter.max.truncateToDouble()} ${parameter.unit ?? ''}'),
              ],
            ),
            IconButton(
              onPressed: () => onDelete(parameter),
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Greenhouse modal ─────────────────────────────────────────────────────────

class GreenhouseModal extends ConsumerStatefulWidget {
  const GreenhouseModal({
    super.key,
    this.initialName,
    this.initialLocation,
    this.initialIpAddress,
    required this.appbarTitle,
    required this.onAction,
    required this.actionIcon,
    required this.actionLabel,
    required this.helpTitle,
    required this.helpContent,
    required this.parameters,
  });

  final String? initialName;
  final String? initialLocation;
  final String? initialIpAddress;
  final List<Parameter> parameters;
  final String appbarTitle;
  final void Function(String name, String location, String ipAddress,
      List<Parameter> parameters) onAction;
  final IconData actionIcon;
  final String actionLabel;
  final String helpTitle;
  final String helpContent;

  @override
  ConsumerState<GreenhouseModal> createState() => _GreenhouseModalState();
}

class _GreenhouseModalState extends ConsumerState<GreenhouseModal> {
  final _formKey = GlobalKey<FormBuilderState>();
  late List<Parameter> _params;

  @override
  void initState() {
    super.initState();
    _params = widget.parameters.map((p) => p.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.6),
      child: Material(
        child: Scaffold(
          primary: false,
          appBar: AppBar(
            title: Text(widget.appbarTitle, style: const TextStyle(fontSize: 17)),
            automaticallyImplyLeading: false,
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  _formKey.currentState?.validate();
                  if (_formKey.currentState?.isValid == true) {
                    final fields = _formKey.currentState!.fields;
                    widget.onAction(
                      fields['name']!.value as String,
                      fields['location']!.value as String,
                      fields['ipAddress']!.value as String,
                      _params,
                    );
                    Navigator.of(context).pop();
                  }
                },
                icon: Icon(widget.actionIcon, size: 20),
                label: Text(widget.actionLabel,
                    style: const TextStyle(fontSize: 15)),
              ),
              IconButton(
                icon: const Icon(Icons.help),
                onPressed: () => _showHelp(context),
              ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: BoxConstraints(maxWidth: width * 0.9),
              padding: const EdgeInsets.only(top: 5),
              child: FormBuilder(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      FormBuilderTextField(
                        name: 'name',
                        initialValue: widget.initialName,
                        decoration: InputDecoration(
                          labelText: S
                              .of(context)
                              .addNewGreenhouseTextFieldGreenhouseNameLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: FormBuilderValidators.required(
                            errorText:
                                S.of(context).authThisFieldCannotBeEmpty),
                      ),
                      buildSizedBoxBetweenInputs(),
                      FormBuilderTextField(
                        name: 'location',
                        initialValue: widget.initialLocation,
                        decoration: InputDecoration(
                          labelText: S
                              .of(context)
                              .addNewGreenhouseTextFieldGreenhouseLocationLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: FormBuilderValidators.required(
                            errorText:
                                S.of(context).authThisFieldCannotBeEmpty),
                      ),
                      buildSizedBoxBetweenInputs(),
                      FormBuilderTextField(
                        name: 'ipAddress',
                        initialValue: widget.initialIpAddress,
                        decoration: InputDecoration(
                          labelText: S
                              .of(context)
                              .addNewGreenhouseTextFieldGreenhouseIpAddressLabel,
                          border: const OutlineInputBorder(),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                              errorText:
                                  S.of(context).authThisFieldCannotBeEmpty),
                          FormBuilderValidators.ip(
                              errorText: S
                                  .of(context)
                                  .addNewGreenhouseTextFieldGreenhouseIpAddressErrorLabel),
                        ]),
                      ),
                      ParameterList(
                        parameterList: _params,
                        onAdd: (p) => _params.add(p),
                        onDelete: (p) => _params.remove(p),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(widget.helpTitle, style: const TextStyle(fontSize: 25)),
        content: Text(S.of(context).addNewGreenhouseHelpContent,
            style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            child: Text(widget.helpContent,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}

// ─── Zone modal ───────────────────────────────────────────────────────────────

class ZoneModal extends ConsumerStatefulWidget {
  const ZoneModal({
    super.key,
    this.initialName,
    required this.appbarTitle,
    required this.onAction,
    required this.actionIcon,
    required this.actionLabel,
    required this.helpTitle,
    required this.helpContent,
    required this.parameters,
  });

  final String? initialName;
  final String appbarTitle;
  final void Function(String name, List<Parameter> parameters) onAction;
  final IconData actionIcon;
  final String actionLabel;
  final String helpTitle;
  final String helpContent;
  final List<Parameter> parameters;

  @override
  ConsumerState<ZoneModal> createState() => _ZoneModalState();
}

class _ZoneModalState extends ConsumerState<ZoneModal> {
  final _formKey = GlobalKey<FormBuilderState>();
  late List<Parameter> _params;

  @override
  void initState() {
    super.initState();
    _params = widget.parameters.map((p) => p.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.5),
      child: Material(
        child: Scaffold(
          primary: false,
          appBar: AppBar(
            title: Text(widget.appbarTitle,
                style: const TextStyle(fontSize: 17)),
            automaticallyImplyLeading: false,
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  _formKey.currentState?.validate();
                  if (_formKey.currentState?.isValid == true) {
                    widget.onAction(
                        _formKey.currentState!.fields['name']!.value as String,
                        _params);
                    Navigator.of(context).pop();
                  }
                },
                icon: Icon(widget.actionIcon, size: 20),
                label: Text(widget.actionLabel,
                    style: const TextStyle(fontSize: 15)),
              ),
              IconButton(
                icon: const Icon(Icons.help),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(widget.helpTitle),
                    content: Text(widget.helpContent),
                    actions: [
                      TextButton(
                          child: const Text('OK'),
                          onPressed: () => Navigator.pop(context))
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: BoxConstraints(maxWidth: width * 0.9),
              padding: const EdgeInsets.only(top: 5),
              child: FormBuilder(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      FormBuilderTextField(
                        name: 'name',
                        initialValue: widget.initialName,
                        decoration: InputDecoration(
                          labelText: S
                              .of(context)
                              .addNewGreenhouseTextFieldGreenhouseNameLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: FormBuilderValidators.required(
                            errorText:
                                S.of(context).authThisFieldCannotBeEmpty),
                      ),
                      buildSizedBoxBetweenInputs(),
                      ParameterList(
                        parameterList: _params,
                        onAdd: (p) => _params.add(p),
                        onDelete: (p) => _params.remove(p),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Flowerpot modal ──────────────────────────────────────────────────────────

class FlowerpotModal extends ConsumerStatefulWidget {
  const FlowerpotModal({
    super.key,
    this.initialName,
    required this.appbarTitle,
    required this.onAction,
    required this.actionIcon,
    required this.actionLabel,
    required this.helpTitle,
    required this.helpContent,
    required this.parameters,
  });

  final String? initialName;
  final String appbarTitle;
  final void Function(String name, List<Parameter> parameters) onAction;
  final IconData actionIcon;
  final String actionLabel;
  final String helpTitle;
  final String helpContent;
  final List<Parameter> parameters;

  @override
  ConsumerState<FlowerpotModal> createState() => _FlowerpotModalState();
}

class _FlowerpotModalState extends ConsumerState<FlowerpotModal> {
  final _formKey = GlobalKey<FormBuilderState>();
  late List<Parameter> _params;

  @override
  void initState() {
    super.initState();
    _params = widget.parameters.map((p) => p.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.5),
      child: Material(
        child: Scaffold(
          primary: false,
          appBar: AppBar(
            title: Text(widget.appbarTitle,
                style: const TextStyle(fontSize: 17)),
            automaticallyImplyLeading: false,
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  _formKey.currentState?.validate();
                  if (_formKey.currentState?.isValid == true) {
                    widget.onAction(
                        _formKey.currentState!.fields['name']!.value as String,
                        _params);
                    Navigator.of(context).pop();
                  }
                },
                icon: Icon(widget.actionIcon, size: 20),
                label: Text(widget.actionLabel,
                    style: const TextStyle(fontSize: 15)),
              ),
              IconButton(
                icon: const Icon(Icons.help),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(widget.helpTitle),
                    content: Text(widget.helpContent),
                    actions: [
                      TextButton(
                          child: const Text('OK'),
                          onPressed: () => Navigator.pop(context))
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: BoxConstraints(maxWidth: width * 0.9),
              padding: const EdgeInsets.only(top: 5),
              child: FormBuilder(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      FormBuilderTextField(
                        name: 'name',
                        initialValue: widget.initialName,
                        decoration: InputDecoration(
                          labelText: S
                              .of(context)
                              .addNewGreenhouseTextFieldGreenhouseNameLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: FormBuilderValidators.required(
                            errorText:
                                S.of(context).authThisFieldCannotBeEmpty),
                      ),
                      buildSizedBoxBetweenInputs(),
                      ParameterList(
                        parameterList: _params,
                        onAdd: (p) => _params.add(p),
                        onDelete: (p) => _params.remove(p),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Add greenhouse button ────────────────────────────────────────────────────

class AddNewGreenhouseButton extends ConsumerWidget {
  const AddNewGreenhouseButton({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showModal(context, ref),
      child: Container(
        constraints: BoxConstraints(minHeight: height * 0.09),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showModal(BuildContext context, WidgetRef ref) {
    showMaterialModalBottomSheet(
      elevation: modalBottomSheetElevation,
      context: context,
      builder: (_) => GreenhouseModal(
        appbarTitle: S.of(context).addNewGreenhouseAppbarTitle,
        onAction: (name, location, ip, params) {
          ref.read(greenhouseNotifierProvider.notifier).addNewGreenhouse(
                Greenhouse(name: name, location: location, ipAddress: ip,
                    parameters: params),
              );
        },
        actionIcon: Icons.add,
        actionLabel: S.of(context).addNewGreenhouseAppbarButton,
        helpTitle: S.of(context).addNewGreenhouseHelpTitle,
        helpContent: S.of(context).addNewGreenhouseHelpContent,
        parameters: const [],
      ),
    );
  }
}

// ─── Plant tile ───────────────────────────────────────────────────────────────

class PlantTile extends StatelessWidget {
  const PlantTile({super.key, required this.plant, this.onRemove});

  final Plant plant;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.local_florist),
      title: Text(plant.name),
      subtitle: Text(S.of(context).controlsDescription(plant.description)),
      trailing: onRemove != null
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.orange),
              tooltip: 'Remove from flowerpot',
              onPressed: () => _confirmRemove(context),
            )
          : null,
      children: [
        if (plant.requirements.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Requirements:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...plant.requirements.map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${r.name}: ${r.lowerThreshold} – ${r.upperThreshold} ${r.unit}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove plant'),
        content: Text('Remove "${plant.name}" from this flowerpot?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Remove',
                style: TextStyle(color: Colors.orange)),
            onPressed: () {
              Navigator.of(context).pop();
              onRemove?.call();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Plant modal (add plant to flowerpot) ─────────────────────────────────────

class PlantModal extends StatelessWidget {
  const PlantModal({super.key, required this.entityWithPlants});

  final HasPlants entityWithPlants;

  @override
  Widget build(BuildContext mainContext) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(mainContext).size.height * 0.6),
      child: Material(
        child: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => Builder(builder: (childContext) {
              return Scaffold(
                primary: false,
                appBar: AppBar(
                  title: Text(
                    S.of(mainContext).addPlantToGreenhouseModalTitle(
                        entityWithPlants.getName),
                    style: const TextStyle(fontSize: 20),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(childContext).push(
                          MaterialPageRoute(
                              builder: (_) => const AddNewPlantForm()),
                        );
                      },
                      child: Text(S
                          .of(mainContext)
                          .addPlantToGreenhouseAppbarButton),
                    ),
                  ],
                ),
                body: Consumer(
                  builder: (_, ref, __) {
                    final plants = ref.watch(plantListNotifierProvider);
                    return plants.when(
                      data: (data) => ListView.builder(
                        shrinkWrap: true,
                        itemCount: data.length,
                        itemBuilder: (_, i) => Card(
                          child: ListTile(
                            title: Text(data[i].name),
                            subtitle: Text(data[i].description),
                            onTap: () {
                              if (entityWithPlants.getId != null &&
                                  data[i].getId != null) {
                                ref
                                    .read(greenhouseNotifierProvider.notifier)
                                    .addNewPlantToFlowerpot(
                                        data[i].getId!,
                                        entityWithPlants.getId!);
                                Navigator.of(mainContext).pop();
                              }
                            },
                          ),
                        ),
                      ),
                      error: (e, _) => ErrorScreen(
                        error: e,
                        onRetry: () =>
                            ref.invalidate(plantListNotifierProvider),
                      ),
                      loading: () => const LoadingIndicatorWidget(),
                    );
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Add new plant form ───────────────────────────────────────────────────────

class AddNewPlantForm extends ConsumerStatefulWidget {
  const AddNewPlantForm({super.key});

  @override
  ConsumerState<AddNewPlantForm> createState() => _AddNewPlantFormState();
}

class _AddNewPlantFormState extends ConsumerState<AddNewPlantForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).addNewPlantAppbarTitle,
            style: const TextStyle(fontSize: 17)),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              _formKey.currentState?.validate();
              if (_formKey.currentState?.isValid == true) {
                final fields = _formKey.currentState!.fields;
                ref.read(plantListNotifierProvider.notifier).addPlant(Plant(
                      name: fields['name']!.value as String,
                      description: fields['description']!.value as String,
                    ));
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.add, size: 20),
            label: Text(S.of(context).addNewPlantAppbarButton,
                style: const TextStyle(fontSize: 15)),
          ),
          IconButton(
            icon: const Icon(Icons.help),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(S.of(context).addNewPlantHelpTitle,
                    style: const TextStyle(fontSize: 25)),
                content: Text(S.of(context).addNewPlantHelpContent,
                    style: const TextStyle(fontSize: 15)),
                actions: [
                  TextButton(
                    child: Text(S.of(context).addNewPlantHelpDismiss,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      primary: false,
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: BoxConstraints(maxWidth: width * 0.9),
          padding: const EdgeInsets.only(top: 5),
          child: FormBuilder(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  FormBuilderTextField(
                    name: 'name',
                    decoration: InputDecoration(
                      labelText:
                          S.of(context).addNewPlantTextFieldPlantName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                        errorText:
                            S.of(context).authThisFieldCannotBeEmpty),
                  ),
                  buildSizedBoxBetweenInputs(),
                  FormBuilderTextField(
                    name: 'description',
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText:
                          S.of(context).addNewPlantTextFieldDescription,
                      border: const OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                        errorText:
                            S.of(context).authThisFieldCannotBeEmpty),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Rename flowerpot modal ───────────────────────────────────────────────────

class RenameFlowerpotModal extends ConsumerStatefulWidget {
  const RenameFlowerpotModal({
    super.key,
    required this.flowerpot,
  });

  final Flowerpot flowerpot;

  @override
  ConsumerState<RenameFlowerpotModal> createState() =>
      _RenameFlowerpotModalState();
}

class _RenameFlowerpotModalState
    extends ConsumerState<RenameFlowerpotModal> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.3),
      child: Material(
        child: Scaffold(
          primary: false,
          appBar: AppBar(
            title: const Text('Rename flowerpot',
                style: TextStyle(fontSize: 17)),
            automaticallyImplyLeading: false,
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  _formKey.currentState?.validate();
                  if (_formKey.currentState?.isValid == true) {
                    final name = _formKey
                        .currentState!.fields['name']!.value as String;
                    ref
                        .read(greenhouseNotifierProvider.notifier)
                        .editFlowerpot(name, widget.flowerpot.id!);
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.check, size: 20),
                label: const Text('Save'),
              ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: BoxConstraints(maxWidth: width * 0.9),
              padding: const EdgeInsets.only(top: 10),
              child: FormBuilder(
                key: _formKey,
                child: FormBuilderTextField(
                  name: 'name',
                  initialValue: widget.flowerpot.name,
                  decoration: const InputDecoration(
                    labelText: 'Flowerpot name',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

SizedBox buildSizedBoxBetweenInputs() => const SizedBox(height: 5);