// dashboard.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_1/backend/app_scaffold.dart';
import 'package:flutter_application_1/backend/database_helper.dart';

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

// -----------------------------
// NET WORTH CARD -> Stacked Bar Chart for last 12 months
// -----------------------------
class NetWorthCard extends StatefulWidget {
  const NetWorthCard({super.key});

  @override
  State<NetWorthCard> createState() => _NetWorthCardState();
}

class _NetWorthCardState extends State<NetWorthCard> {
  double totalNetWorth = 0.0;
  List<Map<String, dynamic>> accounts = [];

  @override
  void initState() {
    super.initState();
    loadNetWorth();
  }

  Future<void> loadNetWorth() async {
    final db = DatabaseHelper.instance;
    final accs = await db.getAccounts();

    double total = 0;
    for (var a in accs) {
      total += (a['balance'] as num).toDouble();
    }

    setState(() {
      accounts = accs;
      totalNetWorth = total;
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

            const SizedBox(height: 6),

            Text(
              "₱${totalNetWorth.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF064D76),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 260,
              child: accounts.isEmpty
                  ? const Center(child: Text("No accounts found"))
                  : BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),

                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final acc = accounts[group.x.toInt()];
                              return BarTooltipItem(
                                "${acc['bankName']}\n₱${rod.toY.toStringAsFixed(2)}",
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),

                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index >= accounts.length) {
                                  return Container();
                                }

                                String name = accounts[index]["bankName"];
                                if (name.length > 6) {
                                  name = name.substring(0, 6);
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        barGroups: List.generate(accounts.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: (accounts[i]["balance"] as num).toDouble(),
                                color: const Color(0xFF064D76),
                                borderRadius: BorderRadius.circular(4),
                                width: 18,
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------
// SPENDING CARD (unchanged from last version, connected to DB)
// -----------------------------
class SpendingCard extends StatefulWidget {
  const SpendingCard({super.key});

  @override
  State<SpendingCard> createState() => _SpendingCardState();
}

class _SpendingCardState extends State<SpendingCard> {
  Map<String, double> categoryTotals = {};
  double total = 0.0;

  @override
  void initState() {
    super.initState();
    loadSpendingTotals();
  }

  Future<void> loadSpendingTotals() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('spendings', columns: ['category', 'amount']);

    final Map<String, double> map = {};
    double t = 0;

    for (var r in rows) {
      final cat = (r['category'] ?? 'Other') as String;
      final amt = (r['amount'] as num).toDouble();
      t += amt;
      map[cat] = (map[cat] ?? 0) + amt;
    }

    setState(() {
      categoryTotals = map;
      total = t;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];

    if (categoryTotals.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          color: Colors.grey[300],
          title: 'No data',
        ),
      );
    } else {
      final colors = const [
        Color(0xFF0A7A78),
        Color(0xFF064D76),
        Color(0xFFE1B12C),
        Color(0xFFB83227),
        Color(0xFF669BEC),
      ];

      int i = 0;
      categoryTotals.forEach((cat, amt) {
        final perc = total > 0 ? (amt / total * 100) : 0.0;

        sections.add(
          PieChartSectionData(
            value: amt,
            color: colors[i % colors.length],
            title: "${perc.toStringAsFixed(0)}%",
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );

        i++;
      });
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Spending Breakdown",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Centered Pie Chart
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ▼▼ LABELS NOW UNDER THE PIE CHART ▼▼
            if (categoryTotals.isNotEmpty)
              Column(
                children: categoryTotals.entries.map((e) {
                  final idx =
                      categoryTotals.keys.toList().indexOf(e.key);
                  final color = [
                    Color(0xFF0A7A78),
                    Color(0xFF064D76),
                    Color(0xFFE1B12C),
                    Color(0xFFB83227),
                    Color(0xFF669BEC),
                  ][idx % 5];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.key,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "₱${e.value.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------
// SAVINGS CARD (Dynamic - from DB)
// -----------------------------
class SavingsCard extends StatefulWidget {
  const SavingsCard({super.key});

  @override
  State<SavingsCard> createState() => _SavingsCardState();
}

class _SavingsCardState extends State<SavingsCard> {
  double totalSaved = 0.0;
  double totalGoals = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;

    final saved = await db.computeTotalSaved();
    final goals = await db.computeTotalGoals();

    setState(() {
      totalSaved = saved;
      totalGoals = goals;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Savings",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // Total Saved
              Text(
                "₱${totalSaved.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Total Goals
              Text(
                "Goal: ₱${totalGoals.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
