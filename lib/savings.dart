import 'package:flutter/material.dart';
import 'app_scaffold.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 2,
      body: Center(
        child: Text("Savings Page"),
      ),
    );
  }
}
