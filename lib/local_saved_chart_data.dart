import 'saved_chart_data.dart';

class LocalSavedChartData{
  final List<SavedChartData> items;
  final String fileName;

  const LocalSavedChartData({
    required this.items,
    required this.fileName,
  });
}