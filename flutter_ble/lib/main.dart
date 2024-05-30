import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ble/sensor_data_provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:async';
import 'package:restart_app/restart_app.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SensorDataProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SensorDataProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Pico BLE Test',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: "ble test"),
      ),
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
  bool isScanning = false;
  List scanResults = [];
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  late var device;
  late var write_characteristic;
  TextEditingController inputController = TextEditingController();
  int check = 0;
  // �� �̸�
  final _modelFile = 'assets/sleep_position_model.tflite';

  late Interpreter _interpreter;

  List<String> _output = ['supine', 'left', 'right', 'prone'];
  List<int> vib_level = [
    0, // ���� �׽�Ʈ���� �� 15000���� �������� ������ ��������
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8 //65535�� �ʹ� �����ϴ� ��� 50000����� ���� ������ ����� ������ ����� �̷��� ����
  ];
  String sleep_position = 'start please';
  String connected = 'false';
  @override
  void initState() {
    super.initState();

    // ���� �� �ʱ� ���� ����
    // �� �ҷ�����
    flutterBlueSettings();
    _loadModel();
    // // �� ���� ��ĵ
    flutterBlueInit();
  }

  void flutterBlueSettings() async {
    // ����̽��� ������� ���� ���� �Ǵ�.
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }

    // ������� Ȱ��ȭ ���� â
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
  }

  void _loadModel() async {
    // �� ����
    _interpreter = await Interpreter.fromAsset(_modelFile);
    print('Interpreter loaded successfully');
  }

  void flutterBlueInit() async {
    // ��ĵ ��� listen
    print("��ĵ ����");
    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult r = results.last; // the most recently found device
          print(
              '${r.device.remoteId}: "${r.advertisementData.advName}" found!');
          print("device : ");
          print(r.device);
          print("advertising data : ");
          print(r.advertisementData);
          device = r.device;
          connect_device(device);
        }
      },
      onError: (e) => print(e),
    );

    // ��ĵ ���� �� �� listen ����
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    // ������� Ȱ��ȭ �� ���� �ο� �׽�Ʈ
    // In your real app you should use `FlutterBluePlus.adapterState.listen` to handle all states
    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    // ��ĵ ���� �� ��ĵ ���������� ��ٸ���
    await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 7),
        withServices: [Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e")]);
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
  }

  // ���� ��Ʈ�� �� ���� ����
  String former_sleep_pos = '';
  int now_vib_level = 0;
  int cnt = 0;

  void vib() async {
    // �������̰ų� ������ �ڼ��� ��
    // ������ ���Ѵ�.
    if (sleep_position == _output[2] || sleep_position == _output[3]) {
      // ���� �����ڼ��� ���� �� �� �������� ��ȭ�� ���� ��
      // ���ڿ��� 5�� ���� ������ �ְ� �ٽ� �Ȱ��� �ڼ����� �Ǵ�  �Ȱ��ٸ� ���� ���� ����
      if (former_sleep_pos == _output[2] || former_sleep_pos == _output[3]) {
        cnt++;
        if (cnt == 1 && now_vib_level < vib_level.length) {
          now_vib_level += 1;
          cnt = 0;
        }
      }
      // ���� �����ڼ��� �ùٸ� �ڼ����ٸ�
      // �ʱ� �������� ���� ���� ����
      else {
        now_vib_level = 1;
        cnt = 0;
      }
      await write_characteristic.write([vib_level[now_vib_level]]);
    }

    // �ùٸ� �ڼ���� ������ ���� �ʴ´�.
    else {
      now_vib_level = 0;
      cnt = 0;
      // ������ ���� �������� ������ ������ ��� ���� ���Ͱ� �۵����̱� �����̴�.
      if (former_sleep_pos == _output[2] || former_sleep_pos == _output[3]) {
        await write_characteristic.write([0]);
      }
    }
  }

  late dynamic connectSubscription;
  void connect_device(device) async {
    // �ش� ����̽��� ����
    await device.connect().then((result) => print("connection sucess"));
    setState(() {
      connected = 'true';
    });
    // ���� ã��
    List<BluetoothService> services = await device.discoverServices();
    print("find service");
    print(services);
    print("=======================");
    for (var service in services) {
      // ĳ���͸���ƽ �б�
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        print("characteristic : ");
        print(c);
        print("=======================");
        if (c.properties.read) {
          List<int> value = await c.read();
        } else {
          // ����
          write_characteristic = c;
        }

        final valueSubscription = c.onValueReceived.listen((value) {
          print("value arrived $value");
          Provider.of<SensorDataProvider>(context, listen: false)
              .convertAscii(value);
          var output = List<double>.filled(4, 0.0).reshape([1, 4]);
          _interpreter.run(
              [Provider.of<SensorDataProvider>(context, listen: false).input],
              output);

          setState(() {
            sleep_position = _output[argmax(output[0])];
            vib();
            former_sleep_pos = sleep_position;
          });
        });

        // listen for disconnection
        connectSubscription = device.connectionState
            .listen((BluetoothConnectionState state) async {
          if (state == BluetoothConnectionState.disconnected) {
            print("connection stopped");
            setState(() {
              connected = 'ggungim';
            });
            Restart.restartApp();
            // �翬�� �õ�
            //restart(connectSubscription, valueSubscription, device);
          }
        });
        // cleanup: cancel subscription when disconnected
        //device.cancelWhenDisconnected(connectSubscription,
        //    delayed: true, next: false);

        // ���� �������� subscribe ����
        //device.cancelWhenDisconnected(valueSubscription);

        // subscribe ���� - Notify
        await c.setNotifyValue(true);
      }
    }
  }

  // Future restart(dynamic sub1, dynamic sub2, dynamic device) async {
  //   // cleanup: cancel subscription when disconnected
  //   device.cancelWhenDisconnected(sub1, delayed: true, next: false);

  //   // ���� �������� subscribe ����
  //   device.cancelWhenDisconnected(sub2);
  //   //FlutterBluePlus.stopScan();
  //   //await device.disconnect();
  //   flutterBlueInit();
  // }

  Future onStopScan() async {
    print("connection stopped");

    // Disconnect from device
    FlutterBluePlus.stopScan();
    await device.disconnect();
    //flutterBlueInit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Provider.of<SensorDataProvider>(context, listen: true)
                      .display_data,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(
                  height: 10.0,
                  width: 30.0,
                ),
                ElevatedButton(
                    onPressed: onStopScan, child: const Text("stop scan")),
                const SizedBox(
                  height: 10.0,
                  width: 30.0,
                ),
                Text(
                  'sleep position is $sleep_position',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(
                  height: 10.0,
                  width: 30.0,
                ),
                Text(
                  'is $connected',
                  style: Theme.of(context).textTheme.headlineMedium,
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: flutterBlueInit,
        tooltip: 'Scanning',
        child: const Icon(Icons.add),
      ),
    );
  }
}
