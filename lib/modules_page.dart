import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'content_page.dart';
import 'progress_page.dart';
import 'collaboration_page.dart';
import 'rewards_page.dart';
import 'security_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soma Buddy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const ModulesPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ModulesPage extends StatelessWidget {
  const ModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SOMA BUDDY',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to Soma Buddy',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI-Powered Learning Companion',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
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
];

class ModuleCard extends StatelessWidget {
  final Module module;

  const ModuleCard({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
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
                module.color.withOpacity(0.8),
                module.color.withOpacity(0.5)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                module.icon,
                size: 40,
                color: Colors.white,
              ),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
