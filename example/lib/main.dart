import 'package:example/custom_fritz_api_client.dart';
import 'package:flutter/material.dart';

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
            fritzApiClient.getSessionId(username: '', password: '');
          }
          if (currentStep < 2) {
            //currentStep++;

            //setState(() {});
          }
        },
        onStepTapped: (tappedStep) {
          if (tappedStep < currentStep) {
            setState(() {
              currentStep = tappedStep;
            });
          }
        },
        steps: [
          Step(
            title: const Text('Fetch session id'),
            content: SizedBox.shrink(),
            state: currentStep >= 0 ?
            StepState.complete : StepState.disabled,
          ),
          Step(
            title: const Text('Select device'),
            content: SizedBox.shrink(),
            isActive: currentStep > 1,
            state: currentStep >= 1 ?
            StepState.complete : StepState.disabled,
          ),
          Step(
            title: const Text('See EnergyStats'),
            content: SizedBox.shrink(),
            isActive: currentStep > 2,
            state: currentStep >= 2 ?
            StepState.complete : StepState.disabled,
          ),
        ],
      )
    );
  }
}
