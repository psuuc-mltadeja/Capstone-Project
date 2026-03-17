import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class BarangayDetails extends StatefulWidget {
  const BarangayDetails({super.key, required this.brgyData});
  final Map<String, dynamic> brgyData;

  @override
  _BarangayDetailsState createState() => _BarangayDetailsState();
}

class _BarangayDetailsState extends State<BarangayDetails> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 28, 51),
      appBar: AppBar(
        title: Text(widget.brgyData['name']),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
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
                  // Date Filter Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _selectDate(context),
                        child: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : 'Selected Date: ${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Crime Data Card
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
                          // Crime Data Bar Chart
                          const Text(
                            'Crime Data',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildChart('crimes'),
                          const SizedBox(height: 10),
                          _buildTotalCount('crimes'),
                          const SizedBox(height: 20),

                          // Flood Data Bar Chart
                          const Text(
                            'Flood Data',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildChart('floods'),
                          const SizedBox(height: 10),
                          _buildTotalCount('floods'),
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

  Future<void> _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  Query _getFilteredQuery(String collection) {
    Query query = FirebaseFirestore.instance
        .collection(collection)
        .where('brgy', isEqualTo: widget.brgyData['name']);

    if (_selectedDate != null) {
      DateTime startOfDay = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      DateTime endOfDay = DateTime(_selectedDate!.year, _selectedDate!.month,
          _selectedDate!.day, 23, 59, 59);
      query = query
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay);
    }

    return query;
  }

  Widget _buildChart(String collection) {
    return FutureBuilder<QuerySnapshot>(
      future: _getFilteredQuery(collection).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: const Text(
              'No data available.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        Map<String, int> dataCount = {};
        for (var doc in snapshot.data!.docs) {
          String type = doc['type'];
          dataCount[type] = (dataCount[type] ?? 0) + 1;
        }

        return SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barGroups: dataCount.entries.map((entry) {
                int index = dataCount.keys.toList().indexOf(entry.key);
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      color: Colors.blueAccent,
                      width: 15,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.zero,
                        topRight: Radius.zero,
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalCount(String collection) {
    return FutureBuilder<QuerySnapshot>(
      future: _getFilteredQuery(collection).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: const Text(
              'No records available.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        Map<String, int> dataCount = {};
        int totalCount = 0;

        for (var doc in snapshot.data!.docs) {
          String type = doc['type'];
          dataCount[type] = (dataCount[type] ?? 0) + 1;
          totalCount++; // Increment total count for each document
        }

        List<TableRow> detailsTableRows = dataCount.entries.map((entry) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  entry.key,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${entry.value}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
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
                horizontalInside:
                    BorderSide(color: Colors.white.withOpacity(0.3)),
                verticalInside:
                    BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              children: [
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Type',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Padding(
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
            const SizedBox(height: 10),
            Text(
              'Total ${collection == 'crimes' ? 'Crimes' : 'Floods'}: $totalCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
}
