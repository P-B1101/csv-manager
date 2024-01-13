import 'dart:convert';
import 'dart:io';

import 'package:csv_reader_and_writer/chart_data.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:csv_reader_and_writer/local_saved_chart_data.dart';
import 'package:csv_reader_and_writer/saved_chart_data.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSV Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final items = <LocalSavedChartData>[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: _selectFile,
                    child: const Text('Select File'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _saveData,
                    child: const Text('Save Data'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                itemBuilder: (context, index) =>
                    _ItemWidget(item: items[index]),
                separatorBuilder: (context, index) => const Divider(),
                itemCount: items.length,
                shrinkWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectFile() async {
    final files = await FilePicker.platform.pickFiles(
      allowedExtensions: ['csv'],
      allowMultiple: true,
    );
    if (files == null) return;
    items.clear();
    final temp = await compute(_readChartData, files.files);
    setState(() {
      items.addAll(temp);
    });
  }

  void _saveData() async {
    if (items.isEmpty) return;
    final data = <List<String>>[];
    final mItems = items.last.items;
    data.add(['0', ...mItems.map((e) => e.name)]);
    for (int i = 0; i < mItems.length; i++) {
      final temp = <String>[];
      temp.add((i + 1).toString());
      for (int j = 0; j < mItems.length; j++) {
        final mData = mItems[j].items.elementAtOrNull(i)?.data.toString() ?? '';
        temp.add(mData);
      }
      data.add(temp);
    }
    final bytes = await compute(_convertData, data);
    final result = await FileSaver().saveFile(
      name: DateTime.now().millisecondsSinceEpoch.toString(),
      bytes: Uint8List.fromList(bytes),
      ext: '.csv',
      mimeType: MimeType.other,
    );
    print('result: $result');
  }
}

Future<Uint8List> _convertData(List<List<String>> arg) async {
  final data = arg.map((e) => e.join(',')).join('\n');
  final bytes = utf8.encode(data);
  return Uint8List.fromList(bytes);
}

Future<List<LocalSavedChartData>> _readChartData(
  List<PlatformFile> arg,
) async {
  final result = <LocalSavedChartData>[];
  for (int i = 0; i < arg.length; i++) {
    final file = File(arg[i].path ?? '');
    final bytes = await file.readAsBytes();
    final data = utf8.decode(bytes);
    final lines = data.split('\n');
    final items = lines.map((e) => e.split(',')).toList();
    final keys = items.isEmpty ? <String>[] : items.first;
    final chartData = List.generate(
      keys.length - 1,
      (index) => SavedChartData(
        name: keys[index + 1],
        items: List.generate(
          items.length - 1,
          (innerIndex) => ChartData(
            data: double.parse(items[innerIndex + 1][index + 1]),
          ),
        ),
      ),
    );
    result.add(
      LocalSavedChartData(
        items: chartData,
        fileName: basename(file.path),
      ),
    );
  }
  return result;
}

class _ItemWidget extends StatelessWidget {
  final LocalSavedChartData item;
  const _ItemWidget({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.fileName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Flexible(
            child: ListView.separated(
              separatorBuilder: (context, index) => const Divider(),
              padding: const EdgeInsetsDirectional.only(
                start: 12,
                top: 12,
                bottom: 12,
              ),
              itemCount: item.items.length,
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => _InnerItemWidget(
                item: item.items[index],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InnerItemWidget extends StatelessWidget {
  final SavedChartData item;
  const _InnerItemWidget({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          ...List.generate(
            item.items.length,
            (index) => Text(item.items[index].data.toString()),
          ),
        ],
      ),
    );
  }
}
