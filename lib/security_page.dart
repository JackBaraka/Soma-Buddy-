import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _changePassword() async {
    // Implement change password functionality
  }

  Future<void> _enableTwoFactorAuth() async {
    // Implement two-factor authentication functionality
  }

  Future<void> _manageTrustedDevices() async {
    // Implement trusted devices management functionality
  }

  Future<void> _reviewAccountActivity() async {
    // Fetch and display account activity logs from Firestore
  }

  Future<void> _updatePrivacySettings() async {
    // Implement privacy settings update functionality
  }

  Future<void> _logoutFromAllDevices() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'tokens': [],
      });
      await _auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Your Security Preferences',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Update your password, enable 2FA, and review account activity.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  SecurityOption(
                    title: 'Change Password',
                    icon: Icons.lock,
                    onTap: _changePassword,
                  ),
                  SecurityOption(
                    title: 'Enable Two-Factor Authentication',
                    icon: Icons.shield,
                    onTap: _enableTwoFactorAuth,
                  ),
                  SecurityOption(
                    title: 'Manage Trusted Devices',
                    icon: Icons.devices,
                    onTap: _manageTrustedDevices,
                  ),
                  SecurityOption(
                    title: 'Review Account Activity',
                    icon: Icons.history,
                    onTap: _reviewAccountActivity,
                  ),
                  SecurityOption(
                    title: 'Privacy Settings',
                    icon: Icons.privacy_tip,
                    onTap: _updatePrivacySettings,
                  ),
                  SecurityOption(
                    title: 'Logout from All Devices',
                    icon: Icons.exit_to_app,
                    onTap: _logoutFromAllDevices,
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

class SecurityOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const SecurityOption({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
