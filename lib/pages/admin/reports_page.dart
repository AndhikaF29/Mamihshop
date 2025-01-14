import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<BarChartGroupData> _salesBarChartData = [];
  List<BarChartGroupData> _categoryBarChartData = [];

  @override
  void initState() {
    super.initState();
    _fetchCheckoutData();
    _fetchCategoryData();
  }

  Future<void> _fetchCheckoutData() async {
    QuerySnapshot checkoutSnapshot =
        await _firestore.collection('checkouts').get();
    Map<String, double> monthlySales = {};

    for (var doc in checkoutSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      double total = (data['totalPrice'] is int
          ? (data['totalPrice'] as int).toDouble()
          : (data['totalPrice'] ?? 0.0).toDouble());
      DateTime date = (data['createdAt'] as Timestamp).toDate();

      String month = "${date.month}-${date.year}";

      if (monthlySales.containsKey(month)) {
        monthlySales[month] = monthlySales[month]! + total;
      } else {
        monthlySales[month] = total;
      }
    }

    setState(() {
      _salesBarChartData = _createBarChartData(monthlySales);
    });
  }

  Future<void> _fetchCategoryData() async {
    QuerySnapshot checkoutSnapshot =
        await _firestore.collection('checkouts').get();
    Map<String, int> categorySales = {};

    for (var doc in checkoutSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      List<dynamic> items =
          (data['totalItems'] is List) ? data['totalItems'] : [];

      for (var item in items) {
        String category = item['category'] ?? 'Uncategorized';
        if (categorySales.containsKey(category)) {
          categorySales[category] = categorySales[category]! + 1;
        } else {
          categorySales[category] = 1;
        }
      }
    }

    setState(() {
      _categoryBarChartData = _createCategoryBarChartData(categorySales);
    });
  }

  List<BarChartGroupData> _createBarChartData(
      Map<String, double> monthlySales) {
    List<BarChartGroupData> barGroups = [];
    int index = 0;

    monthlySales.forEach((month, total) {
      barGroups.add(BarChartGroupData(
        x: index++,
        barRods: [BarChartRodData(toY: total, color: Colors.blue)],
      ));
    });

    return barGroups;
  }

  List<BarChartGroupData> _createCategoryBarChartData(
      Map<String, int> categorySales) {
    List<BarChartGroupData> barGroups = [];
    int index = 0;

    categorySales.forEach((category, count) {
      barGroups.add(BarChartGroupData(
        x: index++,
        barRods: [BarChartRodData(toY: count.toDouble(), color: Colors.green)],
      ));
    });

    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Grafik Penjualan Bulanan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _salesBarChartData.isNotEmpty
                      ? _salesBarChartData
                          .map((e) => e.barRods[0].toY)
                          .reduce((a, b) => a > b ? a : b)
                      : 0,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _salesBarChartData,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Grafik Penjualan Berdasarkan Kategori',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _categoryBarChartData.isNotEmpty
                      ? _categoryBarChartData
                          .map((e) => e.barRods[0].toY)
                          .reduce((a, b) => a > b ? a : b)
                      : 0,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _categoryBarChartData,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
