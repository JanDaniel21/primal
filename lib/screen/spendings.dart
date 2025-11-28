import 'package:flutter/material.dart';
import 'package:flutter_application_1/backend/database_helper.dart';
import '../backend/app_scaffold.dart';

class SpendingsPage extends StatefulWidget {
  const SpendingsPage({super.key});

  @override
  State<SpendingsPage> createState() => _SpendingsPageState();
}

class _SpendingsPageState extends State<SpendingsPage> {
  void refreshPage() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 3,
      body: Column(
        children: [
          const TotalSpendingCard(),
          const SizedBox(height: 8),

          // LIST + SCROLL
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SpendingBreakdownCard(key: UniqueKey()),
            ),
          ),

          // FIXED BOTTOM BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Spending"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A7A78), // matches add account
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => showAddSpendingDialog(context, refreshPage),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------
// TOTAL SPENDING
// -----------------------------------
class TotalSpendingCard extends StatefulWidget {
  const TotalSpendingCard({super.key});

  @override
  State<TotalSpendingCard> createState() => _TotalSpendingCardState();
}

class _TotalSpendingCardState extends State<TotalSpendingCard> {
  double total = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final v = await DatabaseHelper.instance.computeTotalSpending();
    setState(() => total = v);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Total Spending",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "₱${total.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------
// LIST OF SPENDINGS
// -----------------------------------
class SpendingBreakdownCard extends StatefulWidget {
  const SpendingBreakdownCard({super.key});

  @override
  State<SpendingBreakdownCard> createState() => _SpendingBreakdownCardState();
}

class _SpendingBreakdownCardState extends State<SpendingBreakdownCard> {
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    rows = await DatabaseHelper.instance.getSpendings();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Spending Breakdown",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                return ListTile(
                  title: Text(r["category"]),
                  subtitle: Text(r["date"]),
                  trailing: Text(
                    "₱${(r["amount"] as num).toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

// -----------------------------------
// ADD SPENDING POPUP
// -----------------------------------
void showAddSpendingDialog(
  BuildContext context,
  VoidCallback onDone,
) {
  final catCtrl = TextEditingController();
  final amtCtrl = TextEditingController();
  DateTime? picked;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setSB) {
        return AlertDialog(
          title: const Text("Add Spending"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) {
                    setSB(() => picked = d);
                  }
                },
                child: Text(
                  picked == null
                      ? "Select Date"
                      : "${picked!.year}-${picked!.month.toString().padLeft(2, '0')}-${picked!.day.toString().padLeft(2, '0')}",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final cat = catCtrl.text.trim();
                final amt = double.tryParse(amtCtrl.text.trim());

                if (cat.isEmpty || amt == null || picked == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                  return;
                }

                await DatabaseHelper.instance.insertSpending({
                  "category": cat,
                  "amount": amt,
                  "date":
                      "${picked!.year}-${picked!.month.toString().padLeft(2, '0')}-${picked!.day.toString().padLeft(2, '0')}",
                });

                Navigator.pop(context);
                onDone();
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    ),
  );
}
