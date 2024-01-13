class ChartData {
  final double data;
  const ChartData({
    required this.data,
  });

  

  factory ChartData.noData() => const ChartData(data: 0);
}