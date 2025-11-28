import 'package:flutter/material.dart';
import '../backend/app_scaffold.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_application_1/main.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  String _name = "John Doe";
  bool _isDarkMode = false;

  final ImagePicker _picker = ImagePicker();

  String _version = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadAppVersion();
  }

  // Load app version
  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = "v${info.version}+${info.buildNumber}";
    });
  }

  // Load saved profile data
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    final name = prefs.getString('profile_name');
    final darkMode = prefs.getBool('profile_dark_mode') ?? false;

    setState(() {
      if (path != null) _profileImage = File(path);
      if (name != null) _name = name;
      _isDarkMode = darkMode;
    });
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      final dir = await getApplicationDocumentsDirectory();
      final newPath = '${dir.path}/profile.png';
      final savedImage = await File(image.path).copy(newPath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', savedImage.path);

      setState(() {
        _profileImage = savedImage;
      });
    }
  }

  // Edit name
  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Name"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text("Save")),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', result);
      setState(() {
        _name = result;
      });
    }
  }

  // Toggle dark mode
Future<void> _toggleDarkMode(bool value) async {
final appState = context.findAncestorStateOfType<MyAppState>();
if (appState != null) {
  appState.setDarkMode(value);
}


  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('profile_dark_mode', value);

  setState(() {
    _isDarkMode = value;
  });
}

  // Reset all local data
  Future<void> _resetLocalData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset App Data"),
        content: const Text(
            "This will clear your saved profile name, picture, and preferences."),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Reset"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Delete profile image if exists
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/profile.png");
    if (await file.exists()) {
      await file.delete();
    }

    setState(() {
      _profileImage = null;
      _name = "John Doe";
      _isDarkMode = false;
    });
  }

  // Log out
  Future<void> _logout() async {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 4,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Picture
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? const Icon(Icons.person, size: 70, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Name
            GestureDetector(
              onTap: _editName,
              child: Text(
                _name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Dark Mode Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Dark Mode", style: TextStyle(fontSize: 18)),
                Switch(value: _isDarkMode, onChanged: _toggleDarkMode),
              ],
            ),
            const Divider(height: 40),

            // Reset local data
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Reset Local Data"),
              onTap: _resetLocalData,
            ),

            // About / Version
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("App Version"),
              subtitle: Text(_version),
            ),
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: const Text("Log Out"),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
