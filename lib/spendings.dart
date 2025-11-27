import 'package:flutter/material.dart';
import 'package:flutter_application_1/database_helper.dart';
import 'package:path/path.dart';
import 'app_scaffold.dart';

class SpendingsPage extends StatelessWidget {
  const SpendingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 3,
      body: Column(
        children: [
          const TotalSpendingCard(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: const SpendingBreakdownCard(),
            ),
          ),
        ],
      ),
    );
  }
}

class TotalSpendingCard extends StatefulWidget {
  const TotalSpendingCard({super.key});

  @override
  State<TotalSpendingCard> createState() => _TotalSpendingCardState();
}

class _TotalSpendingCardState extends State<TotalSpendingCard> {
  double totalSpending = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTotalSpending();
  }

  Future<void> _loadTotalSpending() async {
    final value = await DatabaseHelper.instance.computeTotalSpending();
    setState(() {
      totalSpending = value;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Total Spending",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "₱${totalSpending.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.redAccent,
                shadows: [
                  Shadow(
                    blurRadius: 3,
                    offset: Offset(1, 1),
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpendingBreakdownCard extends StatefulWidget {
  const SpendingBreakdownCard({super.key});

  @override
  State<SpendingBreakdownCard> createState() => _SpendingBreakdownCardState();
}

class _SpendingBreakdownCardState extends State<SpendingBreakdownCard> {
  List<Map<String, dynamic>> spendings = [];

  @override
  void initState() {
    super.initState();
    _loadSpendings();
  }

  Future<void> _loadSpendings() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'spendings',
      columns: ['id', 'category', 'amount', 'date'],
      orderBy: 'date DESC',
    );
    setState(() {
      spendings = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Spending Breakdown",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Scrollable list of spendings
          SizedBox(
            height: 400,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: spendings.length,
              itemBuilder: (context, index) {
                final item = spendings[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['category'],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(item['date'],
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Text("₱${item['amount'].toString()}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
