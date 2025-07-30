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
import '../../shared/loading_indicator.dart';
import '../../shared/status/parameter_list.dart';
import '../error/error_view.dart';

const String humidityUnit = "%";
const String temperatureUnit = "℃";

class GreenhouseStatusIndicator extends StatelessWidget {
  const GreenhouseStatusIndicator({
    super.key,
    required this.greenhouseStatus,
  });

  final Status greenhouseStatus;

  @override
  Widget build(BuildContext context) {
    switch (greenhouseStatus) {
      case Status.ON:
        return Icon(
          Icons.signal_cellular_4_bar,
          color: Colors.green,
        );
      case Status.OFF:
        return Icon(
          Icons.signal_cellular_0_bar,
          color: Colors.red,
        );
      case Status.NOT_RESPONSIVE:
        return Icon(
          Icons.signal_cellular_connected_no_internet_0_bar,
          color: Colors.blue,
        );
    }
  }
}

class EntityTile extends ConsumerWidget {
  const EntityTile(
      {super.key,
      required this.entity,
      this.onAddChild,
      required this.elevation});

  final EntityMarker entity;
  final void Function(EntityMarker parent, BuildContext context, WidgetRef ref)?
      onAddChild;
  final double elevation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.white,
      elevation: elevation,
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Text(
          entity.getName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        // subtitle: Text(S.of(context).controlsLocation(greenhouse.location)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Column(
              children: [
                // GreenhouseStatusPanel(greenhouse: greenhouse),
                if (entity is HasParameters)
                  ParametersControlPanel(
                    parameters: (entity as HasParameters).parameterList,
                  ),
                if (entity is HasParametrizedChildren)
                  ...((entity as HasParametrizedChildren)
                      .parametrizedChildren
                      .map((e) => EntityTile(
                            entity: e,
                            onAddChild: onAddChild,
                            elevation: 2,
                          ))),
              ],
            ),
          ),
          if (entity is HasPlants)
            ...(entity as HasPlants).plantList.map((plant) => PlantTile(
                  plant: plant,
                )),
          if (onAddChild != null)
            ElevatedButton(
              onPressed: () => onAddChild?.call(entity, context, ref),
              child: Text("Add"),
            ),
        ],
      ),
    );
  }

  Future<dynamic> buildPlantListBottomSheet(
      BuildContext context, HasPlants entityWithPlants) {
    return showMaterialModalBottomSheet(
        elevation: 5,
        context: context,
        builder: (context) {
          return PlantModal(
            entityWithPlants: entityWithPlants,
          );
        });
  }
}

class PlantModal extends StatelessWidget {
  const PlantModal({
    super.key,
    required this.entityWithPlants,
  });

  final HasPlants entityWithPlants;

  @override
  Widget build(BuildContext mainContext) {
    return Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(mainContext).size.height * 0.6),
        child: Material(
            child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute(
                    builder: (childContext) =>
                        Builder(builder: (childContext2) {
                          return Scaffold(
                            primary: false,
                            appBar: AppBar(
                              title: Text(
                                S
                                    .of(mainContext)
                                    .addPlantToGreenhouseModalTitle(
                                        entityWithPlants.getName),
                                style: TextStyle(fontSize: 20),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(childContext2).push(
                                        MaterialPageRoute(builder: (context) {
                                      return AddNewPlantForm();
                                    }));
                                  },
                                  child: Text(S
                                      .of(mainContext)
                                      .addPlantToGreenhouseAppbarButton),
                                ),
                              ],
                            ),
                            body: Consumer(
                              builder: (BuildContext context, WidgetRef ref,
                                  Widget? child) {
                                final plants =
                                    ref.watch(plantListNotifierProvider);
                                return plants.when(
                                  data: (List<Plant> data) {
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      // controller:
                                      //     ModalScrollController.of(childContext2),
                                      itemCount: data.length,
                                      itemBuilder: (context, index) {
                                        return Card(
                                          child: ListTile(
                                            title: Text(data[index].name),
                                            subtitle:
                                                Text(data[index].description),
                                            onTap: () {
                                              if (entityWithPlants.getId !=
                                                      null &&
                                                  data[index].getId != null) {
                                                ref
                                                    .read(
                                                        greenhouseNotifierProvider
                                                            .notifier)
                                                    .addNewPlantToFlowerpot(
                                                        data[index].getId!,
                                                        entityWithPlants
                                                            .getId!);
                                                Navigator.of(mainContext).pop();
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  error: (Object error, StackTrace stackTrace) {
                                    return ErrorScreen(
                                      error: error,
                                      onRetry: () {
                                        ref.invalidate(
                                            plantListNotifierProvider);
                                      },
                                    );
                                  },
                                  loading: () {
                                    return LoadingIndicatorWidget();
                                  },
                                );
                              },
                            ),
                          );
                        })))));
  }
}

class AddNewGreenhouseButton extends ConsumerWidget {
  const AddNewGreenhouseButton({
    super.key,
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        buildAddGreenhouseBottomSheet(context, ref);
      },
      child: Container(
        constraints: BoxConstraints(minHeight: height * 0.09),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<dynamic> buildAddGreenhouseBottomSheet(
      BuildContext context, WidgetRef ref) {
    return showMaterialModalBottomSheet(
        elevation: modalBottomSheetElevation,
        context: context,
        builder: (context) {
          return GreenhouseModal(
            appbarTitle: S.of(context).addNewGreenhouseAppbarTitle,
            onAction: (name, location, ipAddress) async {
              ref.read(greenhouseNotifierProvider.notifier).addNewGreenhouse(
                    Greenhouse(
                        name: name, location: location, ipAddress: ipAddress),
                  );
            },
            actionIcon: Icons.add,
            actionLabel: S.of(context).addNewGreenhouseAppbarButton,
            helpTitle: S.of(context).addNewGreenhouseHelpTitle,
            helpContent: S.of(context).addNewGreenhouseHelpContent,
            parameters: [],
          );
        });
  }
}

class ParameterForm extends ConsumerStatefulWidget {
  const ParameterForm({super.key, required this.onSubmit});

  final void Function(Parameter parameter) onSubmit;

  @override
  ConsumerState<ParameterForm> createState() => _ParameterFormState();
}

class _ParameterFormState extends ConsumerState<ParameterForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  final GlobalKey<FormBuilderFieldState> _nameFieldKey =
      GlobalKey<FormBuilderFieldState>();
  final GlobalKey<FormBuilderFieldState> _minMaxFieldKey =
      GlobalKey<FormBuilderFieldState>();
  final GlobalKey<FormBuilderFieldState> _unitFieldKey =
      GlobalKey<FormBuilderFieldState>();
  final GlobalKey<FormBuilderFieldState> _parameterTypeFieldKey =
      GlobalKey<FormBuilderFieldState>();
  final GlobalKey<FormBuilderFieldState> _mutableFieldKey =
      GlobalKey<FormBuilderFieldState>();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: BoxConstraints(maxWidth: width * 0.9),
            padding: EdgeInsets.only(top: 5),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 5),
                  FormBuilderTextField(
                    key: _nameFieldKey,
                    name: 'name',
                    decoration: InputDecoration(
                      labelText: "Parameter name",
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: S.of(context).authThisFieldCannotBeEmpty),
                    ]),
                  ),
                  buildSizedBoxBetweenInputs(),
                  FormBuilderRangeSlider(
                    key: _minMaxFieldKey,
                    name: 'minMaxRange',
                    min: -100,
                    max: 100,
                    initialValue: RangeValues(-10, 10),
                    decoration: InputDecoration(
                        labelText: "Range of values",
                        border: OutlineInputBorder()),
                  ),
                  buildSizedBoxBetweenInputs(),
                  FormBuilderTextField(
                    key: _unitFieldKey,
                    name: "unit",
                    decoration: InputDecoration(
                      labelText: "unit",
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: S.of(context).authThisFieldCannotBeEmpty),
                    ]),
                    maxLength: 5,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  ),
                  buildSizedBoxBetweenInputs(),
                  FormBuilderCheckbox(
                    key: _mutableFieldKey,
                    name: "mutable",
                    title: Text("Is mutable"),
                    decoration: InputDecoration(
                      labelText: "Mutable parameter",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: true,
                    onChanged: (isMutable) {},
                  ),
                  buildSizedBoxBetweenInputs(),
                  FormBuilderRadioGroup(
                    key: _parameterTypeFieldKey,
                    name: "parameterType",
                    decoration: InputDecoration(
                      labelText: "Parameter type",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: "Toggle",
                    options: [
                      FormBuilderFieldOption(
                        value: "Toggle",
                      ),
                      FormBuilderFieldOption(
                        value: "Value",
                      )
                    ],
                  ),
                  buildSizedBoxBetweenInputs(),
                ],
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            _formKey.currentState?.validate();
            if (_formKey.currentState != null &&
                _formKey.currentState!.isValid) {
              widget.onSubmit.call(Parameter(
                name: _nameFieldKey.currentState!.value,
                mutable: _mutableFieldKey.currentState!.value,
                unit: _unitFieldKey.currentState!.value,
                type: ParameterType.values.byName(
                    _parameterTypeFieldKey.currentState!.value.toUpperCase()),
                min: _minMaxFieldKey.currentState!.value.start,
                max: _minMaxFieldKey.currentState!.value.end,
                currentValue: -1,
                requestedValue: -1,
              ));
            }
          },
          child: Text("Add parameter"),
        ),
      ],
    );
  }
}

class ParameterList extends StatefulWidget {
  const ParameterList({super.key, required this.parameterList});

  final List<Parameter> parameterList;

  @override
  State<ParameterList> createState() => _ParameterListState();
}

class _ParameterListState extends State<ParameterList> {
  late List<Parameter> tempParameterList = [];

  @override
  void initState() {
    super.initState();
    for (var parameter in widget.parameterList) {
      tempParameterList.add(parameter.copyWith());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Parameters:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Flexible(
          child: ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              // padding: const EdgeInsets.all(16.0),
              itemCount: widget.parameterList.length + 1,
              // Add 1 for the button
              itemBuilder: (context, index) {
                if (index == widget.parameterList.length) {
                  return ExpansionTile(
                    title: Text("Add new parameter"),
                    children: [
                      ParameterForm(
                        onSubmit: (parameter) {
                          setState(() {
                            widget.parameterList.add(parameter);
                          });
                        },
                      ),
                    ],
                  );
                }
                return Card(
                  child: Text(widget.parameterList.elementAt(index).getName),
                );
              }),
        ),
      ],
    );
  }
}

class GreenhouseModal extends ConsumerStatefulWidget {
  final String? initialName;
  final String? initialLocation;
  final String? initialIpAddress;
  final List<Parameter> parameters;
  final String appbarTitle;
  final void Function(String name, String location, String ipAddress) onAction;
  final IconData actionIcon;
  final String actionLabel;
  final String helpTitle;
  final String helpContent;

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

  @override
  ConsumerState<GreenhouseModal> createState() => _AddNewGreenhouseModalState();
}

class _AddNewGreenhouseModalState extends ConsumerState<GreenhouseModal> {
  final _formKey = GlobalKey<FormBuilderState>();

  final GlobalKey<FormBuilderFieldState> _nameFieldKey =
      GlobalKey<FormBuilderFieldState>();
  final GlobalKey<FormBuilderFieldState> _locationFieldKey =
      GlobalKey<FormBuilderFieldState>();
  final GlobalKey<FormBuilderFieldState> _ipAddressFieldKey =
      GlobalKey<FormBuilderFieldState>();

  @override
  Widget build(BuildContext mainContext) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.4),
      child: Material(
        child: Scaffold(
            primary: false,
            appBar: AppBar(
              title: Text(
                widget.appbarTitle,
                style: TextStyle(fontSize: 17),
              ),
              automaticallyImplyLeading: false,
              actions: [
                ElevatedButton.icon(
                  onPressed: () async {
                    _formKey.currentState?.validate();
                    if (_formKey.currentState != null &&
                        _formKey.currentState!.isValid) {
                      widget.onAction(
                          _nameFieldKey.currentState!.value,
                          _locationFieldKey.currentState!.value,
                          _ipAddressFieldKey.currentState!.value);
                      Navigator.of(mainContext).pop();
                    }
                  },
                  icon: Icon(
                    widget.actionIcon,
                    size: 20,
                  ),
                  label: Text(
                    widget.actionLabel,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.help),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                              title: Text(widget.helpTitle,
                                  style: TextStyle(fontSize: 25)),
                              content: Text(
                                  S.of(context).addNewGreenhouseHelpContent,
                                  style: TextStyle(fontSize: 15)),
                              actions: [
                                TextButton(
                                  child: Text(widget.helpContent,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                  },
                                ),
                              ],
                            ),
                        barrierDismissible: true);
                  },
                ),
              ],
            ),
            body: Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: BoxConstraints(maxWidth: width * 0.9),
                padding: EdgeInsets.only(top: 5),
                child: FormBuilder(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        FormBuilderTextField(
                          key: _nameFieldKey,
                          name: 'name',
                          initialValue: widget.initialName,
                          decoration: InputDecoration(
                            labelText: S
                                .of(context)
                                .addNewGreenhouseTextFieldGreenhouseNameLabel,
                            border: OutlineInputBorder(),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                                errorText:
                                    S.of(context).authThisFieldCannotBeEmpty),
                          ]),
                        ),
                        buildSizedBoxBetweenInputs(),
                        FormBuilderTextField(
                          key: _locationFieldKey,
                          name: 'location',
                          initialValue: widget.initialLocation,
                          decoration: InputDecoration(
                            labelText: S
                                .of(context)
                                .addNewGreenhouseTextFieldGreenhouseLocationLabel,
                            border: OutlineInputBorder(),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                                errorText:
                                    S.of(context).authThisFieldCannotBeEmpty),
                          ]),
                        ),
                        buildSizedBoxBetweenInputs(),
                        FormBuilderTextField(
                          key: _ipAddressFieldKey,
                          name: 'ipAddress',
                          initialValue: widget.initialIpAddress,
                          decoration: InputDecoration(
                            labelText: S
                                .of(context)
                                .addNewGreenhouseTextFieldGreenhouseIpAddressLabel,
                            border: OutlineInputBorder(),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: FormBuilderValidators.compose(
                            [
                              FormBuilderValidators.required(
                                  errorText:
                                      S.of(context).authThisFieldCannotBeEmpty),
                              FormBuilderValidators.ip(
                                errorText: S
                                    .of(context)
                                    .addNewGreenhouseTextFieldGreenhouseIpAddressErrorLabel,
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          child:
                              ParameterList(parameterList: widget.parameters),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ),
    );
  }
}

class FlowerpotModal extends ConsumerStatefulWidget {
  final String? initialName;
  final String appbarTitle;
  final void Function(String name) onAction;
  final IconData actionIcon;
  final String actionLabel;
  final String helpTitle;
  final String helpContent;

  const FlowerpotModal({
    super.key,
    this.initialName,
    required this.appbarTitle,
    required this.onAction,
    required this.actionIcon,
    required this.actionLabel,
    required this.helpTitle,
    required this.helpContent,
  });

  @override
  ConsumerState<FlowerpotModal> createState() => _FlowerpotModalState();
}

class _FlowerpotModalState extends ConsumerState<FlowerpotModal> {
  final _formKey = GlobalKey<FormBuilderState>();

  final GlobalKey<FormBuilderFieldState> _nameFieldKey =
      GlobalKey<FormBuilderFieldState>();

  @override
  Widget build(BuildContext mainContext) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.4),
      child: Material(
        child: Scaffold(
            primary: false,
            appBar: AppBar(
              title: Text(
                widget.appbarTitle,
                style: TextStyle(fontSize: 17),
              ),
              automaticallyImplyLeading: false,
              actions: [
                ElevatedButton.icon(
                  onPressed: () async {
                    _formKey.currentState?.validate();
                    if (_formKey.currentState != null &&
                        _formKey.currentState!.isValid) {
                      widget.onAction(_nameFieldKey.currentState!.value);
                      Navigator.of(mainContext).pop();
                    }
                  },
                  icon: Icon(
                    widget.actionIcon,
                    size: 20,
                  ),
                  label: Text(
                    widget.actionLabel,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.help),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                              title: Text(widget.helpTitle,
                                  style: TextStyle(fontSize: 25)),
                              content: Text(
                                  "Add new flowerpot content placeholder",
                                  style: TextStyle(fontSize: 15)),
                              actions: [
                                TextButton(
                                  child: Text(widget.helpContent,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                  },
                                ),
                              ],
                            ),
                        barrierDismissible: true);
                  },
                ),
              ],
            ),
            body: Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: BoxConstraints(maxWidth: width * 0.9),
                padding: EdgeInsets.only(top: 5),
                child: FormBuilder(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        FormBuilderTextField(
                          key: _nameFieldKey,
                          name: 'name',
                          initialValue: widget.initialName,
                          decoration: InputDecoration(
                            labelText: S
                                .of(context)
                                .addNewGreenhouseTextFieldGreenhouseNameLabel,
                            border: OutlineInputBorder(),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                                errorText:
                                    S.of(context).authThisFieldCannotBeEmpty),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ),
    );
  }
}

class ZoneModal extends ConsumerStatefulWidget {
  final String? initialName;
  final String appbarTitle;
  final void Function(String name) onAction;
  final IconData actionIcon;
  final String actionLabel;
  final String helpTitle;
  final String helpContent;

  const ZoneModal({
    super.key,
    this.initialName,
    required this.appbarTitle,
    required this.onAction,
    required this.actionIcon,
    required this.actionLabel,
    required this.helpTitle,
    required this.helpContent,
  });

  @override
  ConsumerState<ZoneModal> createState() => _ZoneModalState();
}

class _ZoneModalState extends ConsumerState<ZoneModal> {
  final _formKey = GlobalKey<FormBuilderState>();

  final GlobalKey<FormBuilderFieldState> _nameFieldKey =
      GlobalKey<FormBuilderFieldState>();

  @override
  Widget build(BuildContext mainContext) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.4),
      child: Material(
        child: Scaffold(
            primary: false,
            appBar: AppBar(
              title: Text(
                widget.appbarTitle,
                style: TextStyle(fontSize: 17),
              ),
              automaticallyImplyLeading: false,
              actions: [
                ElevatedButton.icon(
                  onPressed: () async {
                    _formKey.currentState?.validate();
                    if (_formKey.currentState != null &&
                        _formKey.currentState!.isValid) {
                      widget.onAction(_nameFieldKey.currentState!.value);
                      Navigator.of(mainContext).pop();
                    }
                  },
                  icon: Icon(
                    widget.actionIcon,
                    size: 20,
                  ),
                  label: Text(
                    widget.actionLabel,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.help),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                              title: Text(widget.helpTitle,
                                  style: TextStyle(fontSize: 25)),
                              content: Text("Add new zone content placeholder",
                                  style: TextStyle(fontSize: 15)),
                              actions: [
                                TextButton(
                                  child: Text(widget.helpContent,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                  },
                                ),
                              ],
                            ),
                        barrierDismissible: true);
                  },
                ),
              ],
            ),
            body: Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: BoxConstraints(maxWidth: width * 0.9),
                padding: EdgeInsets.only(top: 5),
                child: FormBuilder(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        FormBuilderTextField(
                          key: _nameFieldKey,
                          name: 'name',
                          initialValue: widget.initialName,
                          decoration: InputDecoration(
                            labelText: S
                                .of(context)
                                .addNewGreenhouseTextFieldGreenhouseNameLabel,
                            border: OutlineInputBorder(),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                                errorText:
                                    S.of(context).authThisFieldCannotBeEmpty),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ),
    );
  }
}

class AddNewFlowerpotForm extends ConsumerStatefulWidget {
  const AddNewFlowerpotForm({super.key, required this.zone});

  final Zone zone;

  @override
  ConsumerState<AddNewFlowerpotForm> createState() =>
      _AddNewFlowerpotFormState();
}

class _AddNewFlowerpotFormState extends ConsumerState<AddNewFlowerpotForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  final GlobalKey<FormBuilderFieldState> _flowerpotNameFieldKey =
      GlobalKey<FormBuilderFieldState>();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add new flowerpot",
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              _formKey.currentState?.validate();
              if (_formKey.currentState != null &&
                  _formKey.currentState!.isValid) {
                /// TODO: add
                Navigator.of(context).pop();
              }
            },
            icon: Icon(
              Icons.add,
              size: 20,
            ),
            label: Text(
              "Add new flowerpot",
              style: TextStyle(fontSize: 15),
            ),
          ),
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                        title: Text("Add new flowerpot placeholder",
                            style: TextStyle(fontSize: 25)),
                        content: Text("Add new flowerpot content",
                            style: TextStyle(fontSize: 15)),
                        actions: [
                          TextButton(
                            child: Text("Add new flowerpot dismiss",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                          ),
                        ],
                      ),
                  barrierDismissible: true);
            },
          )
        ],
      ),
      primary: false,
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: BoxConstraints(maxWidth: width * 0.9),
          padding: EdgeInsets.only(top: 5),
          child: FormBuilder(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 5),
                  FormBuilderTextField(
                    key: _flowerpotNameFieldKey,
                    name: 'name',
                    decoration: InputDecoration(
                      labelText: "Add new flowerpot",
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: S.of(context).authThisFieldCannotBeEmpty),
                    ]),
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

class AddNewZoneForm extends ConsumerStatefulWidget {
  const AddNewZoneForm({super.key, required this.greenhouse});

  final Greenhouse greenhouse;

  @override
  ConsumerState<AddNewZoneForm> createState() => _AddNewZoneFormState();
}

class _AddNewZoneFormState extends ConsumerState<AddNewZoneForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  final GlobalKey<FormBuilderFieldState> _zoneNameFieldKey =
      GlobalKey<FormBuilderFieldState>();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).addNewPlantAppbarTitle,
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              _formKey.currentState?.validate();
              if (_formKey.currentState != null &&
                  _formKey.currentState!.isValid) {
                /// TODO: add
                Navigator.of(context).pop();
              }
            },
            icon: Icon(
              Icons.add,
              size: 20,
            ),
            label: Text(
              "Add new zone",
              style: TextStyle(fontSize: 15),
            ),
          ),
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                        title: Text("Add new zone placeholder",
                            style: TextStyle(fontSize: 25)),
                        content: Text("Add new zone content",
                            style: TextStyle(fontSize: 15)),
                        actions: [
                          TextButton(
                            child: Text("Add new zone dismiss",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                          ),
                        ],
                      ),
                  barrierDismissible: true);
            },
          )
        ],
      ),
      primary: false,
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: BoxConstraints(maxWidth: width * 0.9),
          padding: EdgeInsets.only(top: 5),
          child: FormBuilder(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 5),
                  FormBuilderTextField(
                    key: _zoneNameFieldKey,
                    name: 'name',
                    decoration: InputDecoration(
                      labelText: "Add new flowerpot",
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: S.of(context).authThisFieldCannotBeEmpty),
                    ]),
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

class AddNewPlantForm extends ConsumerStatefulWidget {
  const AddNewPlantForm({
    super.key,
  });

  @override
  ConsumerState<AddNewPlantForm> createState() => _AddNewPlantFormState();
}

class _AddNewPlantFormState extends ConsumerState<AddNewPlantForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  final GlobalKey<FormBuilderFieldState> _nameFieldKey =
      GlobalKey<FormBuilderFieldState>();

  final GlobalKey<FormBuilderFieldState> _descriptionFieldKey =
      GlobalKey<FormBuilderFieldState>();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).addNewPlantAppbarTitle,
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              _formKey.currentState?.validate();
              if (_formKey.currentState != null &&
                  _formKey.currentState!.isValid) {
                ref.read(plantListNotifierProvider.notifier).addPlant(Plant(
                      name: _nameFieldKey.currentState!.value,
                      description: _descriptionFieldKey.currentState!.value,
                    ));
                Navigator.of(context).pop();
              }
            },
            icon: Icon(
              Icons.add,
              size: 20,
            ),
            label: Text(
              S.of(context).addNewPlantAppbarButton,
              style: TextStyle(fontSize: 15),
            ),
          ),
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                        title: Text(S.of(context).addNewPlantHelpTitle,
                            style: TextStyle(fontSize: 25)),
                        content: Text(S.of(context).addNewPlantHelpContent,
                            style: TextStyle(fontSize: 15)),
                        actions: [
                          TextButton(
                            child: Text(S.of(context).addNewPlantHelpDismiss,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                          ),
                        ],
                      ),
                  barrierDismissible: true);
            },
          )
        ],
      ),
      primary: false,
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: BoxConstraints(maxWidth: width * 0.9),
          padding: EdgeInsets.only(top: 5),
          child: FormBuilder(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 5),
                  FormBuilderTextField(
                    key: _nameFieldKey,
                    name: 'name',
                    decoration: InputDecoration(
                      labelText: S.of(context).addNewPlantTextFieldPlantName,
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: S.of(context).authThisFieldCannotBeEmpty),
                    ]),
                  ),
                  buildSizedBoxBetweenInputs(),
                  FormBuilderTextField(
                    key: _descriptionFieldKey,
                    name: 'description',
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: S.of(context).addNewPlantTextFieldDescription,
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: S.of(context).authThisFieldCannotBeEmpty),
                    ]),
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

SizedBox buildSizedBoxBetweenInputs() {
  return SizedBox(
    height: 5,
  );
}

class PlantTile extends StatelessWidget {
  const PlantTile({super.key, required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.local_florist),
      title: Text(plant.name),
      subtitle: Text(S.of(context).controlsDescription(plant.description)),
    );
  }
}

class ParametersControlPanel extends ConsumerStatefulWidget {
  const ParametersControlPanel({super.key, required this.parameters});

  final List<Parameter> parameters;

  @override
  ConsumerState<ParametersControlPanel> createState() =>
      _ParametersControlPanelState();
}

class _ParametersControlPanelState
    extends ConsumerState<ParametersControlPanel> {
  late List<Parameter> tempParameters;
  final List<Parameter> changedParameters = [];

  @override
  void initState() {
    super.initState();
    tempParameters = widget.parameters.map((p) => p.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ExpansionTile(
          title: Text(
            S.of(context).controlsControlPanel,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            Column(
              children: [
                ...tempParameters.map((parameter) {
                  return _buildParameterColumn(parameter);
                }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildChangesConfirmationButton(context),
                    _buildChangesResetButton(context)
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  ElevatedButton _buildChangesResetButton(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          setState(() {
            tempParameters =
                widget.parameters.map((p) => p.copyWith()).toList();
            changedParameters.clear();
          });
        },
        child: Text(S.of(context).controlsResetChange));
  }

  ElevatedButton _buildChangesConfirmationButton(BuildContext context) {
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
                onPressed: () {},
              ),
              TextButton(
                child: Text(S.of(context).controlsDialogAccept),
                onPressed: () {},
              ),
            ],
          ),
          barrierDismissible: true,
        );
      },
      child: Text(S.of(context).controlsConfirmChange),
    );
  }

  Column _buildParameterColumn(Parameter parameter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(parameter.name),
        Row(
          children: [
            Expanded(
              child: FlutterSlider(
                tooltip:
                    FlutterSliderTooltip(rightSuffix: Text(parameter.unit)),
                values: [parameter.requestedValue],
                max: parameter.max,
                min: parameter.min,
                onDragging: (handlerIndex, lowerValue, upperValue) {
                  setState(() {
                    parameter = parameter.copyWith(currentValue: lowerValue);
                  });
                },
              ),
            ),
            Text("${parameter.name} ${parameter.unit}"),
          ],
        ),
      ],
    );
  }
}
//
// class GreenhouseStatusPanel extends ConsumerWidget {
//   const GreenhouseStatusPanel({
//     super.key,
//     required this.greenhouse,
//   });
//
//   final Greenhouse greenhouse;
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Card(
//       child: ExpansionTile(
//         title: ParameterList(parameters: greenhouse.parameters),
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               children: [
//                 Text(
//                   "Detailed information",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("name: ${greenhouse.name}"),
//                         Text("location: ${greenhouse.location}"),
//                         Text("ip address: ${greenhouse.ipAddress}"),
//                       ],
//                     ),
//                     Align(
//                         alignment: Alignment.centerRight,
//                         child: IconButton(
//                           icon: Icon(Icons.edit),
//                           onPressed: () {
//                             buildEditGreenhouseBottomSheet(context, ref);
//                           },
//                         )),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<dynamic> buildEditGreenhouseBottomSheet(
//       BuildContext context, WidgetRef ref) {
//     return showMaterialModalBottomSheet(
//         elevation: modalBottomSheetElevation,
//         context: context,
//         builder: (context) {
//           return GreenhouseModal(
//             appbarTitle: "Edit greenhouse",
//             onAction: (name, location, ipAddress) async {
//               ref.read(greenhouseNotifierProvider.notifier).editGreenhouse(
//                     Greenhouse(
//                       name: name,
//                       location: location,
//                       ipAddress: ipAddress,
//                     ),
//                     greenhouse.id!,
//                   );
//             },
//             initialName: greenhouse.name,
//             initialLocation: greenhouse.location,
//             initialIpAddress: greenhouse.ipAddress,
//             actionIcon: Icons.edit,
//             actionLabel: "Edit greenhouse",
//             helpTitle: "dupa",
//             helpContent: "dupadupadupa",
//           );
//         });
//   }
// }
