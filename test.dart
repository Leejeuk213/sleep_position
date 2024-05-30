void main() {
  // Dart������ �迭�� List�� ��Ÿ���ϴ�.
  List<List<double>> outputData = [
    [0.1, 0.2, 0.3, 0.4]
  ]; // �߷� ����� ���� ���� ������

  // ���� ū ���� �ε��� ã��
  int predictedClass = argmax(outputData);

  print('$predictedClass');
}

int argmax(List<List<double>> data) {
  double maxValue = double.negativeInfinity;
  int maxIndex = -1;

  // ���� List�� ��ȸ�ϸ� �ִ밪�� �� �ε����� ã���ϴ�.
  for (int i = 0; i < data.length; i++) {
    for (int j = 0; j < data[i].length; j++) {
      if (data[i][j] > maxValue) {
        maxValue = data[i][j];
        maxIndex = j;
      }
    }
  }

  return maxIndex;
}
