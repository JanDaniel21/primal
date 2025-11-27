import 'package:flutter/material.dart';
import 'app_scaffold.dart';

class SpendingsPage extends StatelessWidget {
  const SpendingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 3,
      body: Center(
        child: Text("Spendings Page"),
      ),
    );
  }
}
