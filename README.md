<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

Get data from Fritz!Box, FRITZ!DECT inside Flutter applications

Right now this is only tested inside local network. Also note that emulator seems not to be able
to connect with FRITZ!Box.

## Features

* Fetch session id for FRITZ!Box API access
* Fetch smart home devices connected to Fritz!Box
* Get energy consumption in Wh of FRITZ!DECT 200

## Usage

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fritzapi/flutter_fritzapi.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const title = 'FRITZ!API Demo App';
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final fritzApiClient = CustomFritzApiClient();

  int currentStep = 0;

  bool isConnected = false;

  String? password;

  String? sessionId;

  bool failedToFetchSessionId = false;

  Iterable<Device>? measuringDevices;

  Device? selectedDevice;

  EnergyStats? stats;

  HomeAutoQueryCommand? command;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Stepper(
          physics: const ScrollPhysics(),
          currentStep: currentStep,
          onStepContinue: () {
            if (currentStep == 0) {
              if (isConnected) {
                setState(() {
                  currentStep = 1;
                });
              } else {
                fritzApiClient.isConnectedWithFritzBox().then((isConnected) {
                  this.isConnected = isConnected;
                  if (isConnected) {
                    setState(() {
                      currentStep = 1;
                    });
                  }
                });
              }
            } else if (currentStep == 1 && password?.isNotEmpty == true) {
              fritzApiClient.getSessionId(password: password!).then((sessionId){
                if (sessionId == null) {
                  setState(() {
                    failedToFetchSessionId = true;
                  });
                } else {
                  failedToFetchSessionId = false;
                  setState(() {
                    this.sessionId = sessionId;
                    currentStep = 2;
                  });
                  fritzApiClient.getDevices().then((devices) {
                    setState(() {
                      measuringDevices = devices.getConnectedDevices();
                    });
                  });
                }
              });
            } else if (currentStep == 2 && sessionId?.isNotEmpty == true) {
              if (selectedDevice == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You have to select a device before you can continue.')),
                );
              } else {
                setState(() {
                  currentStep++;
                });
              }
            } else if (currentStep == 3) {
              // Cannot continue on last step
            }
          },
          onStepTapped: (tappedStep) {
            setState(() {
              currentStep = tappedStep;
            });
          },
          steps: [
            Step(
              title: const Text('Check if connected with Fritz!Box'),
              content: const SizedBox.shrink(),
              isActive: currentStep == 0,
              state: currentStep > 0
                  ? StepState.complete
                  : StepState.indexed,
            ),
            Step(
              title: const Text('Fetch session id'),
              content: Column(
                children: [
                  if (failedToFetchSessionId)
                    const Text('Failed to fetch session id.', style: TextStyle(color: Colors.red)),
                  TextField(
                    decoration: const InputDecoration(
                      label: Text('Password'),
                    ),
                    onChanged: (String input) {
                      setState(() {
                        password = input;
                      });
                    },
                  )
                ],
              ),
              isActive: currentStep == 1,
              state: currentStep == 1
                  ? StepState.indexed
                  : currentStep > 1 || sessionId != null ? StepState.complete : StepState.disabled,
            ),
            Step(
              title: const Text('Select device'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Successfully fetched session id (SID) "$sessionId" for next API calls in step 2. We should now do have access to devices.'),
                  const SizedBox(height: 8),
                  if (measuringDevices == null)
                    ...[
                      const CircularProgressIndicator(),
                      Text('Loading devices', style: Theme.of(context).textTheme.caption),
                    ]
                  else for (final device in measuringDevices!)
                    ListTile(
                      title: Text('${device.displayName} (${device.model})'),
                      onTap: () {
                        setState(() {
                          selectedDevice = device;
                          currentStep++;
                        });
                      },
                    ),
                ],
              ),
              isActive: currentStep == 2,
              state: currentStep == 2
                  ? StepState.indexed
                  : sessionId != null ? StepState.complete : StepState.disabled,
            ),
            Step(
              title: const Text('Fetch EnergyStats'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final command in HomeAutoQueryCommand.values)
                    ListTile(
                      title: Text(command.name.replaceFirst('EnergyStats_', '')),
                      selected: this.command == command,
                      onTap: () {
                        final deviceId = selectedDevice!.id;
                        fritzApiClient.getEnergyStats(
                          command: command,
                          deviceId: deviceId,
                        ).then((result) {
                          if (result != null) {
                            setState(() {
                              this.command = command;
                              stats = result;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to fetch EnergyStats for ${command.name} of ${selectedDevice!.displayName}.'),
                              ),
                            );
                          }
                        });
                      },
                    ),
                  if (stats != null)
                    ...[
                      Text('${stats!.energyStat.values.length} values where each value represents ${(stats!.energyStat.timesType/60/60).toStringAsFixed(2).replaceFirst('.00', '')} hours:'),
                      Text(stats!.energyStat.values.toString()),
                    ]
                ],
              ),
              isActive: currentStep == 3,
              state: currentStep == 3
                  ? StepState.indexed
                  : StepState.disabled,
            ),
          ],
        )
    );
  }
}
```
