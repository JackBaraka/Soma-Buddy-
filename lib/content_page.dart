import 'package:flutter/material.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  final List<ContentCourse> _courses = [
    ContentCourse(
      title: 'Introduction to Programming',
      description: 'Learn basics of programming with Python',
      progress: 0.75,
      icon: Icons.code,
      color: Colors.blue,
      modules: [
        ContentModule(
            title: 'Variables and Data Types',
            duration: '45 mins',
            isCompleted: true),
        ContentModule(
            title: 'Control Structures',
            duration: '60 mins',
            isCompleted: true),
        ContentModule(
            title: 'Functions', duration: '55 mins', isCompleted: true),
        ContentModule(
            title: 'Object-Oriented Programming',
            duration: '90 mins',
            isCompleted: false),
      ],
    ),
    ContentCourse(
      title: 'Web Development Fundamentals',
      description: 'HTML, CSS, and JavaScript basics',
      progress: 0.5,
      icon: Icons.web,
      color: Colors.orange,
      modules: [
        ContentModule(
            title: 'HTML Structure', duration: '30 mins', isCompleted: true),
        ContentModule(
            title: 'CSS Styling', duration: '45 mins', isCompleted: true),
        ContentModule(
            title: 'JavaScript Basics',
            duration: '60 mins',
            isCompleted: false),
        ContentModule(
            title: 'Building a Simple Website',
            duration: '120 mins',
            isCompleted: false),
      ],
    ),
    ContentCourse(
      title: 'Mobile App Development',
      description: 'Flutter and Dart programming',
      progress: 0.25,
      icon: Icons.smartphone,
      color: Colors.green,
      modules: [
        ContentModule(
            title: 'Dart Programming', duration: '60 mins', isCompleted: true),
        ContentModule(
            title: 'Flutter Widgets', duration: '90 mins', isCompleted: false),
        ContentModule(
            title: 'Navigation and Routing',
            duration: '45 mins',
            isCompleted: false),
        ContentModule(
            title: 'Building a Complete App',
            duration: '180 mins',
            isCompleted: false),
      ],
    ),
  ];

  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Content')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton('My Courses', 0),
              _buildTabButton('Recommended', 1),
              _buildTabButton('Saved', 2),
            ],
          ),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildMyCourses()
                : _selectedTabIndex == 1
                    ? _buildRecommendedCourses()
                    : _buildSavedCourses(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return TextButton(
      onPressed: () => setState(() => _selectedTabIndex = index),
      style: TextButton.styleFrom(
        backgroundColor:
            _selectedTabIndex == index ? Colors.teal : Colors.grey[200],
      ),
      child: Text(title,
          style: TextStyle(
              color: _selectedTabIndex == index ? Colors.white : Colors.black)),
    );
  }

  Widget _buildMyCourses() {
    return ListView.builder(
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return Card(
          child: ListTile(
            title: Text(course.title),
            subtitle: Text(course.description),
            trailing: CircularProgressIndicator(value: course.progress),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildRecommendedCourses() {
    return Center(child: Text('Recommended courses coming soon!'));
  }

  Widget _buildSavedCourses() {
    return Center(child: Text('No saved courses yet.'));
  }
}

class ContentCourse {
  final String title;
  final String description;
  final double progress;
  final IconData icon;
  final Color color;
  final List<ContentModule> modules;

  ContentCourse(
      {required this.title,
      required this.description,
      required this.progress,
      required this.icon,
      required this.color,
      required this.modules});
}

class ContentModule {
  final String title;
  final String duration;
  final bool isCompleted;

  ContentModule(
      {required this.title, required this.duration, required this.isCompleted});
}
