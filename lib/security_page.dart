import 'package:flutter/material.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

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
              'Update your password, enable two-factor authentication, and review account activity.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  SecurityOption(
                    title: 'Change Password',
                    icon: Icons.lock,
                    onTap: () {},
                  ),
                  SecurityOption(
                    title: 'Enable Two-Factor Authentication',
                    icon: Icons.shield,
                    onTap: () {},
                  ),
                  SecurityOption(
                    title: 'Manage Trusted Devices',
                    icon: Icons.devices,
                    onTap: () {},
                  ),
                  SecurityOption(
                    title: 'Review Account Activity',
                    icon: Icons.history,
                    onTap: () {},
                  ),
                  SecurityOption(
                    title: 'Privacy Settings',
                    icon: Icons.privacy_tip,
                    onTap: () {},
                  ),
                  SecurityOption(
                    title: 'Logout from All Devices',
                    icon: Icons.exit_to_app,
                    onTap: () {},
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
