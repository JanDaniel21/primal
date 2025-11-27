import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_scaffold.dart';
import 'database_helper.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            NetWorthCard(),
            SizedBox(height: 16),
            SpendingCard(),
            SizedBox(height: 16),
            SavingsCard(),
          ],
        ),
      ),
    );
  }
}


// NET WORTH CARD (LINE CHART)


class NetWorthCard extends StatefulWidget {
  const NetWorthCard({super.key});

  @override
  State<NetWorthCard> createState() => _NetWorthCardState();
}

class _NetWorthCardState extends State<NetWorthCard> {
  List<FlSpot> spots = [];
  double totalNetWorth = 0;

  @override
  void initState() {
    super.initState();
    loadNetWorth();
  }

  Future<void> loadNetWorth() async {
    final db = DatabaseHelper.instance;
    final accounts = await db.fetchAccounts();

    double total = 0;
    for (var acc in accounts) {
      total += (acc['balance'] as num).toDouble();
    }

    // Build simple trending graph (just as example)
    List<FlSpot> generated = [];
    for (int i = 0; i < 6; i++) {
      generated.add(FlSpot(i.toDouble(), total * (0.8 + i * 0.04)));
    }

    setState(() {
      totalNetWorth = total;
      spots = generated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Net Worth",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            Text(
              "₱${totalNetWorth.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF064D76),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 3,
                      color: const Color(0xFF064D76),
                      spots: spots.isEmpty
                          ? [FlSpot(0, 0)] // placeholder if DB empty
                          : spots,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// SPENDING CARD (PIE CHART)

class SpendingCard extends StatelessWidget {
  const SpendingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Spending Breakdown",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: 40,
                      color: Color(0xFF0A7A78),
                      title: "Food",
                    ),
                    PieChartSectionData(
                      value: 30,
                      color: Color(0xFF064D76),
                      title: "Bills",
                    ),
                    PieChartSectionData(
                      value: 20,
                      color: Color(0xFFE1B12C),
                      title: "Leisure",
                    ),
                    PieChartSectionData(
                      value: 10,
                      color: Color(0xFFB83227),
                      title: "Other",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SAVINGS CARD

class SavingsCard extends StatelessWidget {
  const SavingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Savings",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                "₱12,540.00",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Goal: ₱50,000",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}