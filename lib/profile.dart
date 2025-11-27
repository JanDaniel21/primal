import 'package:flutter/material.dart';
import 'app_scaffold.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 4,
      body: Center(
        child: Text("Profile Page"),
      ),
    );
  }
}
