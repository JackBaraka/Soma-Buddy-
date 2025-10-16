// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'progress_page.dart';
import 'collaboration_page.dart';
import 'rewards_page.dart';
import 'security_page.dart';
import 'login_page.dart';
import 'offline_mode_page.dart';
import 'content_page.dart';

class ModulesPage extends StatefulWidget {
  const ModulesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ModulesPageState createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userName = 'User';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] ?? userName;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error logging out. Please try again.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SOMA BUDDY',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.indigo],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $userName',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your AI-Powered Learning Companion',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: moduleList.length,
                  itemBuilder: (context, index) {
                    return ModuleCard(module: moduleList[index]);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Module {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget page;

  Module({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.page,
  });
}

List<Module> moduleList = [
  Module(
    title: 'User Profile',
    description: 'Manage your academic profile and preferences',
    icon: Icons.person,
    color: Colors.blue,
    page: const ProfilePage(),
  ),
  Module(
    title: 'Content',
    description: 'Personalized learning recommendations',
    icon: Icons.library_books,
    color: Colors.orange,
    page: const ContentPage(),
  ),
  Module(
    title: 'Progress',
    description: 'Track your learning achievements',
    icon: Icons.trending_up,
    color: Colors.purple,
    page: const ProgressPage(),
  ),
  Module(
    title: 'Collaborate',
    description: 'Connect with peers for group study',
    icon: Icons.group,
    color: Colors.red,
    page: const CollaborationPage(),
  ),
  Module(
    title: 'Rewards',
    description: 'View your earned badges and points',
    icon: Icons.star,
    color: Colors.amber,
    page: const RewardsPage(),
  ),
  Module(
    title: 'Security',
    description: 'Manage your privacy settings',
    icon: Icons.security,
    color: Colors.teal,
    page: const SecurityPage(),
  ),
  Module(
    title: 'Offline Mode',
    description: 'Access your saved content without internet',
    icon: Icons.offline_pin,
    color: Colors.green,
    page: const OfflineModePage(),
  ),
];

class ModuleCard extends StatelessWidget {
  final Module module;

  const ModuleCard({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => module.page),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                module.color.withAlpha(230),
                module.color.withAlpha(150)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(module.icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                module.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                module.description,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
