import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../utils/currency_format.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<BarChartGroupData> _salesData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() => _isLoading = true);
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('checkouts').get();

      Map<String, double> dailySales = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['createdAt'] != null && data['totalPrice'] != null) {
          final Timestamp createdAt = data['createdAt'] as Timestamp;
          final String dateKey =
              DateFormat('yyyy-MM-dd').format(createdAt.toDate());

          dailySales[dateKey] =
              (dailySales[dateKey] ?? 0) + (data['totalPrice'] as num);
        }
      }

      var sortedSales = dailySales.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));

      final List<BarChartGroupData> data = [];
      int index = 0;

      sortedSales.take(7).forEach((entry) {
        data.add(
          BarChartGroupData(
            x: index++,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                gradient: _barsGradient,
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            showingTooltipIndicators: [0],
          ),
        );
      });

      setState(() {
        _salesData = data.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sales data: $e');
      setState(() => _isLoading = false);
    }
  }

  LinearGradient get _barsGradient => const LinearGradient(
        colors: [
          Color(0xFFFF758F),
          Color(0xFFFF4D6D),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text = _getWeekDay(value.toInt())[0];
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(text, style: style),
    );
  }

  String _getWeekDay(int value) {
    switch (value) {
      case 0:
        return 'Senin';
      case 1:
        return 'Selasa';
      case 2:
        return 'Rabu';
      case 3:
        return 'Kamis';
      case 4:
        return 'Jumat';
      case 5:
        return 'Sabtu';
      case 6:
        return 'Minggu';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 247, 95, 138),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Penjualan 7 Hari Terakhir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${CurrencyFormat.convertToIdr(_getTotalSales())}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: getTitles,
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _salesData,
                        gridData: const FlGridData(show: false),
                        alignment: BarChartAlignment.spaceAround,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  double _getTotalSales() {
    double total = 0;
    for (var group in _salesData) {
      total += group.barRods.first.toY;
    }
    return total;
  }
}
