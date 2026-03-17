import 'package:cityinsight_mobile/services/crime/crime_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CrimeCharts extends StatefulWidget {
  const CrimeCharts({super.key});

  @override
  _CrimeChartsState createState() => _CrimeChartsState();
}

class _CrimeChartsState extends State<CrimeCharts> {
  int _selectedThreshold = 0; // Default threshold for filtering
  late Future<Map<String, int>> _crimeDataFuture;

  @override
  void initState() {
    super.initState();
    _crimeDataFuture = CrimeDataService().getCrimesGroupedByBarangay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 28, 51),
      appBar: AppBar(
        title: const Text(
          'Crime Charts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background logo
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/UrdanetaLogo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Section: Threshold Dropdown
                  Center(
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Filter by Crime Count'),
                            content: DropdownButton<int>(
                              value: _selectedThreshold,
                              items: [0, 5, 10, 15, 20]
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value.toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedThreshold = value;
                                  });
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Filter: $_selectedThreshold+',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Crime Data Card (Top)
                  Card(
                    color: Colors.white.withOpacity(0.1),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Crime Data Title
                          const Text(
                            'Crime Data',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Crime Bar Chart
                          FutureBuilder<Map<String, int>>(
                            future: _crimeDataFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                );
                              } else if (snapshot.hasError) {
                                return const Center(
                                  child: Text(
                                    'Error fetching data',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              // Process data
                              final originalData = snapshot.data!;
                              final filteredData = originalData.entries
                                  .where((entry) =>
                                      entry.value >= _selectedThreshold)
                                  .toMap();
                              final barangays = filteredData.keys.toList();
                              final crimeCounts = filteredData.values.toList();

                              return barangays.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No data matches the filter',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    )
                                  : _buildChart(barangays, crimeCounts);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Crime Details Table (Bottom)
                  Card(
                    color: Colors.white.withOpacity(0.1),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Crime Details',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Crime Data Table
                          FutureBuilder<Map<String, int>>(
                            future: _crimeDataFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                );
                              } else if (snapshot.hasError) {
                                return const Center(
                                  child: Text(
                                    'Error fetching data',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              final originalData = snapshot.data!;
                              final filteredData = originalData.entries
                                  .where((entry) =>
                                      entry.value >= _selectedThreshold)
                                  .toMap();
                              final dataCount = filteredData;

                              List<TableRow> detailsTableRows =
                                  dataCount.entries.map((entry) {
                                return TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        '${entry.value}',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Details:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Table(
                                    border: TableBorder(
                                      horizontalInside: BorderSide(
                                          color: Colors.white.withOpacity(0.3)),
                                      verticalInside: BorderSide(
                                          color: Colors.white.withOpacity(0.3)),
                                    ),
                                    children: [
                                      const TableRow(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'Type',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'Count',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      ...detailsTableRows,
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<String> barangays, List<int> crimeCounts) {
    return SizedBox(
      height: 220, // Increased space for chart
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.white.withOpacity(0.3)), // Border around chart
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Added space around the chart
          child: BarChart(
            BarChartData(
              barGroups: List.generate(
                barangays.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: crimeCounts[index].toDouble(),
                      color: Colors.blueAccent,
                      width: 18, // Wider bars with more space
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.zero,
                        topRight: Radius.zero,
                      ),
                      borderSide: BorderSide(
                        color:
                            Colors.white.withOpacity(0.5), // Border around bars
                        width: 1,
                      ),
                    ),
                  ],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            color: Colors.white), // White numbers on the Y-axis
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            color: Colors.white), // White numbers on the Y-axis
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            color: Colors.white), // White numbers on the Y-axis
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            color: Colors.white), // White numbers on the Y-axis
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              alignment: BarChartAlignment.spaceAround, // Space between bars
            ),
          ),
        ),
      ),
    );
  }
}

extension MapFilter<K, V> on Iterable<MapEntry<K, V>> {
  Map<K, V> toMap() => {for (var entry in this) entry.key: entry.value};
}
