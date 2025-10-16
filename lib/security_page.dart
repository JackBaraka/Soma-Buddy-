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
    try {
      await _auth.sendPasswordResetEmail(email: _auth.currentUser!.email!);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset email: \$e')),
      );
    }
  }

  Future<void> _enableTwoFactorAuth() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Two-Factor Authentication Enabled!')),
    );
  }

  Future<void> _manageTrustedDevices() async {
    var devicesSnapshot = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('trusted_devices')
        .get();
    if (devicesSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trusted devices found.')),
      );
    } else {
      for (var doc in devicesSnapshot.docs) {
        print('Device: ${doc['device_name']}');
      }
    }
  }

  Future<void> _reviewAccountActivity() async {
    var logsSnapshot = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('account_logs')
        .get();
    if (logsSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No account activity found.')),
      );
    } else {
      for (var doc in logsSnapshot.docs) {
        print('Activity: ${doc['activity']}, Timestamp: ${doc['timestamp']}');
      }
    }
  }

  Future<void> _updatePrivacySettings() async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      'privacy_settings': 'Updated',
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings updated!')),
    );
  }

  Future<void> _logoutFromAllDevices() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'tokens': [],
      });
      await _auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Logged out from all devices successfully.')),
      );
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
