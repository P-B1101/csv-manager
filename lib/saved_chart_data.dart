import 'package:csv_reader_and_writer/chart_data.dart';

class SavedChartData {
  final List<ChartData> items;
  final String name;
  const SavedChartData({
    required this.name,
    required this.items,
  });
}