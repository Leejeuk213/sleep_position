void main() {
  // Dart에서는 배열을 List로 나타냅니다.
  List<List<double>> outputData = [
    [0.1, 0.2, 0.3, 0.4]
  ]; // 추론 결과로 얻은 예시 데이터

  // 가장 큰 값의 인덱스 찾기
  int predictedClass = argmax(outputData);

  print('$predictedClass');
}

int argmax(List<List<double>> data) {
  double maxValue = double.negativeInfinity;
  int maxIndex = -1;

  // 이중 List를 순회하며 최대값과 그 인덱스를 찾습니다.
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
