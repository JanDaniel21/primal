import 'package:flutter/material.dart';
import '../backend/app_scaffold.dart';
import '../backend/database_helper.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  List<Map<String, dynamic>> accounts = [];

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    accounts = await DatabaseHelper.instance.getAccounts();
    setState(() {});
  }

  // -------------------------
  // ADD ACCOUNT POPUP
  // -------------------------
void showAddAccountDialog() {
  final TextEditingController bankController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Add Bank Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankController,
              decoration: InputDecoration(labelText: "Bank Name"),
            ),
            TextField(
              controller: balanceController,
              decoration: InputDecoration(labelText: "Balance"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String bank = bankController.text.trim();
              String balanceText = balanceController.text.trim();

              // Validate inputs
              if (bank.isEmpty || balanceText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill all fields")));
                return;
              }

              double? balance = double.tryParse(balanceText);

              if (balance == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Balance must be a number")));
                return;
              }

              // Insert into DB
              await DatabaseHelper.instance.insertAccount({
                "bankName": bank,
                "balance": balance,
              });

              Navigator.pop(context);
              loadAccounts(); // Refresh UI
            },
            child: Text("Add"),
          ),
        ],
      );
    },
  );
}

  // -------------------------
  // EDIT ACCOUNT POPUP
  // -------------------------
  void showEditAccountDialog(int id, String bankName, double balance) {
    final TextEditingController bankNameController =
        TextEditingController(text: bankName);

    final TextEditingController balanceController =
        TextEditingController(text: balance.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Account"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankNameController,
                decoration: const InputDecoration(labelText: "Bank Name"),
              ),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Balance"),
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
                final newName = bankNameController.text.trim();
                final newBalance =
                    double.tryParse(balanceController.text.trim());

                if (newName.isEmpty || newBalance == null) return;

                await DatabaseHelper.instance.updateAccount(
                    id, newName, newBalance);

                Navigator.pop(context);
                loadAccounts();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // -------------------------
  // DELETE CONFIRMATION
  // -------------------------
  void showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete this account?"),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteAccount(id);
              Navigator.pop(context);
              loadAccounts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ----------------------------------
  // MAIN PAGE
  // ----------------------------------
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 1,

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // -----------------------------
            // LIST OF ACCOUNTS
            // -----------------------------
            Expanded(
              child: ListView.builder(
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final acc = accounts[index];

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance,
                        size: 40,
                        color: Colors.blueGrey,
                      ),

                      title: Text(
                        acc["bankName"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        "₱${acc["balance"].toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: "edit",
                            child: Text("Edit"),
                          ),
                          const PopupMenuItem(
                            value: "delete",
                            child: Text("Delete"),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == "edit") {
                            showEditAccountDialog(
                              acc["id"],
                              acc["bankName"],
                              acc["balance"],
                            );
                          } else if (value == "delete") {
                            showDeleteDialog(acc["id"]);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------
            // ADD ACCOUNT BUTTON
            // -----------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: showAddAccountDialog,
                icon: const Icon(Icons.add),
                label: const Text("Add Account"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B7B4A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
