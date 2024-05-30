import 'package:flutter/material.dart';

class SensorDataProvider extends ChangeNotifier {
  String display_data = "None";
  List<double> input = [];

  void convertAscii(asciiSignals) {
    display_data = "";

    for (int asciiValue in asciiSignals) {
      display_data += String.fromCharCode(asciiValue);
    }
    input = display_data
        .split(',')
        .map((signal) => double.parse(signal.trim()))
        .toList();
    print('signal : $display_data');
    print(input);
    notifyListeners(); // ���� ���� �˸�
  }
}

int argmax(List<double> data) {
  double maxValue = double.negativeInfinity;
  int maxIndex = -1;

  // ���� List�� ��ȸ�ϸ� �ִ밪�� �� �ε����� ã���ϴ�.
  for (int i = 0; i < data.length; i++) {
    if (data[i] > maxValue) {
      maxValue = data[i];
      maxIndex = i;
    }
  }

  return maxIndex;
}
