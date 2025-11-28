// lib/savings.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/backend/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/backend/app_scaffold.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  List<Map<String, dynamic>> savings = [];
  List<Map<String, dynamic>> filtered = [];
  double totalSaved = 0.0;
  double totalGoals = 0.0;
  String query = '';

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      query = _searchCtrl.text.trim().toLowerCase();
      _applyFilter();
    });
  }

  Future<void> _loadAll() async {
    savings = await DatabaseHelper.instance.getSavings();
    totalSaved = await DatabaseHelper.instance.computeTotalSaved();
    totalGoals = await DatabaseHelper.instance.computeTotalGoals();
    _applyFilter();
    setState(() {});
  }

  void _applyFilter() {
    if (query.isEmpty) {
      filtered = List.from(savings);
    } else {
      filtered = savings.where((s) {
        final name = (s['name'] as String).toLowerCase();
        return name.contains(query);
      }).toList();
    }
  }

  Color _colorFromHex(String hex) {
    try {
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return Colors.grey;
    }
  }

  void _showAddContributionDialog(
    BuildContext context,
    int savingId,
    VoidCallback refresh,
  ) {
    final TextEditingController amtCtrl = TextEditingController();
    final TextEditingController noteCtrl = TextEditingController();
    DateTime picked = DateTime.now();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSB) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Add Contribution"),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount"),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: "Note (optional)",
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Text("Date: "),
                    TextButton(
                      child: Text(
                        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}",
                      ),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: picked,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) {
                          setSB(() => picked = d);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A7A78),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Add"),
                onPressed: () async {
                  final amt = double.tryParse(amtCtrl.text.trim());
                  final note = noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim();

                  if (amt == null || amt <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Enter a valid amount")),
                    );
                    return;
                  }

                  await DatabaseHelper.instance.addSavingContribution(
                    savingId,
                    amt,
                    "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}",
                    note: note,
                  );

                  refresh();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddSavingDialog() async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime? picked;
    String selectedColor = '2EA66F';

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSB) {
            return AlertDialog(
              title: const Text('Add Saving'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Saving name'),
                  ),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target amount',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Target date: '),
                      TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) setSB(() => picked = d);
                        },
                        child: Text(
                          picked == null
                              ? 'Select'
                              : DateFormat('yyyy-MM-dd').format(picked!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Color: '),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setSB(() => selectedColor = '2EA66F'),
                        child: _colorChoice(
                          '2EA66F',
                          selectedColor == '2EA66F',
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setSB(() => selectedColor = 'E66A5A'),
                        child: _colorChoice(
                          'E66A5A',
                          selectedColor == 'E66A5A',
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setSB(() => selectedColor = '669BEC'),
                        child: _colorChoice(
                          '669BEC',
                          selectedColor == '669BEC',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final target = double.tryParse(targetCtrl.text.trim());
                    if (name.isEmpty || target == null || picked == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    await DatabaseHelper.instance.insertSaving({
                      'name': name,
                      'target': target,
                      'current': 0.0,
                      'color': selectedColor,
                      'targetDate': DateFormat('yyyy-MM-dd').format(picked!),
                    });

                    Navigator.pop(context);
                    await _loadAll();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _colorChoice(String hex, bool selected) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _colorFromHex(hex),
        shape: BoxShape.circle,
        border: selected ? Border.all(width: 2, color: Colors.black) : null,
      ),
    );
  }

  Future<void> _renameSaving(Map<String, dynamic> s) async {
    final ctrl = TextEditingController(text: s['name']);
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Saving'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (res != null && res.isNotEmpty) {
      await DatabaseHelper.instance.renameSaving(s['id'] as int, res);
      await _loadAll();
    }
  }

  Future<void> _changeColor(Map<String, dynamic> s) async {
    String selected = s['color'];
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSB) {
          return AlertDialog(
            title: const Text('Change Color'),
            content: Row(
              children: [
                GestureDetector(
                  onTap: () => setSB(() => selected = '2EA66F'),
                  child: _colorChoice('2EA66F', selected == '2EA66F'),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setSB(() => selected = 'E66A5A'),
                  child: _colorChoice('E66A5A', selected == 'E66A5A'),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setSB(() => selected = '669BEC'),
                  child: _colorChoice('669BEC', selected == '669BEC'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await DatabaseHelper.instance.changeSavingColor(
                    s['id'] as int,
                    selected,
                  );
                  Navigator.pop(context);
                  await _loadAll();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirm(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Saving'),
        content: const Text(
          'Are you sure you want to delete this saving and its history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.deleteSaving(id);
      await _loadAll();
    }
  }

  // bottom sheet: saving detail + history + add contribution
 Future<void> _openSavingDetail(Map<String, dynamic> s) async {
  final id = s['id'] as int;

  // local mutable amount
  double localCurrent = (s['current'] as num).toDouble();

  List<Map<String, dynamic>> history = [];

  Future<void> loadHistory() async {
    history = await DatabaseHelper.instance.getSavingHistory(id);
  }

  await loadHistory();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (context) {
      final amountCtrl = TextEditingController();

      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (context, setSB) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// TITLE + CURRENT AMOUNT
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s['name'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        "₱${localCurrent.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text("Goal: ₱${(s['target'] as num).toStringAsFixed(2)}"),

                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (localCurrent / (s['target'] as num)).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    color: _colorFromHex(s['color']),
                  ),

                  const SizedBox(height: 16),

                  /// INPUT + BUTTON
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Amount",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      ElevatedButton(
                        onPressed: () async {
                          final amt = double.tryParse(amountCtrl.text.trim());
                          if (amt == null || amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Enter valid amount")),
                            );
                            return;
                          }

                          final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
                          await DatabaseHelper.instance.addSavingContribution(id, amt, now);

                          amountCtrl.clear();

                          // Reload updated saving from DB
                          final updated = (await DatabaseHelper.instance.getSavings())
                              .firstWhere((e) => e['id'] == id);

                          setSB(() {
                            localCurrent = (updated['current'] as num).toDouble();
                          });

                          await loadHistory();
                          await _loadAll();
                        },
                        child: const Text("Add"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("History",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 200,
                    child: history.isEmpty
                        ? const Center(child: Text("No history yet"))
                        : ListView.builder(
                            itemCount: history.length,
                            itemBuilder: (_, i) {
                              final h = history[i];
                              return ListTile(
                                title: Text(
                                  "₱${(h['amount'] as num).toStringAsFixed(2)}",
                                ),
                                subtitle: Text(h['date']),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}


  // triple-dot menu handler
  void _onTripleTap(Map<String, dynamic> s, String choice) {
    if (choice == 'rename') _renameSaving(s);
    if (choice == 'color') _changeColor(s);
    if (choice == 'delete') _showDeleteConfirm(s['id'] as int);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 2,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // search
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search savings',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // total saved & goals
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Saved',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<double>(
                            future: DatabaseHelper.instance.computeTotalSaved(),
                            builder: (context, snap) {
                              final v = snap.data ?? totalSaved;
                              return Text(
                                '₱${v.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Goals',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<double>(
                            future: DatabaseHelper.instance.computeTotalGoals(),
                            builder: (context, snap) {
                              final v = snap.data ?? totalGoals;
                              return Text(
                                '₱${v.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // list
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No savings found'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        final color = _colorFromHex(s['color']);
                        final curr = (s['current'] as num).toDouble();
                        final target = (s['target'] as num).toDouble();
                        final progress = target > 0
                            ? (curr / target).clamp(0.0, 1.0)
                            : 0.0;

                        return Card(
                          color: color.withOpacity(0.12),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            onTap: () => _openSavingDetail(s),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: color,
                              child: Text(s['name'][0].toUpperCase()),
                            ),
                            title: Text(
                              s['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  '₱${curr.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text('Goal: ₱${target.toStringAsFixed(2)}'),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[200],
                                  color: color,
                                  minHeight: 8,
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) => _onTripleTap(s, v),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text('Rename'),
                                ),
                                PopupMenuItem(
                                  value: 'color',
                                  child: Text('Change color'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // add button bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAddSavingDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Savings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B7B4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
