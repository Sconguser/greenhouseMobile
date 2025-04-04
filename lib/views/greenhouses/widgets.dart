import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:maker_greenhouse/providers/greenhouse_notifier.dart';
import 'package:maker_greenhouse/providers/plant_list_controller_provider.dart';
import 'package:maker_greenhouse/shared/loading_indicator.dart';
import 'package:maker_greenhouse/shared/ui_constants.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../generated/l10n.dart';
import '../../models/greenhouse_model.dart';
import '../../models/greenhouse_status_model.dart';
import '../../models/plant_model.dart';
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

class GreenhouseTile extends StatelessWidget {
  const GreenhouseTile({super.key, required this.greenhouse});

  final Greenhouse greenhouse;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Text(
          greenhouse.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        // subtitle: Text(S.of(context).controlsLocation(greenhouse.location)),
        children: [
          if (greenhouse.status != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Column(
                children: [
                  GreenhouseStatusPanel(greenhouse: greenhouse),
                  GreenhouseControlPanel(greenhouseStatus: greenhouse.status!),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: () {
              buildPlantListBottomSheet(context, greenhouse);
            },
            child: Text(S.of(context).plantAddNewPlant),
          ),
          ...greenhouse.plants.map((plant) => PlantTile(
                plant: plant,
              )),
        ],
      ),
    );
  }

  Future<dynamic> buildPlantListBottomSheet(
      BuildContext context, Greenhouse greenhouse) {
    return showMaterialModalBottomSheet(
        elevation: 5,
        context: context,
        builder: (context) {
          return PlantModal(
            greenhouse: greenhouse,
          );
        });
  }
}

class PlantModal extends StatelessWidget {
  const PlantModal({
    super.key,
    required this.greenhouse,
  });

  final Greenhouse greenhouse;

  @override
  Widget build(BuildContext mainContext) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(mainContext).size.height * 0.6),
      child: Material(
        child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
                builder: (childContext) => Builder(builder: (childContext2) {
                      return Scaffold(
                        primary: false,
                        appBar: AppBar(
                          title: Text(
                            S.of(mainContext).addPlantToGreenhouseModalTitle(
                                greenhouse.name),
                            style: TextStyle(fontSize: 20),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(childContext2)
                                    .push(MaterialPageRoute(builder: (context) {
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
                            final plants = ref.watch(plantListNotifierProvider);
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
                                        subtitle: Text(data[index].description),
                                        onTap: () {
                                          if (greenhouse.id != null) {
                                            ref
                                                .read(greenhouseNotifierProvider
                                                    .notifier)
                                                .addNewPlantToGreenhouse(
                                                    data[index],
                                                    greenhouse.id!);
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
                                    ref.invalidate(plantListNotifierProvider);
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
                    }))),
      ),
    );
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
          );
        });
  }
}

class GreenhouseModal extends ConsumerStatefulWidget {
  final String? initialName;
  final String? initialLocation;
  final String? initialIpAddress;
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

  double minTemperature = 10;
  double maxTemperature = 40;
  double minHumidity = 10;
  double maxHumidity = 40;
  double minSoilHumidity = 10;
  double maxSoilHumidity = 40;

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
                      minTemperature: minTemperature.floor(),
                      maxTemperature: maxTemperature.floor(),
                      minHumidity: minHumidity.floor(),
                      maxHumidity: maxHumidity.floor(),
                      minSoilHumidity: minSoilHumidity.floor(),
                      maxSoilHumidity: maxSoilHumidity.floor(),
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
                  buildSizedBoxBetweenInputs(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.of(context).addNewPlantTemperatureSlider(
                          minTemperature, temperatureUnit, maxTemperature)),
                      FlutterSlider(
                        selectByTap: false,
                        tooltip: FlutterSliderTooltip(
                          leftPrefix: Text("Min:"),
                          leftSuffix: Text(temperatureUnit),
                          rightPrefix: Text("Max"),
                          rightSuffix: Text(temperatureUnit),
                        ),
                        values: [minTemperature, maxTemperature],
                        max: 100,
                        min: 0,
                        rangeSlider: true,
                        onDragging: (handlerIndex, lowerValue, upperValue) {
                          setState(() {
                            minTemperature = lowerValue;
                            maxTemperature = upperValue;
                          });
                        },
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.of(context).addNewPlantHumiditySlider(
                          minHumidity, humidityUnit, maxHumidity)),
                      FlutterSlider(
                        selectByTap: false,
                        tooltip: FlutterSliderTooltip(
                          leftPrefix: Text("Min:"),
                          leftSuffix: Text(humidityUnit),
                          rightPrefix: Text("Max"),
                          rightSuffix: Text(humidityUnit),
                        ),
                        values: [minHumidity, maxHumidity],
                        max: 100,
                        min: 0,
                        rangeSlider: true,
                        onDragging: (handlerIndex, lowerValue, upperValue) {
                          setState(() {
                            minHumidity = lowerValue;
                            maxHumidity = upperValue;
                          });
                        },
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.of(context).addNewPlantSoilHumiditySlider(
                          minSoilHumidity, humidityUnit, maxSoilHumidity)),
                      FlutterSlider(
                        selectByTap: false,
                        tooltip: FlutterSliderTooltip(
                          leftPrefix: Text("Min:"),
                          leftSuffix: Text(humidityUnit),
                          rightPrefix: Text("Max"),
                          rightSuffix: Text(humidityUnit),
                        ),
                        values: [minSoilHumidity, maxSoilHumidity],
                        max: 100,
                        min: 0,
                        rangeSlider: true,
                        onDragging: (handlerIndex, lowerValue, upperValue) {
                          setState(() {
                            minSoilHumidity = lowerValue;
                            maxSoilHumidity = upperValue;
                          });
                        },
                      ),
                    ],
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

class GreenhouseControlPanel extends ConsumerStatefulWidget {
  const GreenhouseControlPanel({super.key, required this.greenhouseStatus});

  final GreenhouseStatus greenhouseStatus;

  @override
  ConsumerState<GreenhouseControlPanel> createState() =>
      _GreenhouseControlPanelState();
}

class _GreenhouseControlPanelState
    extends ConsumerState<GreenhouseControlPanel> {
  double newTemperature = 0.0; // Store in state
  double newHumidity = 0.0;
  double newSoilHumidity = 0.0;

  @override
  void initState() {
    super.initState();
    newTemperature = widget.greenhouseStatus.temperature;
    newHumidity = widget.greenhouseStatus.humidity;
    newSoilHumidity = widget.greenhouseStatus.soilHumidity;
  }

  @override
  Widget build(BuildContext context) {
    double currentTemperature = widget.greenhouseStatus.temperature;
    double currentHumidity = widget.greenhouseStatus.humidity;
    double currentSoilHumidity = widget.greenhouseStatus.soilHumidity;
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
                _buildTemperatureColumn(),
                _buildHumidityColumn(),
                _buildSoilHumidityColumn(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildChangesConfirmationButton(currentSoilHumidity,
                        currentTemperature, currentHumidity, context),
                    _buildChangesResetButton(currentHumidity,
                        currentTemperature, currentSoilHumidity, context)
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  ElevatedButton _buildChangesResetButton(
      double currentHumidity,
      double currentTemperature,
      double currentSoilHumidity,
      BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          setState(() {
            newHumidity = currentHumidity;
            newTemperature = currentTemperature;
            newSoilHumidity = currentSoilHumidity;
          });
        },
        child: Text(S.of(context).controlsResetChange));
  }

  ElevatedButton _buildChangesConfirmationButton(double currentSoilHumidity,
      double currentTemperature, double currentHumidity, BuildContext context) {
    return ElevatedButton(
      onPressed: (currentSoilHumidity != newSoilHumidity ||
              currentTemperature != newTemperature ||
              currentHumidity != newHumidity)
          ? () {
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
            }
          : null,
      child: Text(S.of(context).controlsConfirmChange),
    );
  }

  Column _buildSoilHumidityColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.current.soilHumidity),
        Row(
          children: [
            Expanded(
              child: FlutterSlider(
                tooltip: FlutterSliderTooltip(rightSuffix: Text(humidityUnit)),
                values: [newSoilHumidity],
                max: 100,
                min: 0,
                onDragging: (handlerIndex, lowerValue, upperValue) {
                  setState(() {
                    newSoilHumidity = lowerValue;
                  });
                },
              ),
            ),
            Text("$newSoilHumidity $humidityUnit"),
          ],
        ),
      ],
    );
  }

  Column _buildHumidityColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.current.humidity),
        Row(
          children: [
            Expanded(
              child: FlutterSlider(
                tooltip: FlutterSliderTooltip(rightSuffix: Text(humidityUnit)),
                values: [newHumidity],
                max: 100,
                min: 0,
                onDragging: (handlerIndex, lowerValue, upperValue) {
                  setState(() {
                    newHumidity = lowerValue;
                  });
                },
              ),
            ),
            Text("$newHumidity $humidityUnit"),
          ],
        ),
      ],
    );
  }

  Column _buildTemperatureColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.current.temperature),
        Row(
          children: [
            Expanded(
              child: FlutterSlider(
                tooltip:
                    FlutterSliderTooltip(rightSuffix: Text(temperatureUnit)),
                values: [newTemperature],
                max: 100,
                min: 0,
                onDragging: (handlerIndex, lowerValue, upperValue) {
                  setState(() {
                    newTemperature = lowerValue;
                  });
                },
              ),
            ),
            Text("$newTemperature $temperatureUnit"),
          ],
        ),
      ],
    );
  }
}

class GreenhouseStatusPanel extends ConsumerWidget {
  const GreenhouseStatusPanel({
    super.key,
    required this.greenhouse,
  });

  final Greenhouse greenhouse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).controlsStatus),
            GreenhouseStatusIndicator(
              greenhouseStatus: greenhouse.status!.status,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "${S.of(context).controlsTemperature(greenhouse.status!.temperature)} $temperatureUnit"),
                Text(
                    "${S.of(context).controlsHumidity(greenhouse.status!.humidity)} $humidityUnit"),
                Text(
                    "${S.of(context).controlsSoilHumidity(greenhouse.status!.soilHumidity)} $humidityUnit"),
              ],
            )
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  "Detailed information",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("name: ${greenhouse.name}"),
                        Text("location: ${greenhouse.location}"),
                        Text("ip address: ${greenhouse.ipAddress}"),
                      ],
                    ),
                    Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            buildEditGreenhouseBottomSheet(context, ref);
                          },
                        )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<dynamic> buildEditGreenhouseBottomSheet(
      BuildContext context, WidgetRef ref) {
    return showMaterialModalBottomSheet(
        elevation: modalBottomSheetElevation,
        context: context,
        builder: (context) {
          return GreenhouseModal(
            appbarTitle: "Edit greenhouse",
            onAction: (name, location, ipAddress) async {
              ref.read(greenhouseNotifierProvider.notifier).editGreenhouse(
                    Greenhouse(
                      name: name,
                      location: location,
                      ipAddress: ipAddress,
                    ),
                    greenhouse.id!,
                  );
            },
            initialName: greenhouse.name,
            initialLocation: greenhouse.location,
            initialIpAddress: greenhouse.ipAddress,
            actionIcon: Icons.edit,
            actionLabel: "Edit greenhouse",
            helpTitle: "dupa",
            helpContent: "dupadupadupa",
          );
        });
  }
}
